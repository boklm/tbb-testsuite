from marionette_driver import By, Actions
from marionette_driver.errors import MarionetteException, JavascriptException

from marionette import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.URL = "file://%s/testfile.pdf" % ts.t['options']['test_data_dir']


    def test_download_pdf(self):
        m = self.marionette

        m.set_search_timeout(1000)
        m.set_window_size(1024, 300)

        with m.using_context('content'):

            current_window = m.current_chrome_window_handle

            m.navigate(self.URL)
            download_button = m.find_element('id', 'download')
            action = Actions(m)
            action.click(download_button)
            action.wait(time=3)
            action.perform()

            closed_window = 0
            with m.using_context('chrome'):
                for window in m.chrome_window_handles:
                    if window != current_window:
                        m.switch_to_window(window)
                        info_msg = m.find_element('id', 'info.body')
                        self.assertRegexpMatches(info_msg.text, 'Tails',
                                msg='Pop up window text does not include Tails')
                        m.close()
                        closed_window += 1
                m.switch_to_window(current_window)
            self.assertEqual(closed_window, 1, msg="no download pop up")

