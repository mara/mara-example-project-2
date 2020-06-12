CREATE FOREIGN TABLE pypi_dim_next.download_counts_data_set (
  "Download date"   DATE    NOT NULL,
  "Project ID"      TEXT    NOT NULL,
  "Project"         TEXT    NOT NULL,
  "Project version" TEXT    NOT NULL,
  "Installer"       TEXT    NOT NULL,
  "Python version"  TEXT    NOT NULL,
  "# Downloads"     INTEGER NOT NULL

) SERVER cstore_server OPTIONS ( COMPRESSION 'pglz');


CREATE OR REPLACE FUNCTION pypi_tmp.create_download_counts_data_set(day_chunk SMALLINT)
  RETURNS SETOF pypi_dim_next.DOWNLOAD_COUNTS_DATA_SET AS $$
SELECT
  _date                AS "Download date",
  project_id :: TEXT   AS "Project ID",
  project_name         AS "Project",
  project_version_name AS "Project version",
  installer_name       AS "Installer",
  python_version_name  AS "Python version",
  number_of_downloads  AS "# Downloads"
FROM pypi_dim_next.download_counts
  JOIN time.day ON day_fk = day_id
  JOIN pypi_dim_next.installer ON installer_fk = installer_id
  JOIN pypi_dim_next.project_version ON project_version_fk = project_version_id
  JOIN pypi_dim_next.project ON project_fk = project_id
  JOIN pypi_dim_next.python_version ON python_version_fk = python_version_id
WHERE _day_chunk = $1
$$
LANGUAGE SQL;


CREATE OR REPLACE FUNCTION pypi_tmp.insert_download_counts_data_set(day_chunk SMALLINT)
  RETURNS VOID AS $$
BEGIN
  EXECUTE 'CREATE TABLE pypi_tmp.download_counts_data_set_' || day_chunk
          || ' AS SELECT * FROM pypi_tmp.create_download_counts_data_set(' || day_chunk || '::SMALLINT );';

  EXECUTE 'INSERT INTO pypi_dim_next.download_counts_data_set SELECT * FROM pypi_tmp.download_counts_data_set_'
          || day_chunk || ';';

  EXECUTE 'DROP TABLE pypi_tmp.download_counts_data_set_' || day_chunk;

END;
$$
LANGUAGE plpgsql;


