DROP TABLE IF EXISTS gh_data.repo_activity CASCADE;

CREATE TABLE gh_data.repo_activity (
  day_id                         INTEGER NOT NULL,
  "user"                         TEXT    NOT NULL,
  repo                           TEXT    NOT NULL,
  number_of_forks                INTEGER,
  number_of_commits              INTEGER,
  number_of_closed_pull_requests INTEGER
) PARTITION BY LIST (day_id);

