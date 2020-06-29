DROP TABLE IF EXISTS gh_dim_next.repo;

CREATE TABLE gh_dim_next.repo
(
  repo_id   STRING NOT NULL, -- PRIMARY KEY,
  repo_name STRING NOT NULL,
  user_name STRING NOT NULL
);

INSERT INTO gh_dim_next.repo
SELECT GENERATE_UUID(),
       repo,
       user
FROM gh_tmp.repo_activity
GROUP BY repo, user;

-- SELECT util.add_index('gh_dim_next', 'repo', column_names := ARRAY ['repo_name', 'user_name']);
