// This test should be run with the https-everywhere extension disabled

"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var prefs = require("../mozilla-mozmill-tests/firefox/lib/prefs");
var common = require("../lib/common");

const PREF_ENABLE_HE = "extensions.https_everywhere.globalEnabled";
const HTTP_URL = "http://www.freedomboxfoundation.org/images/freedombox_large.png";

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testStartTBB = function() {
    var prefSrv = prefs.preferences;
    expect.equal(prefSrv.getPref(PREF_ENABLE_HE, true), false,
            "https-everywhere is disabled");
    common.load_page(controller, HTTP_URL);
    expect.equal(controller.tabs.activeTab.URL, HTTP_URL,
            "http URL has not been redirected to https");
}
