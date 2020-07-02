from marionette_driver import By, Wait
from marionette_driver.errors import MarionetteException, NoSuchElementException, TimeoutException
from marionette_driver.legacy_actions import Actions
from marionette_harness import MarionetteTestCase, WindowManagerMixin

import testsuite

from stem.control import Controller
from stem.process import launch_tor_with_config

from urlparse import urlparse
from tempfile import mkdtemp
import shutil
import os
import base64

import time


class Test(WindowManagerMixin, MarionetteTestCase):
    def setUp(self):
        super(Test, self).setUp()

        self.public_key = 'E4ST65PDZDVZRAW2FLT5RBFKYEM3GW73SRQDMEBLBDHQP3Y4NADQ'
        self.private_key = 'B7H4TVVQNEOIENRS3GW3GI4VLVTSZPKS7NVSJAIDTNLBRWKWPHLQ'

        self.tmp_dir = mkdtemp()
        fixtures_port = urlparse(self.marionette.absolute_url('')).port
        os.mkdir(os.path.join(self.tmp_dir, 'hidden_service'), 0700)
        os.mkdir(os.path.join(self.tmp_dir, 'hidden_service',
                              'authorized_clients'), 0700)
        with open(os.path.join(self.tmp_dir, 'hidden_service', 'authorized_clients', 'alice.auth'), "w") as myfile:
            myfile.write("descriptor:x25519:" + self.public_key + '\n')

        # Add tor executable directory to the LD_LIBRARY_PATH
        ld_lib_list = filter(len, os.environ.get(
            "LD_LIBRARY_PATH", "").split(":"))
        tor_dirname = os.path.dirname(
            testsuite.TestSuite().t['tbbinfos']['torbin'])
        if tor_dirname not in ld_lib_list:
            ld_lib_list = [tor_dirname] + ld_lib_list
        os.environ["LD_LIBRARY_PATH"] = ":".join(ld_lib_list)

        self.tor_process = launch_tor_with_config(
            config={
                'ControlPort': '9999',
                'SOCKSPort': '0',
                'DataDirectory': self.tmp_dir,
                'HiddenServiceDir': os.path.join(self.tmp_dir, 'hidden_service'),
                'HiddenServicePort': '80 127.0.0.1:' + str(fixtures_port),
            },
            take_ownership=True,
            tor_cmd=testsuite.TestSuite().t['tbbinfos']['torbin']
        )

        with open(os.path.join(self.tmp_dir, 'hidden_service', 'hostname'), 'r') as myfile:
            self.onion = myfile.read().strip()

        self.controller = Controller.from_port(port=9999)
        self.controller.authenticate()

        def is_published(_):
            try:
                self.controller.get_hidden_service_descriptor(self.onion)
                return True
            except:
                return False
        Wait(self.marionette, timeout=10).until(is_published)
        # Wait a reasonable amount of time to increase the chances of the service to work
        time.sleep(10)

    def tearDown(self):
        self.controller.close()
        self.tor_process.terminate()
        shutil.rmtree(self.tmp_dir, ignore_errors=True)
        super(Test, self).tearDown()

    def load_onion(self, onion=None, wait_auth=True):
        if not onion:
            onion = self.onion
        m = self.marionette
        with m.using_context('content'):
            self.marionette.execute_script(
                'window.location = "http://' + onion + '/dom-objects-enumeration.html";')
        if wait_auth:
            with m.using_context('chrome'):
                Wait(m, timeout=m.timeout.page_load).until(lambda _: m.find_element(
                    'id', 'tor-clientauth-notification-key').is_displayed())

    def check_errors(self, title, short, long):
        m = self.marionette
        with m.using_context('content'):
            Wait(m, timeout=m.timeout.page_load).until(lambda _: m.find_element(
                'css selector', '#text-container .title-text').text != '')
            self.assertEqual(m.find_element(
                'css selector', '#text-container .title-text').text, title)
            self.assertEqual(m.find_element(
                'id', 'errorShortDescText').text, short)
            self.assertEqual(m.find_element('id', 'errorLongDesc').text, long)

    def get_keys(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate("about:preferences#privacy")
            self.marionette.find_element(
                'id', 'torOnionServiceKeys-savedKeys').click()
            return self.marionette.execute_script('''
                const dialog = document.querySelector('.dialogFrame');
                const tree = dialog.contentDocument.querySelector('#onionservices-savedkeys-tree');
                const view = tree.view;
                const rowCount = view.rowCount;
                const result = [];
                for (let i = 0; i < rowCount; ++i) {
                    result.push([
                        view.getCellText(i, tree.columns[0]),
                        view.getCellText(i, tree.columns[1]),
                    ]);
                }
                return result;
            ''')

    def new_identity(self):
        m = self.marionette
        with m.using_context('chrome'):
            m.set_pref('extensions.torbutton.confirm_newnym', False)
            m.find_element('id', 'new-identity-button').click()
        # Wait some time for new identity to finish.
        time.sleep(2)
        # Reload marionette session after new identity.
        self.marionette.quit()
        self.marionette.start_session()
        self.marionette.timeout.implicit = 10

    def delete_all_keys(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate("about:preferences#privacy")
            self.marionette.find_element(
                'id', 'torOnionServiceKeys-savedKeys').click()
            return self.marionette.execute_script('''
                const dialog = document.querySelector('.dialogFrame');
                dialog.contentDocument.querySelector('#onionservices-savedkeys-removeall').click();
            ''')

    def test_client_auth(self):
        m = self.marionette
        m.timeout.implicit = 10

        # Cancel auth
        self.load_onion()
        with m.using_context('chrome'):
            cancel = m.find_element(
                'css selector', '#tor-clientauth-notification .popup-notification-secondary-button')
            cancel.click()

        self.check_errors('Onionsite Requires Authentication', 'Access to the onionsite requires a key but none was provided.',
                          u'Details: 0xF4 \u2014 The client downloaded the requested onion service descriptor but was unable to decrypt its content because client authorization information is missing.')

        # Wrong auth
        self.load_onion()
        with m.using_context('chrome'):
            m.find_element('id', 'tor-clientauth-notification-key').send_keys(
                'E4ST65PDZDVZRAW2FLT5RBFKYEM3GW73SRQDMEBLBDHQP3Y4NADQ')
            m.find_element(
                'css selector', '#tor-clientauth-notification .popup-notification-primary-button').click()
            Wait(m, timeout=m.timeout.page_load).until(lambda _: not m.find_element(
                'id', 'tor-clientauth-notification-key').is_displayed())
            Wait(m, timeout=m.timeout.page_load).until(lambda _: m.find_element(
                'id', 'tor-clientauth-notification-key').is_displayed())

        # Good auth, don't remember key
        with m.using_context('chrome'):
            m.find_element(
                'id', 'tor-clientauth-notification-key').send_keys(self.private_key)
            m.find_element(
                'css selector', '#tor-clientauth-notification .popup-notification-primary-button').click()
        with m.using_context('content'):
            m.find_element('id', 'enumeration')
            keys = self.get_keys()
            self.assertEqual(len(keys), 0)
        self.new_identity()
        self.load_onion()  # This will block if the auth prompt is not displayed

        # Good auth, remember key
        with m.using_context('chrome'):
            m.find_element(
                'id', 'tor-clientauth-notification-key').send_keys(self.private_key)
            m.find_element('id', 'tor-clientauth-persistkey-checkbox').click()
            m.find_element(
                'css selector', '#tor-clientauth-notification .popup-notification-primary-button').click()
        with m.using_context('content'):
            m.find_element('id', 'enumeration')
            keys = self.get_keys()
            self.assertEqual(len(keys), 1)
            self.assertEqual(keys[0][0], self.onion[:-6])
            self.assertEqual(keys[0][1], base64.b64encode(
                base64.b32decode(self.private_key + '====')))
        self.new_identity()
        with m.using_context('content'):
            m.navigate('http://' + self.onion +
                       '/dom-objects-enumeration.html')  # Should not block

        self.delete_all_keys()
        # Wait a bit, otherwise it sometimes loads the onion without the auth prompt
        time.sleep(5)
        with m.using_context('content'):
            self.load_onion()  # Load and wait for the auth doorgahnger

        # Check invalid onion address error
        with m.using_context('content'):
            bad_char = 'a' if self.onion[-7:-6] != 'a' else 'b'
            self.load_onion(
                onion=self.onion[:-7] + bad_char + ".onion", wait_auth=False)
            self.check_errors('Invalid Onionsite Address', 'The provided onionsite address is invalid. Please check that you entered it correctly.',
                              u'Details: 0xF6 \u2014 The provided .onion address is invalid. This error is returned due to one of the following reasons: the address checksum doesn\'t match, the ed25519 public key is invalid, or the encoding is invalid.')

        # TODO: check other onion errors
