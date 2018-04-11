DROP SCHEMA IF EXISTS pp_dim_next CASCADE;
CREATE SCHEMA pp_dim_next;

DROP SCHEMA IF EXISTS pp_tmp CASCADE;
CREATE SCHEMA pp_tmp;

SELECT util.create_chunking_functions('pp_tmp');
