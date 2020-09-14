# This test checks whether the User Timing API (see:
# https://www.w3.org/TR/user-timing/) is really disabled in the default
# Tor Browser. Setting |dom.enable_user_timing| to |false| and testing that
# might not be sufficient.

from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        self.TEST_URL = "https://www.mediawiki.org/wiki/MediaWiki"
        self.RESOURCE_URL = "https://upload.wikimedia.org/wikipedia/mediawiki/b/bc/Wiki.png"


    def test_user_timing(self):

        with self.marionette.using_context('content'):
            self.marionette.navigate(self.TEST_URL)

            # measure()
            err_msg = 'user timing is working (performance.measure())'
            self.assertTrue(self.marionette.execute_script("""
                document.defaultView.performance.mark("startTask1");
                document.defaultView.performance.mark("endTask1");
                document.defaultView.performance.measure("measure1", "startTask1", "endTask1");
                let e = document.defaultView.performance.getEntriesByType("measure");
                return e.length == 0;
                """),
                msg=err_msg)

            # mark()
            err_msg = 'user timing is working (performance.mark())'
            self.assertTrue(self.marionette.execute_script("""
                document.defaultView.performance.mark("startTask2");
                let e = document.defaultView.performance.getEntriesByName("startTask2", "mark");
                return e.length == 0;
                """),
                msg=err_msg)
