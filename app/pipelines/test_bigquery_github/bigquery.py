from google.cloud import bigquery
from google.api_core import exceptions
from mara_db import dbs


def create_bigquery_dataset(bigquery_db_alias: str, dataset_name: str):
    """Creates a BQ dataset (as corresponding to schema SQL definition)"""
    import sys

    if not bigquery_db_alias or not dataset_name:
        print('Missing required argument for function: '
              'create_bigquery_dataset(bigquery_db_alias: str, schema_name: str)',
              file=sys.stderr)
        sys.exit(-1)
    bigquery_db = dbs.db(bigquery_db_alias)

    client = bigquery.Client.from_service_account_json(
        json_credentials_path=bigquery_db.service_account_private_key_file)

    dataset_id = "{}.{}".format(client.project, dataset_name)
    dataset = bigquery.Dataset(dataset_id)
    # TODO: Specify the geographic location where the dataset should reside.
    # dataset.location = "US"
    try:
        dataset = client.create_dataset(dataset)
        print("Created BigQuery dataset: {}.{}".format(client.project, dataset.dataset_id))
    except exceptions.Conflict:
        print("BigQuery dataset: {}.{} already exists".format(client.project, dataset.dataset_id))
    return True


def remove_bigquery_dataset(bigquery_db_alias: str, dataset_name: str):
    """Removes BQ dataset (as corresponding to schema SQL definition)"""
    import sys

    if not bigquery_db_alias or not dataset_name:
        print('Missing required argument for function: '
              'remove_bigquery_dataset(bigquery_db_alias: str, schema_name: str)',
              file=sys.stderr)
        sys.exit(-1)

    bigquery_db = dbs.db(bigquery_db_alias)

    client = bigquery.Client.from_service_account_json(
        json_credentials_path=bigquery_db.service_account_private_key_file)

    dataset_id = "{}.{}".format(client.project, dataset_name)
    # Use the not_found_ok parameter to not receive an error if the dataset has already been deleted.
    client.delete_dataset(
        dataset_id, delete_contents=True, not_found_ok=True
    )
    print("Deleted dataset '{}'.".format(dataset_id))
    return True


def copy_bigquery_dataset(bigquery_db_alias: str, source_dataset_name: str, target_dataset_name: str):
    """Copies all tables from a schema to another"""
    # Currently BQ does not support dataset renaming and copying is still in beta only available in client

    import sys

    if not bigquery_db_alias or not source_dataset_name or not target_dataset_name:
        print('Missing required argument for function: '
              'copy_bigquery_dataset(bigquery_db_alias: str, source_dataset_name: str, target_dataset_name: str)',
              file=sys.stderr)
        sys.exit(-1)
    bigquery_db = dbs.db(bigquery_db_alias)

    client = bigquery.Client.from_service_account_json(
        json_credentials_path=bigquery_db.service_account_private_key_file)

    source_dataset_id = "{}.{}".format(client.project, source_dataset_name)
    target_dataset_id = "{}.{}".format(client.project, target_dataset_name)

    create_bigquery_dataset(bigquery_db_alias, target_dataset_name)

    # Copy all tables to target schema
    tables = list(client.list_tables(source_dataset_id))
    if tables:
        for table in tables:
            # delete table if exists in target schema
            client.delete_table("{}.{}".format(target_dataset_id, table.table_id), not_found_ok=True)
            # copy table to target schema
            client.copy_table("{}.{}".format(source_dataset_id, table.table_id),
                              "{}.{}".format(target_dataset_id, table.table_id))
            print("Copied table '{}' from dataset '{}' to dataset '{}'".format(table.table_id,
                                                                               source_dataset_name,
                                                                               target_dataset_name))

    else:
        print("This BigQuery dataset does not contain any tables.")
        return True

    print("Source dataset '{}' has been copied to target dataset '{}'".format(source_dataset_id, target_dataset_id))
    return True
