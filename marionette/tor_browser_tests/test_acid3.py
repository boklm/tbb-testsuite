from marionette_driver import By, Wait
from marionette_driver.errors import MarionetteException

from marionette_harness import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)
        ts = testsuite.TestSuite()
        self.test_page_url = '%s/acid3/' % ts.t['options']['test_data_url']

    def test_acid3(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate(self.test_page_url)
            wait = Wait(self.marionette, timeout=500, interval=1)
            wait.until(lambda m: m.find_element('id', 'score').text == '100',
                    message='acid3 not 100')

