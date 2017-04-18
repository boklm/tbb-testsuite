from marionette_driver import By, Actions
from marionette_driver.errors import MarionetteException, JavascriptException

from marionette_harness import MarionetteTestCase

import testsuite


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
                errorCode = m.find_element('id', 'errorCode')
                self.assertEqual(errorCode.get_attribute('title'),
                        'MOZILLA_PKIX_ERROR_KEY_PINNING_FAILURE',
                        msg='Wrong error code')

