DROP TABLE IF EXISTS gh_tmp.repo_activity;

CREATE TABLE gh_tmp.repo_activity
(
  day_id                         INT64  NOT NULL,
  user                           STRING NOT NULL,
  repo                           STRING NOT NULL,
  number_of_forks                INT64,
  number_of_commits              INT64,
  number_of_closed_pull_requests INT64
);
--   PARTITION BY LIST (_day_chunk);

-- SELECT util.create_table_partitions('gh_tmp', 'repo_activity', 'SELECT util.get_all_chunks()');

INSERT INTO gh_tmp.repo_activity
SELECT day_id,
       COALESCE(user, 'Unknown') AS user,
       repo,
       number_of_forks,
       number_of_commits,
       number_of_closed_pull_requests
FROM gh_data.repo_activity;
