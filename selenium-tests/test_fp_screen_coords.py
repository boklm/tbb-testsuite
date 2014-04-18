#!/usr/bin/python
import tbbtest


class Test(tbbtest.TBBTest):
    def test_screen_coords(self):
        # https://gitweb.torproject.org/torbrowser.git/blob/HEAD:/src/current-patches/firefox/0021-Do-not-expose-physical-screen-info.-via-window-and-w.patch
        driver = self.driver
        js = driver.execute_script
        # check that screenX, screenY are 0
        self.assertEqual(True, js("return screenX === 0"))
        self.assertEqual(True, js("return screenY === 0"))
        # check that mozInnerScreenX, mozInnerScreenY are 0
        self.assertEqual(True, js("return mozInnerScreenX === 0"))
        self.assertEqual(True, js("return mozInnerScreenY === 0"))
        # check that screenLeft, screenTop are 0
        self.assertEqual(True, js("return screen.left === 0"))
        self.assertEqual(True, js("return screen.top === 0"))
        # check that availLeft, availTop are 0
        self.assertEqual(True, js("return screen.availLeft === 0"))
        self.assertEqual(True, js("return screen.availTop === 0"))
