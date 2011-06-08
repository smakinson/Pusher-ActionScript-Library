package com.pusher.data{
	
	public interface IDataDecorator{
		
		/**
		 * Does some work on the given event and data.
		 * 
		 * @param eventName Then name of the event to decorate.
		 * @param eventData The event data to decorate.
		 * @return The decorated data.
		 */		
		function decorate(eventName:String, eventData:Object):Object;
	}
}