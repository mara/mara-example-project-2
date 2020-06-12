DROP SCHEMA IF EXISTS pypi_data CASCADE;

CREATE SCHEMA pypi_data;

SELECT util.create_chunking_functions('pypi_data');
