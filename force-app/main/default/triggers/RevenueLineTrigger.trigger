trigger RevenueLineTrigger on Revenue_Line__c (after insert, after update, after delete,after undelete) {
    if(TriggerHelper.isTriggerExecuted){
        return;
    }
        TriggerHelper.isTriggerExecuted=true;
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                RevenueLineTriggerHandler.handleInsert(Trigger.newMap);
            }
            if(Trigger.isUpdate){
                RevenueLineTriggerHandler.handleUpdate(Trigger.New, Trigger.oldMap);
            }
            if(Trigger.isDelete){
                RevenueLineTriggerHandler.handleDelete(Trigger.oldMap);
            }
            if(Trigger.isUndelete){
                 RevenueLineTriggerHandler.handleInsert(Trigger.newMap);
            }
        }
    
    
}