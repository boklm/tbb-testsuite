from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        # The torbutton_sec_* variables have been copy pasted from
        # torbutton/src/chrome/content/torbutton.js

        self.torbutton_sec_ml_bool_prefs = {
                "javascript.options.ion.content" : False,
                "javascript.options.typeinference" : False,
                "javascript.options.asmjs" : False,
                "noscript.forbidMedia" : True,
                "media.webaudio.enabled" : False,
                "mathml.disabled" : True
                }

        self.torbutton_sec_mh_bool_prefs = {
                "javascript.options.baselinejit.content" : False,
                "gfx.font_rendering.opentype_svg.enabled" : False,
                "noscript.global" : False,
                "noscript.globalHttpsWhitelist" : True
                }

        self.torbutton_sec_h_bool_prefs = {
                "noscript.forbidFonts" : True,
                "noscript.global" : False,
                "svg.in-content.enabled" : False
                };


    def test_slider_settings(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')

            slider_mode = int(self.ts.t['test']['slider_mode'])
            self.assertEqual(slider_mode,
                self.marionette.get_pref('extensions.torbutton.security_slider'),
                msg='Slider mode is not set correctly')

            expected_prefs = {}

            if slider_mode == 1:
                for name, val in self.torbutton_sec_ml_bool_prefs.iteritems():
                        expected_prefs[name] = val
                for name, val in self.torbutton_sec_mh_bool_prefs.iteritems():
                        expected_prefs[name] = val
                        # noscript.globalHttpsWhitelist is special: We don't want it in this
                        # mode.
                        if name == "noscript.globalHttpsWhitelist":
                                expected_prefs[name] = not val
                for name, val in self.torbutton_sec_h_bool_prefs.iteritems():
                    expected_prefs[name] = val

            elif slider_mode == 2:
                for name, val in self.torbutton_sec_ml_bool_prefs.iteritems():
                    expected_prefs[name] = val
                # Order matters here as both the high mode and the medium-high mode
                # share some preferences/values. So, let's revert the high mode
                # preferences first and set the medium-high mode ones afterwards.
                for name, val in self.torbutton_sec_h_bool_prefs.iteritems():
                    expected_prefs[name] = not val
                for name, val in self.torbutton_sec_mh_bool_prefs.iteritems():
                    expected_prefs[name] = val

            elif slider_mode == 3:
                for name, val in self.torbutton_sec_ml_bool_prefs.iteritems():
                    expected_prefs[name] = val
                for name, val in self.torbutton_sec_mh_bool_prefs.iteritems():
                    expected_prefs[name] = not val
                for name, val in self.torbutton_sec_h_bool_prefs.iteritems():
                    expected_prefs[name] = not val

            elif slider_mode == 4:
                for name, val in self.torbutton_sec_ml_bool_prefs.iteritems():
                    expected_prefs[name] = not val
                for name, val in self.torbutton_sec_mh_bool_prefs.iteritems():
                    expected_prefs[name] = not val
                for name, val in self.torbutton_sec_h_bool_prefs.iteritems():
                    expected_prefs[name] = not val

            errors = ''
            for name, val in expected_prefs.iteritems():
                if self.marionette.get_pref(name) != val:
                    errors += "%s: %s != %s\n" % (name, self.marionette.get_pref(name), val)

            self.assertEqual(errors, '', msg=errors)
