CREATE TABLE gh_tmp.repo_activity
(
    day_id                         INTEGER  NOT NULL,
    "user"                         TEXT     NOT NULL,
    repo                           TEXT     NOT NULL,
    number_of_forks                INTEGER,
    number_of_commits              INTEGER,
    number_of_closed_pull_requests INTEGER,
    _day_chunk                     SMALLINT NOT NULL
)
    PARTITION BY LIST (_day_chunk);

SELECT util.create_table_partitions('gh_tmp', 'repo_activity', 'SELECT util.get_all_chunks()');


CREATE OR REPLACE FUNCTION gh_tmp.preprocess_repo_activity(param_day_chunk SMALLINT)
    RETURNS SETOF gh_tmp.REPO_ACTIVITY AS
$$

BEGIN
    RETURN QUERY
        SELECT day_id,
               COALESCE("user", 'Unknown') AS "user",
               repo,
               number_of_forks,
               number_of_commits,
               number_of_closed_pull_requests,
               param_day_chunk
        FROM gh_data.repo_activity
        WHERE
            -- this will return in a few milliseconds for partitions with days in different chunks
            gh_data.compute_chunk(repo_activity.day_id) = param_day_chunk;
END

$$
    LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION gh_tmp.insert_repo_activity_tmp(param_day_chunk INTEGER)
    RETURNS VOID AS
$$

BEGIN
    EXECUTE 'INSERT INTO gh_tmp.repo_activity_' || param_day_chunk ||
            ' (SELECT * FROM gh_tmp.preprocess_repo_activity( ' || param_day_chunk || '::SMALLINT))';

    EXECUTE 'SELECT util.add_index(''gh_tmp'', ''repo_activity_'
                || param_day_chunk || ''', column_names := array[''repo'', ''user''])';
END
$$
    LANGUAGE plpgsql;
