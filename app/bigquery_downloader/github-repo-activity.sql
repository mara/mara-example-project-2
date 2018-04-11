WITH
    raw_events AS (
      SELECT
        type,
        REPLACE(repo.url, 'https://api.github.com/repos/', '')  AS repo,
        JSON_EXTRACT(payload, '$.action')                       AS action,
        cast(JSON_EXTRACT(payload, '$.distinct_size') AS INT64) AS size
      FROM `githubarchive.day.DAY_ID`
      WHERE TYPE IN ('ForkEvent', 'PullRequestEvent', 'PushEvent')),

    events AS (
      SELECT
        repo,
        type,
        action,
        size,
        CASE WHEN type = 'ForkEvent'
          THEN 1 END    AS number_of_forks,
        CASE WHEN type = 'PushEvent' AND size > 0
          THEN size END AS number_of_commits,
        CASE WHEN type = 'PullRequestEvent' AND action = '"closed"'
          THEN 1 END    AS number_of_closed_pull_requests
      FROM raw_events )

SELECT
  DAY_ID                              AS day_id,
  split(repo, '/')[OFFSET (0)]        AS user,
  split(repo, '/')[OFFSET (1)]        AS repository,
  sum(number_of_forks)                AS number_of_forks,
  sum(number_of_commits)              AS number_of_commits,
  sum(number_of_closed_pull_requests) AS number_of_closed_pull_requests
FROM events
GROUP BY user, repository
HAVING (number_of_forks > 0 OR number_of_commits > 0 OR number_of_closed_pull_requests > 0)
    AND repository IS NOT NULL AND repository != '';


