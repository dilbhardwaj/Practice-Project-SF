public class RevenueLineTriggerHandler {
    public static void handleInsert(Map<Id,Revenue_Line__c> revenueLineNewMap){
        Set<Id> oppIdAffected=new Set<Id>();
        for(Revenue_Line__c revLine:revenueLineNewMap.values()){
            if(revLine.Opportunity__c!=null){
                oppIdAffected.add(revLine.Opportunity__c);
            }
        }
        if(!oppIdAffected.isEmpty()){
                    RevenueLineTriggerHandlerHelper.recalculate(oppIdAffected);
        }
    }
    public static void handleUpdate(List<Revenue_Line__c> revenueLinenewList,Map<Id,Revenue_Line__c> revenueLineOldMap){
        Set<Id> oppIdAffected=new Set<Id>();
        for(Revenue_Line__c revLine:revenueLinenewList){
            Revenue_Line__c oldRevLine=revenueLineOldMap.get(revLine.Id);
            if(oldRevLine.Amount__c!=revLine.Amount__c && revLine.Amount__c!=null ){
                oppIdAffected.add(revLine.Opportunity__c);
            }
            if(oldRevLine.Stage__c!=revLine.Stage__c  ){
                oppIdAffected.add(revLine.Opportunity__c);
            }
             if(oldRevLine.Month__c!=revLine.Month__c  ){
                oppIdAffected.add(revLine.Opportunity__c);
            }
            if(oldRevLine.Opportunity__c!=revLine.Opportunity__c){
                oppIdAffected.add(oldRevLine.Opportunity__c);
                oppIdAffected.add(revLine.Opportunity__c);
            }
        }
 			if(!oppIdAffected.isEmpty()){
                    RevenueLineTriggerHandlerHelper.recalculate(oppIdAffected);
        } 
    }
    public static void handleDelete(Map<Id,Revenue_Line__c> revenueLineOldMap){
        Set<Id> oppIdAffected=new Set<Id>();
        for(Revenue_Line__c revLine:revenueLineOldMap.values()){
            if(revLine.Opportunity__c!=null){
                oppIdAffected.add(revLine.Opportunity__c);
            }
        }
 if(!oppIdAffected.isEmpty()){
                    RevenueLineTriggerHandlerHelper.recalculate(oppIdAffected);
        }    }
}