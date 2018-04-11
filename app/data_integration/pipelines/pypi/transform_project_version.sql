DROP TABLE IF EXISTS pypi_dim_next.project_version;

CREATE TABLE pypi_dim_next.project_version AS
  SELECT
    project_version_id,
    project_version_name,
    project_id AS project_fk
  FROM pypi_tmp.project_version
  ORDER BY project_version_id;

SELECT util.add_pk('pypi_dim_next', 'project_version');

SELECT util.add_index('pypi_dim_next', 'project_version',
                      column_names := ARRAY ['project_version_name', 'project_fk'],
                      unique_ := TRUE);


CREATE OR REPLACE FUNCTION pypi_tmp.constrain_product_version()
  RETURNS VOID AS $$
SELECT util.add_fk('pypi_dim_next', 'project_version', 'pypi_dim_next', 'project');
$$
LANGUAGE SQL;

