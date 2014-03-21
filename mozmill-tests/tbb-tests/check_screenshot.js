/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

// Include this if opening relocatable, potentially remotely located files
const BASE_URL = collector.addHttpResource("../mozilla-mozmill-tests/data/");
const TEST_DATA = BASE_URL + "path/file.html";

// Include this if opening external urls
// const TEST_DATA = "http://www.external.url/path/file.html";

// Include this only if specifying a timeout other than 5000ms
const TEST_EXAMPLE_TIMEOUT = 3000;

var common = require("../lib/common");
var screenshot = require("../lib/screenshot");

// Setup for the test
var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

// Run the test
var testStartTBB = function() {
    common.load_page(controller, 'http://check.torproject.org');
    screenshot.create(controller, []);
}
