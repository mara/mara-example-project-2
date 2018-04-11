DROP TABLE IF EXISTS pypi_data.download CASCADE;

CREATE TABLE pypi_data.download (
  day_id              INTEGER NOT NULL,
  project             TEXT    NOT NULL,
  project_version     TEXT    NOT NULL,
  python_version      TEXT,
  installer           TEXT,
  number_of_downloads INTEGER NOT NULL
);

