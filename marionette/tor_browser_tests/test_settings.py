from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette_harness import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        # This variable contains settings we want to check on all versions of
        # Tor Browser. See below for settings to check on specific versions.
        #
        # Most of the following checks and comments are taken from 
        # https://github.com/arthuredelstein/tor-browser/blob/12620/tbb-tests/browser_tor_TB4.js 
        self.SETTINGS = {
                "privacy.clearOnShutdown.cache": True,
                "privacy.clearOnShutdown.cookies": True,
                "privacy.clearOnShutdown.downloads": True,
                "privacy.clearOnShutdown.formdata": True,
                "privacy.clearOnShutdown.history": True,
                "privacy.clearOnShutdown.sessions": True,

                # #16632 : Turn on the background autoupdater
                "app.update.auto": True,

                "browser.search.update": False,
                "browser.rights.3.shown": True,

                # startup.homepage_welcome_url is changed by:
                # marionette/firefox-ui-tests/firefox_ui_harness/runners/base.py
                #"startup.homepage_welcome_url": "",

                # Disk activity: Disable Browsing History Storage
                "browser.privatebrowsing.autostart": True,
                "browser.cache.disk.enable": False,
                "browser.cache.offline.enable": False,
                "dom.indexedDB.enabled": True,
                "permissions.memory_only": True,
                "network.cookie.lifetimePolicy": 2,
                "browser.download.manager.retention": 1,
                "security.nocertdb": True,

                # Disk activity: TBB Directory Isolation
                "browser.download.useDownloadDir": False,
                "browser.shell.checkDefaultBrowser": False,
                "browser.download.manager.addToRecentDocs": False,

                # Misc privacy: Disk
                "signon.rememberSignons": False,
                "browser.formfill.enable": False,
                "signon.autofillForms": False,
                "browser.sessionstore.privacy_level": 2,
                "media.cache_size": 0,

                # Misc privacy: Remote
                "browser.send_pings": False,
                "geo.enabled": False,
                "geo.wifi.uri": "",
                "browser.search.suggest.enabled": False,
                "browser.safebrowsing.enabled": False,
                "browser.safebrowsing.malware.enabled": False,
                "browser.download.manager.scanWhenDone": False, # prevents AV remote reporting of downloads
                "extensions.ui.lastCategory": "addons://list/extension",
                "datareporting.healthreport.service.enabled": False, # Yes, all three of these must be set
                "datareporting.healthreport.uploadEnabled": False,
                "datareporting.policy.dataSubmissionEnabled": False,
                "security.mixed_content.block_active_content": True, # Activated with bug #21323

                # Don't fetch a localized remote page that Tor Browser interacts with, see
                # #16727. And, yes, it is "reportUrl" and not "reportURL".
                "datareporting.healthreport.about.reportUrl": "data:text/plain,",
                "datareporting.healthreport.about.reportUrlUnified": "data:text/plain,",

                # Make sure Unified Telemetry is really disabled, see: #18738.
                "toolkit.telemetry.unified": False,
                "toolkit.telemetry.enabled": False,
                # No experiments, use Tor Browser. See 21797.
                "experiments.enabled": False,
                "browser.syncPromoViewsLeftMap": "{\"addons\":0, \"passwords\":0, \"bookmarks\":0}", # Don't promote sync
                "identity.fxaccounts.enabled": False, # Disable sync by default
                "services.sync.engine.prefs": False, # Never sync prefs, addons, or tabs with other browsers
                "services.sync.engine.addons": False,
                "services.sync.engine.tabs": False,
                "extensions.getAddons.cache.enabled": False, # https://blog.mozilla.org/addons/how-to-opt-out-of-add-on-metadata-updates/
                "browser.newtabpage.preload": False, # Bug 16316 - Avoid potential confusion over tiles for now.
                "browser.search.countryCode": "US", # The next three prefs disable GeoIP search lookups (#16254)
                "browser.search.region": "US",
                "browser.search.geoip.url": "",
                "browser.fixup.alternate.enabled": False, # Bug #16783: Prevent .onion fixups
                # Make sure there is no Tracking Protection active in Tor Browser, see: #17898.
                "privacy.trackingprotection.pbmode.enabled": False,
                # Disable the Pocket extension (Bug #18886)
                "browser.pocket.enabled": False,
                "browser.pocket.api": "",
                "browser.pocket.site": "",
                "network.http.referer.hideOnionSource": True,

                # Fingerprinting
                "webgl.disable-extensions": True,
                "webgl.disable-fail-if-major-performance-caveat": True,
                "webgl.enable-webgl2": False,
                "gfx.downloadable_fonts.fallback_delay": -1,
                "general.appname.override": "Netscape",
                "general.appversion.override": "5.0 (Windows)",
                "general.oscpu.override": "Windows NT 6.1",
                "general.platform.override": "Win32",
                "general.productSub.override": "20100101",
                "general.buildID.override": "20100101",
                "browser.startup.homepage_override.buildID": "20100101",
                "general.useragent.vendor": "",
                "general.useragent.vendorSub": "",
                "dom.enable_performance": False,
                "plugin.expose_full_path": False,
                "browser.zoom.siteSpecific": False,
                "intl.charset.default": "windows-1252",
                "browser.link.open_newwindow.restriction": 0, # Bug 9881: Open popups in new tabs (to avoid fullscreen popups)
                "dom.gamepad.enabled": False, # bugs.torproject.org/13023
                # Disable video statistics fingerprinting vector (bug 15757)
                "media.video_stats.enabled": False,
                # Set video VP9 to 0 for everyone (bug 22548)
                "media.benchmark.vp9.threshold": 0,
                # Disable device sensors as possible fingerprinting vector (bug 15758)
                "device.sensors.enabled": False,
                "dom.enable_resource_timing": False, # Bug 13024: To hell with this API
                "dom.enable_user_timing": False, # Bug 16336: To hell with this API
                "privacy.resistFingerprinting": True,
                "privacy.resistFingerprinting.block_mozAddonManager": True, # Bug 26114
                "dom.event.highrestimestamp.enabled": True, # Bug #17046: "Highres" (but truncated) timestamps prevent uptime leaks
                "privacy.suppressModifierKeyEvents": True, # Bug #17009: Suppress ALT and SHIFT events"
                "ui.use_standins_for_native_colors": True, # https://bugzilla.mozilla.org/232227
                "privacy.use_utc_timezone": True,
                "media.webspeech.synth.enabled": False, # Bug 10283: Disable SpeechSynthesis API
                "dom.webaudio.enabled": False, # Bug 13017: Disable Web Audio API
                "dom.maxHardwareConcurrency": 1, # Bug 21675: Spoof single-core cpu
                "dom.w3c_touch_events.enabled": 0, # Bug 10286: Always disable Touch API
                "dom.w3c_pointer_events.enabled": False,
                "dom.vr.enabled": False, # Bug 21607: Disable WebVR for now
                # Disable randomised Firefox HTTP cache decay user test groups (Bug: 13575)
                "security.webauth.webauthn": False, # Bug 26614: Disable Web Authentication API for now
                "browser.cache.frecency_experiment": -1,
                # Until https://bugzilla.mozilla.org/show_bug.cgi?id=1446472 is solved fall
                # back to old canvas behavior.
                "privacy.resistFingerprinting.autoDeclineNoUserInputCanvasPrompts": False,
                
                # Third party stuff
                "network.cookie.cookieBehavior": 1,
                "privacy.firstparty.isolate": True,
                "network.http.spdy.allow-push": False, # Disabled for now. See https://bugs.torproject.org/27127
                "network.predictor.enabled": False, # Temporarily disabled. See https://bugs.torproject.org/16633
                
                # Proxy and proxy security
                "network.proxy.socks": "127.0.0.1",
                "network.proxy.socks_remote_dns": True,
                "network.proxy.no_proxies_on": "", # For fingerprinting and local service vulns (#10419)
                "network.proxy.type": 1,
                "network.security.ports.banned": "9050,9051,9150,9151",
                "network.dns.disablePrefetch": True,
                "network.protocol-handler.external-default": False,
                "network.protocol-handler.external.mailto": False,
                "network.protocol-handler.external.news": False,
                "network.protocol-handler.external.nntp": False,
                "network.protocol-handler.external.snews": False,
                "network.protocol-handler.warn-external.mailto": True,
                "network.protocol-handler.warn-external.news": True,
                "network.protocol-handler.warn-external.nntp": True,
                "network.protocol-handler.warn-external.snews": True,
                "plugins.click_to_play": True,
                "plugin.state.flash": 1,
                "media.peerconnection.enabled": False, # Disable WebRTC interfaces
                # Disables media devices but only if `media.peerconnection.enabled` is set to
                # `false` as well. (see bug 16328 for this defense-in-depth measure)
                "media.navigator.enabled": False,
                # GMPs: We make sure they don't show up on the Add-on panel and confuse users.
                # And the external update/donwload server must not get pinged. We apply a
                # clever solution for https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=769716.
                "media.gmp-provider.enabled": False,
                "media.gmp-manager.url.override": "data:text/plain,",
                # Since ESR52 it is not enough anymore to block pinging the GMP update/download
                # server. There is a local fallback that must be blocked now as well. See:
                # https://bugzilla.mozilla.org/show_bug.cgi?id=1267495.
                "media.gmp-manager.updateEnabled": False,
                # Mozilla is relying on preferences to make sure no DRM blob is downloaded and
                # run. Even though those prefs should be set correctly by specifying
                # --disable-eme (which we do), we disable all of them here as well for defense
                # in depth.
                "browser.eme.ui.enabled": False,
                "media.gmp-eme-adobe.visible": False,
                "media.gmp-eme-adobe.enabled": False,
                "media.gmp-widevinecdm.visible": False,
                "media.gmp-widevinecdm.enabled": False,
                "media.eme.enabled": False,
                "media.eme.apiVisible": False,
                # WebIDE can bypass proxy settings for remote debugging. It also downloads
                # some additional addons that we have not reviewed. Turn all that off.
                "devtools.webide.autoinstallADBHelper": False,
                "devtools.webide.autoinstallFxdtAdapters": False,
                "devtools.webide.enabled": False,
                "devtools.appmanager.enabled": False,
                # The in-browser debugger for debugging chrome code is not coping with our
                # restrictive DNS look-up policy. We use "127.0.0.1" instead of "localhost" as
                # a workaround. See bug 16523 for more details.
                "devtools.debugger.chrome-debugging-host": "127.0.0.1",
                # Disable using UNC paths (bug 26424 and Mozilla's bug 1413868)
                "network.file.disable_unc_paths": True,
                # Enhance our treatment of file:// to avoid proxy bypasses (see Mozilla's bug
                # 1412081)
                "network.file.path_blacklist": "/net",

                # Network and performance
                "security.ssl.enable_false_start": True,
                "network.http.connection-retry-timeout": 0,
                "network.http.max-persistent-connections-per-proxy": 256,
                "network.manage-offline-status": False,
                # No need to leak things to Mozilla, see bug 21790
                "network.captive-portal-service.enabled": False,
                # As a "defense in depth" measure, configure an empty push server URL (the
                # DOM Push features are disabled by default via other prefs).
                "dom.push.serverURL": "",

                
                # Extension support
                "extensions.autoDisableScopes": 0,
                "extensions.bootstrappedAddons": "{}",
                "extensions.checkCompatibility.4.*": False,
                "extensions.enabledAddons": "https-everywhere%40eff.org:3.1.4,%7B73a6fe31-595d-460b-a920-fcc0f8843232%7D:2.6.6.1,torbutton%40torproject.org:1.5.2,ubufox%40ubuntu.com:2.6,tor-launcher%40torproject.org:0.1.1pre-alpha,%7B972ce4c6-7e08-4474-a285-3208198ce6fd%7D:17.0.5",
                "extensions.enabledItems": "langpack-en-US@firefox.mozilla.org:,{73a6fe31-595d-460b-a920-fcc0f8843232}:1.9.9.57,{e0204bd5-9d31-402b-a99d-a6aa8ffebdca}:1.2.4,{972ce4c6-7e08-4474-a285-3208198ce6fd}:3.5.8",
                # extensions.enabledScopes is set to 5 by marionette_driver
                #"extensions.enabledScopes": 1,
                "extensions.pendingOperations": False,
                "xpinstall.whitelist.add": "",
                "xpinstall.whitelist.add.36": "",
                # We don't know what extensions Mozilla is advertising to our users and we
                # don't want to have some random Google Analytics script running either on the
                # about:addons page, see bug 22073 and 22900.
                "extensions.getAddons.showPane": False,
                # Show our legacy extensions directly on about:addons and get rid of the
                # warning for the default theme.
                "extensions.legacy.exceptions": "{972ce4c6-7e08-4474-a285-3208198ce6fd},torbutton@torproject.org,tor-launcher@torproject.org",
                # Bug 26114: Allow NoScript to access addons.mozilla.org etc.
                "extensions.webextensions.restrictedDomains": "",

                # Audio_data is deprecated in future releases, but still present
                # in FF24. This is a dangerous combination (spotted by iSec)
                "media.audio_data.enabled": False,
                
                "dom.enable_resource_timing": False,

                # If true, remote JAR files will not be opened, regardless of content type
                # Patch written by Jeff Gibat (iSEC).
                "network.jar.block-remote-files": True,

                # Disable RC4 fallback. This will go live in Firefox 44, Chrome and IE/Edge:
                # https://blog.mozilla.org/security/2015/09/11/deprecating-the-rc4-cipher/
                "security.tls.unrestricted_rc4_fallback": False,

                # Enforce certificate pinning, see: https://bugs.torproject.org/16206
                "security.cert_pinning.enforcement_level": 2,

                # Don't allow MitM via Microsoft Family Safety, see bug 21686
                "security.family_safety.mode": 0,

                # Enforce SHA1 deprecation, see: bug 18042.
                "security.pki.sha1_enforcement_level": 2,

                # Disable the language pack signing check for now, see: bug 26465
                "extensions.langpacks.signatures.required": False,

                # Avoid report TLS errors to Mozilla. We might want to repurpose this feature
                # one day to help detecting bad relays (which is bug 19119). For now we just
                # hide the checkbox, see bug 22072.
                "security.ssl.errorReporting.enabled": False,

                # Workaround for https://bugs.torproject.org/13579. Progress on
                # `about:downloads` is only shown if the following preference is set to `true`
                # in case the download panel got removed from the toolbar.
                "browser.download.panel.shown": True,

                # Treat .onions as secure
                "dom.securecontext.whitelist_onions": True,

                # checking torbrowser.version match the version from the filename
                "torbrowser.version": ts.t["tbbinfos"]["version"],
                
                # Disable device sensors as possible fingerprinting vector (bug 15758)
                "device.sensors.enabled": False,
                # Disable video statistics fingerprinting vector (bug 15757)
                "media.video_stats.enabled": False,

                "startup.homepage_override_url": "https://blog.torproject.org/category/tags/tor-browser",
                "network.jar.block-remote-files": True,
                }

        # Settings for the Tor Browser 8.0
        self.SETTINGS_80 = {
                }

        # Settings for the Tor Browser 8.5 and Nightly
        self.SETTINGS_85 = {
                }

    def test_settings(self):
        ts = testsuite.TestSuite()
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')

            settings = self.SETTINGS.copy()
            if self.ts.t['tbbinfos']['version'].startswith('8.0'):
                settings.update(self.SETTINGS_80)

            if self.ts.t['tbbinfos']['version'].startswith('8.5') or \
                    self.ts.t['tbbinfos']['version'] == 'tbb-nightly':
                settings.update(self.SETTINGS_85)

            errors = ''
            for name, val in settings.iteritems():
                if self.marionette.get_pref(name) != val:
                    errors += "%s: %s != %s\n" % (name, self.marionette.get_pref(name), val)



            self.assertEqual(errors, '', msg=errors)
