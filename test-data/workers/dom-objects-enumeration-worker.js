// getAllPropertyNames function taken from:
// https://stackoverflow.com/questions/8024149/is-it-possible-to-get-the-non-enumerable-inherited-property-names-of-an-object
function getAllPropertyNames( obj ) {
    var props = [];
    do {
        Object.getOwnPropertyNames( obj ).forEach(function ( prop ) {
            if ( props.indexOf( prop ) === -1 ) {
                props.push( prop );
            }
        });
    } while ( obj = Object.getPrototypeOf( obj ) );
    return props;
}

onmessage = function(e) {
    var allObjects = getAllPropertyNames(self);
    var res = Array();
    for (var i in allObjects.sort()) {
        res.push(allObjects[i]);
    }
    postMessage(res);
}
