var enumeration = document.createElement('div');
enumeration.setAttribute("id", "enumeration");

if (window.Worker) {
    var myWorker = new Worker("dom-objects-enumeration-worker.js");
    myWorker.postMessage("Hello");
    myWorker.onmessage = function(e) {
        var allObjects = e.data;
        for (var i in allObjects.sort()) {
            var name = allObjects[i];
            enumeration.innerHTML += name + "<br/>";
        }
        document.getElementsByTagName("body")[0].appendChild(enumeration);
    }
}
