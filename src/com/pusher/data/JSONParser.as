package com.pusher.data{
	
	import com.pusher.Pusher;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * Parses incoming data as JSON. This is the default parser for Pusher.
	 * Relies on as3corlib for handling JSON.
	 */
	public class JSONParser implements IDataParser{
		
		/** 
		 * @inheritDoc
		 */		
		public function parse(data:String):*{
			try{
				return JSON.parse(data);
			}catch(err:Error){
				Pusher.log("Pusher : data attribute not valid JSON - you may wish to implement your own Pusher.parser");
				return data;
			}
		}
	}
}