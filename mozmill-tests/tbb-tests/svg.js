"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var prefs = require("../mozilla-mozmill-tests/firefox/lib/prefs");
var common = require("../lib/common");
var testsuite = require("../lib/testsuite");


var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testStartTBB = function() {
    var svgdir = testsuite.options.test_data_dir + "/svg/";
    var svg_enabled = Boolean(testsuite.test.svg_enabled);
    var prefSrv = prefs.preferences;
    expect.equal(prefSrv.getPref("svg.in-content.enabled", false), svg_enabled,
            "svg.in-content.enabled pref");

    common.load_page(controller, svgdir + 'img_src_url.html');
    var svg_elem = elementslib.ID(controller.window.document, "svgImgElem");
    expect.equal(svg_elem.getNode().width, svg_enabled ? 450 : 24, "img src url");

    common.load_page(controller, svgdir + 'img_data_url.html');
    var svg_elem = elementslib.ID(controller.window.document, "svgImgElem");
    expect.equal(svg_elem.getNode().width, svg_enabled ? 300 : 24, "img data url");

    common.load_page(controller, svgdir + 'object_data_url.html');
    var svg_elem = elementslib.ID(controller.window.document, "svgObjectElem");
    if (svg_enabled)
        expect.equal(svg_elem.getNode().contentDocument.visibilityState, "visible", "object data url");
    else
        expect.equal(svg_elem.getNode().contentDocument, null, "object data url");

    common.load_page(controller, svgdir + 'object_remote_url.html');
    var svg_elem = elementslib.ID(controller.window.document, "svgObjectElem");
    if (svg_enabled)
        expect.equal(svg_elem.getNode().contentDocument.visibilityState, "visible", "object remote url");
    else
        expect.equal(svg_elem.getNode().contentDocument, null, "object remote url");

    /* FIXME: when svg not enabled, close prompt asking to save the svg file */
    if (svg_enabled) {
        common.load_page(controller, svgdir + 'iframe_remote_url.html');
        var svg_elem = elementslib.ID(controller.window.document, "svgIframeElem");
        expect.equal(svg_elem.getNode().contentDocument.visibilityState, "visible", "iframe remote url");
    }

    common.load_page(controller, svgdir + 'inline_svg.html');
    var svg_elem = elementslib.ID(controller.window.document, "inlineSVG");
    if (svg_enabled)
        expect.equal(svg_elem.getNode().nodeName, "svg", "inline svg tag");
    else
        expect.equal(svg_elem.getNode(), null, "no inline svg tag");
}
