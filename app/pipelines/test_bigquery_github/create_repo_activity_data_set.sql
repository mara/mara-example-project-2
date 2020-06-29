DROP TABLE IF EXISTS gh_dim_next.repo_activity_data_set;

CREATE TABLE gh_dim_next.repo_activity_data_set
(
  Date                       INT64   NOT NULL, -- todo: change type to date
  RepoID                     STRING NOT NULL,
  User                       STRING NOT NULL,
  Repo                       STRING NOT NULL,
  NumberOfForks              INT64,
  NumberOfCommits            INT64,
  NumberOfClosedPullRequests INT64
);

-- TODO: insert from already partitioned source table in BQ

INSERT INTO gh_dim_next.repo_activity_data_set
SELECT day_fk                         AS Date, -- todo: change type to date
       repo_id                        AS RepoID,
       user_name                      AS User,
       repo_name                      AS Repo,
       number_of_forks                AS NumberOfForks,
       number_of_commits              AS NumberOfCommits,
       number_of_closed_pull_requests AS NumberOfClosedPullRequests
FROM gh_dim_next.repo_activity
     JOIN gh_dim_next.repo ON repo_fk = repo_id;
