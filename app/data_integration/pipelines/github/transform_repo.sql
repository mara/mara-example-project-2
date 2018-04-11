DROP TABLE IF EXISTS gh_dim_next.repo CASCADE;

CREATE TABLE gh_dim_next.repo (
  repo_id   SERIAL PRIMARY KEY,
  repo_name TEXT NOT NULL,
  user_name TEXT NOT NULL
);

INSERT INTO gh_dim_next.repo (repo_name, user_name)
SELECT DISTINCT
  repo,
  "user"
FROM gh_data.repo_activity;

SELECT util.add_index('gh_dim_next', 'repo', column_names := ARRAY ['repo_name', 'user_name']);

