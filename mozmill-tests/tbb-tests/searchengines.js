// This test checks whether the top three search engines are in the right order
// in the upper right search box. This has been an issue as search engine names
// got translated, too, leading to the browser not recognizing them anymore.
// This in turn led to wrong default search engines (see bug 11236 for details).
// We are not testing whether some prefs are set properly as this can be the
// case while the search engines are still not properly ordered. Rather, we
// check the entries in the search box directly.

"use strict";

var {expect} = require("../mozilla-mozmill-tests/lib/assertions");
var common = require("../lib/common");

var setupModule = function(aModule) {
  aModule.controller = mozmill.getBrowserController();
}

var testSearchEngines = function () {
  let searchbar = controller.window.document.getElementById("searchbar");
  // Do we have Startpage as default search engine?
  let searchbarTextbox = controller.window.document.
    getAnonymousElementByAttribute(searchbar, "anonid", "searchbar-textbox");
  expect.match(searchbarTextbox.label, /Search/,
          "Search is not the default search engine!");

  // XXX: Test whether the second and third engine are the ones we want as well.
}
