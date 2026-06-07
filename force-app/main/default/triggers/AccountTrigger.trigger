trigger AccountTrigger on Account (before insert,after insert) {
	 if(Trigger.isBefore){
        if(Trigger.isInsert ){
            AccountTriggerHandler.GrandparentHandler(Trigger.new);
        }
    }
    
     if(Trigger.isAfter){
        if(Trigger.isInsert ){
            AccountTriggerHandler.GrandChildHandler(Trigger.new);
        }
    }
}