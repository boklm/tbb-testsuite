from marionette_driver import Wait
from marionette_driver.errors import NoSuchElementException, TimeoutException
from marionette_harness import MarionetteTestCase, WindowManagerMixin

class Test(WindowManagerMixin, MarionetteTestCase):
    # To be investigated in #40007:
    # In 81, marionette.get_url() sometimes fails with:
    # `UnknownException: TypeError: browsingContext.currentWindowGlobal is null`
    # It happens when clicking "Always Prioritize Onions" in the doorhanger:
    # opens a new tab + refreshes the previous one, then when we close the new tab
    # and move to the old one, marionette.get_url() throws the error.
    # Until a proper fix, this workaround seems to work fine.
    def get_url(self):
        with self.marionette.using_context('content'):
            return self.marionette.execute_script("return document.location.href;")

    def test_onion_location(self):
        m = self.marionette
        m.timeout.implicit = 10

        self.assertEqual(None, m.get_pref(
            'privacy.prioritizeonions.showNotification'))

        with m.using_context('content'):
            m.navigate('https://www.torproject.org/')

        with m.using_context('chrome'):
            # Check whether the urlbar badge is displayed
            self.assertTrue(m.find_element(
                'id', 'onion-location-box').is_displayed())

            # Check whether the notification is displayed the first time
            notification = m.find_element('id', 'onion-location-notification')
            self.assertTrue(notification.is_displayed())
            self.assertFalse(m.get_pref(
                'privacy.prioritizeonions.showNotification'))
            always_prioritize = notification.find_element(
                'css selector', '.popup-notification-primary-button')
            self.assertEqual(always_prioritize.get_attribute(
                'label'), 'Always Prioritize Onions')

            # Check learn more link
            notification.find_element(
                'css selector', '.popup-notification-learnmore-link').click()
            with m.using_context('content'):
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: len(m.window_handles) > 1)
                m.switch_to_window(m.window_handles[1])
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: self.get_url() != "about:blank")
                self.assertEqual(
                    self.get_url(), "https://tb-manual.torproject.org/onion-services/")
                m.close()
                m.switch_to_window(m.window_handles[0])

        with m.using_context('chrome'):
            # Close the notification and check that it's not displayed anymore.
            notification = m.find_element('id', 'onion-location-notification')
            not_now = notification.find_element(
                'css selector', '.popup-notification-secondary-button')
            self.assertEqual(not_now.get_attribute('label'), 'Not Now')
            not_now.click()
            try:
                self.assertFalse(m.find_element(
                    'id', 'onion-location-notification').is_displayed())
            except NoSuchElementException:
                pass

            # Show the notification again
            m.set_pref('privacy.prioritizeonions.showNotification', None)
            new_tab = self.open_tab()
            m.switch_to_window(new_tab)
            m.close()
            m.switch_to_window(self.start_tab)

            # Click "Always prioritize" in the notification
            notification = m.find_element('id', 'onion-location-notification')
            notification.find_element(
                'css selector', '.popup-notification-primary-button').click()
            self.assertTrue(m.get_pref('privacy.prioritizeonions.enabled'))

            with m.using_context('content'):
                m.switch_to_window(m.window_handles[1])
                spotlight = m.find_element('class name', 'spotlight')
                self.assertEqual(
                    spotlight.get_attribute("data-subcategory"), "onionservices")
                m.close()
                m.switch_to_window(self.start_tab)

                # Check that the original page is redirected to .onion
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: self.get_url() != 'https://www.torproject.org/')
                self.assertEqual(
                    self.get_url(), 'http://expyuzz4wqqyqhjn.onion/index.html')

                # Check that auto-redirects work
                m.navigate('https://www.torproject.org/')
                self.assertEqual(self.get_url(), 'https://www.torproject.org/')
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: self.get_url() != 'https://www.torproject.org/')
                self.assertEqual(
                    self.get_url(), 'http://expyuzz4wqqyqhjn.onion/index.html')

                # Go to preferences and disable auto-redirects
                new_tab = self.open_tab()
                m.switch_to_window(new_tab)
                m.navigate('about:preferences#privacy-onionservices')
                m.find_element('id', 'onionServicesRadioAsk').click()
                self.assertFalse(m.get_pref(
                    'privacy.prioritizeonions.enabled'))
                m.close()
                m.switch_to_window(self.start_tab)
                m.navigate('https://www.torproject.org/')
                try:
                    Wait(m, timeout=5).until(lambda _: self.get_url()
                                             != 'https://www.torproject.org/')
                    self.assertTrue(False, "Should not redirect")
                except TimeoutException:
                    pass

            # Check that the page is redirected when clicking on the urlbar badge
            with m.using_context('chrome'):
                self.assertTrue(m.find_element(
                    'id', 'onion-location-box').is_displayed())
                m.find_element('id', 'onion-location-box').click()
                with m.using_context('content'):
                    Wait(m, timeout=5).until(lambda _: self.get_url()
                                             != 'https://www.torproject.org/')
                    self.assertEqual(
                        self.get_url(), 'http://expyuzz4wqqyqhjn.onion/index.html')

            # Check learn more link
            with m.using_context('content'):
                m.navigate('about:preferences#privacy-onionservices')
                m.find_element('id', 'onionServicesLearnMore').click()
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: len(m.window_handles) > 1)
                m.switch_to_window(m.window_handles[1])
                Wait(m, timeout=m.timeout.page_load).until(
                    lambda _: self.get_url() != "about:blank")
                self.assertEqual(
                    self.get_url(), "https://tb-manual.torproject.org/onion-services/")
                m.close()
                m.switch_to_window(m.window_handles[0])
