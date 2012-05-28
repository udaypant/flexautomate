package com.uday.automate.util
{
	import mx.core.IChildList;

	public class AppTreeParser
	{
		public function AppTreeParser()
		{
		}
		
		public static function parseUiTree(sysManager:IChildList, nodeProcessor:Function):void {
			var currNode:IChildList = sysManager;
			var stack:Array = [currNode];
			
			while(stack.length > 0) {
				currNode = stack.pop();
				nodeProcessor(currNode);
				
				for(var childIndex:int = 0; childIndex < currNode.numChildren; childIndex++) {
					var childNode:Object = currNode.getChildAt(childIndex);
					
					if(childNode is IChildList) {
						stack.push(childNode);
					}
				}
			}
		}
	}
}