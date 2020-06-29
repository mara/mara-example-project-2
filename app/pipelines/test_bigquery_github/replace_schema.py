from app.pipelines.test_bigquery_github import bigquery

# bigquery.remove_bigquery_dataset('bq_dwh', 'gh_dim')

bigquery.copy_bigquery_dataset(bigquery_db_alias='bq_dwh',
                               source_dataset_name='gh_dim_next',
                               target_dataset_name='gh_dim')
