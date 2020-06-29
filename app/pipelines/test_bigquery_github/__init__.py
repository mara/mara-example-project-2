import pathlib

import etl_tools.utils
from mara_pipelines.commands.sql import ExecuteSQL
from mara_pipelines.parallel_tasks.sql import ParallelExecuteSQL
from mara_pipelines.commands.python import ExecutePython
from mara_pipelines.commands.files import Compression
from mara_pipelines.parallel_tasks.files import ParallelReadFile, ReadMode
from mara_pipelines.pipelines import Pipeline, Task

from app.pipelines.test_bigquery_github import bigquery

pipeline = Pipeline(
    id="bigquery_github_test",
    description="The Github pipeline in BigQuery (integration is currently under developing).",
    base_path=pathlib.Path(__file__).parent,
    labels={"Dataset": "gh_dim"})

pipeline.add(
    Task(id="initialize_schemas",
         description="Recreates the schemas (corresponding BigQuery datasets) of the pipeline",
         commands=[
             ExecutePython(file_name='create_data_schema.py', file_dependencies=['create_data_schema.py']),
             ExecutePython(file_name='recreate_schemas.py')
         ]))

read_repo_activity_file_dependencies = ["create_repo_activity_data_table.sql", "create_data_schema.py"]

pipeline.add(
    ParallelReadFile(
        id="read_repo_activity",
        description="Loads Github repo activities from pre-downloaded csv files in a BigQuery DB",
        file_pattern="*/*/*/github/repo-activity-v1.csv.gz",
        read_mode=ReadMode.ONLY_NEW,
        compression=Compression.GZIP,
        target_table="gh_data.repo_activity",
        delimiter_char='tab',
        skip_header=True,
        csv_format=True,
        file_dependencies=read_repo_activity_file_dependencies,
        date_regex="^(?P<year>\d{4})\/(?P<month>\d{2})\/(?P<day>\d{2})/",
        partition_target_table_by_day_id=False,
        timezone="UTC",
        commands_before=[
            ExecuteSQL(sql_file_name="create_repo_activity_data_table.sql", db_alias='bq_dwh',
                       file_dependencies=read_repo_activity_file_dependencies)
        ],
        db_alias='bq_dwh'
    ),
    upstreams=['initialize_schemas'])

# TODO: Insert in chunks in a BQ partitioned table
pipeline.add(
    Task(id="preprocess_repo_activity",
         description='Pre-process the repo activities dimensions',
         commands=[
             ExecuteSQL(sql_file_name="preprocess_repo_activity.sql", db_alias='bq_dwh')
         ]),
    upstreams=['read_repo_activity'])

pipeline.add(
    Task(id="transform_repo",
         description='Creates the "repo" dimension',
         commands=[
             ExecuteSQL(sql_file_name="transform_repo.sql", db_alias='bq_dwh')
         ]),
    upstreams=['preprocess_repo_activity'])

# TODO: Insert in chunks in a BQ partitioned table
pipeline.add(
    Task(id="transform_repo_activity",
         description='Maps repo activites to their dimensions',
         commands=[
             ExecuteSQL(sql_file_name="transform_repo_activity.sql", db_alias='bq_dwh')
         ]),
    upstreams=['transform_repo'])

# TODO: Insert in chunks in a BQ partitioned table
pipeline.add(
    Task(id="create_repo_activity_data_set",
         description='Creates a flat data set table for Github repo activities',
         commands=[
             ExecuteSQL(sql_file_name="create_repo_activity_data_set.sql", db_alias='bq_dwh')
         ]),
    upstreams=['transform_repo_activity'])

pipeline.add(
    Task(id="replace_schema",
         description="Replaces the current gh_dim BQ dataset with the contents (tables) of gh_dim_next one",
         commands=[
             ExecutePython(file_name='replace_schema.py')
         ]),
    upstreams=['create_repo_activity_data_set'])
