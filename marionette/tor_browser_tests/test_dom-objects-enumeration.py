# This test enumerates all DOM objects exposed in the global namespace
# and produce an error if one of them is not in the expected list.
#
# This test has been suggested in the iSEC partners' report:
# https://blog.torproject.org/blog/isec-partners-conducts-tor-browser-hardening-study

from marionette_driver import By
from marionette_driver.errors import MarionetteException

from marionette_harness import MarionetteTestCase

import testsuite


class Test(MarionetteTestCase):

    def setUp(self):
        MarionetteTestCase.setUp(self)

        ts = testsuite.TestSuite()
        self.ts = ts

        # The list of expected DOM objects
        self.interfaceNamesInGlobalScope = [
                "AbortController",
                "AbortSignal",
                "addEventListener",
                "adjustToolbarIconArrow",
                "alert",
                "AnalyserNode",
                "Animation",
                "AnimationEffect",
                "AnimationEvent",
                "AnimationPlayer",
                "AnimationTimeline",
                "AnonymousContent",
                "Application",
                "applicationCache",
                "ArchiveRequest",
                "Array",
                "ArrayBuffer",
                "AsyncScrollEventDetail",
                "atob",
                "Attr",
                "Audio",
                "AudioBuffer",
                "AudioBufferSourceNode",
                "AudioContext",
                "AudioDestinationNode",
                "AudioListener",
                "AudioNode",
                "AudioParam",
                "AudioProcessingEvent",
                "AudioScheduledSourceNode",
                "AudioStreamTrack",
                "back",
                "BarProp",
                "BaseAudioContext",
                "BatteryManager",
                "BeforeUnloadEvent",
                "BiquadFilterNode",
                "Blob",
                "BlobEvent",
                "blur",
                "Boolean",
                "BoxObject",
                "BroadcastChannel",
                "BrowserFeedWriter",
                "btoa",
                "Cache",
                "caches",
                "CacheStorage",
                "CameraCapabilities",
                "CameraClosedEvent",
                "CameraConfigurationEvent",
                "CameraControl",
                "CameraDetectedFace",
                "CameraFacesDetectedEvent",
                "CameraManager",
                "CameraRecorderAudioProfile",
                "CameraRecorderProfile",
                "CameraRecorderProfiles",
                "CameraRecorderVideoProfile",
                "CameraStateChangeEvent",
                "cancelAnimationFrame",
                "cancelIdleCallback",
                "CanvasCaptureMediaStream",
                "CanvasGradient",
                "CanvasPattern",
                "CanvasRenderingContext2D",
                "captureEvents",
                "CaretPosition",
                "CDATASection",
                "ChannelMergerNode",
                "ChannelSplitterNode",
                "CharacterData",
                "ChromeMessageBroadcaster",
                "ChromeMessageSender",
                "ChromeWindow",
                "ChromeWorker",
                "clearInterval",
                "clearTimeout",
                "ClientInformation",
                "ClientRect",
                "ClientRectList",
                "ClipboardEvent",
                "close",
                "closed",
                "CloseEvent",
                "CommandEvent",
                "Comment",
                "Components",
                "CompositionEvent",
                "confirm",
                "console",
                "Console",
                "Contact",
                "ContactManager",
                "_content",
                "content",
                "ContentFrameMessageManager",
                "ContentProcessMessageManager",
                "controllers",
                "Controllers",
                "ConvolverNode",
                "Counter",
                "createImageBitmap",
                "CRMFObject",
                "crypto",
                "Crypto",
                "CryptoDialogs",
                "CryptoKey",
                "CSS",
                "CSS2Properties",
                "CSSCharsetRule",
                "CSSConditionRule",
                "CSSCounterStyleRule",
                "CSSFontFaceRule",
                "CSSFontFeatureValuesRule",
                "CSSGroupingRule",
                "CSSGroupRuleRuleList",
                "CSSImportRule",
                "CSSKeyframeRule",
                "CSSKeyframesRule",
                "CSSMediaRule",
                "CSSMozDocumentRule",
                "CSSNamespaceRule",
                "CSSNameSpaceRule",
                "CSSPageRule",
                "CSSPrimitiveValue",
                "CSSRect",
                "CSSRule",
                "CSSRuleList",
                "CSSStyleDeclaration",
                "CSSStyleRule",
                "CSSStyleSheet",
                "CSSSupportsRule",
                "CSSUnknownRule",
                "CSSValue",
                "CSSValueList",
                "CustomEvent",
                "DataChannel",
                "DataContainerEvent",
                "DataErrorEvent",
                "DataTransfer",
                "DataTransferItem",
                "DataTransferItemList",
                "DataView",
                "Date",
                "decodeURI",
                "decodeURIComponent",
                "DelayNode",
                "DesktopNotification",
                "DesktopNotificationCenter",
                "DeviceAcceleration",
                "DeviceLightEvent",
                "DeviceMotionEvent",
                "DeviceOrientationEvent",
                "devicePixelRatio",
                "DeviceProximityEvent",
                "DeviceRotationRate",
                "DeviceStorage",
                "DeviceStorageChangeEvent",
                "DeviceStorageCursor",
                "Directory",
                "dispatchEvent",
                "document",
                "Document",
                "DocumentFragment",
                "DocumentTouch",
                "DocumentType",
                "DocumentXBL",
                "DOMApplication",
                "DOMApplicationsManager",
                "DOMConstructor",
                "DOMCursor",
                "DOMError",
                "DOMException",
                "DOMImplementation",
                "DOMMatrix",
                "DOMMatrixReadOnly",
                "DOMMMIError",
                "DOMParser",
                "DOMPoint",
                "DOMPointReadOnly",
                "DOMQuad",
                "DOMRect",
                "DOMRectList",
                "DOMRectReadOnly",
                "DOMRequest",
                "DOMSettableTokenList",
                "DOMStringList",
                "DOMStringMap",
                "DOMTokenList",
                "DOMTransactionEvent",
                "DragEvent",
                "dump",
                "DynamicsCompressorNode",
                "Element",
                "ElementCSSInlineStyle",
                "ElementReplaceEvent",
                "ElementTimeControl",
                "encodeURI",
                "encodeURIComponent",
                "Error",
                "ErrorEvent",
                "escape",
                "eval",
                "EvalError",
                "Event",
                "EventListener",
                "EventListenerInfo",
                "EventSource",
                "EventTarget",
                "external",
                "External",
                "fetch",
                "File",
                "FileHandle",
                "FileList",
                "FileReader",
                "FileRequest",
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
                "FontFaceList",
                "FontFaceSet",
                "FontFaceSetLoadEvent",
                "FormData",
                "forward",
                "frameElement",
                "frames",
                "fullScreen",
                "Function",
                "FutureResolver",
                "GainNode",
                "Gamepad",
                "GamepadAxisMoveEvent",
                "GamepadButtonEvent",
                "GamepadEvent",
                "GamepadHapticActuator",
                "GamepadPose",
                "GeoGeolocation",
                "GeoPosition",
                "GeoPositionCallback",
                "GeoPositionCoords",
                "GeoPositionError",
                "GeoPositionErrorCallback",
                "getComputedStyle",
                "getDefaultComputedStyle",
                "getInterface",
                "getSelection",
                "GetUserMediaErrorCallback",
                "GetUserMediaSuccessCallback",
                "GlobalObjectConstructor",
                "GlobalPropertyInitializer",
                "HashChangeEvent",
                "Headers",
                "history",
                "History",
                "home",
                "HTMLAllCollection",
                "HTMLAnchorElement",
                "HTMLAppletElement",
                "HTMLAreaElement",
                "HTMLAudioElement",
                "HTMLBaseElement",
                "HTMLBodyElement",
                "HTMLBRElement",
                "HTMLButtonElement",
                "HTMLByteRanges",
                "HTMLCanvasElement",
                "HTMLCollection",
                "HTMLCommandElement",
                "HTMLContentElement",
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
                "HTMLPropertiesCollection",
                "HTMLQuoteElement",
                "HTMLScriptElement",
                "HTMLSelectElement",
                "HTMLShadowElement",
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
                "ImageDocument",
                "indexedDB",
                "Infinity",
                "innerHeight",
                "innerWidth",
                "InputEvent",
                "insertPropertyStrings",
                "InstallTrigger",
                "InstallTriggerImpl",
                "Int16Array",
                "Int32Array",
                "Int8Array",
                "InternalError",
                "IntersectionObserver",
                "IntersectionObserverEntry",
                "Intl",
                "isFinite",
                "isNaN",
                "isSecureContext",
                "Iterator",
                "JSON",
                "JSWindow",
                "KeyboardEvent",
                "KeyEvent",
                "length",
                "LinkStyle",
                "LoadStatus",
                "LocalMediaStream",
                "localStorage",
                "location",
                "Location",
                "locationbar",
                "LockedFile",
                "LSProgressEvent",
                "Map",
                "matchMedia",
                "Math",
                "MediaElementAudioSourceNode",
                "MediaEncryptedEvent",
                "MediaError",
                "MediaKeys",
                "MediaKeyError",
                "MediaKeyMessageEvent",
                "MediaKeySession",
                "MediaKeyStatusMap",
                "MediaKeySystemAccess",
                "MediaList",
                "MediaQueryList",
                "MediaQueryListEvent",
                "MediaQueryListListener",
                "MediaRecorder",
                "MediaRecorderErrorEvent",
                "MediaSource",
                "MediaStream",
                "MediaStreamAudioDestinationNode",
                "MediaStreamAudioSourceNode",
                "MediaStreamTrack",
                "MediaStreamTrackEvent",
                "menubar",
                "MenuBoxObject",
                "MessageChannel",
                "MessageEvent",
                "MessagePort",
                "MimeType",
                "MimeTypeArray",
                "ModalContentWindow",
                "MouseEvent",
                "MouseScrollEvent",
                "moveBy",
                "moveTo",
                "MozAlarmsManager",
                "mozAnimationStartTime",
                "MozApplicationEvent",
                "MozBlobBuilder",
                "MozBrowserFrame",
                "mozCancelAnimationFrame",
                "mozCancelRequestAnimationFrame",
                "MozCanvasPrintState",
                "MozConnection",
                "mozContact",
                "MozContactChangeEvent",
                "MozCSSKeyframeRule",
                "MozCSSKeyframesRule",
                "mozIndexedDB",
                "mozInnerScreenX",
                "mozInnerScreenY",
                "MozMmsEvent",
                "MozMmsMessage",
                "MozMobileCellInfo",
                "MozMobileConnectionInfo",
                "MozMobileMessageManager",
                "MozMobileMessageThread",
                "MozMobileNetworkInfo",
                "MozNamedAttrMap",
                "MozNavigatorMobileMessage",
                "MozNavigatorNetwork",
                "MozNavigatorSms",
                "MozNavigatorTime",
                "MozNetworkStats",
                "MozNetworkStatsData",
                "MozNetworkStatsManager",
                "mozPaintCount",
                "MozPowerManager",
                "mozRequestAnimationFrame",
                "mozRequestOverfill",
                "MozSelfSupport",
                "MozSettingsEvent",
                "MozSettingsTransactionEvent",
                "MozSmsEvent",
                "MozSmsFilter",
                "MozSmsManager",
                "MozSmsMessage",
                "MozSmsSegmentInfo",
                "MozTimeManager",
                "MozTouchEvent",
                "MozWakeLock",
                "MozWakeLockListener",
                "MutationEvent",
                "MutationObserver",
                "MutationRecord",
                "name",
                "NamedNodeMap",
                "NaN",
                "navigator",
                "Navigator",
                "NavigatorCamera",
                "NavigatorDesktopNotification",
                "NavigatorDeviceStorage",
                "NavigatorGeolocation",
                "NavigatorUserMedia",
                "netscape",
                "Node",
                "NodeFilter",
                "NodeIterator",
                "NodeList",
                "NodeSelector",
                "__noscriptStorage",
                "Notification",
                "NotifyAudioAvailableEvent",
                "NotifyPaintEvent",
                "NSEditableElement",
                "NSEvent",
                "NSRGBAColor",
                "NSXPathExpression",
                "Number",
                "Object",
                "OfflineAudioCompletionEvent",
                "OfflineAudioContext",
                "OfflineResourceList",
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
                "ongotpointercapture",
                "onhashchange",
                "oninput",
                "oninvalid",
                "onkeydown",
                "onkeypress",
                "onkeyup",
                "onlanguagechange",
                "onload",
                "onLoad",
                "onloadeddata",
                "onloadedmetadata",
                "onloadend",
                "onloadstart",
                "onlostpointercapture",
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
                "onmozpointerlockchange",
                "onmozpointerlockerror",
                "onoffline",
                "ononline",
                "onpagehide",
                "onpageshow",
                "onpause",
                "onplay",
                "onplaying",
                "onpointercancel",
                "onpointerdown",
                "onpointerenter",
                "onpointerleave",
                "onpointermove",
                "onpointerout",
                "onpointerover",
                "onpointerup",
                "onpopstate",
                "onprogress",
                "onratechange",
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
                "openDialog",
                "opener",
                "OpenWindowEventDetail",
                "Option",
                "origin",
                "OscillatorNode",
                "outerHeight",
                "outerWidth",
                "PageTransitionEvent",
                "pageXOffset",
                "pageYOffset",
                "PaintRequest",
                "PaintRequestList",
                "PannerNode",
                "parent",
                "parseFloat",
                "parseInt",
                "Parser",
                "ParserJS",
                "Path2D",
                "PaymentRequestInfo",
                "performance",
                "Performance",
                "PerformanceEntry",
                "PerformanceMark",
                "PerformanceMeasure",
                "PerformanceNavigation",
                "PerformanceNavigationTiming",
                "PerformanceObserver",
                "PerformanceObserverEntryList",
                "PerformanceResourceTiming",
                "PerformanceTiming",
                "PeriodicWave",
                "Permissions",
                "PermissionSettings",
                "PermissionStatus",
                "personalbar",
                "PhoneNumberService",
                "Pkcs11",
                "Plugin",
                "PluginArray",
                "PluginCrashedEvent",
                "PointerEvent",
                "PopStateEvent",
                "PopupBlockedEvent",
                "PopupBoxObject",
                "postMessage",
                "print",
                "ProcessingInstruction",
                "ProgressEvent",
                "Promise",
                "PromiseDebugging",
                "prompt",
                "PropertyNodeList",
                "Proxy",
                "PushManager",
                "QueryInterface",
                "RadioNodeList",
                "Range",
                "RangeError",
                "realFrameElement",
                "RecordErrorEvent",
                "Rect",
                "ReferenceError",
                "RegExp",
                "releaseEvents",
                "removeEventListener",
                "Request",
                "requestAnimationFrame",
                "requestIdleCallback",
                "RequestService",
                "resizeBy",
                "resizeTo",
                "Response",
                "RGBColor",
                "RTCIceCandidate",
                "RTCPeerConnection",
                "RTCPeerConnectionIdentityErrorEvent",
                "RTCPeerConnectionIdentityEvent",
                "RTCSessionDescription",
                "screen",
                "Screen",
                "ScreenOrientation",
                "screenX",
                "screenY",
                "ScriptProcessorNode",
                "scroll",
                "ScrollAreaEvent",
                "scrollbars",
                "scrollBy",
                "scrollByLines",
                "scrollByPages",
                "scrollMaxX",
                "scrollMaxY",
                "scrollTo",
                "ScrollViewChangeEvent",
                "scrollX",
                "scrollY",
                "Selection",
                "SelectionStateChangedEvent",
                "self",
                "Serializer",
                "Services",
                "sessionStorage",
                "Set",
                "setInterval",
                "setResizable",
                "setTimeout",
                "SettingsLock",
                "SettingsManager",
                "SharedWorker",
                "showModalDialog",
                "sidebar",
                "SimpleGestureEvent",
                "sizeToContent",
                "SmartCardEvent",
                "SourceBuffer",
                "SourceBufferList",
                "SpeechRecognitionError",
                "SpeechRecognitionEvent",
                "speechSynthesis",
                "SpeechSynthesisEvent",
                "status",
                "statusbar",
                "StereoPannerNode",
                "stop",
                "StopIteration",
                "Storage",
                "StorageEvent",
                "StorageIndexedDB",
                "StorageItem",
                "StorageManager",
                "StorageObsolete",
                "String",
                "StyleRuleChangeEvent",
                "StyleSheet",
                "StyleSheetApplicableStateChangeEvent",
                "StyleSheetChangeEvent",
                "StyleSheetList",
                "SubtleCrypto",
                "SVGAElement",
                "SVGAltGlyphElement",
                "SVGAngle",
                "SVGAnimatedAngle",
                "SVGAnimatedBoolean",
                "SVGAnimatedEnumeration",
                "SVGAnimatedInteger",
                "SVGAnimatedLength",
                "SVGAnimatedLengthList",
                "SVGAnimatedNumber",
                "SVGAnimatedNumberList",
                "SVGAnimatedPathData",
                "SVGAnimatedPoints",
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
                "SVGDocument",
                "SVGElement",
                "SVGEllipseElement",
                "SVGEvent",
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
                "SVGFilterPrimitiveStandardAttributes",
                "SVGFitToViewBox",
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
                "SVGLocatable",
                "SVGMarkerElement",
                "SVGMaskElement",
                "SVGMatrix",
                "SVGMetadataElement",
                "SVGMpathElement",
                "SVGMPathElement",
                "SVGNumber",
                "SVGNumberList",
                "SVGPathElement",
                "SVGPathSeg",
                "SVGPathSegArcAbs",
                "SVGPathSegArcRel",
                "SVGPathSegClosePath",
                "SVGPathSegCurvetoCubicAbs",
                "SVGPathSegCurvetoCubicRel",
                "SVGPathSegCurvetoCubicSmoothAbs",
                "SVGPathSegCurvetoCubicSmoothRel",
                "SVGPathSegCurvetoQuadraticAbs",
                "SVGPathSegCurvetoQuadraticRel",
                "SVGPathSegCurvetoQuadraticSmoothAbs",
                "SVGPathSegCurvetoQuadraticSmoothRel",
                "SVGPathSegLinetoAbs",
                "SVGPathSegLinetoHorizontalAbs",
                "SVGPathSegLinetoHorizontalRel",
                "SVGPathSegLinetoRel",
                "SVGPathSegLinetoVerticalAbs",
                "SVGPathSegLinetoVerticalRel",
                "SVGPathSegList",
                "SVGPathSegMovetoAbs",
                "SVGPathSegMovetoRel",
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
                "SVGStylable",
                "SVGStyleElement",
                "SVGSVGElement",
                "SVGSwitchElement",
                "SVGSymbolElement",
                "SVGTests",
                "SVGTextContentElement",
                "SVGTextElement",
                "SVGTextPathElement",
                "SVGTextPositioningElement",
                "SVGTitleElement",
                "SVGTransform",
                "SVGTransformable",
                "SVGTransformList",
                "SVGTSpanElement",
                "SVGUnitTypes",
                "SVGURIReference",
                "SVGUseElement",
                "SVGViewElement",
                "SVGViewSpec",
                "SVGZoomAndPan",
                "SVGZoomEvent",
                "Symbol",
                "SyntaxError",
                "TCPSocket",
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
                "toolbar",
                "top",
                "toStaticHTML",
                "ToString",
                "Touch",
                "TouchEvent",
                "TouchList",
                "TrackEvent",
                "TransitionEvent",
                "TreeColumn",
                "TreeColumns",
                "TreeContentView",
                "TreeSelection",
                "TreeWalker",
                "TypeError",
                "UIEvent",
                "Uint16Array",
                "Uint32Array",
                "Uint8Array",
                "Uint8ClampedArray",
                "undefined",
                "UndoManager",
                "unescape",
                "uneval",
                "updateCommands",
                "URIError",
                "URL",
                "URLSearchParams",
                "UserDataHandler",
                "UserProximityEvent",
                "USSDReceivedEvent",
                "ValidityState",
                "VideoPlaybackQuality",
                "VideoStreamTrack",
                "VTTCue",
                "VTTRegion",
                "WaveShaperNode",
                "WeakMap",
                "WeakSet",
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
                "WebGLVertexArray",
                "WebGLVertexArrayObject",
                "WebKitCSSMatrix",
                "WebSocket",
                "WheelEvent",
                "window",
                "Window",
                "WindowCollection",
                "WindowInternal",
                "WindowPerformance",
                "WindowRoot",
                "WindowUtils",
                "Worker",
                "__XBLClassObjectMap__",
                "XMLDocument",
                "XMLHttpRequest",
                "XMLHttpRequestEventTarget",
                "XMLHttpRequestUpload",
                "XMLSerializer",
                "XMLStylesheetProcessingInstruction",
                "XPathEvaluator",
                "XPathExpression",
                "XPathNamespace",
                "XPathNSResolver",
                "XPathResult",
                "XPCNativeWrapper",
                "XSLTProcessor",
                "XULButtonElement",
                "XULCheckboxElement",
                "XULCommandDispatcher",
                "XULCommandEvent",
                "XULContainerElement",
                "XULContainerItemElement",
                "XULControlElement",
                "XULControllers",
                "XULDescriptionElement",
                "XULDocument",
                "XULElement",
                "XULImageElement",
                "XULLabeledControlElement",
                "XULLabelElement",
                "XULMenuListElement",
                "XULMultiSelectControlElement",
                "XULPopupElement",
                "XULRelatedElement",
                "XULSelectControlElement",
                "XULSelectControlItemElement",
                "XULTemplateBuilder",
                "XULTextBoxElement",
                "XULTreeBuilder",
                "XULTreeElement",
                ]

    def test_dom_objects_enumeration(self):
        with self.marionette.using_context('content'):
            self.marionette.navigate('about:robots')

            r = self.marionette.execute_script('return Object.getOwnPropertyNames(window);')
            err = False
            unknown_objects = ''
            for l in r:
                if l in self.interfaceNamesInGlobalScope:
                    continue
                err = True
                unknown_objects += l + "\n"

            err_msg = "Unknown objects:\n%s" % unknown_objects
            self.assertFalse(err, msg=err_msg)

