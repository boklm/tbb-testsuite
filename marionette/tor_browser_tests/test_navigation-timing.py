# This test checks whether the Navigation Timing API (see:
# http://www.w3.org/TR/navigation-timing/) is really disabled in the default
# Tor Browser. Setting |dom.enable_performance| to |false| and testing that has
# been not sufficient. See bug 13186 for further details.

from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette import MarionetteTestCase

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        self.TEST_URL = "https://www.mediawiki.org/wiki/MediaWiki"

        self.ATTRIBUTES = {
                "navigationStart": 0,
                "unloadEventStart": 0,
                "unloadEventEnd": 0,
                "redirectStart": 0,
                "redirectEnd": 0,
                "fetchStart": 0,
                "domainLookupStart": 0,
                "domainLookupEnd": 0,
                "connectStart": 0,
                "connectEnd": 0,
                # Not available in Firefox yet.
                "secureConnectionStart": None,
                "requestStart": 0,
                "responseStart": 0,
                "responseEnd": 0,
                "domLoading": 0,
                "domInteractive": 0,
                "domContentLoadedEventStart": 0,
                "domContentLoadedEventEnd": 0,
                "domComplete": 0,
                "loadEventStart": 0,
                "loadEventEnd": 0,
                }

    def test_navigation_timing(self):

        with self.marionette.using_context('content'):
            self.marionette.navigate(self.TEST_URL)

            for name, val in self.ATTRIBUTES.iteritems():
                err_msg = '%s != %s' % (name, val)
                self.assertTrue(self.marionette.execute_script(
                    'return document.defaultView.performance.timing[arguments[0]] == arguments[1];',
                    script_args=[name, val]), msg=err_msg)

