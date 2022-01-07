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

                "browser.search.update": False,
                "browser.rights.3.shown": True,

                # startup.homepage_welcome_url is changed by:
                # marionette/firefox-ui-tests/firefox_ui_harness/runners/base.py
                #"startup.homepage_welcome_url": "",

                # Disk activity: Disable Browsing History Storage
                "browser.privatebrowsing.autostart": True,
                "browser.cache.disk.enable": False,
                "permissions.memory_only": True,
                "network.cookie.lifetimePolicy": 2,
                "security.nocertdb": True,

                # Enabled LSNG
                "dom.storage.next_gen": True,

                # Disk activity: TBB Directory Isolation
                "browser.download.useDownloadDir": False,
                "browser.shell.checkDefaultBrowser": False,
                "browser.download.manager.addToRecentDocs": False,

                # Misc privacy: Disk
                "signon.rememberSignons": False,
                "browser.formfill.enable": False,
                "signon.autofillForms": False,
                "browser.sessionstore.privacy_level": 2,

                # Misc privacy: Remote
                "browser.send_pings": False,
                "geo.enabled": False,
                "geo.provider.network.url": "",
                "browser.search.suggest.enabled": False,
                "browser.safebrowsing.phishing.enabled": False,
                "browser.safebrowsing.malware.enabled": False,
                "extensions.ui.lastCategory": "addons://list/extension",
                "datareporting.healthreport.uploadEnabled": False,
                "datareporting.policy.dataSubmissionEnabled": False,
                "security.mixed_content.block_active_content": True, # Activated with bug #21323

                # Bug 40083: Make sure Region.jsm fetching is disabled
                "browser.region.update.enabled": False,

                # Make sure Unified Telemetry is really disabled, see: #18738.
                "toolkit.telemetry.unified": False,
                "toolkit.telemetry.enabled": True if ts.t["tbbinfos"]["version"].startswith("tbb-nightly") else False,
                "identity.fxaccounts.enabled": False, # Disable sync by default
                "services.sync.engine.prefs": False, # Never sync prefs, addons, or tabs with other browsers
                "services.sync.engine.addons": False,
                "services.sync.engine.tabs": False,
                "extensions.getAddons.cache.enabled": False, # https://blog.mozilla.org/addons/how-to-opt-out-of-add-on-metadata-updates/
                "browser.search.region": "US",
                "browser.search.geoip.url": "",
                "browser.fixup.alternate.enabled": False, # Bug #16783: Prevent .onion fixups
                # Make sure there is no Tracking Protection active in Tor Browser, see: #17898.
                "privacy.trackingprotection.pbmode.enabled": False,
                # Disable the Pocket extension (Bug #18886 and #31602)
                "extensions.pocket.enabled": False,

                # Fingerprinting
                "webgl.disable-fail-if-major-performance-caveat": True,
                "webgl.enable-webgl2": False,
                "gfx.downloadable_fonts.fallback_delay": -1,
                "browser.startup.homepage_override.buildID": "20100101",
                "browser.link.open_newwindow.restriction": 0, # Bug 9881: Open popups in new tabs (to avoid fullscreen popups)
                # Set video VP9 to 0 for everyone (bug 22548)
                "media.benchmark.vp9.threshold": 0,
                "dom.enable_resource_timing": False, # Bug 13024: To hell with this API
                "privacy.resistFingerprinting": True,
                "privacy.resistFingerprinting.block_mozAddonManager": True, # Bug 26114
                "dom.webaudio.enabled": False, # Bug 13017: Disable Web Audio API
                "dom.w3c_touch_events.enabled": 0, # Bug 10286: Always disable Touch API
                "dom.vr.enabled": False, # Bug 21607: Disable WebVR for now
                # Disable randomised Firefox HTTP cache decay user test groups (Bug: 13575)
                "security.webauth.webauthn": False, # Bug 26614: Disable Web Authentication API for now
                # Disable SAB, no matter if the sites are cross-origin isolated.
                "dom.postMessage.sharedArrayBuffer.withCOOP_COEP": False,
                "network.http.referer.hideOnionSource": True,
                # Bug 40463: Disable Windows SSO
                "network.http.windows-sso.enabled": False,
                # Bug 40383: Disable new PerformanceEventTiming
                "dom.enable_event_timing": False,
                # Disable API for measuring text width and height.
                "dom.textMetrics.actualBoundingBox.enabled": False,
                "dom.textMetrics.baselines.enabled": False,
                "dom.textMetrics.emHeight.enabled": False,
                "dom.textMetrics.fontBoundingBox.enabled": False,
                "pdfjs.enableScripting": False,

                # Third party stuff
                "network.cookie.cookieBehavior": 1,
                "privacy.firstparty.isolate": True,
                "network.http.spdy.allow-push": False, # Disabled for now. See https://bugs.torproject.org/27127
                "network.predictor.enabled": False, # Temporarily disabled. See https://bugs.torproject.org/16633
                # Bug 40177: Make sure tracker cookie purging is disabled
                "privacy.purge_trackers.enabled": False,
                
                # Proxy and proxy security
                "network.proxy.socks": "127.0.0.1",
                "network.proxy.socks_remote_dns": True,
                "network.proxy.no_proxies_on": "", # For fingerprinting and local service vulns (#10419)
                "network.proxy.type": 1,
                # Bug 40548: Disable proxy-bypass
                "network.proxy.failover_direct": False,
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
                "media.gmp-widevinecdm.visible": False,
                "media.gmp-widevinecdm.enabled": False,
                "media.eme.enabled": False,
                # WebIDE can bypass proxy settings for remote debugging. It also downloads
                # some additional addons that we have not reviewed. Turn all that off.
                "devtools.webide.autoinstallADBExtension": False,
                "devtools.webide.enabled": False,
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
                # extensions.enabledScopes is set to 5 by marionette_driver
                #"extensions.enabledScopes": 1,
                "extensions.pendingOperations": False,
                # We don't know what extensions Mozilla is advertising to our users and we
                # don't want to have some random Google Analytics script running either on the
                # about:addons page, see bug 22073 and 22900.
                "extensions.getAddons.showPane": False,
                # Bug 26114: Allow NoScript to access addons.mozilla.org etc.
                "extensions.webextensions.restrictedDomains": "",
                # Don't give Mozilla-recommended third-party extensions special privileges.
                "extensions.postDownloadThirdPartyPrompt": False,

                "dom.enable_resource_timing": False,

                # Disable RC4 fallback. This will go live in Firefox 44, Chrome and IE/Edge:
                # https://blog.mozilla.org/security/2015/09/11/deprecating-the-rc4-cipher/

                # Enforce certificate pinning, see: https://bugs.torproject.org/16206
                "security.cert_pinning.enforcement_level": 2,

                # Don't load OS client certs.
                "security.osclientcerts.autoload": False,

                # Don't allow MitM via Microsoft Family Safety, see bug 21686
                "security.family_safety.mode": 0,

                # Workaround for https://bugs.torproject.org/13579. Progress on
                # `about:downloads` is only shown if the following preference is set to `true`
                # in case the download panel got removed from the toolbar.
                "browser.download.panel.shown": True,

                # Treat .onions as secure
                "dom.securecontext.whitelist_onions": True,

                # checking torbrowser.version match the version from the filename
                "torbrowser.version": ts.t["tbbinfos"]["version"],

                "startup.homepage_override_url": "https://blog.torproject.org/category/applications",

                # Disable network information API everywhere
                # but, alas, the behavior is inconsistent across platforms, see:
                # https://trac.torproject.org/projects/tor/ticket/27268#comment:19. We should
                # not leak that difference if possible.
                "dom.netinfo.enabled": False,
                }

        MOZ_BUNDLED_FONTS = True
        if MOZ_BUNDLED_FONTS:
            self.SETTINGS["gfx.bundled-fonts.activate"] = 1

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
