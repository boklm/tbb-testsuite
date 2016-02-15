from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

class Test(FirefoxTestCase):
    def test_check_tpo(self):
        with self.marionette.using_context('content'):
           driver = self.marionette
           driver.navigate("http://check.torproject.org/")
           self.assertEqual("Congratulations. This browser is configured to use Tor.", driver.find_element("css selector", "h1.on").text)

