from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

class Test(FirefoxTestCase):
    def test_plugins(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('file://')
            js = self.marionette.execute_script
            # Check that plugins are disabled
            self.assertEqual(True, js("return navigator.plugins.length === 0"))
            self.assertEqual(True, js("return navigator.mimeTypes.length === 0"))
