"use strict";

var common = require("../lib/common");
var screenshot = require("../lib/screenshot");

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testStartTBB = function() {
    common.load_page(controller, 'http://check.torproject.org');
    screenshot.create(controller, []);
}
