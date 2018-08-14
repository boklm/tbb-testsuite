from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette_harness import MarionetteTestCase

import testsuite

# expected values for navigation properties
nav_props = {"appCodeName": "Mozilla",
"appName": "Netscape",
"language": "en-US",
"mimeTypes": "[object MimeTypeArray]",
"vendor": "",
"vendorSub": "",
"product": "Gecko",
"productSub": "20100101",
"plugins": "[object PluginArray]",
"cookieEnabled": "true",
"onLine": "true",
"buildID": "20100101",
"doNotTrack": "unspecified",
"javaEnabled": """function javaEnabled() {
    [native code]
}""",
"taintEnabled": """function taintEnabled() {
    [native code]
}""",
"vibrate": """function vibrate() {
    [native code]
}""",
"registerContentHandler": """function registerContentHandler() {
    [native code]
}""",
"registerProtocolHandler": """function registerProtocolHandler() {
    [native code]
}""",
"mozIsLocallyAvailable": "undefined",
"mozId":  "undefined",
"mozPay":  "undefined",
"mozAlarms":  "undefined",
"mozContacts":  "undefined",
"mozPhoneNumberService":  "undefined",
"mozApps":  "undefined",
"mozTCPSocket":  "undefined",
}


class Test(MarionetteTestCase):
    def test_navigator(self):
        osname = testsuite.TestSuite().t['tbbinfos']['os']
        if osname == 'Linux':
            ua_os = 'X11; Linux x86_64'
            app_version = "5.0 (X11)"
            platform = "Linux x86_64"
            oscpu = "Linux x86_64"
        if osname == 'Windows':
            ua_os = 'Windows NT 6.1; Win64; x64'
            app_version = "5.0 (Windows)"
            platform = "Win64"
            oscpu = "Windows NT 6.1; Win64; x64"
        if osname == 'MacOSX':
            ua_os = 'Macintosh; Intel Mac OS X 10.13'
            app_version = "5.0 (Macintosh)"
            platform = "MacIntel"
            oscpu = "Intel Mac OS X 10.13"
        nav_props["userAgent"] = "Mozilla/5.0 (" + ua_os + "; rv:60.0) Gecko/20100101 Firefox/60.0"
        nav_props["appVersion"] = app_version
        nav_props["platform"] = platform
        nav_props["oscpu"] = oscpu
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')
            js = self.marionette.execute_script
            for nav_prop, expected_value in nav_props.iteritems():
                # cast to string on the JS side, otherwise we have issues
                # that raise from Python/JS type disparity
                self.marionette.set_context(self.marionette.CONTEXT_CONTENT)
                current_value = js("return ''+navigator['%s']" % nav_prop)
                self.assertEqual(expected_value, current_value, "Navigator property mismatch %s [%s != %s]" % (nav_prop, current_value, expected_value))
