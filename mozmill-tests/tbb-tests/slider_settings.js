"use strict";

Cu.import("resource://gre/modules/Services.jsm");

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var prefs = require("../mozilla-mozmill-tests/firefox/lib/prefs");
var testsuite = require("../lib/testsuite");


// The torbutton_sec_* variables have been copy pasted from
// torbutton/src/chrome/content/torbutton.js

var torbutton_sec_ml_bool_prefs = {
  "javascript.options.ion.content" : false,
  "javascript.options.typeinference" : false,
  "javascript.options.asmjs" : false,
  "noscript.forbidMedia" : true,
  "media.webaudio.enabled" : false,
  "network.jar.block-remote-files" : true,
  "mathml.disabled" : true
};

var torbutton_sec_mh_bool_prefs = {
  "javascript.options.baselinejit.content" : false,
  "gfx.font_rendering.opentype_svg.enabled" : false,
  "noscript.global" : false,
  "noscript.globalHttpsWhitelist" : true
};

var torbutton_sec_h_bool_prefs = {
  "noscript.forbidFonts" : true,
  "noscript.global" : false,
  "svg.in-content.enabled" : false
};

////////////////////////////////////

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testTBBSettingsSlider = function() {
    var prefSrv = prefs.preferences;
    var slider_mode = prefSrv.getPref('extensions.torbutton.security_slider', 1);
    expect.equal(parseInt(testsuite.test.slider_mode), slider_mode, 'slider mode');
    expect.equal(prefSrv.getPref('extensions.torbutton.security_custom', true), false, 'security_custom');

    var expected_prefs = {};
    switch (slider_mode) {
        case 1:
            for (p in torbutton_sec_ml_bool_prefs) {
                expected_prefs[p] = torbutton_sec_ml_bool_prefs[p];
            }
            for (p in torbutton_sec_mh_bool_prefs) {
                expected_prefs[p] = torbutton_sec_mh_bool_prefs[p];
                // noscript.globalHttpsWhitelist is special: We don't want it in this
                // mode.
                if (p === "noscript.globalHttpsWhitelist") {
                    expected_prefs[p] = !torbutton_sec_mh_bool_prefs[p];
                }
            }
            for (p in torbutton_sec_h_bool_prefs) {
                expected_prefs[p] = torbutton_sec_h_bool_prefs[p];
            }
            break;
        case 2:
            for (p in torbutton_sec_ml_bool_prefs) {
                expected_prefs[p] = torbutton_sec_ml_bool_prefs[p];
            }
            // Order matters here as both the high mode and the medium-high mode
            // share some preferences/values. So, let's revert the high mode
            // preferences first and set the medium-high mode ones afterwards.
            for (p in torbutton_sec_h_bool_prefs) {
                expected_prefs[p] = !torbutton_sec_h_bool_prefs[p];
            }
            for (p in torbutton_sec_mh_bool_prefs) {
                expected_prefs[p] = torbutton_sec_mh_bool_prefs[p];
            }
            break;
        case 3:
            for (p in torbutton_sec_ml_bool_prefs) {
                expected_prefs[p] = torbutton_sec_ml_bool_prefs[p];
            }
            for (p in torbutton_sec_mh_bool_prefs) {
                expected_prefs[p] = !torbutton_sec_mh_bool_prefs[p];
            }
            for (p in torbutton_sec_h_bool_prefs) {
                expected_prefs[p] = !torbutton_sec_h_bool_prefs[p];
            }
            break;
        case 4:
            for (p in torbutton_sec_ml_bool_prefs) {
                expected_prefs[p] = !torbutton_sec_ml_bool_prefs[p];
            }
            for (p in torbutton_sec_mh_bool_prefs) {
                expected_prefs[p] = !torbutton_sec_mh_bool_prefs[p];
            }
            for (p in torbutton_sec_h_bool_prefs) {
                expected_prefs[p] = !torbutton_sec_h_bool_prefs[p];
            }
            break;
    }

    for (var p in expected_prefs) {
        var value = prefSrv.getPref(p, !expected_prefs[p]);
        expect.equal(expected_prefs[p], value, p);
    }
}
