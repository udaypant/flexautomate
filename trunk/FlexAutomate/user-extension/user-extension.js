// Code below adapted from: http://sfapi.googlecode.com/svn/trunk/js_extension/flex-playback.js
Selenium.prototype.getFlexObject = function() {
	var obj = (this.browserbot.locateElementByXPath('//embed', this.browserbot
			.getDocument())) ? this.browserbot.locateElementByXPath('//embed',
			this.browserbot.getDocument()) : this.browserbot
			.locateElementByXPath('//object', this.browserbot.getDocument());
			alert("Calling 3");
	return obj.id;
};

Selenium.prototype.flashObjectLocator = null;

Selenium.prototype.callFlexMethod = function(method, id, args) {
	alert("Calling 2");
	var dot_index = id.indexOf('.');
	if (dot_index < 0) {
		ids = [ null, id ];
	} else {
		ids = [ id.slice(0, dot_index), id.slice(dot_index + 1) ];
	}

		// Flex application id is specified, so playback within that application
	if (ids[0] !== null && ids[0] != "") {
		this.flashObjectLocator = ids[0];
	} else { // no application id specified so playback in default
		// application
		if (this.flashObjectLocator === null) {
			this.flashObjectLocator = this.getFlexObject();
		}
	}
	alert("Calling 4");
	// the object that contains the exposed Flex functions
	var funcObj = null;
	// get the flash object
	var flashObj = selenium.browserbot.findElement(this.flashObjectLocator);

	if (flashObj.wrappedJSObject) {
		flashObj = flashObj.wrappedJSObject;
	}

	// find object holding functions
	if (typeof (flashObj[method]) == 'function') {
		// for IE (will be the flash object itself)
		funcObj = flashObj;
	} else {
		// Firefox (will be a child of the flash object)
		for ( var i = 0; i < flashObj.childNodes.length; i++) {
			var tmpFuncObj = flashObj.childNodes[i];
			if (typeof (tmpFuncObj) == 'function') {
				funcObj = tmpFuncObj;
				break;
			}
		}
	}

	// throw a error to Selenium if the exposed function could not be found
	if (funcObj === null) {
		throw new SeleniumError('Function ' + method +
				' not found on the External Interface for the flash object ' +
				this.flashObjectLocator);

	} else {
		alert("Calling 5");
		return funcObj[method]( ids[1], args);
	}
};

Selenium.prototype.doFlexSetFlexObjID = function(flasObjID) {
	if (null === flasObjID) {
		throw new SeleniumError(flasObjID);
	}
	this.flashObjectLocator = flasObjID;
};

Selenium.prototype.doFlexType = function(id, args) {
	alert("Calling 1");
	this.callFlexMethod('playBack', id, args);
};
