CREATE TABLE pypi_dim_next.download_counts (
  day_fk              INTEGER  NOT NULL,
  project_version_fk  INTEGER  NOT NULL,
  installer_fk        SMALLINT NOT NULL,
  python_version_fk   SMALLINT NOT NULL,
  number_of_downloads INTEGER  NOT NULL,
  _day_chunk          SMALLINT NOT NULL
)
  PARTITION BY LIST (_day_chunk);

SELECT util.create_table_partitions('pypi_dim_next', 'download_counts', 'SELECT util.get_all_chunks()');


CREATE OR REPLACE FUNCTION pypi_tmp.transform_download_counts(param_day_chunk SMALLINT)
  RETURNS SETOF pypi_dim_next.download_counts AS $$

BEGIN
  RETURN QUERY
  SELECT
    day_id                                      AS day_fk,
    project_version_id                          AS project_version_fk,
    coalesce(installer_id, -1) :: SMALLINT      AS installer_fk,
    coalesce(python_version_id, -1) :: SMALLINT AS python_version_fk,
    number_of_downloads,
    param_day_chunk
  FROM pypi_data.download_counts
    LEFT JOIN pypi_tmp.project_version
      ON download_counts.project_version = project_version.project_version_name
         AND download_counts.project = project_version.project_name

    LEFT JOIN pypi_dim_next.installer
      ON download_counts.installer = installer.installer_name

    LEFT JOIN pypi_dim_next.python_version
      ON download_counts.python_version = python_version.python_version_name
  WHERE
    -- this will return in a few milliseconds for partitions with days in different chunks
    pypi_data.compute_chunk(download_counts.day_id) = param_day_chunk;
END

$$
LANGUAGE plpgsql;


CREATE FUNCTION pypi_tmp.insert_download_counts(param_day_chunk INTEGER)
  RETURNS VOID AS $$

BEGIN
  EXECUTE 'INSERT INTO pypi_dim_next.download_counts_' || param_day_chunk ||
          ' (SELECT * FROM pypi_tmp.transform_download_counts( ' || param_day_chunk || '::SMALLINT))';
END
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pypi_tmp.constrain_download_counts()
  RETURNS VOID AS $$
SELECT util.add_fk('pypi_dim_next', 'download_counts', 'time', 'day');
SELECT util.add_fk('pypi_dim_next', 'download_counts', 'pypi_dim_next', 'project_version');
SELECT util.add_fk('pypi_dim_next', 'download_counts', 'pypi_dim_next', 'installer');
SELECT util.add_fk('pypi_dim_next', 'download_counts', 'pypi_dim_next', 'python_version');
$$
LANGUAGE SQL;

