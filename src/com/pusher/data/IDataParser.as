package com.pusher.data{
	
	public interface IDataParser{
		
		/**
		 * Parses the given data string.
		 * 
		 * @param data The data string to parse.
		 * @return The parsed data.
		 * 
		 */		
		function parse(data:String):*;
	}
}