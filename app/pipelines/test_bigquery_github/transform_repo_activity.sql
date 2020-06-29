DROP TABLE IF EXISTS gh_dim_next.repo_activity;

CREATE TABLE gh_dim_next.repo_activity
(
  day_fk                         INT64 NOT NULL,
  repo_fk                        STRING NOT NULL,
  number_of_forks                INT64,
  number_of_commits              INT64,
  number_of_closed_pull_requests INT64
  --   _day_chunk                     SMALLINT NOT NULL
);
--   PARTITION BY LIST (_day_chunk);

-- TODO: partioning/clustering table in BQ
-- SELECT util.create_table_partitions(''gh_dim_next'', ''repo_activity'', ''SELECT util.get_all_chunks()'');

INSERT INTO gh_dim_next.repo_activity
SELECT day_id  AS day_fk,
       repo_id AS repo_fk,
       number_of_forks,
       number_of_commits,
       number_of_closed_pull_requests
FROM gh_tmp.repo_activity
     LEFT JOIN gh_dim_next.repo
               ON repo_activity.repo = repo.repo_name AND repo_activity.user = repo.user_name;

-- CREATE OR REPLACE FUNCTION gh_tmp.constrain_repo_activity()
--   RETURNS VOID AS
-- $$
-- SELECT util.add_fk(''gh_dim_next'', ''repo_activity'', ''time'', ''day'');
-- SELECT util.add_fk(''gh_dim_next'', ''repo_activity'', ''gh_dim_next'', ''repo'');
-- $$
--   LANGUAGE SQL;


