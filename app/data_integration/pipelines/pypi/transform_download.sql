CREATE TABLE pypi_dim_next.download (
  day_fk              INTEGER  NOT NULL,
  project_version_fk  INTEGER  NOT NULL,
  installer_fk        SMALLINT NOT NULL,
  number_of_downloads INTEGER  NOT NULL,
  _day_chunk          SMALLINT NOT NULL
)
  PARTITION BY LIST (_day_chunk);

SELECT util.create_table_partitions('pypi_dim_next', 'download', 'SELECT util.get_all_chunks()');


CREATE OR REPLACE FUNCTION pypi_tmp.transform_download(param_day_chunk SMALLINT)
  RETURNS SETOF pypi_dim_next.DOWNLOAD AS $$

BEGIN
  RETURN QUERY
  SELECT
    day_id                                 AS day_fk,
    project_version_id                     AS project_version_fk,
    coalesce(installer_id, -1) :: SMALLINT AS installer_fk,
    number_of_downloads,
    param_day_chunk
  FROM pypi_data.download
    LEFT JOIN pypi_tmp.project_version
      ON download.project_version = project_version.project_version_name
         AND download.project = project_version.project_name

    LEFT JOIN pypi_dim_next.installer
      ON download.installer = installer.installer_name
  WHERE
    -- this will return in a few milliseconds for partitions with days in different chunks
    pypi_tmp.compute_chunk(download.day_id) = param_day_chunk;
END

$$
LANGUAGE plpgsql;


CREATE FUNCTION pypi_tmp.insert_download(param_day_chunk INTEGER)
  RETURNS VOID AS $$

BEGIN
  EXECUTE 'INSERT INTO pypi_dim_next.download_' || param_day_chunk ||
          ' (SELECT * FROM pypi_tmp.transform_download( ' || param_day_chunk || '::SMALLINT))';
END
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pypi_tmp.constrain_download()
  RETURNS VOID AS $$
SELECT util.add_fk('pypi_dim_next', 'download', 'time', 'day');
SELECT util.add_fk('pypi_dim_next', 'download', 'pypi_dim_next', 'project_version');
SELECT util.add_fk('pypi_dim_next', 'download', 'pypi_dim_next', 'installer');
$$
LANGUAGE SQL;

