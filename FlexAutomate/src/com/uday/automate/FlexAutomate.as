package com.uday.automate
{
	import com.uday.automate.record.Recorder;
	
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.managers.SystemManager;

	[Mixin]
	public class FlexAutomate
	{
		private static var sysManager:SystemManager = null;
		private static var instance:FlexAutomate;
		private static var recorder:Recorder;
		
		public function FlexAutomate() {
			FlexAutomate.sysManager.addEventListener(FlexEvent.APPLICATION_COMPLETE, appCreationComplete);
		}
	
		public static function init(sysm:SystemManager):void {
			FlexAutomate.sysManager = sysm as SystemManager;
			instance = new FlexAutomate();			
		}
		
		private function appCreationComplete(event:FlexEvent):void {
			var app:Object = FlexAutomate.sysManager.getChildAt(0);
			recorder = new Recorder(FlexAutomate.sysManager);
		}
	}
}