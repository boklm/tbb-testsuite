import os
import json

class TestSuite(object):
    def __init__(self):
        tsfile = os.environ.get('TESTSUITE_DATA_FILE')
        if tsfile == None:
            raise ValueError('TESTSUITE_DATA_FILE is not defined')
        with open(tsfile) as json_data:
            self.t = json.load(json_data)

