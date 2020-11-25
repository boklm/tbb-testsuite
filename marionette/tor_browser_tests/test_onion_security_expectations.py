from marionette_driver import Wait
from marionette_harness import MarionetteTestCase, WindowManagerMixin
from stem.control import Controller
from urlparse import urlparse
import time
import testsuite

class OnionFixturesMixin(object):
    def setUp(self):
        super(OnionFixturesMixin, self).setUp()
        tor_control_port = testsuite.TestSuite(
        ).t['options']['tor-control-port']
        with Controller.from_port(port=int(tor_control_port)) as controller:
            controller.authenticate()
            port = urlparse(self.marionette.absolute_url('')).port
            response = controller.create_ephemeral_hidden_service(
                {80: port},
                key_content='ED25519-V3',
                await_publication=True,
                detached=True,
            )
            self.service_id = response.service_id

    def tearDown(self):
        tor_control_port = testsuite.TestSuite(
        ).t['options']['tor-control-port']
        with Controller.from_port(port=int(tor_control_port)) as controller:
            controller.authenticate()
            controller.remove_ephemeral_hidden_service(self.service_id)
        super(OnionFixturesMixin, self).tearDown()


class Test(OnionFixturesMixin, WindowManagerMixin, MarionetteTestCase):
    def get_identity_class(self):
        with self.marionette.using_context('chrome'):
            return self.marionette.execute_script('''
                return document.getElementById("identity-box").className;
            ''')

    def get_identity_icon(self):
        with self.marionette.using_context('chrome'):
            return self.marionette.execute_script('''
                const el = document.getElementById("identity-icon");
                return document.defaultView.getComputedStyle(el)["list-style-image"];
            ''')

    def get_connection_type(self):
        m = self.marionette
        with self.marionette.using_context('chrome'):
            self.execute_chrome(
                'document.getElementById("identity-popup-more-info").click()')
            m.switch_to_window(m.chrome_window_handles[1])
            Wait(m, timeout=m.timeout.page_load).until(
                lambda _: m.find_element('id', 'security-technical-shortform').get_attribute('value') != '')
            text = m.find_element('id', 'security-technical-shortform').get_attribute('value')
            m.close_chrome_window()
            m.switch_to_window(self.start_window)
            return text

    def execute_chrome(self, script):
        with self.marionette.using_context('chrome'):
            return self.marionette.execute_script(script)

    def test_onion_security_expectations(self):
        m = self.marionette
        m.timeout.implicit = 10

        # Wait some more time to make sure the onion service is set up
        time.sleep(10)

        # Regular onion
        with m.using_context('content'):
            m.navigate('http://' + self.service_id + '.onion')
            self.assertTrue(self.execute_chrome(
                "return !!gIdentityHandler._isSecureConnection;"))
            self.assertEqual(self.get_identity_class(), 'onionUnknownIdentity')
            self.assertEqual(self.get_connection_type(),
                             'Connection Encrypted (Onion Service)')
            self.assertEqual(self.get_identity_icon(),
                             'url("chrome://browser/skin/onion.svg")')

        # Onion with mixed display content
        with m.using_context('content'):
            m.navigate('http://' + self.service_id + '.onion/mixed.html')
            self.assertFalse(self.execute_chrome(
                "return !!gIdentityHandler._isSecureConnection;"))
            self.assertEqual(self.get_identity_class(),
                             'onionUnknownIdentity onionMixedDisplayContent')
            self.assertEqual(self.get_connection_type(),
                             'Connection Partially Encrypted')
            self.assertEqual(self.get_identity_icon(),
                             'url("chrome://browser/skin/onion-warning.svg")')

        # Onion with mixed active content
        with m.using_context('content'):
            m.navigate('http://' + self.service_id +
                       '.onion/mixed_active.html')
            self.assertTrue(self.execute_chrome(
                "return !!gIdentityHandler._isSecureConnection;"))
            self.assertEqual(self.get_identity_class(), 'onionUnknownIdentity')
            self.assertEqual(self.get_connection_type(),
                             'Connection Encrypted (Onion Service)')
            self.assertEqual(self.get_identity_icon(),
                             'url("chrome://browser/skin/onion.svg")')
            # Reload with mixed content protection disabled
            self.execute_chrome(
                'gIdentityHandler.disableMixedContentProtection();')
            Wait(m, timeout=m.timeout.page_load).until(
                lambda _: self.get_identity_class() != 'onionUnknownIdentity')
            self.assertFalse(self.execute_chrome(
                "return !!gIdentityHandler._isSecureConnection;"))
            self.assertEqual(self.get_identity_class(),
                             'onionUnknownIdentity onionMixedActiveContent')
            self.assertEqual(self.get_connection_type(),
                             'Connection Partially Encrypted')
            self.assertEqual(self.get_identity_icon(),
                             'url("chrome://browser/skin/onion-slash.svg")')

        # Onion with valid TLS certificate
        with m.using_context('content'):
            m.navigate('https://3g2upl4pq6kufc4m.onion/')
            self.assertTrue(self.execute_chrome(
                "return !!gIdentityHandler._isSecureConnection;"))
            self.assertEqual(self.get_identity_class(), 'onionVerifiedDomain')
            self.assertEqual(self.get_connection_type(
            ), 'Connection Encrypted (Onion Service, TLS_AES_256_GCM_SHA384, 256 bit keys, TLS 1.3)')
            self.assertEqual(self.get_identity_icon(),
                             'url("chrome://browser/skin/onion.svg")')
