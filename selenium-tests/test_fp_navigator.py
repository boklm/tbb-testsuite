#!/usr/bin/python
import tbbtest

# expected values for navigation properties
nav_props = {"appCodeName": "Mozilla",
"appName": "Netscape",
"appVersion": "5.0 (Windows)",
"language": "en-US",
"mimeTypes": "[object MimeTypeArray]",
"platform": "Win32",
"oscpu": "Windows NT 6.1",
"vendor": "",
"vendorSub": "",
"product": "Gecko",
"productSub": "20100101",
"plugins": "[object PluginArray]",
"userAgent": "Mozilla/5.0 (Windows NT 6.1; rv:38.0) Gecko/20100101 Firefox/38.0",
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
"mozIsLocallyAvailable": """function mozIsLocallyAvailable() {
    [native code]
}""",
"mozId":  "null",
"mozPay":  "null",
"mozAlarms":  "null",
"mozContacts":  "[object ContactManager]",
"mozPhoneNumberService":  "[object PhoneNumberService]",
"mozApps":  "[xpconnect wrapped (nsISupports, mozIDOMApplicationRegistry, mozIDOMApplicationRegistry2)]",
"mozTCPSocket":  "null",
}


class Test(tbbtest.TBBTest):
    def test_navigator(self):
        driver = self.driver
        js = driver.execute_script
        # Check that plugins are disabled
        for nav_prop, expected_value in nav_props.iteritems():
            # cast to string on the JS side, otherwise we have issues
            # that raise from Python/JS type disparity
            current_value = js("return ''+navigator['%s']" % nav_prop)
            self.assertEqual(expected_value, current_value, "Navigator property mismatch %s [%s != %s]" % (nav_prop, current_value, expected_value))
