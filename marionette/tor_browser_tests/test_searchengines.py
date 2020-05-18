# This test checks whether the top three search engines are in the right order
# in the upper right search box. This has been an issue as search engine names
# got translated, too, leading to the browser not recognizing them anymore.
# This in turn led to wrong default search engines (see bug 11236 for details).
# We are not testing whether some prefs are set properly as this can be the
# case while the search engines are still not properly ordered. Rather, we
# check the entries in the search box directly.

from marionette_driver import By, Wait
from marionette_driver.errors import MarionetteException

from marionette_harness import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)
        ts = testsuite.TestSuite()

    def test_searchengines(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')

        with self.marionette.using_context('chrome'):
            self.marionette.timeout.implicit = 5
            searchbar = self.marionette.find_element('id', 'urlbar-input')
            searchbar.click()
            searchbar.send_keys("test")
            urlbarresults = self.marionette.find_element('id', 'urlbar-results')
            result = urlbarresults.find_element("css selector", "div:first-child .urlbarView-action")
            self.assertRegexpMatches(result.text, 'DuckDuckGo', 'DuckDuckGo is not the default search engine!')

            #XXX: Test whether the second and third engine are the ones we want as well.
