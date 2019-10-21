import pathlib

import etl_tools.utils
from data_integration.commands.files import Compression
from data_integration.commands.sql import ExecuteSQL
from data_integration.parallel_tasks.files import ParallelReadFile, ReadMode
from data_integration.parallel_tasks.sql import ParallelExecuteSQL
from data_integration.pipelines import Pipeline, Task
from etl_tools.create_attributes_table import CreateAttributesTable

pipeline = Pipeline(
    id="pypi",
    description="Builds a PyPI downloads cube using the public PyPi BigQuery data set",
    base_path=pathlib.Path(__file__).parent,
    labels={"Schema": "pypi_dim"})

pipeline.add_initial(
    Task(id="initialize_schemas",
         description="Recreates the schemas of the pipeline",
         commands=[
             ExecuteSQL(sql_file_name='recreate_schemas.sql'),
             ExecuteSQL(sql_file_name="create_data_schema.sql",
                        file_dependencies=["create_data_schema.sql"])
         ]))

read_download_file_dependencies = ["create_download_counts_data_table.sql", "create_data_schema.sql"]

pipeline.add(
    ParallelReadFile(
        id="read_download_counts",
        description="Loads PyPI downloads from pre_downloaded csv files",
        file_pattern="*/*/*/pypi/downloads-v2.csv.gz",
        read_mode=ReadMode.ONLY_NEW,
        compression=Compression.GZIP,
        target_table="pypi_data.download_counts",
        delimiter_char="\t", skip_header=True, csv_format=True,
        file_dependencies=read_download_file_dependencies,
        date_regex="^(?P<year>\d{4})\/(?P<month>\d{2})\/(?P<day>\d{2})/",
        partition_target_table_by_day_id=True,
        timezone="UTC",
        commands_before=[
            ExecuteSQL(sql_file_name="create_download_counts_data_table.sql",
                       file_dependencies=read_download_file_dependencies)
        ],
        commands_after=[
            ExecuteSQL(
                sql_statement="SELECT util.add_index('pypi_data', 'download_counts', expression := 'pypi_data.compute_chunk(day_id)');")
        ]
    ))

pipeline.add(
    ParallelExecuteSQL(
        id="preprocess_project_version",
        description='Assigns unique ids to projects and versions',
        commands_before=[
            ExecuteSQL(sql_file_name="preprocess_project_version_1.sql")
        ],
        sql_statement="SELECT pypi_tmp.preprocess_project_version_1(@chunk@::SMALLINT);",
        parameter_function=etl_tools.utils.chunk_parameter_function,
        parameter_placeholders=["@chunk@"],
        commands_after=[
            ExecuteSQL(sql_file_name="preprocess_project_version_2.sql")
        ]),
    upstreams=['read_download_counts'])

for dimension in ['project', 'project_version']:
    pipeline.add(
        Task(id=f"transform_{dimension}",
             description=f'Creates the "{dimension}" dimension',
             commands=[
                 ExecuteSQL(sql_file_name=f"transform_{dimension}.sql")
             ]),
        upstreams=['preprocess_project_version'])

pipeline.add(
    Task(id="transform_installer",
         description='Creates the "installer" dimension',
         commands=[
             ExecuteSQL(sql_file_name="transform_installer.sql")
         ]),
    upstreams=['read_download_counts'])

pipeline.add(
    Task(id="transform_python_version",
         description='Creates the "python_version" dimension',
         commands=[
             ExecuteSQL(sql_file_name="transform_python_version.sql")
         ]),
    upstreams=['read_download_counts'])

pipeline.add(
    ParallelExecuteSQL(
        id="transform_download_counts",
        description="Maps download counts to their dimensions",
        sql_statement="SELECT pypi_tmp.insert_download_counts(@chunk@::SMALLINT);",
        parameter_function=etl_tools.utils.chunk_parameter_function,
        parameter_placeholders=["@chunk@"],
        commands_before=[
            ExecuteSQL(sql_file_name="transform_download_counts.sql")
        ]),
    upstreams=["preprocess_project_version", "transform_installer", "transform_python_version"])

pipeline.add(
    ParallelExecuteSQL(
        id="create_download_counts_data_set",
        description="Creates a flat data set table for PyPi downloads",
        sql_statement="SELECT pypi_tmp.insert_download_counts_data_set(@chunk@::SMALLINT);",
        parameter_function=etl_tools.utils.chunk_parameter_function,
        parameter_placeholders=["@chunk@"],
        commands_before=[
            ExecuteSQL(sql_file_name="create_download_counts_data_set.sql")
        ]),
    upstreams=["transform_project", "transform_project_version", "transform_download_counts"])

pipeline.add(
    CreateAttributesTable(
        id="create_download_counts_data_set_attributes",
        source_schema_name='pypi_dim_next',
        source_table_name='download_counts_data_set'),
    upstreams=['create_download_counts_data_set'])

pipeline.add(
    Task(id="constrain_tables",
         description="Adds foreign key constrains between the dim tables",
         commands=[
             ExecuteSQL(sql_file_name="constrain_tables.sql", echo_queries=False)
         ]),
    upstreams=["transform_project", "transform_project_version", "transform_download_counts"])

pipeline.add_final(
    Task(id="replace_schema",
         description="Replaces the current pypi_dim schema with the contents of pypi_dim_next",
         commands=[
             ExecuteSQL(sql_statement="SELECT util.replace_schema('pypi_dim', 'pypi_dim_next');")
]))
