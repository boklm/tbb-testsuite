// https://trac.torproject.org/projects/tor/ticket/13053

"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var testsuite = require("../lib/testsuite");

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testNoscript = function () {
    var http_url = testsuite.options.test_data_url + '/noscript/';
    var https_url = testsuite.options.test_data_url_https + '/noscript/';

    // http page sourcing http js
    controller.open(http_url + 'http_src.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var f = new elementslib.ID(controller.window.document, "test_result");
    expect.equal(null, f.getNode(), 'http src in http page');

    // https page sourcing http js
    controller.open(https_url + 'http_src.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var f = new elementslib.ID(controller.window.document, "test_result");
    expect.equal(null, f.getNode(), 'http src in https page');

    // http page sourcing https js
    controller.open(http_url + 'https_src.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var f = new elementslib.ID(controller.window.document, "test_result");
    expect.equal(null, f.getNode(), 'https src in http page');

    // https page sourcing https js
    controller.open(https_url + 'https_src.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var f = new elementslib.ID(controller.window.document, "test_result");
    if (f.getNode() == null)
        expect.fail('https src in https page');
    else
        expect.equal('JavaScriptEnabled', f.getNode().innerHTML, 'https src in https page');

    // http page with http iframe
    controller.open(http_url + 'http_iframe.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var frame = new elementslib.Selector(controller.window.document, "#iframe");
    var frameWindow = frame.getNode().contentWindow;
    var f = frameWindow.document.getElementById("test_result");
    expect.equal(null, f, 'http iframe in http page');

    // http page with https iframe
    controller.open(http_url + 'https_iframe.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var frame = new elementslib.Selector(controller.window.document, "#iframe");
    var frameWindow = frame.getNode().contentWindow;
    var f = frameWindow.document.getElementById("test_result");
    expect.equal(null, f, 'https iframe in http page');

    // https page with http iframe
    controller.open(https_url + 'http_iframe.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var frame = new elementslib.Selector(controller.window.document, "#iframe");
    var frameWindow = frame.getNode().contentWindow;
    var f = frameWindow.document.getElementById("test_result");
    expect.equal(null, f, 'http iframe in https page');

    // https page with https iframe
    controller.open(https_url + 'https_iframe.html');
    controller.waitForPageLoad();
    controller.sleep(1000);
    var frame = new elementslib.Selector(controller.window.document, "#iframe");
    var frameWindow = frame.getNode().contentWindow;
    var f = frameWindow.document.getElementById("test_result");
    if (f == null)
        expect.fail('https iframe in https page');
    else
        expect.equal('JavaScriptEnabled', f.innerHTML, 'https iframe in https page');
}
