import os
import json
from marionette_harness import MarionetteTestCase

class TestSuite(object):
    def __init__(self):
        tsfile = os.environ.get('TESTSUITE_DATA_FILE')
        if tsfile == None:
            raise ValueError('TESTSUITE_DATA_FILE is not defined')
        with open(tsfile) as json_data:
            self.t = json.load(json_data)

    def screenshot_filename(self, screenshots_dir):
        i = 1
        while True:
            screenshot_file = "%s/marionette_screenshot-%d.png" % (screenshots_dir, i)
            if not os.path.isfile(screenshot_file):
                return screenshot_file
            i += 1

    def screenshot(self, marionette, full=False):
        screenshots_dir = os.environ.get('MARIONETTE_SCREENSHOTS')
        screenshot_file = self.screenshot_filename(screenshots_dir)
        png_data = marionette.screenshot(format='binary', full=full)
        output = open(screenshot_file, 'w')
        output.write(png_data)
        output.close()


class TorBrowserTest(MarionetteTestCase):
    def get_version(self):
        with self.marionette.using_context("chrome"):
            return self.marionette.execute_script("return parseFloat(AppConstants.MOZ_APP_VERSION);")
