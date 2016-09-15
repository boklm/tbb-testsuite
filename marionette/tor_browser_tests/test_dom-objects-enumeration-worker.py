from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        self.expectedObjects = [
                "Array",
                "ArrayBuffer",
                "Blob",
                "Boolean",
                "BroadcastChannel",
                "Cache",
                "CacheStorage",
                "DOMCursor",
                "DOMError",
                "DOMException",
                "DOMRequest",
                "DOMStringList",
                "DataView",
                "Date",
                "DedicatedWorkerGlobalScope",
                "Error",
                "EvalError",
                "Event",
                "EventTarget",
                "File",
                "FileReaderSync",
                "Float32Array",
                "Float64Array",
                "FormData",
                "Function",
                "Headers",
                "IDBCursor",
                "IDBCursorWithValue",
                "IDBDatabase",
                "IDBFactory",
                "IDBIndex",
                "IDBKeyRange",
                "IDBObjectStore",
                "IDBOpenDBRequest",
                "IDBRequest",
                "IDBTransaction",
                "IDBVersionChangeEvent",
                "ImageBitmap",
                "ImageData",
                "Infinity",
                "Int16Array",
                "Int32Array",
                "Int8Array",
                "InternalError",
                "Intl",
                "Iterator",
                "JSON",
                "Map",
                "Math",
                "MessageChannel",
                "MessageEvent",
                "MessagePort",
                "NaN",
                "Notification",
                "Number",
                "Object",
                "Performance",
                "PerformanceEntry",
                "PerformanceMark",
                "PerformanceMeasure",
                "Promise",
                "Proxy",
                "RangeError",
                "ReferenceError",
                "Reflect",
                "RegExp",
                "Request",
                "Response",
                "Set",
                "StopIteration",
                "String",
                "Symbol",
                "SyntaxError",
                "TextDecoder",
                "TextEncoder",
                "TypeError",
                "URIError",
                "URL",
                "URLSearchParams",
                "Uint16Array",
                "Uint32Array",
                "Uint8Array",
                "Uint8ClampedArray",
                "WeakMap",
                "WeakSet",
                "WebSocket",
                "Worker",
                "WorkerGlobalScope",
                "WorkerLocation",
                "WorkerNavigator",
                "XMLHttpRequest",
                "XMLHttpRequestEventTarget",
                "XMLHttpRequestUpload",
                "__defineGetter__",
                "__defineSetter__",
                "__lookupGetter__",
                "__lookupSetter__",
                "__proto__",
                "addEventListener",
                "atob",
                "btoa",
                "caches",
                "clearInterval",
                "clearTimeout",
                "close",
                "console",
                "constructor",
                "createImageBitmap",
                "decodeURI",
                "decodeURIComponent",
                "dispatchEvent",
                "dump",
                "encodeURI",
                "encodeURIComponent",
                "escape",
                "eval",
                "fetch",
                "getAllPropertyNames",
                "hasOwnProperty",
                "importScripts",
                "indexedDB",
                "isFinite",
                "isNaN",
                "isPrototypeOf",
                "location",
                "navigator",
                "onclose",
                "onerror",
                "onmessage",
                "onoffline",
                "ononline",
                "parseFloat",
                "parseInt",
                "performance",
                "postMessage",
                "propertyIsEnumerable",
                "removeEventListener",
                "self",
                "setInterval",
                "setTimeout",
                "toLocaleString",
                "toSource",
                "toString",
                "undefined",
                "unescape",
                "uneval",
                "unwatch",
                "valueOf",
                "watch",
                ]

    def test_dom_objects_enumeration_workers(self):
        with self.marionette.using_context('content'):
            URL = "file://%s/workers/dom-objects-enumeration.html" % self.ts.t['options']['test_data_dir']
            self.marionette.navigate(URL)
            self.marionette.set_search_timeout(50000)
            elt = self.marionette.find_element('id', 'enumeration')

            err = False
            unknown_objects = ''
            for l in elt.text.split("\n"):
                if l in self.expectedObjects:
                    continue
                err = True
                unknown_objects += l + "\n"

            err_msg = "Unknown objects:\n%s" % unknown_objects
            self.assertFalse(err, msg=err_msg)