(function (window) {
    function nostr() {
        
        // promise handlers
        // these are also the names of the functions
        // that will need to be called back into on window
        const HANDLER_GET_PUBLIC_KEY = "handler_getPublicKey";
        const HANDLER_SIGN_EVENT = "handler_signEvent"
        const HANDLER_GET_RELAYS = "handler_getRelays"
        
        function parseJSON(json) {
            if (typeof json === 'object' && json !== null) {
                return json;
            } else {
                var parsed;
                try {
                    parsed = JSON.parse(json)
                } catch (e) { }
                return parsed || json;
            }
        }
        
        var _retval = {};
        var handlers = {};
        _retval.handlers = handlers;
        
        ///////////////////////////////////////////
        // These are called by native app
        // as Promise responses to the functions
        // called by web app
        ///////////////////////////////////////////
        
        _retval.handler_getPublicKey = function (publicKey) {
            if (this.handlers.hasOwnProperty(HANDLER_GET_PUBLIC_KEY)) {
                if (typeof publicKey == "string" || publicKey instanceof String) {
                    this.handlers[HANDLER_GET_PUBLIC_KEY].resolve(publicKey);
                } else {
                    this.handlers[HANDLER_GET_PUBLIC_KEY].reject(new Error('There was a problem fetching Public Key'));
                }
                delete this.handlers[HANDLER_GET_PUBLIC_KEY];
            }
        };
        
        _retval.handler_signEvent = function (event) {
            
            var parsedResult = parseJSON(event);
            
            if (this.handlers.hasOwnProperty(HANDLER_SIGN_EVENT)) {
                if (typeof parsedResult !== 'undefined') {
                    this.handlers[HANDLER_SIGN_EVENT].resolve(parsedResult);
                } else if (typeof parsedResult !== 'undefined') {
                    this.handlers[HANDLER_SIGN_EVENT].reject(parsedResult);
                } else {
                    this.handlers[HANDLER_SIGN_EVENT].reject(new Error('Signature request was cancelled or there was a problem'));
                }
                delete this.handlers[HANDLER_SIGN_EVENT];
            }
        };
        
        _retval.handler_getRelays = function (event) {
            
            var parsedResult = parseJSON(event);
            
            if (this.handlers.hasOwnProperty(HANDLER_GET_RELAYS)) {
                if (typeof parsedResult !== 'undefined') {
                    this.handlers[HANDLER_GET_RELAYS].resolve(parsedResult);
                } else if (typeof parsedResult !== 'undefined') {
                    this.handlers[HANDLER_GET_RELAYS].reject(parsedResult);
                } else {
                    this.handlers[HANDLER_GET_RELAYS].reject(new Error('There was an issue requesting relays'));
                }
                delete this.handlers[HANDLER_GET_RELAYS];
            }
        };
        
        ///////////////////////////////////////////
        // Public functions. These are to be called
        // by your web application
        // These follow NIP-07
        // https://github.com/nostr-protocol/nips/blob/master/07.md
        ///////////////////////////////////////////
        
        _retval.getPublicKey = function () {
            return new Promise((resolve, reject) => {
                this.handlers[HANDLER_GET_PUBLIC_KEY] = { resolve, reject };
                window.webkit.messageHandlers.getPublicKey.postMessage(null);
            });
        };
        
        _retval.signEvent = function (data) {
            return new Promise((resolve, reject) => {
                if (typeof data === undefined || typeof data !== 'object' && data.constructor !== Object) {
                    reject(new Error('Argument not an object. Expected deserialized transaction'));
                }
                this.handlers[HANDLER_SIGN_EVENT] = { resolve, reject };
                window.webkit.messageHandlers.signEvent.postMessage(JSON.stringify(data));
            });
        };
        
        _retval.getRelays = function () {
            return new Promise((resolve, reject) => {
                this.handlers[HANDLER_GET_RELAYS] = { resolve, reject };
                window.webkit.messageHandlers.getRelays.postMessage(null);
            });
        };
        
        return _retval;
        
    }
    
    if (typeof window.nostr === "undefined") {
        window.nostr = nostr();
    }
    
})(window);
