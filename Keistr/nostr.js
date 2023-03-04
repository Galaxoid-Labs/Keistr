 (function (window) {
     function nostr() {
         
         // promise handlers
         // these are also the names of the functions
         // that will need to be called back into on window
         const HANDLER_GET_PUBLIC_KEY = "handler_getPublicKey";
         const HANDLER_SIGN_EVENT = "handler_signEvent"
         
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
         
         ///////////////////////////////////////////
         // Public functions. These are to be called
         // by your web application
         ///////////////////////////////////////////

         _retval.getPublicKey = function () {
             return new Promise((resolve, reject) => {
                 this.handlers[HANDLER_GET_PUBLIC_KEY] = { resolve, reject };
                 window.webkit.messageHandlers.getPublicKey.postMessage(null);
             });
         };
         
         _retval.signEvent = function (data) {
             return new Promise((resolve, reject) => {
                 
                 console.log(data);
                 
                 if (typeof data === undefined || typeof data !== 'object' && data.constructor !== Object) {
                     reject(new Error('Argument not an object. Expected deserialized transaction'));
                 }
                 
                 this.handlers[HANDLER_SIGN_EVENT] = { resolve, reject };
                 window.webkit.messageHandlers.signEvent.postMessage(JSON.stringify(data));
                 
             });
         };
         
         return _retval;
         
     }
     
     if (typeof window.nostr === "undefined") {
         window.nostr = nostr();
     }
     
 })(window);
