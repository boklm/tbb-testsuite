# This test enumerates all DOM objects exposed in the global namespace
# and produce an error if one of them is not in the expected list.
#
# This test has been suggested in the iSEC partners' report:
# https://blog.torproject.org/blog/isec-partners-conducts-tor-browser-hardening-study

import testsuite

class Test(testsuite.TorBrowserTest):
    def setUp(self):
        testsuite.TorBrowserTest.setUp(self)
        self.marionette.set_pref("network.proxy.allow_hijacking_localhost", False)
        self.test_page_file_url = self.marionette.absolute_url("dom-objects-enumeration.html?testType=window")
        # The list of expected DOM objects
        self.expectedObjects = {
                "AbortController",
                "AbortSignal",
                "AbstractRange",
                "addEventListener",
                "alert",
                "Animation",
                "AnimationEffect",
                "AnimationEvent",
                "AnimationPlaybackEvent",
                "AnimationTimeline",
                "Array",
                "ArrayBuffer",
                "atob",
                "Atomics",
                "Attr",
                "Audio",
                "AudioParamMap",
                "AudioScheduledSourceNode",
                "AudioWorklet",
                "AudioWorkletNode",
                "BarProp",
                "BaseAudioContext",
                "BeforeUnloadEvent",
                "BigInt",
                "BigInt64Array",
                "BigUint64Array",
                "Blob",
                "BlobEvent",
                "blur",
                "Boolean",
                "BroadcastChannel",
                "btoa",
                "ByteLengthQueuingStrategy",
                "Cache",
                "caches",
                "CacheStorage",
                "cancelAnimationFrame",
                "cancelIdleCallback",
                "CanvasCaptureMediaStream",
                "CanvasGradient",
                "CanvasPattern",
                "CanvasRenderingContext2D",
                "captureEvents",
                "CaretPosition",
                "CDATASection",
                "CharacterData",
                "clearInterval",
                "clearTimeout",
                "Clipboard",
                "ClipboardEvent",
                "close",
                "closed",
                "CloseEvent",
                "Comment",
                "CompositionEvent",
                "confirm",
                "console",
                "constructor",
                "content",
                "CountQueuingStrategy",
                "createImageBitmap",
                "crossOriginIsolated",
                "crypto",
                "Crypto",
                "CryptoKey",
                "CSS",
                "CSS2Properties",
                "CSSAnimation",
                "CSSConditionRule",
                "CSSCounterStyleRule",
                "CSSFontFaceRule",
                "CSSFontFeatureValuesRule",
                "CSSGroupingRule",
                "CSSImportRule",
                "CSSKeyframeRule",
                "CSSKeyframesRule",
                "CSSMediaRule",
                "CSSMozDocumentRule",
                "CSSNamespaceRule",
                "CSSPageRule",
                "CSSRule",
                "CSSRuleList",
                "CSSStyleDeclaration",
                "CSSStyleRule",
                "CSSStyleSheet",
                "CSSSupportsRule",
                "CSSTransition",
                "CustomElementRegistry",
                "customElements",
                "CustomEvent",
                "DataTransfer",
                "DataTransferItem",
                "DataTransferItemList",
                "DataView",
                "Date",
                "decodeURI",
                "decodeURIComponent",
                "__defineGetter__",
                "__defineSetter__",
                "DeviceMotionEvent",
                "DeviceOrientationEvent",
                "devicePixelRatio",
                "Directory",
                "dispatchEvent",
                "document",
                "Document",
                "DocumentFragment",
                "DocumentTimeline",
                "DocumentType",
                "DOMException",
                "DOMImplementation",
                "DOMMatrix",
                "DOMMatrixReadOnly",
                "DOMParser",
                "DOMPoint",
                "DOMPointReadOnly",
                "DOMQuad",
                "DOMRect",
                "DOMRectList",
                "DOMRectReadOnly",
                "DOMRequest",
                "DOMStringList",
                "DOMStringMap",
                "DOMTokenList",
                "DragEvent",
                "dump",
                "Element",
                "encodeURI",
                "encodeURIComponent",
                "Error",
                "ErrorEvent",
                "escape",
                "eval",
                "EvalError",
                "event",
                "Event",
                "EventSource",
                "EventTarget",
                "external",
                "fetch",
                "File",
                "FileList",
                "FileReader",
                "FileSystem",
                "FileSystemDirectoryEntry",
                "FileSystemDirectoryReader",
                "FileSystemEntry",
                "FileSystemFileEntry",
                "find",
                "Float32Array",
                "Float64Array",
                "focus",
                "FocusEvent",
                "FontFace",
                "FontFaceSet",
                "FontFaceSetLoadEvent",
                "FormData",
                "FormDataEvent",
                "frameElement",
                "frames",
                "fullScreen",
                "Function",
                "Gamepad",
                "GamepadButton",
                "GamepadEvent",
                "GamepadHapticActuator",
                "GamepadPose",
                "Geolocation",
                "GeolocationCoordinates",
                "GeolocationPosition",
                "GeolocationPositionError",
                "getComputedStyle",
                "getDefaultComputedStyle",
                "getSelection",
                "globalThis",
                "HashChangeEvent",
                "hasOwnProperty",
                "Headers",
                "history",
                "History",
                "HTMLAllCollection",
                "HTMLAnchorElement",
                "HTMLAreaElement",
                "HTMLAudioElement",
                "HTMLBaseElement",
                "HTMLBodyElement",
                "HTMLBRElement",
                "HTMLButtonElement",
                "HTMLCanvasElement",
                "HTMLCollection",
                "HTMLDataElement",
                "HTMLDataListElement",
                "HTMLDetailsElement",
                "HTMLDirectoryElement",
                "HTMLDivElement",
                "HTMLDListElement",
                "HTMLDocument",
                "HTMLElement",
                "HTMLEmbedElement",
                "HTMLFieldSetElement",
                "HTMLFontElement",
                "HTMLFormControlsCollection",
                "HTMLFormElement",
                "HTMLFrameElement",
                "HTMLFrameSetElement",
                "HTMLHeadElement",
                "HTMLHeadingElement",
                "HTMLHRElement",
                "HTMLHtmlElement",
                "HTMLIFrameElement",
                "HTMLImageElement",
                "HTMLInputElement",
                "HTMLLabelElement",
                "HTMLLegendElement",
                "HTMLLIElement",
                "HTMLLinkElement",
                "HTMLMapElement",
                "HTMLMarqueeElement",
                "HTMLMediaElement",
                "HTMLMenuElement",
                "HTMLMenuItemElement",
                "HTMLMetaElement",
                "HTMLMeterElement",
                "HTMLModElement",
                "HTMLObjectElement",
                "HTMLOListElement",
                "HTMLOptGroupElement",
                "HTMLOptionElement",
                "HTMLOptionsCollection",
                "HTMLOutputElement",
                "HTMLParagraphElement",
                "HTMLParamElement",
                "HTMLPictureElement",
                "HTMLPreElement",
                "HTMLProgressElement",
                "HTMLQuoteElement",
                "HTMLScriptElement",
                "HTMLSelectElement",
                "HTMLSlotElement",
                "HTMLSourceElement",
                "HTMLSpanElement",
                "HTMLStyleElement",
                "HTMLTableCaptionElement",
                "HTMLTableCellElement",
                "HTMLTableColElement",
                "HTMLTableElement",
                "HTMLTableRowElement",
                "HTMLTableSectionElement",
                "HTMLTemplateElement",
                "HTMLTextAreaElement",
                "HTMLTimeElement",
                "HTMLTitleElement",
                "HTMLTrackElement",
                "HTMLUListElement",
                "HTMLUnknownElement",
                "HTMLVideoElement",
                "IDBCursor",
                "IDBCursorWithValue",
                "IDBDatabase",
                "IDBFactory",
                "IDBFileHandle",
                "IDBFileRequest",
                "IDBIndex",
                "IDBKeyRange",
                "IDBMutableFile",
                "IDBObjectStore",
                "IDBOpenDBRequest",
                "IDBRequest",
                "IDBTransaction",
                "IDBVersionChangeEvent",
                "IdleDeadline",
                "Image",
                "ImageBitmap",
                "ImageBitmapRenderingContext",
                "ImageData",
                "indexedDB",
                "Infinity",
                "innerHeight",
                "innerWidth",
                "InputEvent",
                "InstallTrigger",
                "Int16Array",
                "Int32Array",
                "Int8Array",
                "InternalError",
                "IntersectionObserver",
                "IntersectionObserverEntry",
                "Intl",
                "isFinite",
                "isNaN",
                "isPrototypeOf",
                "isSecureContext",
                "JSON",
                "KeyboardEvent",
                "KeyEvent",
                "KeyframeEffect",
                "length",
                "localStorage",
                "location",
                "Location",
                "locationbar",
                "__lookupGetter__",
                "__lookupSetter__",
                "Map",
                "matchMedia",
                "Math",
                "MathMLElement",
                "MediaCapabilities",
                "MediaCapabilitiesInfo",
                "MediaEncryptedEvent",
                "MediaError",
                "MediaKeyError",
                "MediaKeyMessageEvent",
                "MediaKeys",
                "MediaKeySession",
                "MediaKeyStatusMap",
                "MediaKeySystemAccess",
                "MediaList",
                "MediaQueryList",
                "MediaQueryListEvent",
                "MediaRecorder",
                "MediaRecorderErrorEvent",
                "MediaSource",
                "MediaStream",
                "MediaStreamTrack",
                "MediaStreamTrackEvent",
                "menubar",
                "MessageChannel",
                "MessageEvent",
                "MessagePort",
                "MimeType",
                "MimeTypeArray",
                "MouseEvent",
                "MouseScrollEvent",
                "moveBy",
                "moveTo",
                "mozInnerScreenX",
                "mozInnerScreenY",
                "MutationEvent",
                "MutationObserver",
                "MutationRecord",
                "name",
                "NamedNodeMap",
                "NaN",
                "navigator",
                "Navigator",
                "netscape",
                "Node",
                "NodeFilter",
                "NodeIterator",
                "NodeList",
                "Notification",
                "NotifyPaintEvent",
                "Number",
                "Object",
                "onabort",
                "onabsolutedeviceorientation",
                "onafterprint",
                "onanimationcancel",
                "onanimationend",
                "onanimationiteration",
                "onanimationstart",
                "onauxclick",
                "onbeforeprint",
                "onbeforeunload",
                "onblur",
                "oncanplay",
                "oncanplaythrough",
                "onchange",
                "onclick",
                "onclose",
                "oncontextmenu",
                "oncuechange",
                "ondblclick",
                "ondevicelight",
                "ondevicemotion",
                "ondeviceorientation",
                "ondeviceproximity",
                "ondrag",
                "ondragend",
                "ondragenter",
                "ondragexit",
                "ondragleave",
                "ondragover",
                "ondragstart",
                "ondrop",
                "ondurationchange",
                "onemptied",
                "onended",
                "onerror",
                "onfocus",
                "onformdata",
                "onhashchange",
                "oninput",
                "oninvalid",
                "onkeydown",
                "onkeypress",
                "onkeyup",
                "onlanguagechange",
                "onload",
                "onloadeddata",
                "onloadedmetadata",
                "onloadend",
                "onloadstart",
                "onmessage",
                "onmessageerror",
                "onmousedown",
                "onmouseenter",
                "onmouseleave",
                "onmousemove",
                "onmouseout",
                "onmouseover",
                "onmouseup",
                "onmozfullscreenchange",
                "onmozfullscreenerror",
                "onoffline",
                "ononline",
                "onpagehide",
                "onpageshow",
                "onpause",
                "onplay",
                "onplaying",
                "onpopstate",
                "onprogress",
                "onratechange",
                "onrejectionhandled",
                "onreset",
                "onresize",
                "onscroll",
                "onseeked",
                "onseeking",
                "onselect",
                "onselectstart",
                "onshow",
                "onstalled",
                "onstorage",
                "onsubmit",
                "onsuspend",
                "ontimeupdate",
                "ontoggle",
                "ontransitioncancel",
                "ontransitionend",
                "ontransitionrun",
                "ontransitionstart",
                "onunhandledrejection",
                "onunload",
                "onuserproximity",
                "onvolumechange",
                "onwaiting",
                "onwebkitanimationend",
                "onwebkitanimationiteration",
                "onwebkitanimationstart",
                "onwebkittransitionend",
                "onwheel",
                "open",
                "opener",
                "Option",
                "origin",
                "outerHeight",
                "outerWidth",
                "PageTransitionEvent",
                "pageXOffset",
                "pageYOffset",
                "PaintRequest",
                "PaintRequestList",
                "parent",
                "parseFloat",
                "parseInt",
                "Path2D",
                "performance",
                "Performance",
                "PerformanceEntry",
                "PerformanceMark",
                "PerformanceMeasure",
                "PerformanceNavigation",
                "PerformanceObserver",
                "PerformanceObserverEntryList",
                "PerformanceResourceTiming",
                "PerformanceServerTiming",
                "PerformanceTiming",
                "Permissions",
                "PermissionStatus",
                "personalbar",
                "Plugin",
                "PluginArray",
                "PopStateEvent",
                "PopupBlockedEvent",
                "postMessage",
                "print",
                "ProcessingInstruction",
                "ProgressEvent",
                "Promise",
                "PromiseRejectionEvent",
                "prompt",
                "propertyIsEnumerable",
                "__proto__",
                "Proxy",
                "queueMicrotask",
                "RadioNodeList",
                "Range",
                "RangeError",
                "ReadableStream",
                "ReferenceError",
                "Reflect",
                "RegExp",
                "releaseEvents",
                "removeEventListener",
                "Request",
                "requestAnimationFrame",
                "requestIdleCallback",
                "resizeBy",
                "ResizeObserver",
                "ResizeObserverEntry",
                "ResizeObserverSize",
                "resizeTo",
                "Response",
                "screen",
                "Screen",
                "screenLeft",
                "ScreenOrientation",
                "screenTop",
                "screenX",
                "screenY",
                "scroll",
                "ScrollAreaEvent",
                "scrollbars",
                "scrollBy",
                "scrollByLines",
                "scrollByPages",
                "scrollMaxX",
                "scrollMaxY",
                "scrollTo",
                "scrollX",
                "scrollY",
                "SecurityPolicyViolationEvent",
                "Selection",
                "self",
                "sessionStorage",
                "Set",
                "setInterval",
                "setResizable",
                "setTimeout",
                "ShadowRoot",
                "SharedWorker",
                "sidebar",
                "sizeToContent",
                "SourceBuffer",
                "SourceBufferList",
                "speechSynthesis",
                "SpeechSynthesis",
                "SpeechSynthesisErrorEvent",
                "SpeechSynthesisEvent",
                "SpeechSynthesisUtterance",
                "SpeechSynthesisVoice",
                "StaticRange",
                "status",
                "statusbar",
                "stop",
                "Storage",
                "StorageEvent",
                "StorageManager",
                "String",
                "StyleSheet",
                "StyleSheetList",
                "SubmitEvent",
                "SubtleCrypto",
                "SVGAElement",
                "SVGAngle",
                "SVGAnimatedAngle",
                "SVGAnimatedBoolean",
                "SVGAnimatedEnumeration",
                "SVGAnimatedInteger",
                "SVGAnimatedLength",
                "SVGAnimatedLengthList",
                "SVGAnimatedNumber",
                "SVGAnimatedNumberList",
                "SVGAnimatedPreserveAspectRatio",
                "SVGAnimatedRect",
                "SVGAnimatedString",
                "SVGAnimatedTransformList",
                "SVGAnimateElement",
                "SVGAnimateMotionElement",
                "SVGAnimateTransformElement",
                "SVGAnimationElement",
                "SVGCircleElement",
                "SVGClipPathElement",
                "SVGComponentTransferFunctionElement",
                "SVGDefsElement",
                "SVGDescElement",
                "SVGElement",
                "SVGEllipseElement",
                "SVGFEBlendElement",
                "SVGFEColorMatrixElement",
                "SVGFEComponentTransferElement",
                "SVGFECompositeElement",
                "SVGFEConvolveMatrixElement",
                "SVGFEDiffuseLightingElement",
                "SVGFEDisplacementMapElement",
                "SVGFEDistantLightElement",
                "SVGFEDropShadowElement",
                "SVGFEFloodElement",
                "SVGFEFuncAElement",
                "SVGFEFuncBElement",
                "SVGFEFuncGElement",
                "SVGFEFuncRElement",
                "SVGFEGaussianBlurElement",
                "SVGFEImageElement",
                "SVGFEMergeElement",
                "SVGFEMergeNodeElement",
                "SVGFEMorphologyElement",
                "SVGFEOffsetElement",
                "SVGFEPointLightElement",
                "SVGFESpecularLightingElement",
                "SVGFESpotLightElement",
                "SVGFETileElement",
                "SVGFETurbulenceElement",
                "SVGFilterElement",
                "SVGForeignObjectElement",
                "SVGGElement",
                "SVGGeometryElement",
                "SVGGradientElement",
                "SVGGraphicsElement",
                "SVGImageElement",
                "SVGLength",
                "SVGLengthList",
                "SVGLinearGradientElement",
                "SVGLineElement",
                "SVGMarkerElement",
                "SVGMaskElement",
                "SVGMatrix",
                "SVGMetadataElement",
                "SVGMPathElement",
                "SVGNumber",
                "SVGNumberList",
                "SVGPathElement",
                "SVGPathSegList",
                "SVGPatternElement",
                "SVGPoint",
                "SVGPointList",
                "SVGPolygonElement",
                "SVGPolylineElement",
                "SVGPreserveAspectRatio",
                "SVGRadialGradientElement",
                "SVGRect",
                "SVGRectElement",
                "SVGScriptElement",
                "SVGSetElement",
                "SVGStopElement",
                "SVGStringList",
                "SVGStyleElement",
                "SVGSVGElement",
                "SVGSwitchElement",
                "SVGSymbolElement",
                "SVGTextContentElement",
                "SVGTextElement",
                "SVGTextPathElement",
                "SVGTextPositioningElement",
                "SVGTitleElement",
                "SVGTransform",
                "SVGTransformList",
                "SVGTSpanElement",
                "SVGUnitTypes",
                "SVGUseElement",
                "SVGViewElement",
                "Symbol",
                "SyntaxError",
                "Text",
                "TextDecoder",
                "TextEncoder",
                "TextMetrics",
                "TextTrack",
                "TextTrackCue",
                "TextTrackCueList",
                "TextTrackList",
                "TimeEvent",
                "TimeRanges",
                "toLocaleString",
                "toolbar",
                "top",
                "toString",
                "TrackEvent",
                "TransitionEvent",
                "TreeWalker",
                "TypeError",
                "u2f",
                "U2F",
                "UIEvent",
                "Uint16Array",
                "Uint32Array",
                "Uint8Array",
                "Uint8ClampedArray",
                "undefined",
                "unescape",
                "updateCommands",
                "URIError",
                "URL",
                "URLSearchParams",
                "ValidityState",
                "valueOf",
                "VideoPlaybackQuality",
                "VisualViewport",
                "VTTCue",
                "VTTRegion",
                "WeakMap",
                "WeakSet",
                "WebAssembly",
                "WebGLActiveInfo",
                "WebGLBuffer",
                "WebGLContextEvent",
                "WebGLFramebuffer",
                "WebGLProgram",
                "WebGLQuery",
                "WebGLRenderbuffer",
                "WebGLRenderingContext",
                "WebGLShader",
                "WebGLShaderPrecisionFormat",
                "WebGLTexture",
                "WebGLUniformLocation",
                "WebGLVertexArrayObject",
                "WebKitCSSMatrix",
                "webkitURL",
                "WebSocket",
                "WheelEvent",
                "window",
                "Window",
                "Worker",
                "Worklet",
                "XMLDocument",
                "XMLHttpRequest",
                "XMLHttpRequestEventTarget",
                "XMLHttpRequestUpload",
                "XMLSerializer",
                "XPathEvaluator",
                "XPathExpression",
                "XPathResult",
                "XSLTProcessor",
        }

    def test_dom_objects_enumeration(self):
        expectedObjects = self.expectedObjects
        if self.get_version() >= 77 and self.is_early_beta_or_earlier():
            # https://bugzilla.mozilla.org/show_bug.cgi?id=1632143
            expectedObjects.remove("content")
        if self.get_version() >= 80:
            expectedObjects = expectedObjects.union({"AggregateError", "FinalizationRegistry", "WeakRef"})
        if self.get_version() >= 82:
            expectedObjects = expectedObjects.union({"MediaMetadata","MediaSession","Sanitizer"})
        if self.get_version() >= 83 and self.is_early_beta_or_earlier():
            expectedObjects = expectedObjects.union({"onbeforeinput"})
        if self.get_version() >= 84:
            expectedObjects = expectedObjects.union({"PerformancePaintTiming"}).difference({"Sanitizer"})
        if self.get_version() >= 85:
            expectedObjects = expectedObjects.difference({"onshow", "HTMLMenuItemElement"})

        with self.marionette.using_context('content'):
            self.marionette.navigate(self.test_page_file_url)
            self.marionette.timeout.implicit = 5
            elt = self.marionette.find_element('id', 'enumeration')
            r = elt.text.split("\n")
            err = False
            unknown_objects = ''
            for l in r:
                if l in expectedObjects:
                    continue
                err = True
                unknown_objects += l + "\n"

            err_msg = "Unknown objects:\n%s" % unknown_objects
            self.assertFalse(err, msg=err_msg)

            for l in expectedObjects:
                if l in r:
                    continue
                err = True
                unknown_objects += l + "\n"

            err_msg = "Expected objects not found:\n%s" % unknown_objects
            self.assertFalse(err, msg=err_msg)

