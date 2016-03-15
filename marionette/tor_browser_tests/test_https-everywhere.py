from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

import testsuite


class Test(FirefoxTestCase):

    def setUp(self):
        FirefoxTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.PREF_ENABLE_HE = "extensions.https_everywhere.globalEnabled"
        self.HTTP_URL = "http://www.freedomboxfoundation.org/thanks/"
        self.HTTPS_URL = "https://www.freedomboxfoundation.org/thanks/"


    def test_https_everywhere(self):
        self.assertEqual(self.prefs.get_pref(self.PREF_ENABLE_HE), \
                self.ts.t['test']['name'] == 'https-everywhere')

        with self.marionette.using_context('content'):
            self.marionette.navigate(self.HTTP_URL)

            if self.ts.t['test']['name'] == 'https-everywhere':
                self.assertEqual(self.marionette.get_url(), self.HTTPS_URL)
            else:
                self.assertEqual(self.marionette.get_url(), self.HTTP_URL)

