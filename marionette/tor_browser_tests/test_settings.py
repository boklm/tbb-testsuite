from marionette_driver import By
from marionette_driver.errors import MarionetteException

from firefox_ui_harness import FirefoxTestCase

import testsuite


class Test(FirefoxTestCase):

    def setUp(self):
        FirefoxTestCase.setUp(self)

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
                "dom.indexedDB.enabled": False,
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
                "security.mixed_content.block_active_content": False, # Disable until https://bugzilla.mozilla.org/show_bug.cgi?id=878890 is patched
                "browser.syncPromoViewsLeftMap": "{\"addons\":0, \"passwords\":0, \"bookmarks\":0}", # Don't promote sync
                "services.sync.engine.prefs": False, # Never sync prefs, addons, or tabs with other browsers
                "services.sync.engine.addons": False,
                "services.sync.engine.tabs": False,
                "extensions.getAddons.cache.enabled": False, # https://blog.mozilla.org/addons/how-to-opt-out-of-add-on-metadata-updates/

                # Fingerprinting
                "webgl.min_capability_mode": True,
                "webgl.disable-extensions": True,
                "dom.battery.enabled": False, # fingerprinting due to differing OS implementations
                "dom.network.enabled":False, # fingerprinting due to differing OS implementations
                "browser.display.max_font_attempts":10,
                "browser.display.max_font_count":10,
                "gfx.downloadable_fonts.fallback_delay": -1,
                "general.appname.override": "Netscape",
                "general.appversion.override": "5.0 (Windows)",
                "general.oscpu.override": "Windows NT 6.1",
                "general.platform.override": "Win32",
                "general.useragent.override": "Mozilla/5.0 (Windows NT 6.1; rv:38.0) Gecko/20100101 Firefox/38.0",
                "general.productSub.override": "20100101",
                "general.buildID.override": "20100101",
                "general.useragent.vendor": "",
                "general.useragent.vendorSub": "",
                "dom.enable_performance": False,
                "plugin.expose_full_path": False,
                "browser.zoom.siteSpecific": False,
                "intl.charset.default": "windows-1252",
                #"intl.accept_languages": "en-us, en": # Set by Torbutton
                #"intl.accept_charsets": "iso-8859-1,*,utf-8": # Set by Torbutton
                #"intl.charsetmenu.browser.cache": "UTF-8": # Set by Torbutton
                
                # Third party stuff
                "network.cookie.cookieBehavior": 1,
                "security.enable_tls_session_tickets": False,
                "network.http.spdy.enabled": False, # Stores state and may have keepalive issues (both fixable)
                "network.http.spdy.enabled.v2": False, # Seems redundant, but just in case
                "network.http.spdy.enabled.v3": False, # Seems redundant, but just in case
                "privacy.thirdparty.isolate": 2, # Always enforce third party isolation
                
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
                
                # Network and performance
                "network.http.pipelining": True,
                "network.http.pipelining.aggressive": True,
                "network.http.pipelining.maxrequests": 12,
                "network.http.pipelining.ssl": True,
                "network.http.proxy.pipelining": True,
                "security.ssl.enable_false_start": True,
                "network.http.connection-retry-timeout": 0,
                "network.http.max-persistent-connections-per-proxy": 256,
                "network.http.pipelining.reschedule-timeout": 15000,
                "network.http.pipelining.read-timeout": 60000,
                # Hacked pref: Now means "Attempt to pipeline at least this many requests together"
                "network.http.pipelining.max-optimistic-requests": 3,
                # "security.disable_session_identifiers": True,  TODO: check the default
                
                # Extension support
                # "extensions.autoDisableScopes": 0, TODO: check default
                "extensions.checkCompatibility.4.*": False,
                # "extensions.databaseSchema": 3, TODO: check default
                
                # TODO: check default
                # "extensions.enabledAddons": "https-everywhere%40eff.org:3.1.4,%7B73a6fe31-595d-460b-a920-fcc0f8843232%7D:2.6.6.1,torbutton%40torproject.org:1.5.2,ubufox%40ubuntu.com:2.6,tor-launcher%40torproject.org:0.1.1pre-alpha,%7B972ce4c6-7e08-4474-a285-3208198ce6fd%7D:17.0.5",
                "extensions.enabledItems": "langpack-en-US@firefox.mozilla.org:,{73a6fe31-595d-460b-a920-fcc0f8843232}:1.9.9.57,{e0204bd5-9d31-402b-a99d-a6aa8ffebdca}:1.2.4,{972ce4c6-7e08-4474-a285-3208198ce6fd}:3.5.8",
                # "extensions.enabledScopes": 1, TODO: check the default value
                "extensions.pendingOperations": False,
                "xpinstall.whitelist.add": "",
                "xpinstall.whitelist.add.36": "",
                
                # Hacks/workarounds: Direct2D seems to crash w/ lots of video cards w/ MinGW?
                # Nvida cards also experience crashes without the second pref set to disabled
                "gfx.direct2d.disabled": True,
                "layers.acceleration.disabled": True,
                
                # Audio_data is deprecated in future releases, but still present
                # in FF24. This is a dangerous combination (spotted by iSec)
                "media.audio_data.enabled": False,
                
                # Enable TLS 1.1 and 1.2:
                # https://trac.torproject.org/projects/tor/ticket/11253
                "security.tls.version.max": 3,
                
                "dom.enable_resource_timing": False,

                # checking torbrowser.version match the version from the filename
                "torbrowser.version": ts.t["tbbinfos"]["version"],
                
                # Disable device sensors as possible fingerprinting vector (bug 15758)
                "device.sensors.enabled": False,
                # Disable video statistics fingerprinting vector (bug 15757)
                "media.video_stats.enabled": False,
                }

        # Settings for the Tor Browser 5.0 branch
        self.SETTINGS_50 = {
                "startup.homepage_override_url": "",
                "browser.startup.homepage_override.buildID": "20100101",
                "browser.startup.homepage_override.mstone": "ignore",
                "dom.workers.sharedWorkers.enabled": False, # See https://bugs.torproject.org/15562
                }

        # Settings for the Tor Browser 5.5 and nightly branch
        self.SETTINGS_55 = {
                "startup.homepage_override_url": "https://blog.torproject.org/category/tags/tor-browser",
                "browser.startup.homepage_override.buildID": "20000101000000",
                "dom.workers.sharedWorkers.enabled": True, # See #15564
                }


    def test_settings(self):
        ts = testsuite.TestSuite()
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')

            settings = self.SETTINGS.copy()
            if self.ts.t['tbbinfos']['version'].startswith('5.0'):
                settings.update(self.SETTINGS_50)

            if self.ts.t['tbbinfos']['version'].startswith('5.5') or \
                    self.ts.t['tbbinfos']['version'] == 'tbb-nightly':
                settings.update(self.SETTINGS_55)

            errors = ''
            for name, val in settings.iteritems():
                if self.prefs.get_pref(name) != val:
                    errors += "%s: %s != %s\n" % (name, self.prefs.get_pref(name), val)



            self.assertEqual(errors, '', msg=errors)
