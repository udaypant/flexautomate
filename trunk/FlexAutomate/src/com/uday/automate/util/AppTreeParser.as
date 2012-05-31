package com.uday.automate.util
{
	import flash.utils.Dictionary;
	
	import mx.core.IChildList;

	public class AppTreeParser
	{
		public function AppTreeParser()
		{
		}
		
		public static function parseUiTree(sysManager:IChildList, nodeProcessor:Function, param:Object):IChildList {
			var currNode:IChildList = sysManager;
			var stack:Array = [currNode];
			
			while(stack.length > 0) {
				currNode = stack.pop();
				if(nodeProcessor(currNode,param)) {
					break;
				}
				
				for(var childIndex:int = 0; childIndex < currNode.numChildren; childIndex++) {
					var childNode:Object = currNode.getChildAt(childIndex);
					
					if(childNode is IChildList) {
						stack.push(childNode);
					}
				}
			}
			
			return currNode;
		}
		
		public static function getNode(sysManager:IChildList, identifier:String):Object {
			var splitId:Array = identifier.split("/");
			var currNode:IChildList = sysManager;
			
			for(var idIndex:int = 0; idIndex < splitId.length; idIndex++) {
				if(splitId[idIndex] == "") {
					continue;
				}
				var stack:Array = [currNode];
				var singleId:Array = splitId[idIndex].split(":");
				var foundNode:Boolean = false;
				
				if(singleId.length == 1) {
					singleId.push("id");
				}
				
				while(stack.length > 0) {
					currNode = stack.pop();
					if((currNode is Object) && (currNode as Object).hasOwnProperty(singleId[1]) && currNode[singleId[1]] &&
						(currNode[singleId[1]].toString() == singleId[0].toString())) {
						foundNode = true;
						break;
					}
					
					for(var childIndex:int = 0; childIndex < currNode.numChildren; childIndex++) {
						var childNode:Object = currNode.getChildAt(childIndex);
						
						if(childNode is IChildList) {
							stack.push(childNode);
						}
					}
				}
				
				if(foundNode && (idIndex == (splitId.length - 1))) {
					return currNode;
				}
			}
			
			return null;
		}
	}
}