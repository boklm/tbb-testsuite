/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var prefs = require("../mozilla-mozmill-tests/firefox/lib/prefs");

const SETTINGS = {
    "browser.cache.disk.enable": false,
    "privacy.clearOnShutdown.cache": true,
    "privacy.clearOnShutdown.cookies": true,
    "privacy.clearOnShutdown.downloads": true,
    "privacy.clearOnShutdown.formdata": true,
    "privacy.clearOnShutdown.history": true,
    "privacy.clearOnShutdown.sessions": true,
    "app.update.enabled": false,
    "geo.enabled": false,
    "network.cookie.cookieBehavior": 1,
    "browser.download.manager.addToRecentDocs": false,
    "browser.formfill.enable": false,
    "network.http.spdy.enabled": false,
};

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
}
