package com.pusher.channel{
	
	import com.pusher.Pusher;
	import com.pusher.PusherConstants;
	
	
	/**
	 * @author Shawn Makinson, squareFACTOR, www.squarefactor.com
	 *
	 * PresenceChannel version of Channel. Used for creating groups of members in a channel.
	 */
	public class PresenceChannel extends PrivateChannel{
		
		protected var members:Members;
		
		/** 
		 * @inheritDoc
		 */
		public function PresenceChannel(channelName:String, pusher:Pusher=null){
			super(channelName, pusher);
			
			members = new Members();
			
			bind('pusher_internal:subscription_succeeded', onSubscriptionSucceeded);
			bind('pusher_internal:member_added', onSubscriptionMemberAdded);
			bind('pusher_internal:member_removed', onSubscriptionMemberRemoved);
		}
		
		/** 
		 * @inheritDoc
		 */		
		override public function disconnect():void{
			members.clear();
			super.disconnect();
		}
		
		/**
		 * @private
		 */	
		override protected function acknowledgeSubscription(data:Object):void{
			members._membersMap = data.presence.hash;
			members.count = data.presence.count;
			super.acknowledgeSubscription(data);
		}
		
		/**
		 * @private
		 */	
		protected function onSubscriptionSucceeded(data:Object):void{
			acknowledgeSubscription(data);
			dispatchWithAll(PusherConstants.SUBSCRIPTION_SUCCEEDED_EVENT_NAME, members);
		}
		
		/**
		 * @private
		 */	
		protected function onSubscriptionMemberAdded(data:Object):void{
			var member:Object = members.add(data.user_id, data.user_info);
			if(member){
				dispatchWithAll(PusherConstants.MEMBER_ADDED_EVENT_NAME, member);
			}
		}
		
		/**
		 * @private
		 */	
		protected function onSubscriptionMemberRemoved(data:Object):void{
			var member:Object = this.members.remove(data.user_id);
			if(member){
				dispatchWithAll(PusherConstants.MEMBER_REMOVED_EVENT_NAME, member);
			}
		}
		
		/** 
		 * @inheritDoc
		 */		
		override public function toString():String{
			return "[PresenceChannel " + name + "]";
		}
	}
}

/**
 * Internal members list. 
 */
internal class Members{
	
	public var _membersMap:Object = {};
	public var count:int = 0;
	
	public function eachItem(callback:Function):void{
		for(var i:Object in _membersMap){
			callback({
				id: i,
				info: _membersMap[i]
			});
		}
	}
	
	public function add(id:String, info:Object):Object{
		_membersMap[id] = info;
		count++;
		return get(id);
	}
	
	public function remove(userId:String):Object{
		var member:Object = get(userId);
		
		if(member){
			delete _membersMap[userId];
			count--;
		}
		return member;
	}
	
	public function get(userId:String):Object{
		var userInfo:Object = _membersMap[userId];
		
		if(userInfo){
			return {
				id: userId,
				info: userInfo
			}
		}else{
			return null;
		}
	}
	
	public function clear():void{
		_membersMap = {};
		count = 0;
	}
}