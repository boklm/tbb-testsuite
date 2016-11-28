from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts


        self.kSecuritySettings = {
                #                                                 1-high 2-m    3-m    4-low
                "javascript.options.ion.content" :          [ 0,  False, False, False, True ],
                "javascript.options.typeinference" :        [ 0,  False, False, False, True ],
                "noscript.forbidMedia" :                    [ 0,  True,  True,  True,  False],
                "media.webaudio.enabled" :                  [ 0,  False, False, False, True ],
                "mathml.disabled" :                         [ 0,  True,  True,  True,  False],
                "javascript.options.baselinejit.content" :  [ 0,  False, False, True,  True ],
                "gfx.font_rendering.opentype_svg.enabled" : [ 0,  False, False, True,  True ],
                "noscript.global" :                         [ 0,  False, False, True,  True ],
                "noscript.globalHttpsWhitelist" :           [ 0,  False, True,  False, False],
                "noscript.forbidFonts" :                    [ 0,  True,  False, False, False],
                "svg.in-content.enabled" :                  [ 0,  False, True,  True,  True],
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

            errors = ''
            for name, val in expected_prefs.iteritems():
                if self.marionette.get_pref(name) != val:
                    errors += "%s: %s != %s\n" % (name, self.marionette.get_pref(name), val)

            self.assertEqual(errors, '', msg=errors)
