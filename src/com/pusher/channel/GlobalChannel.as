package com.pusher.channel{
	
	import com.pusher.Pusher;
	
	import flash.events.Event;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * A normal pusher channle marked as global.
	 */
	public class GlobalChannel extends Channel{
		
		static public const GLOBAL_CHANNEL_NAME:String = "pusher_global_channel";
		
		override public function get global():Boolean{
			return true;
		}
		
		public function GlobalChannel(pusher:Pusher=null){
			super(GLOBAL_CHANNEL_NAME, pusher);
		}
	}
}