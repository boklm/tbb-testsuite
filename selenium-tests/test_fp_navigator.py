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
"userAgent": "Mozilla/5.0 (Windows NT 6.1; rv:24.0) Gecko/20100101 Firefox/24.0",
"cookieEnabled": "true",
"onLine": "true",
"buildID": "20100101",
"doNotTrack": "unspecified",
"mozPower": "null",
"javaEnabled": """function javaEnabled() {
    [native code]
}""",
"taintEnabled": """function taintEnabled() {
    [native code]
}""",
"vibrate": """function vibrate() {
    [native code]
}""",
"addIdleObserver": """function addIdleObserver() {
    [native code]
}""",
"removeIdleObserver": """function removeIdleObserver() {
    [native code]
}""",
"requestWakeLock": """function requestWakeLock() {
    [native code]
}""",
"getDeviceStorage": """function getDeviceStorage() {
    [native code]
}""",
"getDeviceStorages": """function getDeviceStorages() {
    [native code]
}""",
"geolocation": "null",
"registerContentHandler": """function registerContentHandler() {
    [native code]
}""",
"registerProtocolHandler": """function registerProtocolHandler() {
    [native code]
}""",
"mozIsLocallyAvailable": """function mozIsLocallyAvailable() {
    [native code]
}""",
"mozSms": "null",
"mozMobileMessage": "null",
"mozGetUserMediaDevices": """function mozGetUserMediaDevices() {
    [native code]
}""",
"mozGetUserMedia": """function mozGetUserMedia() {
    [native code]
}""",
"mozCameras": "null", }


class Test(tbbtest.TBBTest):
    def test_navigator(self):
        driver = self.driver
        js = driver.execute_script
        # Check that plugins are disabled
        for nav_prop, value in nav_props.iteritems():
            # cast to string on the JS side, otherwise we have issues
            # that raise from Python/JS type disparity
            self.assertEqual(value, js("return ''+navigator['%s']" % nav_prop))
