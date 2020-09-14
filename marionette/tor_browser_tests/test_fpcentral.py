from marionette_harness import MarionetteTestCase
import testsuite

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.test_page_url = ts.t['test']['fpcentral_url']

        if 'timeout' in ts.t['test']:
            self.timeout = ts.t['test']['timeout']
        else:
            self.timeout = 50000

    def test_page(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate(self.test_page_url)
            self.marionette.set_search_timeout(self.timeout)
            elt = self.marionette.find_element('id', 'acceptableSummaryResult');
            self.assertEqual(elt.text, 'All attributes have an acceptable value.')

