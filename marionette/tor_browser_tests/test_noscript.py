# https://trac.torproject.org/projects/tor/ticket/13053

from marionette_driver import By
from marionette_driver.errors import MarionetteException, NoSuchElementException

from marionette_harness import MarionetteTestCase

import testsuite

class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.http_url = "%s/noscript/" % ts.t['options']['test_data_url']
        self.https_url = "%s/noscript/" % ts.t['options']['test_data_url_https']


    def test_noscript(self):
        self.marionette.timeout.implicit = 1

        with self.marionette.using_context('content'):

            # http page sourcing http js
            self.marionette.navigate("%s/http_src.html" % self.http_url)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="http page sourcing http js")

            # https page sourcing http js
            self.marionette.navigate("%s/http_src.html" % self.https_url)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="https page sourcing http js")

            # https page sourcing http js (alternate hostname)
            self.marionette.navigate("%s/alternate_http_src.html" % self.https_url)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="https page sourcing http js (alternate hostname)")

            # http page sourcing https js
            self.marionette.navigate("%s/https_src.html" % self.http_url)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="http page sourcing https js")

            # https page sourcing https js
            self.marionette.navigate("%s/https_src.html" % self.https_url)
            res = True
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = False
            self.assertTrue(res, msg="https page sourcing https js")
            self.assertEqual('JavaScriptEnabled', elt.text, msg="https page sourcing https js")

            # https page sourcing https js (alternate hostname)
            self.marionette.navigate("%s/alternate_https_src.html" % self.https_url)
            res = True
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = False
            self.assertTrue(res, msg="https page sourcing https js (alternate hostname)")
            self.assertEqual('JavaScriptEnabled', elt.text,
                    msg="https page sourcing https js (alternate hostname)")

            # http page with http iframe
            self.marionette.navigate("%s/http_iframe.html" % self.http_url)
            iframe = self.marionette.find_element('id', 'iframe')
            self.marionette.switch_to_frame(iframe)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="http page with http iframe")
            self.marionette.switch_to_default_content()

            # http page with https iframe
            self.marionette.navigate("%s/https_iframe.html" % self.http_url)
            iframe = self.marionette.find_element('id', 'iframe')
            self.marionette.switch_to_frame(iframe)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="http page with https iframe")
            self.marionette.switch_to_default_content()

            # https page with http iframe
            self.marionette.navigate("%s/http_iframe.html" % self.https_url)
            iframe = self.marionette.find_element('id', 'iframe')
            self.marionette.switch_to_frame(iframe)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="https page with http iframe")
            self.marionette.switch_to_default_content()

            # https page sourcing https js (alternate hostname)
            self.marionette.navigate("%s/alternate_http_iframe.html" % self.https_url)
            iframe = self.marionette.find_element('id', 'iframe')
            self.marionette.switch_to_frame(iframe)
            res = False
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = True
            self.assertTrue(res, msg="https page sourcing https js (alternate hostname)")
            self.marionette.switch_to_default_content()

            # https page with https iframe
            self.marionette.navigate("%s/https_iframe.html" % self.https_url)
            iframe = self.marionette.find_element('id', 'iframe')
            self.marionette.switch_to_frame(iframe)
            res = True
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = False
            self.assertTrue(res, msg="https page with https iframe")
            self.assertEqual(elt.text, 'JavaScriptEnabled',
                    msg="https page with https iframe")
            self.marionette.switch_to_default_content()

            # https page with https iframe (alternate hostname)
            self.marionette.navigate("%s/alternate_https_iframe.html" % self.https_url)
            iframe = self.marionette.find_element('id', 'iframe')
            self.marionette.switch_to_frame(iframe)
            res = True
            try:
                elt = self.marionette.find_element('id', 'test_result')
            except NoSuchElementException:
                res = False
            self.assertTrue(res, msg="https page with https iframe")
            self.assertEqual(elt.text, 'JavaScriptEnabled',
                    msg="https page with https iframe")
            self.marionette.switch_to_default_content()

