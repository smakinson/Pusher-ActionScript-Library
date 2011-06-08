package com.pusher.channel{
	
	import com.pusher.Pusher;
	import com.pusher.PusherConstants;
	
	import flash.utils.Dictionary;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * This is an open channel of communication for pusher.
	 */
	public class Channel{
		
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
		 * Sends the given event with the given data to Pusher over this channel.
		 *  
		 * @param eventName The name of the event. Include prefix in 
		 * 									the name for client events.
		 * @param data The data to send with the event.
		 * @return The Channel instance.
		 */		
		public function trigger(eventName:String, data:Object):Channel{
			pusher.sendEvent(eventName, data, name);
			return this;
		}
		
		/**
		 * Convenience method for sending client events.
		 * Sends the given event with the given data to Pusher over this channel.
		 *  
		 * @param eventName The name of the event without the client event prefix.
		 * @param data The data to send with the event.
		 * @return The Channel instance.
		 */		
		public function triggerClient(eventName:String, data:Object):Channel{
			return trigger(PusherConstants.CLIENT_EVENT_NAME_PREFIX + eventName, data);
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
		}
		
		/**
		 * @private
		 */
		public function dispatchWithAll(eventName:String, data:Object):void{
			if(! global){
				Pusher.log("Pusher : event recd (channel,event,data)", name, eventName, data);
			}
			dispatch(eventName, data);
			dispatchGlobalCallbacks(eventName, data);
		}
		
		protected function dispatchGlobalCallbacks(eventName:String, data:Object):void{
			var callback:Function;
			for(var i:int = 0; i < globalCallbacks.length; i++){
				callback = globalCallbacks[i] as Function;
				if(callback != null)
					callback(eventName, data);
			}
		}
		
		/** 
		 * @inheritDoc
		 */		
		public function toString():String{
			return "[Channel " + name + "]";
		}
	}
}

