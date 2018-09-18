DROP TABLE IF EXISTS pp_dim_next.python_project_activity CASCADE;

CREATE TABLE pp_dim_next.python_project_activity (
  day_fk                         INTEGER  NOT NULL,
  project_fk                     INTEGER  NOT NULL,
  number_of_downloads            INTEGER  NOT NULL,
  number_of_forks                INTEGER,
  number_of_commits              INTEGER,
  number_of_closed_pull_requests INTEGER,
  _day_chunk                     SMALLINT NOT NULL
)
  PARTITION BY LIST (_day_chunk);

SELECT util.create_table_partitions('pp_dim_next', 'python_project_activity', 'SELECT util.get_all_chunks()');


CREATE OR REPLACE FUNCTION pp_tmp.transform_python_project_activity(param_day_chunk SMALLINT)
  RETURNS SETOF pp_dim_next.PYTHON_PROJECT_ACTIVITY AS $$

BEGIN
  RETURN QUERY
  WITH project_downloads AS (
      SELECT
        project_fk,
        day_fk,
        sum(number_of_downloads) :: INTEGER AS number_of_downloads
      FROM pypi_dim.download_counts
        JOIN pypi_dim.project_version ON project_version_fk = project_version_id
      WHERE
        download_counts._day_chunk = param_day_chunk
      GROUP BY project_fk, day_fk
  )

  SELECT
    project_downloads.day_fk,
    project_downloads.project_fk,
    project_downloads.number_of_downloads,
    python_repo_activity.number_of_forks,
    python_repo_activity.number_of_commits,
    python_repo_activity.number_of_closed_pull_requests,
    param_day_chunk
  FROM project_downloads
    LEFT JOIN pp_tmp.python_repo_activity
      ON project_downloads.project_fk = python_repo_activity.project_id
         AND project_downloads.day_fk = python_repo_activity.day_id;
END $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pp_tmp.insert_python_project_activity(param_day_chunk INTEGER)
  RETURNS VOID AS $$
BEGIN
  EXECUTE 'INSERT INTO pp_dim_next.python_project_activity_' || param_day_chunk ||
          ' (SELECT * FROM pp_tmp.transform_python_project_activity( ' || param_day_chunk || '::SMALLINT))';

  EXECUTE 'SELECT util.add_index(''pp_dim_next'',''python_project_activity_' || param_day_chunk ||
          ''', column_names := array[''day_fk'',''project_fk''], unique_ := TRUE)';
END $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pp_tmp.constrain_python_project_activity()
  RETURNS VOID AS $$
SELECT util.add_fk('pp_dim_next', 'python_project_activity', 'time', 'day');
SELECT util.add_fk('pp_dim_next', 'python_project_activity', 'pypi_dim', 'project');
$$
LANGUAGE SQL;


