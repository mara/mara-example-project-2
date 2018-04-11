DROP SCHEMA IF EXISTS gh_data CASCADE;

CREATE SCHEMA gh_data;

SELECT util.create_chunking_functions('gh_data');
