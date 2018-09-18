DROP TABLE IF EXISTS pypi_tmp.unique_projects_version_per_day_chunk CASCADE;

CREATE TABLE pypi_tmp.unique_projects_version_per_day_chunk (
  project_version TEXT     NOT NULL,
  project         TEXT     NOT NULL,
  _day_chunk      SMALLINT NOT NULL
)
  PARTITION BY LIST (_day_chunk);

SELECT util.create_table_partitions('pypi_tmp', 'unique_projects_version_per_day_chunk',
                                    'SELECT util.get_all_chunks()');


CREATE OR REPLACE FUNCTION pypi_tmp.preprocess_project_version_1(param_day_chunk SMALLINT)
  RETURNS VOID AS $$
BEGIN
  EXECUTE 'INSERT INTO pypi_tmp.unique_projects_version_per_day_chunk_' || param_day_chunk
          || ' SELECT DISTINCT project_version, project, ' || param_day_chunk
          || ' FROM pypi_data.download_counts WHERE pypi_data.compute_chunk(download_counts.day_id) = '
          || param_day_chunk;
END $$
LANGUAGE plpgsql;

