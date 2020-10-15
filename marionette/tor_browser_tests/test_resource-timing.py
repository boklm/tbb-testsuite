# This test checks whether the Resource Timing API (see:
# http://www.w3.org/TR/resource-timing/) is really disabled in the default
# Tor Browser. Setting |dom.enable_resource_timing| to |false| and testing that
# might not be sufficient.

from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        self.TEST_URL = "https://www.mediawiki.org/wiki/MediaWiki"
        self.RESOURCE_URL = "https://upload.wikimedia.org/wikipedia/mediawiki/b/bc/Wiki.png"


    def test_resource_timing(self):

        with self.marionette.using_context('content'):
            self.marionette.navigate(self.TEST_URL)

            # If resource timing is disabled we should not be able to get resource
            # entries at all in the first place. We test all three methods for safety's
            # sake.

            # getEntriesByType()
            err_msg = 'resource entries found (getEntriesByType())'
            self.assertTrue(self.marionette.execute_script("""
                try {
                        var resources = document.defaultView.performance.
                                getEntriesByType("resource")[0];
                } catch (e) {
                        return false;
                }
                return resources == undefined;
                """),
                msg=err_msg)

            # getEntriesByName()
            err_msg = "resource entries found (getEntriesByName())"
            self.assertTrue(self.marionette.execute_script("""
                try {
                        var resources = document.defaultView.performance.
                                getEntriesByName(arguments[0])[0];
                } catch (e) {
                        return false;
                }
                return resources == undefined;
                """, script_args=[self.RESOURCE_URL]),
                msg=err_msg)

            # getEntries()
            err_msg = "resource entries found (getEntries())"
            self.assertTrue(self.marionette.execute_script("""
                try {
                        var resources = document.defaultView.performance.
                                getEntries()[0];
                } catch (e) {
                        return false;
                }
                return resources == undefined;
                """),
                msg=err_msg)

