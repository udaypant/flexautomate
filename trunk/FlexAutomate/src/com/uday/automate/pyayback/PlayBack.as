package com.uday.automate.pyayback
{
	import flash.external.ExternalInterface;
	
	import mx.controls.Alert;
	import mx.managers.SystemManager;

	public class PlayBack
	{
		public function PlayBack(sysm:SystemManager)
		{
			if(ExternalInterface.available) {
				ExternalInterface.addCallback("playBack", playback);
			}
		}
		
		private function playback(target:String, value:String):void {
			Alert.show(target + ":" +  value);
		}
	}
}