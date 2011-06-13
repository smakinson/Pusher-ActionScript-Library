package com.pusher.channel{
	
	import com.pusher.Pusher;
	import com.pusher.PusherConstants;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * A private Pusher channel that requires authorization.
	 */
	public class PrivateChannel extends Channel{
		
		/** 
		 * @inheritDoc
		 */
		override public function get isPrivate():Boolean{
			return true;
		}
		
		/** 
		 * @inheritDoc
		 */
		public function PrivateChannel(channelName:String, pusher:Pusher=null){
			super(channelName, pusher);
		}
		
		/**
		 * @private
		 */	
		override public function authorize(pusher:Pusher, callback:Function):void{
			try{
				Pusher.authorizer.authorize(pusher, this, callback);
			}catch(err:Error){
				throw new Error("Pusher : Error, you tried to use a private channel without setting Pusher.authorizer");
			}
		}
		
		/** 
		 * @inheritDoc
		 */		
		override public function trigger(eventName:String, data:Object):Channel{
			pusher.sendEvent(PusherConstants.CLIENT_EVENT_NAME_PREFIX + eventName, data, name);
			return this;
		}
		
		/** 
		 * @inheritDoc
		 */		
		override public function toString():String{
			return "[PrivateChannel " + name + "]";
		}
	}
}