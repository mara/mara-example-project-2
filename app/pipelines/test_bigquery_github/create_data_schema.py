from app.pipelines.test_bigquery_github import bigquery

bigquery.remove_bigquery_dataset('bq_dwh', 'gh_data')
bigquery.create_bigquery_dataset('bq_dwh', 'gh_data')
