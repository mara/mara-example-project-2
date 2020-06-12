"""Configures the data integration pipelines of the project"""

import datetime
import functools

import mara_pipelines.config
import etl_tools.config
from mara_pipelines.pipelines import Pipeline
from mara_app.monkey_patch import patch

import app.config

patch(mara_pipelines.config.data_dir)(lambda: app.config.data_dir())
patch(mara_pipelines.config.first_date)(lambda: app.config.first_date())
patch(mara_pipelines.config.default_db_alias)(lambda: 'dwh')


@patch(mara_pipelines.config.root_pipeline)
@functools.lru_cache(maxsize=None)
def root_pipeline():
    import app.pipelines.github
    import app.pipelines.pypi
    import app.pipelines.utils
    import app.pipelines.python_projects

    pipeline = Pipeline(
        id='mara_example_project',
        description='An example pipeline that integrates PyPI download stats with the Github activity of a project')

    pipeline.add(app.pipelines.utils.pipeline)
    pipeline.add(app.pipelines.pypi.pipeline, upstreams=['utils'])
    pipeline.add(app.pipelines.github.pipeline, upstreams=['utils'])
    pipeline.add(app.pipelines.python_projects.pipeline,
                 upstreams=['pypi', 'github'])
    return pipeline


patch(etl_tools.config.number_of_chunks)(lambda: 11)
patch(etl_tools.config.first_date_in_time_dimensions)(lambda: app.config.first_date())
patch(etl_tools.config.last_date_in_time_dimensions)(
    lambda: datetime.datetime.utcnow().date() - datetime.timedelta(days=1))
