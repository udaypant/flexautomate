package com.uday.automate
{
	import com.uday.automate.playback.PlayBack;
	import com.uday.automate.record.Recorder;
	
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.managers.SystemManager;

	[Mixin]
	public class FlexAutomate
	{
		private static var sysManager:SystemManager = null;
		private static var instance:FlexAutomate;
		public static var recorder:Recorder;
		public static var playback:PlayBack;
		
		public function FlexAutomate() {
			FlexAutomate.sysManager.addEventListener(FlexEvent.APPLICATION_COMPLETE, appCreationComplete);
		}
	
		public static function init(sysm:SystemManager):void {
			FlexAutomate.sysManager = sysm as SystemManager;
			instance = new FlexAutomate();			
			playback = new PlayBack(sysm);
			recorder = new Recorder(sysm);
		}
		
		private function appCreationComplete(event:FlexEvent):void {
			recorder.processSysManager();
		}
		
		public static function getInstance():FlexAutomate {
			return instance;
		}
	}
}
