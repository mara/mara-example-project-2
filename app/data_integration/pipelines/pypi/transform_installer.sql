CREATE TABLE pypi_dim_next.installer (
  installer_id   SMALLSERIAL PRIMARY KEY,
  installer_name TEXT UNIQUE
);

INSERT INTO pypi_dim_next.installer (installer_name)
  SELECT DISTINCT installer
  FROM pypi_data.download
  WHERE installer IS NOT NULL
  ORDER BY installer;

INSERT INTO pypi_dim_next.installer
VALUES (-1, 'Unknown installer');