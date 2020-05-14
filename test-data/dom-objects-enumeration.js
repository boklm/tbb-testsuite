(() => {
    // getAllPropertyNames function taken from:
    // https://stackoverflow.com/questions/8024149/is-it-possible-to-get-the-non-enumerable-inherited-property-names-of-an-object
    function getAllPropertyNames(obj) {
        const props = [];
        do {
            Object.getOwnPropertyNames(obj).forEach((prop) => {
                if (props.indexOf(prop) === -1) {
                    props.push(prop);
                }
            });
        } while (obj = Object.getPrototypeOf(obj));
        return [...new Set(props)].sort();
    }

    function getGlobalNames() {
        return getAllPropertyNames(globalThis);
    }

    if (!self.document) {
        // This is a worker
        self.postMessage(getGlobalNames());
    } else {
        // Not a worker, loaded via script.
        const enumeration = document.createElement("div");
        enumeration.setAttribute("id", "enumeration");
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        let onmessage = (allObjects) => {
            for (const name of allObjects) {
                enumeration.innerHTML += name + "<br/>";
            }
            document.getElementsByTagName("body")[0].appendChild(enumeration);
        };
        if (urlParams.get("testType") === "worker") {
            // Must enumerate worker globals
            const worker = new Worker("dom-objects-enumeration.js");
            worker.onmessage = (e) => onmessage(e.data);
        } else {
            // Must enumerate window global
            onmessage(getGlobalNames());
        }
    }
})();