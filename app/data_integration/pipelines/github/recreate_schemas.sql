DROP SCHEMA IF EXISTS gh_dim_next CASCADE;
CREATE SCHEMA gh_dim_next;

DROP SCHEMA IF EXISTS gh_tmp CASCADE;
CREATE SCHEMA gh_tmp;

SELECT util.create_chunking_functions('gh_tmp');

