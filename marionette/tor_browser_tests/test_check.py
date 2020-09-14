from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):
    def test_check_tpo(self):
        with self.marionette.using_context('content'):
           driver = self.marionette
           driver.navigate("http://check.torproject.org/")
           self.assertEqual("Congratulations. This browser is configured to use Tor.", driver.find_element("css selector", "h1.on").text)

