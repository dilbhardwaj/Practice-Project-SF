trigger DemoTrigger on Demo__c (after insert,after update) {
    if(Trigger.isAfter && Trigger.isInsert){
        //DemoTriggerHandler.handleInsert(Trigger.newMap);
    }
    if(Trigger.isAfter && Trigger.isUpdate){
       // DemoTriggerHandler.handleUpdate(Trigger.new,Trigger.oldMap);
    }
}