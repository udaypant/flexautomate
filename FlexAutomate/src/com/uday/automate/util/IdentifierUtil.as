package com.uday.automate.util
{
	import mx.core.UIComponent;
	import mx.managers.SystemManager;

	public class IdentifierUtil
	{
		/**
		 * Uses the id, automationName, text properties to generate an identifier 
		 * for a component as value:property/value:property
		 * 
		 * If a property is not specified, id is taken as the default property
		 */
		public static function generateIdentifier(component:Object):String {
			var identifier:String = "";
			
			while(component && !(component is SystemManager)) {
				if(component.hasOwnProperty("id") && component.id) {
					identifier = ( "/" + component.id + identifier);
				} else if(component.hasOwnProperty("automationName") && component.automationName) {
					identifier = ( "/" + component.automationName + ":" + "automationName" + identifier);
				} else if(component.hasOwnProperty("label") && component.label) {
					identifier = ( "/" + component.label + ":" + "label" + identifier);
				} else if(component.hasOwnProperty("name") && component.name) {
					identifier = ( "/" + component.name + ":" + "name" + identifier);
				} else {
					identifier = ( "/" + component.className + ":" + "className" + identifier);
				}
				component = component.parent;
			}
			
			return identifier;
		}
	}
}