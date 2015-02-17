"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var screenshot = require("../lib/screenshot");

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testAcid3 = function() {
    var acid_page = 'http://acid3.acidtests.org/';
    controller.open(acid_page);
    controller.waitForPageLoad();
    controller.sleep(4000);
    var result = new elementslib.ID(controller.window.document, "score");
    result.waitForElement(5000, 100);

    controller.waitFor(
            function() {
                var result = new elementslib.ID(controller.window.document, "score");
                var result_text = result.getNode().innerHTML;
                return result_text == "100";
            },
            "acid3 100", 50000, 100);
    screenshot.create(controller, []);
}
