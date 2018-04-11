import pathlib

import etl_tools.utils
from data_integration.commands.files import Compression
from data_integration.commands.sql import ExecuteSQL
from data_integration.parallel_tasks.files import ParallelReadFile, ReadMode
from data_integration.parallel_tasks.sql import ParallelExecuteSQL
from data_integration.pipelines import Pipeline, Task

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

read_download_file_dependencies = ["create_download_data_table.sql", "create_data_schema.sql"]

pipeline.add(
    ParallelReadFile(
        id="read_download",
        description="Loads PyPI downloads from pre_downloaded csv files",
        file_pattern="*/*/*/pypi/downloads-v1.csv.gz",
        read_mode=ReadMode.ONLY_NEW,
        compression=Compression.GZIP,
        target_table="pypi_data.download",
        delimiter_char="\t", skip_header=True, csv_format=True,
        file_dependencies=read_download_file_dependencies,
        date_regex="^(?P<year>\d{4})\/(?P<month>\d{2})\/(?P<day>\d{2})/",
        partition_target_table_by_day_id=True,
        timezone="UTC",
        commands_before=[
            ExecuteSQL(sql_file_name="create_download_data_table.sql",
                       file_dependencies=read_download_file_dependencies)
        ]))

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
    upstreams=['read_download'])

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
    upstreams=['read_download'])

pipeline.add(
    ParallelExecuteSQL(
        id="transform_download",
        description="Maps downloads to their dimensions",
        sql_statement="SELECT pypi_tmp.insert_download(@chunk@::SMALLINT);",
        parameter_function=etl_tools.utils.chunk_parameter_function,
        parameter_placeholders=["@chunk@"],
        commands_before=[
            ExecuteSQL(sql_file_name="transform_download.sql")
        ]),
    upstreams=["preprocess_project_version", "transform_installer"])

pipeline.add(
    Task(id="constrain_tables",
         description="Adds foreign key constrains between the dim tables",
         commands=[
             ExecuteSQL(sql_file_name="constrain_tables.sql", echo_queries=False)
         ]),
    upstreams=["transform_project", "transform_project_version", "transform_download"])

pipeline.add_final(
    Task(id="replace_schema",
         description="Replaces the current pypi_dim schema with the contents of pypi_dim_next",
         commands=[
             ExecuteSQL(sql_statement="SELECT util.replace_schema('pypi_dim', 'pypi_dim_next');")
         ]))
