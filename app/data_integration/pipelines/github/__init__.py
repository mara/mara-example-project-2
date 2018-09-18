import pathlib

import etl_tools.utils
from data_integration.commands.files import Compression
from data_integration.commands.sql import ExecuteSQL
from data_integration.parallel_tasks.files import ParallelReadFile, ReadMode
from data_integration.parallel_tasks.sql import ParallelExecuteSQL
from data_integration.pipelines import Pipeline, Task
from etl_tools.create_attributes_table import CreateAttributesTable

pipeline = Pipeline(
    id="github",
    description="Builds a Github activity cube using the public Github archive data set",
    base_path=pathlib.Path(__file__).parent,
    labels={"Schema": "gh_dim"})

pipeline.add_initial(
    Task(id="initialize_schemas",
         description="Recreates the schemas of the pipeline",
         commands=[
             ExecuteSQL(sql_file_name='recreate_schemas.sql'),
             ExecuteSQL(sql_file_name="create_data_schema.sql",
                        file_dependencies=["create_data_schema.sql"])
         ]))

read_repo_activity_file_dependencies = ["create_repo_activity_data_table.sql", "create_data_schema.sql"]

pipeline.add(
    ParallelReadFile(
        id="read_repo_activity",
        description="Loads Github repo activities from pre-downloaded csv files",
        file_pattern="*/*/*/github/repo-activity-v1.csv.gz",
        read_mode=ReadMode.ONLY_NEW,
        compression=Compression.GZIP,
        target_table="gh_data.repo_activity",
        delimiter_char="\t", skip_header=True, csv_format=True,
        file_dependencies=read_repo_activity_file_dependencies,
        date_regex="^(?P<year>\d{4})\/(?P<month>\d{2})\/(?P<day>\d{2})/",
        partition_target_table_by_day_id=True,
        timezone="UTC",
        commands_before=[
            ExecuteSQL(sql_file_name="create_repo_activity_data_table.sql",
                       file_dependencies=read_repo_activity_file_dependencies)
        ],
        commands_after=[
            ExecuteSQL(
                sql_statement="SELECT util.add_index('gh_data', 'repo_activity', expression := 'gh_data.compute_chunk(day_id)');")
        ]
    ))

pipeline.add(
    Task(id="transform_repo",
         description='Creates the "repo" dimension',
         commands=[
             ExecuteSQL(sql_file_name="transform_repo.sql")
         ]),
    upstreams=['read_repo_activity'])

pipeline.add(
    ParallelExecuteSQL(
        id="transform_repo_activity",
        description="Maps repo activites to their dimensions",
        commands_before=[
            ExecuteSQL(sql_file_name="transform_repo_activity.sql")
        ],
        sql_statement="SELECT gh_tmp.insert_repo_activity(@chunk@::SMALLINT);",
        parameter_function=etl_tools.utils.chunk_parameter_function,
        parameter_placeholders=["@chunk@"]),
    upstreams=["transform_repo"])

pipeline.add(
    ParallelExecuteSQL(
        id="create_repo_activity_data_set",
        description="Creates a flat data set table for Github repo activities",
        sql_statement="SELECT gh_tmp.insert_repo_activity_data_set(@chunk@::SMALLINT);",
        parameter_function=etl_tools.utils.chunk_parameter_function,
        parameter_placeholders=["@chunk@"],
        commands_before=[
            ExecuteSQL(sql_file_name="create_repo_activity_data_set.sql")
        ]),
    upstreams=["transform_repo_activity"])

pipeline.add(
    CreateAttributesTable(
        id="create_repo_activity_data_set_attributes",
        source_schema_name='gh_dim_next',
        source_table_name='repo_activity_data_set'),
    upstreams=['create_repo_activity_data_set'])


pipeline.add(
    Task(id="constrain_tables",
         description="Adds foreign key constrains between the dim tables",
         commands=[
             ExecuteSQL(sql_file_name="constrain_tables.sql", echo_queries=False)
         ]),
    upstreams=["transform_repo_activity"])

pipeline.add_final(
    Task(id="replace_schema",
         description="Replaces the current gh_dim schema with the contents of gh_dim_next",
         commands=[
             ExecuteSQL(sql_statement="SELECT util.replace_schema('gh_dim', 'gh_dim_next');")
         ]))
