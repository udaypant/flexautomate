package com.uday.automate.pyayback
{
	import com.uday.automate.util.AppTreeParser;
	
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.managers.SystemManager;

	public class PlayBack
	{
		private var sysManager:SystemManager;
		
		public function PlayBack(sysm:SystemManager) {
			if(ExternalInterface.available) {
				ExternalInterface.addCallback("playBack", playback);
			}
			sysManager = sysm;
		}
		
		private function playback(command:String,target:String, value:String):String {
			var node:Object = AppTreeParser.getNode(sysManager,target);
			var returnVal:String = "";
			if(node) {
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
					
					case "flexWaitForElement":
						returnVal = "true";
						break;
				}
			} else if(command == "flexWaitForElement"){
				returnVal = waitForElement(target, 30);
			} else {
				returnVal = "Component with id " + target + " not found.";
			}
			
			return returnVal;
		}
		
		private function waitForElement(target:String, timeOut:int):String {
			while(timeOut > 0) {
				var node:Object = AppTreeParser.getNode(sysManager,target);
				if(node) {
					break;
				}
				timeOut--;
			}
			
			if(node) {
				return "true";
			} else {
				return "Component with id " + target + " not found.";
			}
		}
	}
}