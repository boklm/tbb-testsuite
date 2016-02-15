from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

class Test(FirefoxTestCase):
    def test_screen_dims(self):
        with self.marionette.using_context('content'):
            # https://gitweb.torproject.org/torbrowser.git/blob/HEAD:/src/current-patches/firefox/0021-Do-not-expose-physical-screen-info.-via-window-and-w.patch
            js = self.marionette.execute_script
            # check that availWidth and availHeight are equal to window innerWidth and innerHeight
            self.assertEqual(True, js("return screen.availWidth === window.innerWidth"))
            self.assertEqual(True, js("return screen.availHeight === window.innerHeight"))
            # check that screen width and height are equal to availWidth and availHeight
            self.assertEqual(True, js("return screen.width === screen.availWidth"))
            self.assertEqual(True, js("return screen.height === screen.availHeight"))
            # check that innerWidth and innerHeight are equal to outerWidth and outerHeight
            self.assertEqual(True, js("return window.innerWidth === window.outerWidth"))
            self.assertEqual(True, js("return window.innerHeight === window.outerHeight"))
