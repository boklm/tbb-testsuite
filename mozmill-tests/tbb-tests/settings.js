/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

Cu.import("resource://gre/modules/Services.jsm");

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var prefs = require("../mozilla-mozmill-tests/firefox/lib/prefs");
var utils = require("../mozilla-mozmill-tests/firefox/lib/utils");
var testsuite = require("../lib/testsuite");

// This variable contains settings we want to check on all versions of
// Tor Browser. See below for settings to check on specific versions.
//
// Most of the following checks and comments are taken from 
// https://github.com/arthuredelstein/tor-browser/blob/12620/tbb-tests/browser_tor_TB4.js 
const SETTINGS = {
    "privacy.clearOnShutdown.cache": true,
    "privacy.clearOnShutdown.cookies": true,
    "privacy.clearOnShutdown.downloads": true,
    "privacy.clearOnShutdown.formdata": true,
    "privacy.clearOnShutdown.history": true,
    "privacy.clearOnShutdown.sessions": true,
    
    // Disable browser auto updaters and associated homepage notifications
    "app.update.auto": false,
    "app.update.enabled": false,
    "browser.search.update": false,
    "browser.rights.3.shown": true,
    "browser.startup.homepage_override.mstone": "ignore",
    "startup.homepage_welcome_url": "",
    "startup.homepage_override_url": "",

    // Disk activity: Disable Browsing History Storage
    "browser.privatebrowsing.autostart": true,
    "browser.cache.disk.enable": false,
    "browser.cache.offline.enable": false,
    "dom.indexedDB.enabled": false,
    "permissions.memory_only": true,
    "network.cookie.lifetimePolicy": 2,
    "browser.download.manager.retention": 1,
    "security.nocertdb": true,

    // Disk activity: TBB Directory Isolation
    "browser.download.useDownloadDir": false,
    "browser.shell.checkDefaultBrowser": false,
    "browser.download.manager.addToRecentDocs": false,

    // Misc privacy: Disk
    "signon.rememberSignons": false,
    "browser.formfill.enable": false,
    "signon.autofillForms": false,
    "browser.sessionstore.privacy_level": 2,
    "media.cache_size": 0,

    // Misc privacy: Remote
    "browser.send_pings": false,
    "geo.enabled": false,
    "geo.wifi.uri": "",
    "browser.search.suggest.enabled": false,
    "browser.safebrowsing.enabled": false,
    "browser.safebrowsing.malware.enabled": false,
    "browser.download.manager.scanWhenDone": false, // prevents AV remote reporting of downloads
    "extensions.ui.lastCategory": "addons://list/extension",
    "datareporting.healthreport.service.enabled": false, // Yes, all three of these must be set
    "datareporting.healthreport.uploadEnabled": false,
    "datareporting.policy.dataSubmissionEnabled": false,
    "security.mixed_content.block_active_content": false, // Disable until https://bugzilla.mozilla.org/show_bug.cgi?id=878890 is patched
    "browser.syncPromoViewsLeftMap": "{\"addons\":0, \"passwords\":0, \"bookmarks\":0}", // Don't promote sync
    "services.sync.engine.prefs": false, // Never sync prefs, addons, or tabs with other browsers
    "services.sync.engine.addons": false,
    "services.sync.engine.tabs": false,
    "extensions.getAddons.cache.enabled": false, // https://blog.mozilla.org/addons/how-to-opt-out-of-add-on-metadata-updates/

    // Fingerprinting
    "webgl.min_capability_mode": true,
    "webgl.disable-extensions": true,
    "dom.battery.enabled": false, // fingerprinting due to differing OS implementations
    "dom.network.enabled":false, // fingerprinting due to differing OS implementations
    "browser.display.max_font_attempts":10,
    "browser.display.max_font_count":10,
    "gfx.downloadable_fonts.fallback_delay": -1,
    "general.appname.override": "Netscape",
    "general.appversion.override": "5.0 (Windows)",
    "general.oscpu.override": "Windows NT 6.1",
    "general.platform.override": "Win32",
    "general.useragent.override": "Mozilla/5.0 (Windows NT 6.1; rv:31.0) Gecko/20100101 Firefox/31.0",
    "general.productSub.override": "20100101",
    "general.buildID.override": "20100101",
    "browser.startup.homepage_override.buildID": "20100101",
    "general.useragent.vendor": "",
    "general.useragent.vendorSub": "",
    "dom.enable_performance": false,
    "plugin.expose_full_path": false,
    "browser.zoom.siteSpecific": false,
    "intl.charset.default": "windows-1252",
    //"intl.accept_languages": "en-us, en": // Set by Torbutton
    //"intl.accept_charsets": "iso-8859-1,*,utf-8": // Set by Torbutton
    //"intl.charsetmenu.browser.cache": "UTF-8": // Set by Torbutton

    // Third party stuff
    "network.cookie.cookieBehavior": 1,
    "security.enable_tls_session_tickets": false,
    "network.http.spdy.enabled": false, // Stores state and may have keepalive issues (both fixable)
    "network.http.spdy.enabled.v2": false, // Seems redundant, but just in case
    "network.http.spdy.enabled.v3": false, // Seems redundant, but just in case
    "privacy.thirdparty.isolate": 2, // Always enforce third party isolation
    "dom.workers.sharedWorkers.enabled": false, // See https://bugs.torproject.org/15562

    // Proxy and proxy security
    "network.proxy.socks": "127.0.0.1",
    "network.proxy.socks_remote_dns": true,
    "network.proxy.no_proxies_on": "", // For fingerprinting and local service vulns (#10419)
    "network.proxy.type": 1,
    "network.security.ports.banned": "9050,9051,9150,9151",
    "network.dns.disablePrefetch": true,
    "network.protocol-handler.external-default": false,
    "network.protocol-handler.external.mailto": false,
    "network.protocol-handler.external.news": false,
    "network.protocol-handler.external.nntp": false,
    "network.protocol-handler.external.snews": false,
    "network.protocol-handler.warn-external.mailto": true,
    "network.protocol-handler.warn-external.news": true,
    "network.protocol-handler.warn-external.nntp": true,
    "network.protocol-handler.warn-external.snews": true,
    "plugins.click_to_play": true,

    // Network and performance
    "network.http.pipelining": true,
    "network.http.pipelining.aggressive": true,
    "network.http.pipelining.maxrequests": 12,
    "network.http.pipelining.ssl": true,
    "network.http.proxy.pipelining": true,
    "security.ssl.enable_false_start": true,
    "network.http.keep-alive.timeout": 20,
    "network.http.connection-retry-timeout": 0,
    "network.http.max-persistent-connections-per-proxy": 256,
    "network.http.pipelining.reschedule-timeout": 15000,
    "network.http.pipelining.read-timeout": 60000,
    // Hacked pref: Now means "Attempt to pipeline at least this many requests together"
    "network.http.pipelining.max-optimistic-requests": 3,
    // "security.disable_session_identifiers": true,  TODO: check the default

    // Extension support
    // "extensions.autoDisableScopes": 0, TODO: check default
    "extensions.checkCompatibility.4.*": false,
    // "extensions.databaseSchema": 3, TODO: check default
    
    // TODO: check default
    // "extensions.enabledAddons": "https-everywhere%40eff.org:3.1.4,%7B73a6fe31-595d-460b-a920-fcc0f8843232%7D:2.6.6.1,torbutton%40torproject.org:1.5.2,ubufox%40ubuntu.com:2.6,tor-launcher%40torproject.org:0.1.1pre-alpha,%7B972ce4c6-7e08-4474-a285-3208198ce6fd%7D:17.0.5",
    "extensions.enabledItems": "langpack-en-US@firefox.mozilla.org:,{73a6fe31-595d-460b-a920-fcc0f8843232}:1.9.9.57,{e0204bd5-9d31-402b-a99d-a6aa8ffebdca}:1.2.4,{972ce4c6-7e08-4474-a285-3208198ce6fd}:3.5.8",
    // "extensions.enabledScopes": 1, TODO: check the default value
    "extensions.pendingOperations": false,
    "xpinstall.whitelist.add": "",
    "xpinstall.whitelist.add.36": "",

    // Hacks/workarounds: Direct2D seems to crash w/ lots of video cards w/ MinGW?
    // Nvida cards also experience crashes without the second pref set to disabled
    "gfx.direct2d.disabled": true,
    "layers.acceleration.disabled": true,

    // Audio_data is deprecated in future releases, but still present
    // in FF24. This is a dangerous combination (spotted by iSec)
    "media.audio_data.enabled": false,

    // Enable TLS 1.1 and 1.2:
    // https://trac.torproject.org/projects/tor/ticket/11253
    "security.tls.version.max": 3,

    "dom.enable_resource_timing": false,

    // "torbrowser.version": "UNKNOWN", // TODO: Should we check version using a regexp?
};

