package com.pusher{
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * Contains constants related to working with Pusher.
	 */
	public final class PusherConstants{
		
		static public const CHANNEL_NAME_PRIVATE_PREFIX:String = "private-";
		static public const CHANNEL_NAME_PRESENCE_PREFIX:String = "presence-";
		
		/**
		 * @private
		 * The end user should not need to use this prefix since the methods auto prepend it. 
		 */		
		static public const CLIENT_EVENT_NAME_PREFIX:String = "client-";
		
		static public const CONNECTION_ESTABLISHED_EVENT_NAME:String = "pusher:connection_established";
		static public const CONNECTION_DISCONNECTED_EVENT_NAME:String = "pusher:connection_disconnected";
		static public const CONNECTION_FAILED_EVENT_NAME:String = "pusher:connection_failed";
		static public const ERROR_EVENT_NAME:String = "pusher:error";
		
		static public const SUBSCRIPTION_SUCCEEDED_EVENT_NAME:String = "pusher:subscription_succeeded";
		static public const MEMBER_ADDED_EVENT_NAME:String = "pusher:member_added";
		static public const MEMBER_REMOVED_EVENT_NAME:String = "pusher:member_removed";
		
		// End user should not need these since they can call methods that use these.
		static public const SUBSCRIBE_EVENT_NAME:String = "pusher:subscribe";
		static public const UNSUBSCRIBE_EVENT_NAME:String = "pusher:unsubscribe";
	}
}