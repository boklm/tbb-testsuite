// This test checks whether the Resource Timing API (see:
// http://www.w3.org/TR/resource-timing/) is really disabled in the default
// Tor Browser. Setting |dom.enable_resource_timing| to |false| and testing that
// might not be sufficient.

"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var common = require("../lib/common");

const TEST_URL = "https://www.mediawiki.org/wiki/MediaWiki";
const RESOURCE_URL =
  "https://upload.wikimedia.org/wikipedia/mediawiki/b/bc/Wiki.png";

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testNavigationTiming = function() {
  var pass = false;
  common.load_page(controller, TEST_URL);

  // If resource timing is disabled we should not be able to get resource
  // entries at all in the first place. We test all three methods for safety's
  // sake.
  // getEntriesByType()
  try {
    let resources = controller.tabs.activeTab.defaultView.performance.
      getEntriesByType("resource")[0];
  } catch (e) {
    pass = true;
  }
  expect.ok(pass, "No resource entries found (getEntriesByType())");

  // getEntriesByName()
  pass = false;
  try {
    let resources = controller.tabs.activeTab.defaultView.performance.
      getEntriesByName(RESOURCE_URL)[0];
  } catch (e) {
    pass = true;
  }
  expect.ok(pass, "No resource entries found (getEntriesByName())");

  // getEntries()
  pass = false;
  try {
    let resources = controller.tabs.activeTab.defaultView.performance.
      getEntries()[0];
  } catch (e) {
    pass = true;
  }
  expect.ok(pass, "No resource entries found (getEntries())");
}
