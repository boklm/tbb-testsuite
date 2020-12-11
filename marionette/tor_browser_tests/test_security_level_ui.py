from marionette_driver import Wait, expected
from marionette_harness import MarionetteTestCase

class Test(MarionetteTestCase):
    # Starting 84, opening the security level panel by clicking the button
    # started to fail (the panel was not visible). Opening via JavaScript
    # seems to still work for 84 and 78.
    def open_security_level_panel(self):
        m = self.marionette
        with m.using_context('chrome'):
            self.marionette.execute_script(
                'document.getElementById("security-level-button").click();')

    def test_security_level_ui(self):
        custom_pref = 'javascript.options.wasm'
        m = self.marionette
        m.timeout.implicit = 5
        with m.using_context('chrome'):
            self.open_security_level_panel()
            m.find_element(
                'id', 'securityLevel-advancedSecuritySettings').click()
            with m.using_context('content'):
                # Test whether changing the security level value works
                spotlight = m.find_element('class name', 'spotlight')
                self.assertEqual(
                    spotlight.get_attribute("data-subcategory"), "securitylevel")
                self.assertEqual(4, m.get_pref(
                    'extensions.torbutton.security_slider'))
                m.find_element(
                    'css selector', '#securityLevel-vbox-safer radio').click()
                self.assertEqual(2, m.get_pref(
                    'extensions.torbutton.security_slider'))
                m.find_element(
                    'css selector', '#securityLevel-vbox-safest radio').click()
                self.assertEqual(1, m.get_pref(
                    'extensions.torbutton.security_slider'))
                m.find_element(
                    'css selector', '#securityLevel-vbox-standard radio').click()
                self.assertEqual(4, m.get_pref(
                    'extensions.torbutton.security_slider'))

                # Test custom security settings
                elem = m.find_element('id', 'securityLevel-restoreDefaults')
                self.assertEqual(elem.is_displayed(), False)
                m.set_pref(custom_pref, False)
                self.assertEqual(elem.is_displayed(), True)
                elem.click()
                self.assertEqual(True, m.get_pref(custom_pref))

                # Test Learn More link
                m.find_element('id', 'securityLevel-learnMore').click()
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: len(m.window_handles) > 1)
                m.switch_to_window(m.window_handles[1])
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: m.get_url() != "about:blank")
                self.assertTrue(
                    m.get_url() in ["https://tb-manual.torproject.org/en-US/security-settings/", "https://tb-manual.torproject.org/security-settings/"])

            # Test Learn More link from panel
            self.open_security_level_panel()
            m.find_element('id', 'securityLevel-learnMore').click()
            Wait(m, timeout=m.timeout.page_load).until(
                lambda _: len(m.window_handles) > 2)
            with m.using_context('content'):
                m.switch_to_window(m.window_handles[2])
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: m.get_url() != "about:blank")
                self.assertTrue(
                    m.get_url() in ["https://tb-manual.torproject.org/en-US/security-settings/", "https://tb-manual.torproject.org/security-settings/"])

            # Test custom settings from panel
            m.set_pref(custom_pref, False)
            elem = m.find_element('id', 'securityLevel-restoreDefaults')
            self.assertEqual(elem.is_displayed(), False)
            self.open_security_level_panel()
            self.assertEqual(elem.is_displayed(), True)
            elem.click()
            self.assertEqual(True, m.get_pref(custom_pref))
