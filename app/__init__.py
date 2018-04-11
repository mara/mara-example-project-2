"""Initializes the flask application"""

import pathlib
import sys

# configure application and packages
import app.data_integration
import app.bigquery_downloader
import app.ui

# apply environment specific settings (not in git repo)
if not pathlib.Path(__file__).parent.joinpath('local_setup.py').exists():
    sys.stderr.write('Please copy app/local_setup.py.example to app/local_setup.py and adapt\n')
    sys.exit(-1)
else:
    import app.local_setup

