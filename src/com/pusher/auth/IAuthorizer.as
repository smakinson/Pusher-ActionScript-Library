package com.pusher.auth{
	
	import com.pusher.Pusher;
	import com.pusher.channel.Channel;
	
	public interface IAuthorizer{
		
		/**
		 * Sends a request to authorize the given communication instatnce.
		 * 
		 * @param pusher The Pusher instance used for authorizing.
		 * @param channel The Channel being authorized.
		 * @param callback The function to call after authorization.
		 */
		function authorize(pusher:Pusher, channle:Channel, callback:Function):void;
	}
}