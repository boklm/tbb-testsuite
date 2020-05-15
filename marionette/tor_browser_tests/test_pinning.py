from marionette_harness import MarionetteTestCase

import testsuite
import json

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.URL = 'https://pinning-test.badssl.com/'


    def test_pinning(self):
        m = self.marionette

        with m.using_context('content'):

            res = False
            try:
                m.navigate(self.URL)
            except Exception:
                res = True

            self.assertTrue(res, msg="Page could be loaded")

            if res:
                errorCode = m.find_element('id', 'errorShortDescText2')
                self.assertEqual(json.loads(errorCode.get_attribute('data-l10n-args'))["error"],
                        'MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE',
                        msg='Wrong error code')

