from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette_harness import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts


        self.kSecuritySettings = {
                #                                                 1-high 2-m    3-m    4-low
                "javascript.options.ion" :                  [ 0,  False, False, False, True ],
                "javascript.options.baselinejit" :          [ 0,  False, False, False, True ],
                "javascript.options.native_regexp" :        [ 0,  False, False, False, True ],
                "mathml.disabled" :                         [ 0,  True,  True,  True,  False],
                "gfx.font_rendering.opentype_svg.enabled" : [ 0,  False, False, True,  True ],
                "svg.disabled" :                            [ 0,  True,  False, False, False],
                };

        # Settings for Tor Browser 6.0.* versions
        self.kSecuritySettings_60 = {
                };


    def test_slider_settings(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')

            slider_mode = int(self.ts.t['test']['slider_mode'])
            self.assertEqual(slider_mode,
                self.marionette.get_pref('extensions.torbutton.security_slider'),
                msg='Slider mode is not set correctly')

            expected_prefs = {}

            for name, val in self.kSecuritySettings.iteritems():
                expected_prefs[name] = val[slider_mode]

            if self.ts.t['tbbinfos']['version'].startswith('6.0'):
                for name, val in self.kSecuritySettings_60.iteritems():
                    expected_prefs[name] = val[slider_mode]

            errors = ''
            for name, val in expected_prefs.iteritems():
                if self.marionette.get_pref(name) != val:
                    errors += "%s: %s != %s\n" % (name, self.marionette.get_pref(name), val)

            self.assertEqual(errors, '', msg=errors)
