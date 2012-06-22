package com.uday.automate.playback
{
	import com.uday.automate.util.AppTreeParser;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.controls.Alert;
	import mx.controls.DateField;
	import mx.controls.Menu;
	import mx.controls.MenuBar;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.menuClasses.IMenuItemRenderer;
	import mx.controls.menuClasses.MenuBarItem;
	import mx.controls.menuClasses.MenuItemRenderer;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.ListEvent;
	import mx.managers.SystemManager;

	public class PlayBack
	{
		private var sysManager:SystemManager;
		
		use namespace mx_internal;
		
		public function PlayBack(sysm:SystemManager) {
			if(ExternalInterface.available) {
				ExternalInterface.addCallback("playBack", playback);
			}
			sysManager = sysm;
		}
		
		public function playback(command:String,target:String, value:String):String {
			var node:Object = AppTreeParser.getNode(sysManager,target);
			var returnVal:String = "";
			if(node) {
				if(node is UIComponent) {
					(node as UIComponent).setFocus();
				}
				
				switch(command) {
					case "flexType":
						if(node && node.hasOwnProperty("text")) {
							node.text = value;
							returnVal = "true";
						}						
						break;
					
					case "flexFocusIn":
						if(node is UIComponent) {
							(node as UIComponent).setFocus();
							returnVal = "true";
						}
						break;
					
					case "flexClick":
						if((node as UIComponent).dispatchEvent(new MouseEvent(MouseEvent.CLICK))) {
							returnVal = "true";
						}
						break;
					
					case "flexSelectDate":
						var dateArr:Array = value.split("|");
						var dateVal:Date = null;
						
						if(dateArr.length == 1) {
							dateArr.push("DD-MM-YYYY");
						}
						
						if(dateArr[0] || dateArr[0]!="") {
							dateVal = DateField.stringToDate(dateArr[0],dateArr[1]);
						}

						if(node && node.hasOwnProperty("selectedDate") && dateVal) {
							node.selectedDate = dateVal;
							returnVal = "true";
						}
						break;
					
					case "flexSelect":
						var index:int = int(value);
						if(node && node.hasOwnProperty("selectedIndex") && !isNaN(index) && (index >= 0)) {
							node.selectedIndex = index;
							returnVal = "true";
						}
						(node as UIComponent).dispatchEvent(new ListEvent(ListEvent.CHANGE,false,false,-1,index)); 
						break;
					
					case "flexWaitForElement":
						returnVal = "true";
						break;
					
					case "flexMenuSelected":
						if(node is MenuBar) {
							returnVal = flexMenuItemOver(node as MenuBar, value).toString();							
						}
						break;
				}
			} else if(command == "flexWaitForElement"){
				returnVal = waitForElement(target, 1000);
			} else {
				returnVal = "Component with id " + target + " not found.";
			}
			
			return returnVal;
		}
		
		private function flexMenuItemOver(target:MenuBar, value:String):Boolean {
			var tokens:Array = value.split("/");
			var menuToken:Array = (tokens[1] as String).split(":");
			var menuData:String = menuToken[0];
			var menuField:String = menuToken[1];
			var menu:Menu = null;
			var index:int = -1;
			
			for(var menuBarItemIndex:int = 0; menuBarItemIndex < target.numChildren; menuBarItemIndex++) {
				var child:DisplayObject = target.getChildAt(menuBarItemIndex);
				if((child is MenuBarItem) && ((child as MenuBarItem).data[menuField] == menuData)) {					
					var menuBarItem:MenuBarItem = child as MenuBarItem;
					menu = target.getMenuAt((menuBarItem).menuBarItemIndex);
					menuBarItem.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false));
					
					if(menu.dataDescriptor.isBranch(menuBarItem.data,menuBarItem.data) &&
						menu.dataDescriptor.hasChildren(menuBarItem.data,menuBarItem.data) &&
						!menu.visible) {
						child.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false));
					}
					break;
				}
			}
			
			if(menuBarItemIndex == target.numChildren) {
				return false;
			}
			
			if(menu && (tokens.length > 2)) {
				var menuItemRenderer:UIComponent = null;
				
				for(var menuTokenIndex:int = 2; menuTokenIndex < tokens.length; menuTokenIndex++) {
					menuToken = (tokens[menuTokenIndex] as String).split(":");
					menuData = menuToken[0];
					menuField = menuToken[1];
					index = -1;

					var collection:ICollectionView = menu.dataProvider as ICollectionView;
					var iviewCursor:IViewCursor = collection.createCursor();					
					
					while(iviewCursor.current) {
						index ++;
						var data:Object = iviewCursor.current;
						if(data[menuField] == menuData) {
							menuItemRenderer = menu.indexToItemRenderer(index) as MenuItemRenderer;
							//Is this not the last token?
							if(menuTokenIndex != (tokens.length - 1)) {								
								menu.openSubMenu(menuItemRenderer as IListItemRenderer);
								menu = (menuItemRenderer as IMenuItemRenderer).menu;
							}
							
							break;
						}
						iviewCursor.moveNext();
					}
					
					if(iviewCursor.afterLast) {
						return false;
					}
				}
				(menuItemRenderer as MenuItemRenderer).getLabel().dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER,true,false,1,1));
				(menuItemRenderer as MenuItemRenderer).getLabel().dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP,true,false,1,1));
			} else if(tokens.length > 2) {
				return false;
			}
			
			return true;
		}
		
		private function waitForElement(target:String, timeOut:int):String {
			var currTime:Number = new Date().time;
			var breakTime:Number = currTime + timeOut;
			
			while((breakTime - currTime) >= 0) {
				var node:Object = AppTreeParser.getNode(sysManager,target);
				if(node) {
					break;
				}
				currTime = new Date().time;
			}
			
			if(node) {
				return "true";
			} else {
				return "Component with id " + target + " not found.";
			}
		}
	}
}