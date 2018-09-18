CREATE TABLE gh_dim_next.repo_activity (
  day_fk                         INTEGER  NOT NULL,
  repo_fk                        INTEGER  NOT NULL,
  number_of_forks                INTEGER,
  number_of_commits              INTEGER,
  number_of_closed_pull_requests INTEGER,
  _day_chunk                     SMALLINT NOT NULL
)
  PARTITION BY LIST (_day_chunk);

SELECT util.create_table_partitions('gh_dim_next', 'repo_activity', 'SELECT util.get_all_chunks()');


CREATE OR REPLACE FUNCTION gh_tmp.transform_repo_activity(param_day_chunk SMALLINT)
  RETURNS SETOF gh_dim_next.REPO_ACTIVITY AS $$

BEGIN
  RETURN QUERY
  SELECT
    day_id  AS day_fk,
    repo_id AS repo_fk,
    number_of_forks,
    number_of_commits,
    number_of_closed_pull_requests,
    param_day_chunk
  FROM gh_data.repo_activity
    LEFT JOIN gh_dim_next.repo
      ON repo_activity.repo = repo.repo_name AND repo_activity.user = repo.user_name

  WHERE
    -- this will return in a few milliseconds for partitions with days in different chunks
    gh_data.compute_chunk(repo_activity.day_id) = param_day_chunk;
END

$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION gh_tmp.insert_repo_activity(param_day_chunk INTEGER)
  RETURNS VOID AS $$

BEGIN
  EXECUTE 'INSERT INTO gh_dim_next.repo_activity_' || param_day_chunk ||
          ' (SELECT * FROM gh_tmp.transform_repo_activity( ' || param_day_chunk || '::SMALLINT))';

  EXECUTE 'SELECT util.add_index(''gh_dim_next'', ''repo_activity_'
          || param_day_chunk || ''', column_names := array[''repo_fk''])';
END
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION gh_tmp.constrain_repo_activity()
  RETURNS VOID AS $$
SELECT util.add_fk('gh_dim_next', 'repo_activity', 'time', 'day');
SELECT util.add_fk('gh_dim_next', 'repo_activity', 'gh_dim_next', 'repo');
$$
LANGUAGE SQL;


