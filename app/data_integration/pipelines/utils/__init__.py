import pathlib

from etl_tools import initialize_utils, create_time_dimensions
from data_integration import pipelines

pipeline = pipelines.Pipeline(
    id="utils",
    description="Creates a number of utility functions",
    base_path=pathlib.Path(__file__).parent)


pipeline.add(initialize_utils.utils_pipeline(with_cstore_fdw=True))
pipeline.add(create_time_dimensions.pipeline, upstreams=['initialize_utils'])
