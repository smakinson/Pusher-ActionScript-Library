package com.pusher{
	
	import com.pusher.auth.IAuthorizer;
	import com.pusher.channel.Channel;
	import com.pusher.channel.GlobalChannel;
	import com.pusher.channel.PresenceChannel;
	import com.pusher.channel.PrivateChannel;
	import com.pusher.data.IDataDecorator;
	import com.pusher.data.IDataParser;
	import com.pusher.data.JSONParser;
	
	import flash.events.EventDispatcher;
	import flash.system.Security;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * An ActionScript implementation of the JavaScript Pusher library.
	 * Wraps the WebSocket library ( https://github.com/y8/websocket-as ) that is used as a fallback in JavaScript.
	 * Currently relies on as3corelib for JSON parsing.
	 */
	public class Pusher{
		
		static public const VERSION:String = "1.8.3";
		static protected const STANDARD_PORT:int = 80;
		static protected const SECURE_PORT:int = 443;
		static protected const HOST:String = "ws.pusherapp.com";
		
		/**
		 * The number of milliseconds to wait before timing out when trying to connect. 
		 */		
		static public var connectionTimeout:int = 5000;
		
		/**
		 * Set this to true to see what the WebSocket logs as well as Pushers logs. 
		 */		
		static public var enableWebSocketLogging:Boolean = false;
		
		/**
		 * Set this to have channels dispatch events even if
		 * addEventListener has not been called directly on that channel.
		 * If this is set then its assumed you want the events to bubble as well.
		 * You can override this on a per channel basis if desired.
		 * If you want to catch events all over the place you could set this to the stage.
		 */
		static public var eventDispatcher:EventDispatcher;
		
		static protected var webSocketNextId:int = 0;
		static protected var allowReconnect:Boolean = true;
		static protected var policyFileLoaded:Boolean = false;
		
		// Set these to override the defaults.
		static public var log:Function = defaultLogger;	// Set this to log as you prefer.
		static public var parser:IDataParser;
		static public var dataDecorator:IDataDecorator;
		
		// Set this to specify your auth endpoint for private and presence channels.
		static public var channelAuthEndpoint:String = "/pusher/auth";
		
		/**
		 * Used to authorize calls with your server. This must be set is private channels are used. 
		 */		
		static public var authorizer:IAuthorizer;
		
		protected var _socketId:String;
		public function get socketId():String{
			return _socketId;
		}
		
		protected var _key:String;
		public function get key():String{
			return _key;
		}
		
		protected var id:int;
		protected var options:Object;
		
		protected var retryCounter:int = 0;
		protected var retryTimeout:int;
		
		protected var globalChannel:GlobalChannel;
		protected var connection:WebSocket;
		protected var connectionTimeoutRef:int;
		protected var channels:Channels;
		protected var connectionPath:String;
		protected var origin:String = "";
		
		// A few things that get passed straight to websocket.
		protected var protocols:Array = [];
		protected var proxyHost:String = "";
		protected var proxyPort:int = 0;
		protected var headers:String = "";
		
		protected var _connected:Boolean = false;
		public function get connected():Boolean{
			return _connected;
		}
		
		protected var _connecting:Boolean = false;
		public function get connecting():Boolean{
			return _connecting;
		}
		
		// Options that can be passed in via the constructor.
		protected var _encrypted:Boolean = false;
		public function get encrypted():Boolean{
			return _encrypted;
		}
		
		protected var _secure:Boolean = false;
		public function get secure():Boolean{
			return _secure;
		}		
		
		/**
		 * @param applicationKey Your key from your pusher account
		 * @param origin Indicates where you are conecting from, generally a url.
		 * @param options An optional object containing some connection options, etc.
		 * 								Currently they can be: 
		 * 									secure: true/false
		 * 									encrypted: true/false
		 * 									protocols: An array of protocols for the connection. See https://github.com/y8/websocket-as for more info.
		 * 									proxyHost: A proxy host to be used when connecting. See https://github.com/y8/websocket-as for more info.
		 * 									proxyPort: A proxy port to be used when connecting. See https://github.com/y8/websocket-as for more info.
		 * 									headers: Headers to send when connecting. See https://github.com/y8/websocket-as for more info.
		 * @param connect An optional param to prevent immediate connecting if desired.
		 */		
		public function Pusher(applicationKey:String, origin:String, options:Object = null, connect:Boolean = true){
			
			id = webSocketNextId++;
			
			if(! policyFileLoaded){
				Security.loadPolicyFile("xmlsocket://ws.pusherapp.com:843/crossdomain.xml");
				policyFileLoaded = true;
			}
			
			if(! parser)parser = new JSONParser();
			if(! dataDecorator)dataDecorator = new DefaultDataDecorator();
			
			this.options = options || {};
			
			// TODO: Maybe someday the client might need to be specified as something other than js.
			connectionPath = '/app/' + applicationKey + "?client=js&version=" + VERSION;
			_key = applicationKey;
			
			this.origin = origin;
						
			channels = new Channels();
			globalChannel = new GlobalChannel();
			_encrypted = this.options.encrypted ? true : false;
			_secure = this.options.secure ? true : false;
			
			if(this.options.hasOwnProperty("protocols"))protocols = this.options.protocols as Array;
			if(this.options.hasOwnProperty("proxyHost"))proxyHost = this.options.proxyHost;
			if(this.options.hasOwnProperty("proxyPort"))proxyPort = parseInt(this.options.proxyPort);
			if(this.options.hasOwnProperty("headers"))headers = this.options.headers;
			
			if(connect)
				this.connect();
			
			// This is the new namespaced version.
			bind(PusherConstants.CONNECTION_ESTABLISHED_EVENT_NAME, onPusherConnectionEstablished);
			bind(PusherConstants.CONNECTION_DISCONNECTED_EVENT_NAME, onPusherDisconnected);
			bind(PusherConstants.ERROR_EVENT_NAME, onPusherError);
		}
		
		static protected function defaultLogger(msg:String):void{}
		
		/**
		 * Finds a channel by name.
		 * 
		 * @param channelName The name of the channel you want.
		 * @return The channel.
		 */		
		public function channel(channelName:String):Channel{
			return channels.find(channelName);
		}
		
		/**
		 * Connects to Pusher.
		 */		
		public function connect():void{
			
			if(connected || connecting)return;
			
			_connecting = true;
			
			if(retryTimeout)clearTimeout(retryTimeout);
			if(connectionTimeoutRef)clearTimeout(connectionTimeoutRef);
				
			var url:String;
			
			if(encrypted || _secure){
				url = "wss://" + HOST + ":" + SECURE_PORT + connectionPath;
			}else{
				url = "ws://" + HOST + ":" + STANDARD_PORT + connectionPath;
			}
			
			allowReconnect = true;
			log('Pusher : connecting : ' + url);
			
			connection = new WebSocket(id, url, protocols, origin, proxyHost, proxyPort, "", headers, new WebSocketLogger());
			
			// Timeout for the connection to handle silently hanging connections.
			// Increase the timeout after each retry in case of extreme latencies.
			var timeout:int = connectionTimeout + (retryCounter * 1000);
			
			connectionTimeoutRef = setTimeout(function():void{
				log('Pusher : connection timeout after ' + timeout + 'ms');
				connection.close();
			}, timeout);
			
			connection.addEventListener(WebSocketEvent.OPEN, onSocketConnect);
			connection.addEventListener(WebSocketEvent.CLOSE, onSocketClose);
			connection.addEventListener(WebSocketEvent.ERROR, onSocketError);
			connection.addEventListener(WebSocketEvent.MESSAGE, onSocketMessage);
		}
		
		/**
		 * Disconnects from Pusher.
		 */		
		public function disconnect():void{
			if(retryTimeout)clearTimeout(retryTimeout);
			if(connectionTimeoutRef)clearTimeout(connectionTimeoutRef);
			
			log('Pusher : disconnecting');
			allowReconnect = false;
			retryCounter = 0;
			connection.close();
		}
		
		/**
		 * @private
		 */
		protected function reconnect():void{
			connect();
		}
		
		/**
		 * @private
		 */
		protected function retryConnect():void{
			// Unless we're ssl only, try toggling between ws & wss
			if(! encrypted){
				toggleSecure();
			}
			
			// Retry with increasing delay, with a maximum interval of 10s
			var retryDelay:int = Math.min(retryCounter * 1000, 10000);
			
			log("Pusher : Retrying connection in " + retryDelay + "ms");
			
			if(retryTimeout)clearTimeout(retryTimeout);
			setTimeout(connect, retryDelay);
			retryCounter++;
		}
		
		/**
		 * Creates a callback for specific Pusher events on all channels.
		 * 
		 * @param eventName The name of the event to run the callback for.
		 * @param callback The callback function to run.
		 * @return The Pusher instance. 
		 */		
		public function bind(eventName:String, callback:Function):Pusher{
			globalChannel.bind(eventName, callback);
			return this;
		}
		
		/**
		 * Creates a callback that runs for all Pusher events on all channels.
		 * 
		 * @param callback The callback function to run.
		 * @return The Pusher instance.
		 */		
		public function bindAll(callback:Function):Pusher{
			globalChannel.bindAll(callback);
			return this;
		}
		
		/**
		 * Creates a channel with the given name.
		 * 
		 * @param channelName The name of your channel. Include prefix in 
		 * 										the name for private and presence, or use the 
		 * 										convenience methods.
		 * @return The new Channel instance.
		 */		
		public function subscribe(channelName:String):Channel{
			var channel:Channel = channels.add(channelName, this);
			
			if(connected){
				channel.authorize(this, function(data:Object):void{
					sendEvent(PusherConstants.SUBSCRIBE_EVENT_NAME, {
						channel: channelName,
						auth: data.auth,
						channel_data: data.channel_data
					});
				});
			}
			return channel;
		}
		
		/**
		 * Convenience method for making private channels.
		 * 
		 * @param channelName The channel name without the private prefix.
		 * @return The channel.
		 */		
		public function subscribeAsPrivate(channelName:String):PrivateChannel{
			return subscribe(PusherConstants.CHANNEL_NAME_PRIVATE_PREFIX + channelName) as PrivateChannel;			
		}
		
		/**
		 * Convenience method for making presence channels.
		 * 
		 * @param channelName The channel name without the presence prefix.
		 * @return The channel.
		 */		
		public function subscribeAsPresence(channelName:String):PresenceChannel{
			return subscribe(PusherConstants.CHANNEL_NAME_PRESENCE_PREFIX + channelName) as PresenceChannel;			
		}
		
		/**
		 * @private
		 */	
		protected function subscribeAll():void{
			for each(var channel:Channel in channels.channels){
				subscribe(channel.name);
			}
		}
		
		/**
		 * Stops the communications on a previously subscribed channel.
		 * 
		 * @param channelName The name of the channel.
		 */		
		public function unsubscribe(channelName:String):void{
			channels.remove(channelName);
			
			if(connected){
				sendEvent(PusherConstants.UNSUBSCRIBE_EVENT_NAME, {
					channel: channelName
				});
			}
		}
		
		/**
		 * @private
		 * @param eventName The name of the event.
		 * @param data The data to send with the event.
		 * @param channelName Optional name of the channel to send over.
		 * @return The Pusher instance.
		 */
		public function sendEvent(eventName:String, data:Object, channelName:String = ""):Pusher{
			log("Pusher : event sent (channel,event,data) : " + channelName + ", " + eventName + ", " + data);
			
			var payload:Object = {
				event: eventName,
				data: data
			}
			
			if(channelName && channelName.length > 0){
				payload['channel'] = channelName;
			}
			
			connection.send(JSON.stringify(payload));
			return this;
		}
		
		/**
		 * @private
		 * @param eventName The name of the event.
		 * @param data The data to send with the event.
		 * @param channelName Optional name of the channel to send over.
		 * @return The Pusher instance.
		 */
		protected function sendLocalEvent(eventName:String, data:Object, channelName:String = ""):void{
			data = dataDecorator.decorate(eventName, data);
			
			if(channelName && channelName.length > 0){
				var channel:Channel = channel(channelName);
				
				if(channel){
					channel.dispatchWithAll(eventName, data);
				}
			}else{
				// Bit hacky but these events won't get logged otherwise
				log("Pusher : event recd (event,data) : " + eventName + "," + data);
			}
			
			globalChannel.dispatchWithAll(eventName, data);
		}
		
		/**
		 * @private
		 */
		protected function toggleSecure():void{
			log((_secure ? "Pusher : switching to standard connection" : "Pusher : switching to secure connection"));
			_secure = !_secure;
		}
		
		/**
		 * @private
		 */
		protected function onSocketConnect(e:WebSocketEvent):void{
			if(retryTimeout)clearTimeout(retryTimeout);
			if(connectionTimeoutRef)clearTimeout(connectionTimeoutRef);
			log('Pusher : Connected');
			globalChannel.dispatch('open', null);
		}
		
		/**
		 * @private
		 */
		protected function onSocketClose(e:WebSocketEvent = null):void{
			if(retryTimeout)clearTimeout(retryTimeout);
			if(connectionTimeoutRef)clearTimeout(connectionTimeoutRef);
			
			globalChannel.dispatch('close', null);
			
			log("Pusher : Socket closed");
			
			if(connected){
				sendLocalEvent(PusherConstants.CONNECTION_DISCONNECTED_EVENT_NAME, {});
				
				if(allowReconnect){
					log('Pusher : Connection broken, trying to reconnect');
					reconnect();
				}
			}else{
				sendLocalEvent(PusherConstants.CONNECTION_FAILED_EVENT_NAME, {});
				retryConnect();
			}
			
			_connected = false;
			_connecting = false;
		}
		
		/**
		 * @private
		 */
		protected function onSocketError(e:WebSocketEvent):void{
			onSocketClose();
		}
		
		/**
		 * @private
		 */
		protected function onSocketMessage(e:WebSocketEvent):void{
			var params:Object;
			
			try{
				params = JSON.parse(decodeURIComponent(e.message));
			}catch(err:Error){
				log('Pusher : Error getting message data');
			}
			
			if(params.socket_id && params.socket_id == socketId) return;
			
			// Try to parse the event data unless it has already been decoded.
			if(params.data is String){
				params.data = parser.parse(params.data);
			}
			// log("Pusher : received message : " + params)
			
			sendLocalEvent(params.event, params.data, params.channel);
		}
		
		/**
		 * @private
		 */
		protected function onPusherConnectionEstablished(data:Object):void{
			_connected = true;
			_connecting = false;
			retryCounter = 0;
			_socketId = data.socket_id;
			subscribeAll();
		}
		
		/**
		 * @private
		 */
		protected function onPusherDisconnected(data:Object):void{
			log("Pusher : Disconnected");
			for each(var channel:Channel in channels.channels){
				channel.disconnect();
			}
		}
		
		/**
		 * @private
		 */
		protected function onPusherError(data:Object):void{
			log("Pusher : error : " + data.message);
		}
		
		/** 
		 * @inheritDoc
		 */	
		public function toString():String{
			return "[Pusher " + socketId + "]";
		}
	}
}

// A few things that only this class uses.

import com.pusher.Pusher;
import com.pusher.channel.Channel;
import com.pusher.data.IDataDecorator;
import com.pusher.data.IDataParser;

import flash.utils.Dictionary;

/**
 * Uses same log function as Pusher for websocket logs and errors.
 */
internal class WebSocketLogger implements IWebSocketLogger{
	
	public function log(message:String):void{
		if(Pusher.enableWebSocketLogging)Pusher.log(message);
	}
	
	public function error(message:String):void{
		Pusher.log(message);
	}
}

/**
 * Holds the list of pusher channels.
 */
internal class Channels{
	
	protected var _channels:Dictionary;
	public function get channels():Dictionary{
		return _channels;
	}
	
	public function Channels(){
		_channels = new Dictionary();
	}
	
	public function add(channelName:String, pusher:Pusher):Channel{
		
		var existingChannel:Channel = find(channelName);
		
		if(! existingChannel){
			var channel:Channel = Channel.factory(channelName, pusher);
			_channels[channelName] = channel;
			return channel;
		}else{
			return existingChannel;
		}
	}
	
	public function find(channelName:String):Channel{
		if(_channels.hasOwnProperty(channelName)){
			return _channels[channelName];
		}
		return null;
	}
	
	public function remove(channelName:String):void{
		if(_channels.hasOwnProperty(channelName)){
			delete _channels[channelName];
		}
	}
}

internal class DefaultDataDecorator implements IDataDecorator{
	
	public function decorate(eventName:String, eventData:Object):Object{
		return eventData;
	}
}
