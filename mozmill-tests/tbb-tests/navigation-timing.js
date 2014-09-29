// This test checks whether the Navigation Timing API (see:
// http://www.w3.org/TR/navigation-timing/) is really disabled in the default
// Tor Browser. Setting |dom.enable_performance| to |false| and testing that has
// been not sufficient. See bug 13186 for further details.

"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var common = require("../lib/common");

const TEST_URL = "https://www.mediawiki.org/wiki/MediaWiki";

const ATTRIBUTES = {
  "navigationStart": 0,
  "unloadEventStart": 0,
  "unloadEventEnd": 0,
  "redirectStart": 0,
  "redirectEnd": 0,
  "fetchStart": 0,
  "domainLookupStart": 0,
  "domainLookupEnd": 0,
  "connectStart": 0,
  "connectEnd": 0,
  // Not available in Firefox yet.
  "secureConnectionStart": undefined,
  "requestStart": 0,
  "responseStart": 0,
  "responseEnd": 0,
  "domLoading": 0,
  "domInteractive": 0,
  "domContentLoadedEventStart": 0,
  "domContentLoadedEventEnd": 0,
  "domComplete": 0,
  "loadEventStart": 0,
  "loadEventEnd": 0
};

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testNavigationTiming = function() {
  common.load_page(controller, TEST_URL);
  let timing = controller.tabs.activeTab.defaultView.performance.timing;
  for (let attr in ATTRIBUTES) {
    expect.equal(timing[attr], ATTRIBUTES[attr], attr);
  }
}
