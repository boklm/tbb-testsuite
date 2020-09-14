from marionette_harness import MarionetteTestCase
import testsuite

class Test(MarionetteTestCase):
    def test_useragent(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')
            js = self.marionette.execute_script
            # Check that useragent string is as expected
            # We better know the ESR version we're testing
            osname = testsuite.TestSuite().t['tbbinfos']['os']
            if osname == 'Linux':
                ua_os = 'X11; Linux x86_64'
            if osname == 'Windows':
                ua_os = 'Windows NT 6.1; Win64; x64'
            if osname == 'MacOSX':
                ua_os = 'Macintosh; Intel Mac OS X 10.13'
            self.assertEqual("Mozilla/5.0 (" + ua_os + "; rv:78.0) Gecko/20100101 Firefox/78.0",
                              js("return navigator.userAgent"))
