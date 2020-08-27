from marionette_driver import By, Wait
from marionette_driver.errors import MarionetteException, NoSuchElementException, TimeoutException
from marionette_driver.legacy_actions import Actions
from marionette_harness import MarionetteTestCase, WindowManagerMixin

import time


class Test(WindowManagerMixin, MarionetteTestCase):
    def get_url(self):
        with self.marionette.using_context('content'):
            return self.marionette.execute_script("return document.location.href;")

    def get_urlbar_value(self):
        with self.marionette.using_context('chrome'):
            return self.marionette.execute_script("return gURLBar.value;")

    def test_onion_alias(self):
        m = self.marionette
        m.timeout.implicit = 10

        # Wait until .tor.onion rules have been loaded
        with m.using_context('chrome'):
            Wait(m, timeout=m.timeout.page_load).until(
                lambda _: m.execute_script("return OnionAliasStore._onionMap.size;") > 0)

        with m.using_context('content'):
            # Navigating to a known .tor.onion should redirect and rewrite the urlbar with the alias.
            m.navigate('http://theintercept.securedrop.tor.onion')
            self.assertEqual(self.get_url(
            ), 'http://xpxduj55x2j27l2qytu2tcetykyfxbjbafin3x4i3ywddzphkbrd3jyd.onion/')
            self.assertEqual(self.get_urlbar_value(),
                             'theintercept.securedrop.tor.onion')

            # Bookmark should be created with the onion alias URL
            with m.using_context('chrome'):
                m.find_element('id', 'star-button-box').click()
                m.find_element('id', 'editBookmarkPanelDoneButton').click()
                recent_bookmarks = m.execute_script(
                    "return PlacesUtils.bookmarks.getRecent(1);")
                self.assertEqual(
                    recent_bookmarks[0]["url"], "http://theintercept.securedrop.tor.onion/")

            # Opening a same-origin link should keep the onion alias in the urlbar
            el = m.find_element('id', 'submit-documents-button')
            action = Actions(m)
            action.middle_click(el)
            action.perform()
            Wait(m, timeout=m.timeout.page_load).until(
                lambda _: len(m.window_handles) > 1)
            m.switch_to_window(m.window_handles[1])
            Wait(m, timeout=m.timeout.page_load).until(
                lambda _: self.get_url() != 'about:blank')
            self.assertEqual(self.get_url(
            ), 'http://xpxduj55x2j27l2qytu2tcetykyfxbjbafin3x4i3ywddzphkbrd3jyd.onion/generate')
            self.assertEqual(self.get_urlbar_value(),
                             'theintercept.securedrop.tor.onion/generate')
            m.close()
            m.switch_to_window(m.window_handles[0])

            # Going directly to .onion should not rewrite the urlbar
            new_tab = self.open_tab()
            m.switch_to_window(new_tab)
            m.navigate(
                'http://xpxduj55x2j27l2qytu2tcetykyfxbjbafin3x4i3ywddzphkbrd3jyd.onion')
            self.assertEqual(self.get_url(
            ), 'http://xpxduj55x2j27l2qytu2tcetykyfxbjbafin3x4i3ywddzphkbrd3jyd.onion/')
            self.assertEqual(self.get_urlbar_value(
            ), 'xpxduj55x2j27l2qytu2tcetykyfxbjbafin3x4i3ywddzphkbrd3jyd.onion')
            m.close()
            m.switch_to_window(self.start_tab)
