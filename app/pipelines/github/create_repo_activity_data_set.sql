DROP FOREIGN TABLE IF EXISTS gh_dim_next.repo_activity_data_set;

CREATE FOREIGN TABLE gh_dim_next.repo_activity_data_set (
  "Date"                   DATE NOT NULL,
  "Repo ID"                TEXT NOT NULL,
  "User"                   TEXT NOT NULL,
  "Repo"                   TEXT NOT NULL,
  "# Forks"                INTEGER,
  "# Commits"              INTEGER,
  "# Closed pull requests" INTEGER

) SERVER cstore_server OPTIONS ( COMPRESSION 'pglz');


CREATE OR REPLACE FUNCTION gh_tmp.create_repo_activity_data_set(day_chunk SMALLINT)
  RETURNS SETOF gh_dim_next.REPO_ACTIVITY_DATA_SET AS $$
SELECT
  _date                          AS "Date",
  repo_id :: TEXT                AS "Repo ID",
  user_name                      AS "User",
  repo_name                      AS "Repo",
  number_of_forks                AS "# Forks",
  number_of_commits              AS "# Commits",
  number_of_closed_pull_requests AS "# Closed pull requests"
FROM gh_dim_next.repo_activity
  JOIN time.day ON day_fk = day_id
  JOIN gh_dim_next.repo ON repo_fk = repo_id
WHERE _day_chunk = $1
$$
LANGUAGE SQL;


CREATE OR REPLACE FUNCTION gh_tmp.insert_repo_activity_data_set(day_chunk SMALLINT)
  RETURNS VOID AS $$
BEGIN
  EXECUTE 'CREATE TABLE gh_tmp.repo_activity_data_set_' || day_chunk
          || ' AS SELECT * FROM gh_tmp.create_repo_activity_data_set(' || day_chunk || '::SMALLINT );';

  EXECUTE 'INSERT INTO gh_dim_next.repo_activity_data_set SELECT * FROM gh_tmp.repo_activity_data_set_'
          || day_chunk || ';';

  EXECUTE 'DROP TABLE gh_tmp.repo_activity_data_set_' || day_chunk;

END;
$$
LANGUAGE plpgsql;


