"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var testsuite = require("../lib/testsuite");

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testPage = function() {
    var test_data_url = testsuite.test.remote ? testsuite.options.test_data_url
                                : ("file://" + testsuite.options.test_data_dir);
    var test_page_url = test_data_url + "/" + testsuite.test.name + ".html";
    var timeout = testsuite.test.timeout ? testsuite.test.timeout : 50000;
    var interval = testsuite.test.interval ? testsuite.test.interval : 100;
    controller.open(test_page_url);
    controller.waitForPageLoad();
    var result = new elementslib.ID(controller.window.document, "test_result");
    result.waitForElement(timeout, interval);
    var result_text = result.getNode().innerHTML;
    expect.equal(result_text, "OK", result_text);
}
