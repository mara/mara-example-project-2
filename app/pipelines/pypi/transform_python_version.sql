CREATE TABLE pypi_dim_next.python_version (
  python_version_id   SMALLSERIAL PRIMARY KEY,
  python_version_name TEXT UNIQUE
);

INSERT INTO pypi_dim_next.python_version (python_version_name)
  SELECT DISTINCT python_version
  FROM pypi_data.download_counts
  WHERE python_version IS NOT NULL
  ORDER BY python_version;

INSERT INTO pypi_dim_next.python_version
VALUES (-1, 'Unknown python version');