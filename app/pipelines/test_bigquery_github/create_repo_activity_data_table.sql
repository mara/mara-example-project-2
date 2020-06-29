DROP TABLE IF EXISTS gh_data.repo_activity;

CREATE TABLE gh_data.repo_activity
(
  day_id                         INT64  NOT NULL,
  user                           STRING,
  repo                           STRING NOT NULL,
  number_of_forks                INT64,
  number_of_commits              INT64,
  number_of_closed_pull_requests INT64
); --PARTITION BY LIST (day_id);
