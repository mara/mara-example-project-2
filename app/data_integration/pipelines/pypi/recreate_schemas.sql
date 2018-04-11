DROP SCHEMA IF EXISTS pypi_dim_next CASCADE;
CREATE SCHEMA pypi_dim_next;

DROP SCHEMA IF EXISTS pypi_tmp CASCADE;
CREATE SCHEMA pypi_tmp;

SELECT util.create_chunking_functions('pypi_tmp');

