from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

import testsuite


class Test(FirefoxTestCase):

    def setUp(self):
        FirefoxTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        if ts.t['test']['remote']:
            test_data_url = ts.t['options']['test_data_url']
        else:
            test_data_url = "file://%s" % ts.t['options']['test_data_dir']
        self.test_page_url = '%s/%s.html' % (test_data_url, ts.t['test']['name'])

        if ts.t['test']['timeout']:
            self.timeout = ts.t['test']['timeout']
        else:
            self.timeout = 50000

    def test_page(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate(self.test_page_url)
            self.marionette.set_search_timeout(self.timeout)
            elt = self.marionette.find_element('id', 'test_result');
            self.assertEqual(elt.text, 'OK')

