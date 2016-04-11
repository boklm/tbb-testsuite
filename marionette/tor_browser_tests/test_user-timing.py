# This test checks whether the User Timing API (see:
# https://www.w3.org/TR/user-timing/) is really disabled in the default
# Tor Browser. Setting |dom.enable_user_timing| to |false| and testing that
# might not be sufficient.

from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

class Test(FirefoxTestCase):

    def setUp(self):
        FirefoxTestCase.setUp(self)

        self.TEST_URL = "https://www.mediawiki.org/wiki/MediaWiki"
        self.RESOURCE_URL = "https://upload.wikimedia.org/wikipedia/mediawiki/b/bc/Wiki.png"


    def test_user_timing(self):

        with self.marionette.using_context('content'):
            self.marionette.navigate(self.TEST_URL)

            # If user timing is disabled we should not be able to use the
            # measure and mark methods.

            # measure()
            err_msg = 'user timing is working (performance.measure())'
            self.assertTrue(self.marionette.execute_script("""
                var pass = false;
                try {
                        document.defaultView.performance.measure("measure1");
                } catch (e) {
                        pass = true;
                }
                return pass;
                """),
                msg=err_msg)

            # mark()
            err_msg = 'user timing is working (performance.mark())'
            self.assertTrue(self.marionette.execute_script("""
                var pass = false;
                try {
                        document.defaultView.performance.mark("startTask1");
                } catch (e) {
                        pass = true;
                }
                return pass;
                """),
                msg=err_msg)
