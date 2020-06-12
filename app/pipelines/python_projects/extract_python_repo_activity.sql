DROP TABLE IF EXISTS pp_tmp.python_repo_activity;

CREATE TABLE pp_tmp.python_repo_activity AS

  WITH python_repos AS (
      SELECT
        repo_id,
        repo_name,
        project_id
      FROM gh_dim.repo
        JOIN pypi_dim.project ON project.project_name = repo.repo_name)

  SELECT
    day_fk                                         AS day_id,
    project_id,
    sum(number_of_forks) :: INTEGER                AS number_of_forks,
    sum(number_of_commits) :: INTEGER              AS number_of_commits,
    sum(number_of_closed_pull_requests) :: INTEGER AS number_of_closed_pull_requests
  FROM gh_dim.repo_activity
    JOIN python_repos ON repo_id = repo_fk
  GROUP BY day_fk, project_id;


SELECT util.add_index('pp_tmp', 'python_repo_activity',
                      column_names := ARRAY ['day_id', 'project_id'], unique_ := TRUE);


