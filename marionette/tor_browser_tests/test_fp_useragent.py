from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

class Test(FirefoxTestCase):
    def test_useragent(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('file://')
            js = self.marionette.execute_script
            # Check that useragent string is as expected
            # We better know the ESR version we're testing
            self.assertEqual("Mozilla/5.0 (Windows NT 6.1; rv:38.0) Gecko/20100101 Firefox/38.0",
                              js("return navigator.userAgent"))
