CREATE TABLE pypi_dim_next.project AS
  SELECT DISTINCT
    project_id,
    project_name
  FROM pypi_tmp.project_version
  ORDER BY project_id;

SELECT util.add_pk('pypi_dim_next', 'project');

SELECT util.add_index('pypi_dim_next', 'project',
                      column_names := ARRAY ['project_name'], unique_ := TRUE);
