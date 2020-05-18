# This test checks whether the Performance Observer API (see:
# https://w3c.github.io/performance-timeline/#the-performanceobserver-interface)
# is really disabled in the default Tor Browser.
# Setting |dom.enable_performance_observer| to |false| and testing that
# might not be sufficient.

from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        self.TEST_URL = "about:robots"


    def test_performance_observer(self):

        def is_perf_obs_working(marionette):
            return self.marionette.execute_async_script("""
                let [resolve] = arguments;
                var observer = new PerformanceObserver(function(...args) { resolve(true); });
                observer.observe({entryTypes: ['resource', 'mark', 'measure']});
                performance.mark("hello");
                setTimeout(function() {
                    resolve(false);
                }, 2000);
            """)

        with self.marionette.using_context('content'):
            m = self.marionette
            m.navigate(self.TEST_URL)
            m.timeout.script = 10

            # Performance observer should not work with default settings
            self.assertFalse(is_perf_obs_working(m), 'performance observer is working')

            # Performance observer should work if `privacy.resistFingerprinting = false`
            with self.marionette.using_prefs({"privacy.resistFingerprinting": False}):
                self.assertTrue(is_perf_obs_working(m), 'performance observer is not working')
