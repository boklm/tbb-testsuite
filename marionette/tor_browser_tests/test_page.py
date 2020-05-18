from marionette_harness import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        if ts.t['test']['remote']:
            test_data_url = ts.t['options']['test_data_url']
            self.test_page_url = '%s/%s.html' % (test_data_url, ts.t['test']['name'])
        else:
            self.test_page_url = self.marionette.absolute_url('%s.html' % (ts.t['test']['name']))
            self.marionette.set_pref("network.proxy.allow_hijacking_localhost", False)

        if ts.t['test']['timeout']:
            self.timeout = ts.t['test']['timeout']
        else:
            self.timeout = 50000

    def test_page(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate(self.test_page_url)
            self.marionette.timeout.implicit = self.timeout/1000
            elt = self.marionette.find_element('id', 'test_result');
            self.assertEqual(elt.text, 'OK')