// Settings for the Tor Browser 4.0 branch
const SETTINGS_40 = {
    // Omnibox settings
    "keyword.URL": "https://startpage.com/do/search?q=",

    // Security enhancements
    // https://trac.torproject.org/projects/tor/ticket/9387#comment:17
    "javascript.options.ion.content": false,
    "javascript.options.baselinejit.content": false,
    "javascript.options.asmjs": false,
    "javascript.options.typeinference": false,
}

// Settings for the Tor Browser 4.5 and nightly branch
const SETTINGS_45 = {
}

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

function dval(v) {
    if (typeof v == "boolean")
        return !v;
    if (typeof v == "number")
        return v + 1;
    if (typeof v == "string")
        return "ZZZ";
    return "ZZZ";
}

var testTBBSettings = function() {
    var prefSrv = prefs.preferences;
    for (let prefname in SETTINGS)
        expect.equal(prefSrv.getPref(prefname, dval(SETTINGS[prefname])),
                     SETTINGS[prefname], prefname);
    if (testsuite.tbbinfos.version.startsWith("4.0")) {
        for (let prefname in SETTINGS_40)
            expect.equal(prefSrv.getPref(prefname, dval(SETTINGS_40[prefname])),
                         SETTINGS_40[prefname], prefname);
    }
    if (testsuite.tbbinfos.version.startsWith("4.5")
            || testsuite.tbbinfos.version == "tbb-nightly") {
        for (let prefname in SETTINGS_45)
            expect.equal(prefSrv.getPref(prefname, dval(SETTINGS_45[prefname])),
                         SETTINGS_45[prefname], prefname);
    }
}
