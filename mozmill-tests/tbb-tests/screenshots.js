"use strict";

var common = require("../lib/common");
var screenshot = require("../lib/screenshot");

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testStartTBB = function() {
    common.load_page(controller, 'http://check.torproject.org');
    screenshot.create(controller, []);
    const URLs = [
        'chrome://browser/content/preferences/preferences.xul',
        'chrome://torbutton/content/preferences.xul',
        'chrome://torlauncher/content/network-settings-wizard.xul',
        ];
    for (var i=0; i < URLs.length; i++) {
        controller.open(URLs[i]);
        controller.waitForPageLoad();
        screenshot.create(controller.browserObject.selectedBrowser.contentWindow, []);
    }
}
