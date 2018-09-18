"""Project specific configurations"""

import pathlib
import datetime

def data_dir():
    """The directory where persistent input data is stored"""
    return pathlib.Path('./data')


def first_date():
    """The first date for which to download and integrate BigQuery data"""
    return datetime.date(2017, 7, 1)