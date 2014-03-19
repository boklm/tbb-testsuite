/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This test should be run with the https-everywhere extension disabled

"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var prefs = require("../mozilla-mozmill-tests/firefox/lib/prefs");

const PREF_ENABLE_HE = "extensions.https_everywhere.globalEnabled";
const HTTP_URL = "http://www.mediawiki.org/wiki/MediaWiki";

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testStartTBB = function() {
    var prefSrv = prefs.preferences;
    expect.equal(prefSrv.getPref(PREF_ENABLE_HE, true), false,
            "https-everywhere is disabled");
    controller.open(HTTP_URL);
    controller.waitForPageLoad();
    expect.equal(controller.tabs.activeTab.URL, HTTP_URL,
            "http URL has not been redirected to https");
}
