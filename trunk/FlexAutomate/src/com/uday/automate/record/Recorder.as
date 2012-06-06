
package com.uday.automate.record
{
	import com.uday.automate.util.AppTreeParser;
	import com.uday.automate.util.IdentifierUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.DateField;
	import mx.controls.TextInput;
	import mx.core.FlexGlobals;
	import mx.core.IChildList;
	import mx.core.UIComponent;
	import mx.events.ChildExistenceChangedEvent;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.MenuEvent;
	import mx.managers.SystemManager;
	import mx.modules.Module;
	
	public class Recorder
	{
		private var sysManager:SystemManager;
		private var recordQueue:ArrayCollection = new ArrayCollection();
		public static const MAX_QUEUE_SIZE:int = 10;
		
		private var appStartTime:Number;
		
		public function Recorder(sysMan:SystemManager)
		{	
			appStartTime = new Date().time;
			sysManager = sysMan;
		}
		
		public function processSysManager():void {
			var pauseDelay:int = (new Date().time - appStartTime) + 3000;
			sendToSelenium("pause",pauseDelay.toString());
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
		
		public function sendToSelenium(command:String, target:String = null, value:String = null):void {
			var dynaEvent:DynamicEvent = new DynamicEvent("selenium",true,false);
			dynaEvent.cmd = command;
			dynaEvent.trgt = target;
			dynaEvent.val = value;
			FlexGlobals.topLevelApplication.dispatchEvent(dynaEvent);
			if(ExternalInterface.available) {
				if(recorderAvailable()) {
					flushQueue();
					var js:String = "function(cmd, target, value) {window['_Selenium_IDE_Recorder'].record(cmd,target,value);}";
					ExternalInterface.call(js, command, target, value);				
				} else {
					recordQueue.addItem({cmd:command,trgt:target,val:value});
				}
			}
		}
		
		private function flushQueue():void {
			var js:String = "function(cmd, target, value) {window['_Selenium_IDE_Recorder'].record(cmd,target,value);}";

			for(var cmdIndex:int = 0; cmdIndex < recordQueue.length; cmdIndex++) {
				var cmdObject:Object = recordQueue.getItemAt(cmdIndex);
				ExternalInterface.call(js, cmdObject.cmd, cmdObject.trgt, cmdObject.val);
			}
			
			recordQueue.removeAll();
		}
		
		private function recorderAvailable():Boolean {
			var js:String = "function() {" +
				"if(window['_Selenium_IDE_Recorder']) {" +
					"return true;" +
				"} else {" +
					"return false;" +
				"}}";
			return Boolean(ExternalInterface.call(js));
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
			var attachDefault:Boolean = false;
			if(isTypeOrSubType(component, "TextInput")) {
				attachDefault = true;
				component.addEventListener(FlexEvent.VALUE_COMMIT, valueCommitHandlerTextInput, false, 0, true);
			} else if(isTypeOrSubType(component, "Date")) {
				attachDefault = true;
				component.addEventListener(FlexEvent.VALUE_COMMIT, valueCommitHandlerDate, false, 0, true);
			} else if((isTypeOrSubType(component, "Combo")) || (isTypeOrSubType(component, "List"))) {
				attachDefault = true;
				component.addEventListener(ListEvent.CHANGE, valueCommitHandlerListControl, false, 0, true);
			} else if (isTypeOrSubType(component, "Button")) {
				attachDefault = true;
				component.addEventListener(MouseEvent.CLICK, mouseHandler, false, 0, true);
			} else if (isTypeOrSubType(component, "mx.controls::MenuBar")) {
				component.addEventListener(MenuEvent.MENU_SHOW, menuShowHandler, false, 0, true);
			} else if (isTypeOrSubType(component, "mx.controls.menuClasses::MenuBarItem") || isTypeOrSubType(component, "mx.controls.menuClasses::MenuItemRenderer")) {
				component.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler, false, 0, true);
				component.addEventListener(MouseEvent.MOUSE_UP, mouseHandler, false, 0, true);
				component.addEventListener(MouseEvent.MOUSE_OVER, mouseHandler, false, 0, true);
				component.addEventListener(MouseEvent.MOUSE_OUT, mouseHandler, false, 0, true);
			}
			
			//Some handlers to be attached to all controls
			if(attachDefault) {
				component.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, false, 0, true);
				component.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
			}
		}
		
		private function registerContainer(component:Object):void {
			component.addEventListener(ChildExistenceChangedEvent.CHILD_ADD, childAddedToContainer, false, 0, true);
		}
		
		private function childAddedToContainer(event:ChildExistenceChangedEvent):void {
			if(event.relatedObject is Module) {
				sendToSelenium("flexWaitForElement",IdentifierUtil.generateIdentifier(event.relatedObject));
			}
			AppTreeParser.parseUiTree(event.relatedObject as IChildList, registerComponent,null);
		}
		
		private function valueCommitHandlerTextInput(event:Event):void {
			sendToSelenium("flexType",IdentifierUtil.generateIdentifier(event.currentTarget), event.currentTarget.text);
		}
		
		private function valueCommitHandlerListControl(event:Event):void {
			sendToSelenium("flexSelect",IdentifierUtil.generateIdentifier(event.currentTarget), event.currentTarget.selectedIndex);
		}
		
		private function valueCommitHandlerDate(event:Event):void {
			sendToSelenium("flexSelectDate",IdentifierUtil.generateIdentifier(event.currentTarget), 
							DateField.dateToString(event.currentTarget.selectedDate,"DD-MM-YYYY") + "|DD-MM-YYYY");
		}
		
		private function menuShowHandler(event:MenuEvent):void {
			AppTreeParser.parseUiTree(event.menu as IChildList, registerComponent,null);
		}
		
		private function mouseHandler(event:MouseEvent):void {
			switch(event.type) {
				case MouseEvent.CLICK:
					sendToSelenium("flexClick",IdentifierUtil.generateIdentifier(event.currentTarget));
					break;
				
				case MouseEvent.MOUSE_DOWN:
					sendToSelenium("flexMouseDown",IdentifierUtil.generateIdentifier(event.currentTarget));
					break;
				
				case MouseEvent.MOUSE_UP:
					sendToSelenium("flexMouseUp",IdentifierUtil.generateIdentifier(event.currentTarget));
					break;
				
				case MouseEvent.MOUSE_OVER:
					sendToSelenium("flexMouseOver",IdentifierUtil.generateIdentifier(event.currentTarget));
					break;
				
				case MouseEvent.MOUSE_OUT:
					sendToSelenium("flexMouseOut",IdentifierUtil.generateIdentifier(event.currentTarget));
					break;
			}
		}
		
		private function focusInHandler(event:FocusEvent):void {
			sendToSelenium("flexFocusIn",IdentifierUtil.generateIdentifier(event.currentTarget));
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