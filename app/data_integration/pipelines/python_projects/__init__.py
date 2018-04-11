import pathlib

import etl_tools.utils
from data_integration.commands.sql import ExecuteSQL
from data_integration.parallel_tasks.sql import ParallelExecuteSQL
from data_integration.pipelines import Pipeline, Task

pipeline = Pipeline(
    id="python_projects",
    description="Combines PyPI downloads and github activities to a Python project activity cube",
    base_path=pathlib.Path(__file__).parent,
    labels={"Schema": "pp_dim"})

pipeline.add_initial(
    Task(id="initialize_schemas",
        description="Recreates the schemas of the pipeline",
        commands=[
            ExecuteSQL(sql_file_name='recreate_schemas.sql')
        ]))

pipeline.add(
    Task(id="extract_python_repo_activity",
         description='Extracts activity metrics for github repos that have a corresponding pypi package (by name)',
         commands=[
             ExecuteSQL(sql_file_name="extract_python_repo_activity.sql")
         ]))

pipeline.add(
    ParallelExecuteSQL(
        id="transform_python_project_activity",
        description="Aggregates downloads at project level and combines them with github activity metrics",
        commands_before=[
            ExecuteSQL(sql_file_name="transform_python_project_activity.sql")
        ],
        sql_statement="SELECT pp_tmp.insert_python_project_activity(@chunk@::SMALLINT);",
        parameter_function=etl_tools.utils.chunk_parameter_function,
        parameter_placeholders=["@chunk@"]),
    upstreams=["extract_python_repo_activity"])

pipeline.add(
    Task(id="constrain_tables",
         description="Adds foreign key constrains between the dim tables",
         commands=[
             ExecuteSQL(sql_file_name="constrain_tables.sql", echo_queries=False)
         ]),
    upstreams=["transform_python_project_activity"])

pipeline.add_final(
    Task(id="replace_schema",
         description="Replaces the current pp_dim schema with the contents of pp_dim_next",
         commands=[
             ExecuteSQL(sql_statement="SELECT util.replace_schema('pp_dim', 'pp_dim_next');")
         ]))
