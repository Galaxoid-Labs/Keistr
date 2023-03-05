//
//  Action.js
//  Open In Keistr
//
//  Created by Jacob Davis on 3/4/23.
//

var Action = function() {};

Action.prototype = {
    
    run: function(arguments) {
        // Here, you can run code that modifies the document and/or prepares
        // things to pass to your action's native code.
        
        // We will not modify anything, but will pass the body's background
        // style to the native code.
        
        arguments.completionFunction({ "currentBackgroundColor" : document.body.style.backgroundColor })
    },
    
    finalize: function(arguments) {
        const current = encodeURIComponent(window.location.href);
        window.location = `keistr://?openUrl=${current}`
    }
    
};
    
var ExtensionPreprocessingJS = new Action
