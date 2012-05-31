
package com.uday.automate.record
{
	import com.uday.automate.util.AppTreeParser;
	import com.uday.automate.util.IdentifierUtil;
	
	import flash.events.EventDispatcher;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import mx.controls.Button;
	import mx.controls.TextInput;
	import mx.core.FlexGlobals;
	import mx.core.IChildList;
	import mx.core.UIComponent;
	import mx.events.ChildExistenceChangedEvent;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import mx.managers.SystemManager;
	
	public class Recorder
	{
		private var sysManager:SystemManager;
		
		public function Recorder(sysMan:SystemManager)
		{	
			sysManager = sysMan;
		}
		
		public function processSysManager():void {
			sendToSelenium("flexWaitForElement", IdentifierUtil.generateIdentifier(FlexGlobals.topLevelApplication));
			AppTreeParser.parseUiTree(sysManager,registerComponent,null);
			var popupManagerImpl:mx.managers.PopUpManagerImpl = mx.core.Singleton.getInstance("mx.managers::IPopUpManager") as mx.managers.PopUpManagerImpl;
			
			if(popupManagerImpl is EventDispatcher) {
				popupManagerImpl.addEventListener("addedPopUp",popupListener, false, 0, true);
			}
		}
		
		private function popupListener(event:DynamicEvent):void {
			if(event.hasOwnProperty("window") && event.window) {
				AppTreeParser.parseUiTree(event.window,registerComponent,null);
			}
		}
		
		
		private function handleMouseClick(event:MouseEvent):void {
			//Alert.show(IdentifierUtil.generateIdentifier(event.target));
			sendToSelenium(event.type,IdentifierUtil.generateIdentifier(event.target), "");
		}
		
		private function textInputHandler(event:TextEvent):void {
			var a:UIComponent;
			sendToSelenium(event.type,IdentifierUtil.generateIdentifier(event.target), event.text);
		}
		
		public static function sendToSelenium(command:String, target:String, value:String = null):void {
			var js:String = 'function(cmd, target, value) {window["_Selenium_IDE_Recorder"].record(cmd,target,value)}';
			ExternalInterface.call(js, command, target, value);
		}
		
		public function registerComponent(component:Object,param:Object):Boolean {
			
			var isContainer:Boolean = isContainer(component);
			
			if(isContainer) {
				registerContainer(component);
			} else {
				registerControls(component);
			}
			//var isContainer:Boolean = (type.extendsClass.(@type.toString().search("mx.controls") > -1) as XMLList).length;
			trace("Registering " + component.toString() + " with id " + (component.hasOwnProperty("id")?component.id:"NA") + " and class " + getQualifiedClassName(component));
			
			return false;
		}
		
		private function isContainer(component:Object):Boolean {
			return 	isTypeOrSubType(component,"mx.core::Container","mx.containers") || 
					isTypeOrSubType(component, "spark.components.supportClasses::GroupBase") ||
					isTypeOrSubType(component, "spark.components::SkinnableContainer") ||
					isTypeOrSubType(component,"mx.managers::SystemManager");
		}
		
		private function isTypeOrSubType(component:Object, className:String, packageNm:String = null):Boolean {
			var type:XML = describeType(component);
			var returnVal:Boolean = false;
			
			if(className) {
				returnVal = ((type.extendsClass.(@type.toString().search(className) > -1) as XMLList).length() > 0) ||
					(type.@name.toString().search(className) > -1);
			}
			
			if(packageNm && !returnVal) {
				returnVal = ((type.extendsClass.(@type.toString().search(packageNm) > -1) as XMLList).length() > 0) ||
					(type.@name.toString().search(packageNm) > -1);
			}
			
			return returnVal;
		}
		
		private function registerControls(component:Object):void {
			if(isTypeOrSubType(component, "TextInput")) {
				component.addEventListener(FlexEvent.VALUE_COMMIT, valueCommitHandler, false, 0, true);
			} else if (isTypeOrSubType(component, "Button")) {
				component.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
			}
			
			//Some handlers to be attached to all controls
			component.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, false, 0, true);
			component.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
		}
		
		private function registerContainer(component:Object):void {
			component.addEventListener(ChildExistenceChangedEvent.CHILD_ADD, childAddedToContainer, false, 0, true);
		}
		
		private function childAddedToContainer(event:ChildExistenceChangedEvent):void {
			AppTreeParser.parseUiTree(event.relatedObject as IChildList, registerComponent,null);
		}
		
		private function valueCommitHandler(event:FlexEvent):void {
			if(event.target is TextInput) {
				sendToSelenium("flexType",IdentifierUtil.generateIdentifier(event.target), event.target.text);
			} 
		}
		
		private function clickHandler(event:MouseEvent):void {
			sendToSelenium("flexClick",IdentifierUtil.generateIdentifier(event.target));
		}
		
		private function focusInHandler(event:FocusEvent):void {
			sendToSelenium("flexFocusIn",IdentifierUtil.generateIdentifier(event.target));
		}
		
		private function keyDownHandler(event:KeyboardEvent):void {
			if( (event.keyCode == Keyboard.TAB) ||
				(event.keyCode == Keyboard.ENTER)) {
				sendToSelenium(event.type,IdentifierUtil.generateIdentifier(event.target), event.keyCode.toString());
			}
		}
		
		/*private function convertEventToXML(event:Event):String {
		var qName:QName = new QName(event.);
		var xmlDocument:XMLDocument = new XMLDocument();
		var simpleXMLEncoder:SimpleXMLEncoder = new SimpleXMLEncoder(xmlDocument);
		var xmlNode:XMLNode = simpleXMLEncoder.encodeValue(obj, qName, xmlDocument);
		var xml:XML = new XML(xmlDocument.toString());
		// trace(xml.toXMLString());
		return xml.toXMLString();
		}*/
	}
}