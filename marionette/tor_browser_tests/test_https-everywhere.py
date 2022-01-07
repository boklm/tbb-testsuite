from marionette_harness import MarionetteTestCase
from marionette_driver import Wait
import testsuite

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.HTTP_URL = "http://https-everywhere.badssl.com/redirect-test/status.svg"
        self.HTTPS_URL = "https://https-everywhere.badssl.com/redirect-test/status.svg"

        self.is_disabled = self.ts.t['test']['name'] == 'https-everywhere-disabled'

        if self.is_disabled:
            with self.marionette.using_context('chrome'):
                self.marionette.execute_async_script("""
                    let [resolve] = arguments;
                    const { AddonManager } = ChromeUtils.import(
                        "resource://gre/modules/AddonManager.jsm"
                    );
                    AddonManager.getAddonByID("https-everywhere-eff@eff.org")
                        .then(addon => addon.disable())
                        .then(resolve);
                """)

    def tearDown(self):
        super(Test, self).tearDown()
        if self.is_disabled:
            with self.marionette.using_context('chrome'):
                self.marionette.execute_async_script("""
                    let [resolve] = arguments;
                    const { AddonManager } = ChromeUtils.import(
                        "resource://gre/modules/AddonManager.jsm"
                    );
                    AddonManager.getAddonByID("https-everywhere-eff@eff.org")
                        .then(addon => addon.enable())
                        .then(resolve);
                """)

    def test_https_everywhere(self):
        # Wait until .tor.onion rules have been loaded, to make sure HTTPS Everywhere
        # has loaded correctly.
        m = self.marionette
        if not self.is_disabled:
            with m.using_context('chrome'):
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: m.execute_script("return OnionAliasStore._onionMap.size;") > 0)

        with self.marionette.using_context('content'):
            # Even without HTTPS Everywhere, Firefox checks if HTTPS is
            # available, with this set to true
            self.marionette.set_pref('dom.security.https_first_pbm', False)
            self.marionette.navigate(self.HTTP_URL)

            if not self.is_disabled:
                self.assertEqual(self.marionette.get_url(), self.HTTPS_URL)
            else:
                self.assertEqual(self.marionette.get_url(), self.HTTP_URL)
