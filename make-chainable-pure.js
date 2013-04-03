makeChainable = function() {
    var receiver = arguments[0]
    for (var i = 1; i < arguments.length; i++) {
        functionName = arguments[i];
        (function() {
            wrapped = receiver[functionName];
            receiver[functionName] = function() {
                wrapped.apply(receiver, arguments);
                return receiver;
            }
        })();
    }
}

daisy = {
    name: 'Daisy',
    moo:  function() { console.log(this.name + " moos!") }
}

makeChainable(daisy, 'moo');
daisy.moo().moo().moo();
