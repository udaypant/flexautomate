
package com.uday.automate.record
{
	import com.uday.automate.util.AppTreeParser;
	import com.uday.automate.util.IdentifierUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.EventPhase;
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
	import mx.controls.MenuBar;
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
		
		private var lastCommand:Object;
		
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
			var activeWindowManager:Object = sysManager.getImplementation("mx.managers::IActiveWindowManager");
			
			if(popupManagerImpl is EventDispatcher) {
				popupManagerImpl.addEventListener("addedPopUp",popupListener, false, 0, true);
			}
			
			if(activeWindowManager) {
				activeWindowManager.addEventListener("activatedForm",activeWindowListener, false, 0, true);
			}
		}
		
		private function popupListener(event:DynamicEvent):void {
			if(event.hasOwnProperty("window") && event.window) {
				AppTreeParser.parseUiTree(event.window,registerComponent,null);
			}
		}
		
		private function activeWindowListener(event:Event):void {
			trace("activeWindowListener called");
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
			/*The current command is the same as the precious one. 
				In all probablity it is a stray event causing a duplicate recording. Skiping this command*/
			if(lastCommand && (lastCommand.cmd == command) &&
				(lastCommand.trgt == target) && (lastCommand.val == value)) {
				return;
			} else {
				lastCommand = {cmd:command,trgt:target,val:value};
			}
			
			if(ExternalInterface.available) {
				if(recorderAvailable()) {
					flushQueue();
					var js:String = "function(cmd, target, value) {window['_Selenium_IDE_Recorder'].record(cmd,target,value);}";
					ExternalInterface.call(js, command, target, value);				
				} else {
					recordQueue.addItem(lastCommand);
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
			
			return false;
		}
		
		private function isContainer(component:Object):Boolean {
			return 	isTypeOrSubType(component,"mx.core::Container","mx.containers") || 
					isTypeOrSubType(component, "spark.components.supportClasses::GroupBase") ||
					isTypeOrSubType(component, "spark.components::SkinnableContainer") ||
					isTypeOrSubType(component,"mx.managers::SystemManager") ||
					isTypeOrSubType(component,"mx.controls.listClasses::ListBaseContentHolder");
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
				(component as MenuBar).addEventListener(MenuEvent.CHANGE, menuChangeEventListener, false, 0, true);
			}
			
			//Some handlers to be attached to all controls
			if(attachDefault) {
				component.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
			}
			
			trace("Registering control " + component.toString() + " with id " + (component.hasOwnProperty("id")?component.id:"NA") + " and class " + getQualifiedClassName(component));
		}
		
		private function registerContainer(component:Object):void {
			component.addEventListener(ChildExistenceChangedEvent.CHILD_ADD, childAddedToContainer, false, 0, true);
			component.addEventListener(MouseEvent.CLICK, mouseHandler, false, 0, true);
			
			trace("Registering container " + component.toString() + " with id " + (component.hasOwnProperty("id")?component.id:"NA") + " and class " + getQualifiedClassName(component));
		}
		
		private function menuChangeEventListener(event:MenuEvent):void {
			if((event.item is XML) && (event.item.children().length() == 0)) {
				var data:XML = event.item as XML;
				var label:String = event.menuBar.labelField;
				var identifier:String = "";
				
				while(data) {
					identifier = "/" + data[label] + ":" + label + identifier;
					data = data.parent();
				}
				sendToSelenium("flexMenuSelected",IdentifierUtil.generateIdentifier(event.menuBar), identifier);
			}
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
			if(event.currentTarget.value == "" && !event.currentTarget.selectedDate) {
				sendToSelenium("flexSelectDate",IdentifierUtil.generateIdentifier(event.currentTarget), "");
			} else if(event.currentTarget.selectedDate){
				sendToSelenium("flexSelectDate",IdentifierUtil.generateIdentifier(event.currentTarget), 
					DateField.dateToString(event.currentTarget.selectedDate,"DD-MM-YYYY") + "|DD-MM-YYYY");
			}
		}
		
		private function mouseHandler(event:MouseEvent):void {
			if(event.eventPhase != EventPhase.AT_TARGET) {
				return;
			}
			
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