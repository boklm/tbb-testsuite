from marionette_harness import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.URL = "file://%s/testfile.pdf" % ts.t['options']['test_data_dir']


    def test_download_pdf(self):
        m = self.marionette
        m.set_window_rect(width=1024, height=300)
        m.navigate(self.URL)
        download_button = m.find_element('id', 'download').click()
        self.assertEqual(len(m.chrome_window_handles), 2, msg="Number of windows not correct")
        dialog = m.switch_to_alert()
        self.assertRegexpMatches(dialog.text, 'Tails',
                            msg='Pop up window text does not include Tails')
