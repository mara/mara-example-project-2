DROP FOREIGN TABLE IF EXISTS pp_dim_next.python_project_activity_data_set;

CREATE FOREIGN TABLE pp_dim_next.python_project_activity_data_set (
  "Date"                   DATE NOT NULL,
  "Project ID"             TEXT NOT NULL,
  "Project"                TEXT NOT NULL,
  "# Downloads"            INTEGER,
  "# Forks"                INTEGER,
  "# Commits"              INTEGER,
  "# Closed pull requests" INTEGER

) SERVER cstore_server OPTIONS ( COMPRESSION 'pglz');


CREATE OR REPLACE FUNCTION pp_tmp.create_python_project_activity_data_set(day_chunk SMALLINT)
  RETURNS SETOF pp_dim_next.python_project_activity_DATA_SET AS $$
SELECT
  _date                          AS "Date",
  project_id :: TEXT             AS "Project ID",
  project_name                   AS "Project",
  number_of_downloads            AS "# Downloads",
  number_of_forks                AS "# Forks",
  number_of_commits              AS "# Commits",
  number_of_closed_pull_requests AS "# Closed pull requests"
FROM pp_dim_next.python_project_activity
  JOIN time.day ON day_fk = day_id
  JOIN pypi_dim.project ON project_fk = project_id
WHERE _day_chunk = $1
$$
LANGUAGE SQL;


CREATE OR REPLACE FUNCTION pp_tmp.insert_python_project_activity_data_set(day_chunk SMALLINT)
  RETURNS VOID AS $$
BEGIN
  EXECUTE 'CREATE TABLE pp_tmp.python_project_activity_data_set_' || day_chunk
          || ' AS SELECT * FROM pp_tmp.create_python_project_activity_data_set(' || day_chunk || '::SMALLINT );';

  EXECUTE 'INSERT INTO pp_dim_next.python_project_activity_data_set SELECT * FROM pp_tmp.python_project_activity_data_set_'
          || day_chunk || ';';

  EXECUTE 'DROP TABLE pp_tmp.python_project_activity_data_set_' || day_chunk;

END;
$$
LANGUAGE plpgsql;


