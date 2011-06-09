package com.pusher.events{
	
	import flash.events.Event;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * An event to provide an alternative to binding an event callback.
	 * The event types for this event will be the same as the events the user creates.
	 */
	public class PusherEvent extends Event{
		
		public var data:Object;
		
		public function PusherEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
			this.data = data;
		}
		
		/** 
		 * @inheritDoc
		 */
		override public function clone():Event{
			return new PusherEvent(type, data, bubbles, cancelable);
		}
		
		/** 
		 * @inheritDoc
		 */		
		override public function toString():String{
			return "[PusherEvent " + type + "]";
		}
	}
}