package com.pusher.channel{
	
	import com.pusher.Pusher;
	
	
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
			Pusher.authorizer.authorize(pusher, this, callback);
		}
		
		/** 
		 * @inheritDoc
		 */		
		override public function toString():String{
			return "[PrivateChannel " + name + "]";
		}
	}
}