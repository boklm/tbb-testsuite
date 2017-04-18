# This test checks whether the Performance Observer API (see:
# https://w3c.github.io/performance-timeline/#the-performanceobserver-interface)
# is really disabled in the default Tor Browser.
# Setting |dom.enable_performance_observer| to |false| and testing that
# might not be sufficient.

from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        self.TEST_URL = "about:robots"


    def test_performance_observer(self):

        with self.marionette.using_context('content'):
            self.marionette.navigate(self.TEST_URL)

            err_msg = 'performance observer is working'
            self.assertTrue(self.marionette.execute_script("""
                var pass = false;
                try {
                        var observer = new PerformanceObserver(function(list) { });
                        observer.observe({entryTypes: ['resource', 'mark', 'measure']});
                } catch (e) {
                        pass = true;
                }
                return pass;
                """),
                msg=err_msg)
