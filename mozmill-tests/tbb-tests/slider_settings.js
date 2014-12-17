"use strict";

Cu.import("resource://gre/modules/Services.jsm");

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var prefs = require("../mozilla-mozmill-tests/firefox/lib/prefs");
var testsuite = require("../lib/testsuite");


// The torbutton_sec_* variables have been copy pasted from
// torbutton/src/chrome/content/torbutton.js
// The noscript.globalHttpsWhitelist setting has been removed as it is
// special (a special value is set in level 4)
var torbutton_sec_l_bool_prefs = {
  "gfx.font_rendering.opentype_svg.enabled" : false,
};

var torbutton_sec_ml_bool_prefs = {
  "javascript.options.ion.content" : false,
  "javascript.options.typeinference" : false,
  "javascript.options.asmjs" : false,
  "noscript.forbidMedia" : true,
  "media.webaudio.enabled" : false,
  // XXX: pref for disabling MathML is missing
};

var torbutton_sec_mh_bool_prefs = {
  "javascript.options.baselinejit.content" : false,
  // XXX: pref for disableing SVG is missing
};

var torbutton_sec_h_bool_prefs = {
  "noscript.forbidFonts" : true,
  "noscript.global" : false,
  "media.ogg.enabled" : false,
  "media.opus.enabled" :  false,
  "media.wave.enabled" : false,
  "media.apple.mp3.enabled" : false
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
    for (var p in torbutton_sec_l_bool_prefs) {
        var value = prefSrv.getPref(p, !torbutton_sec_l_bool_prefs[p]);
        expect.equal(torbutton_sec_l_bool_prefs[p], value, p);
    }
    for (var p in torbutton_sec_ml_bool_prefs) {
        var value = prefSrv.getPref(p, !torbutton_sec_ml_bool_prefs[p]);
        var b = torbutton_sec_ml_bool_prefs[p];
        expect.equal(slider_mode < 2 ? !b : b, value, p);
    }
    for (var p in torbutton_sec_mh_bool_prefs) {
        var value = prefSrv.getPref(p, !torbutton_sec_mh_bool_prefs[p]);
        var b = torbutton_sec_mh_bool_prefs[p];
        expect.equal(slider_mode < 3 ? !b : b, value, p);
    }
    for (var p in torbutton_sec_h_bool_prefs) {
        var value = prefSrv.getPref(p, !torbutton_sec_h_bool_prefs[p]);
        var b = torbutton_sec_h_bool_prefs[p];
        expect.equal(slider_mode < 4 ? !b : b, value, p);
    }
}
