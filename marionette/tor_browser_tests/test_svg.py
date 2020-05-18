from marionette_driver.errors import MarionetteException, JavascriptException, NoSuchElementException

from marionette_harness import MarionetteTestCase

import testsuite

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.marionette.set_pref("network.proxy.allow_hijacking_localhost", False)


    def test_svg(self):
        m = self.marionette
        svg_enabled = self.ts.t['test']['name'] == 'svg-enable'
        self.assertEqual(self.marionette.get_pref('svg.disabled'),
                not svg_enabled,
                msg="svg.disabled is not set correctly")

        self.marionette.timeout.implicit = 1

        with m.using_context('content'):

            # img src url
            m.navigate(self.marionette.absolute_url("svg/img_src_url.html"))
            svg_elt = m.find_element('id', 'svgImgElem')
            self.assertEqual(svg_elt.get_property('width'),
                    450 if svg_enabled else 24,
                    msg="img src url")

            # img data url
            m.navigate(self.marionette.absolute_url("svg/img_data_url.html"))
            svg_elt = m.find_element('id', 'svgImgElem')
            self.assertEqual(svg_elt.get_property('width'),
                    300 if svg_enabled else 24,
                    msg="img data url")

            # object data url
            m.navigate(self.marionette.absolute_url("svg/object_data_url.html"))
            width = m.execute_script('''
                                var elt = document.getElementById("svgObjectElem");
                                return elt.getBoundingClientRect().width;
                                ''')
            self.assertEqual(width,
                    450 if svg_enabled else 300,
                    msg="object data url")

            # object remote url
            m.navigate(self.marionette.absolute_url("svg/object_remote_url.html"))
            svg_elt = m.find_element('id', 'svgObjectElem')

            width = m.execute_script('''
                                var elt = document.getElementById("svgObjectElem");
                                return elt.getBoundingClientRect().width;
                                ''')
            self.assertEqual(width,
                    450 if svg_enabled else 300,
                    msg="object remote url")

            # inline svg
            m.navigate(self.marionette.absolute_url("svg/inline_svg.html"))
            try:
                elt_width = m.execute_script('''
                                var elt = document.getElementById("inlineSVG");
                                return elt.width.baseVal.value;
                                ''')
            except JavascriptException:
                elt_width = None
            self.assertEqual(elt_width,
                    300 if svg_enabled else None,
                    msg='inline svg')

            # iframe remote url
            m.navigate(self.marionette.absolute_url("svg/iframe_remote_url.html"))
            m.switch_to_frame(m.find_element('id', 'svgIframeElem'))
            svg_elt = m.find_element('tag name', 'svg')
            width = m.execute_script('''
                                var elt = document.getElementsByTagName("svg")[0];
                                return elt.getBoundingClientRect().width;
                                ''')
            self.assertEqual(width,
                    450 if svg_enabled else 500,
                    msg="iframe remote url prompt")
