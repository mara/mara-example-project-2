DROP TABLE IF EXISTS pypi_tmp.project_version CASCADE;

CREATE TABLE pypi_tmp.project_version (
  project_version_id   INTEGER NOT NULL,
  project_version_name TEXT    NOT NULL,
  project_id           INTEGER NOT NULL,
  project_name         TEXT    NOT NULL
);

INSERT INTO pypi_tmp.project_version
  WITH versions AS (
      SELECT DISTINCT
        project_version,
        project
      FROM pypi_tmp.unique_projects_version_per_day_chunk
  )

  SELECT
    rank()
    OVER (
      ORDER BY project, project_version ) AS project_version_id,
    project_version                       AS project_version_name,
    dense_rank()
    OVER (
      ORDER BY project )                  AS project_id,
    project                               AS project_name
  FROM versions
  ORDER BY project_name, project_version;

