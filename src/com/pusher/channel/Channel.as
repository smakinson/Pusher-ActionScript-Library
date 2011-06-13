package com.pusher.channel{
	
	import com.pusher.Pusher;
	import com.pusher.PusherConstants;
	import com.pusher.events.PusherEvent;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * This is an open channel of communication for pusher.
	 */
	public class Channel extends EventDispatcher{
		
		/**
		 * Set this to dispatch events even if addEventListener has not been called directly.
		 * If this is set then its assumed you want the events to bubble as well.
		 */
		public var eventDispatcher:EventDispatcher;
		
		protected var _name:String = "";
		public function get name():String{
			return _name;
		}
		
		public function get isPrivate():Boolean{
			return false;
		}
		
		public function get isPresence():Boolean{
			return false;
		}
		
		public function get global():Boolean{
			return false;
		}
		
		protected var _subscribed:Boolean = false;
		public function get subscribed():Boolean{
			return _subscribed;
		}
		
		protected var pusher:Pusher;
		protected var callbacks:Dictionary;
		protected var globalCallbacks:Array;
		
		/**
		 * A basic Pusher channel.
		 *  
		 * @param channelName The name of the channel you are creating.
		 * @param pusher Optional pusher instance that did it.
		 */		
		public function Channel(channelName:String, pusher:Pusher = null){
			_name = channelName;
			this.pusher = pusher;
			
			callbacks = new Dictionary();
			globalCallbacks = [];
		}
		
		/**
		 * Use this to create a properly typed channel.
		 * 
		 * @param channelName The name of the channel you are creating.
		 * @param pusher Optional pusher instance that did it.
		 * @return The new Channel instance.
		 */		
		static public function factory(channelName:String, pusher:Pusher=null):Channel{
			var channel:Channel;
			
			if(channelName.indexOf(PusherConstants.CHANNEL_NAME_PRIVATE_PREFIX) === 0){
				channel = new PrivateChannel(channelName, pusher);
			}else if(channelName.indexOf(PusherConstants.CHANNEL_NAME_PRESENCE_PREFIX) === 0){
				channel = new PresenceChannel(channelName, pusher);
			}else{
				channel = new Channel(channelName, pusher);
			}
			
			return channel;
		}
		
		/**
		 * @private
		 */		
		public function authorize(pusher:Pusher, callback:Function):void{
			callback({}); // normal channels don't require auth
		}
		
		/**
		 * Creates a callback for specific Pusher events through this channel.
		 * 
		 * @param eventName The name of the event to run the callback for.
		 * @param callback The callback function to run.
		 * @return The Channel instance. 
		 */	
		public function bind(eventName:String, callback:Function):Channel{
			callbacks[eventName] = callbacks[eventName] || [];
			callbacks[eventName].push(callback);
			return this;
		}
		
		/**
		 * Creates a callback for specific Pusher events through this channel.
		 * 
		 * @param eventName The name of the event to run the callback for WITHOUT THE CLIENT EVENT PREFIX, it is prepended automatically.
		 * @param callback The callback function to run.
		 * @return The Channel instance. 
		 */	
		public function bindToClient(eventName:String, callback:Function):Channel{
			eventName = PusherConstants.CLIENT_EVENT_NAME_PREFIX + eventName;
			callbacks[eventName] = callbacks[eventName] || [];
			callbacks[eventName].push(callback);
			return this;
		}
		
		/**
		 * Creates a callback that runs for all Pusher events on this channel.
		 * 
		 * @param callback The callback function to run.
		 * @return The Channel instance.
		 */	
		public function bindAll(callback:Function):Channel{
			globalCallbacks.push(callback);
			return this;
		}
		
		/**
		 * Disconnects from Pusher.
		 */		
		public function disconnect():void{
			// Javascript lib had nothing to port.
		}
		
		/**
		 * Activate after successful subscription. Called on top-level pusher:subscription_succeeded.
		 */
		protected function acknowledgeSubscription(data:Object):void{
			_subscribed = true;
		}
		
		/**
		 * @private
		 */
		public function dispatch(eventName:String, data:Object):void{
			var callbacks:Array = this.callbacks[eventName] as Array;
						
			if(callbacks){
				for(var i:uint = 0; i < callbacks.length; i++){
					callbacks[i](data);
				}
			}else{
				Pusher.log('Pusher : No callbacks for ' + eventName);
			}
			
			if(! global){
				// See if events need to be dispatched as well.
				// Direct listeners.
				if(hasEventListener(eventName)){
					// Bubbles only if one of the other eventDispatcher options has been set to this for some reason.
					dispatchEvent(new PusherEvent(eventName, data, (eventDispatcher ==  this || Pusher.eventDispatcher == this)));
				}
				
				// Indirect listeners. These bubble.
				if(eventDispatcher && eventDispatcher != this){
					eventDispatcher.dispatchEvent(new PusherEvent(eventName, data, true));
				}else if(Pusher.eventDispatcher && Pusher.eventDispatcher != this){
					Pusher.eventDispatcher.dispatchEvent(new PusherEvent(eventName, data, true));
				}
			}
		}
		
		/**
		 * @private
		 */
		public function dispatchWithAll(eventName:String, data:Object):void{
			if(! global){
				Pusher.log("Pusher : event recd (channel,event,data) : " + name + ", " + eventName + ", " + data);
			}
			dispatch(eventName, data);
			dispatchGlobalCallbacks(eventName, data);
		}
		
		/**
		 * @private
		 */
		protected function dispatchGlobalCallbacks(eventName:String, data:Object):void{
			var callback:Function;
			for(var i:int = 0; i < globalCallbacks.length; i++){
				callback = globalCallbacks[i] as Function;
				if(callback != null)
					callback(eventName, data);
			}
		}
		
		/**
		 * Sends the given event with the given data to Pusher over this channel.
		 *  
		 * @param eventName The name of the event WITHOUT THE CLIENT EVENT PREFIX, it is prepended automatically.
		 * @param data The data to send with the event.
		 * @return The Channel instance.
		 */		
		public function trigger(eventName:String, data:Object):Channel{
			throw new Error("Currently the basic Channel does not support trigger calls.");
		}
		
		/** 
		 * @inheritDoc
		 */		
		override public function toString():String{
			return "[Channel " + name + "]";
		}
	}
}

