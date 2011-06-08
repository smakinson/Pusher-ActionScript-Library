package com.pusher.auth{
	
	import com.pusher.Pusher;
	import com.pusher.channel.Channel;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * Handles basic channel authorization via post.
	 */
	public class PostAuthorizer implements IAuthorizer{
		
		protected var endPoint:String;
		
		/**
		 * @param endPoint The endpoint url to POST the authorization to.
		 */		
		public function PostAuthorizer(endPoint:String){
			this.endPoint = endPoint || Pusher.channelAuthEndpoint;
		}
		
		/**
		 * @inheritDoc
		 */		
		public function authorize(pusher:Pusher, channel:Channel, callback:Function):void{
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(endPoint);
			var postVars:URLVariables = new URLVariables();
			
			postVars.socket_id = pusher.socketId;
			postVars.channel_name = channel.name;
			
			request.method = URLRequestMethod.POST;
			request.data = postVars;
			
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onEndPointError);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onEndPointError);
			
			function onComplete(e:Event):void{
				var loader:URLLoader = e.target as URLLoader;
				var data:Object = Pusher.parser.parse(loader.data);
				
				removeListeners(loader);
				loader.removeEventListener(Event.COMPLETE, onComplete);
				callback(data);
			}
			
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.load(request);
		}
		
		protected function removeListeners(loader:URLLoader):void{
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onEndPointError);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onEndPointError);
		}
		
		protected function onEndPointError(e:Event):void{
			removeListeners(e.target as URLLoader);
		}
	}
}