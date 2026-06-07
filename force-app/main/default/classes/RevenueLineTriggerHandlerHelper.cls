public class RevenueLineTriggerHandlerHelper {
    public static void recalculate(Set<Id> oppIdAffected){
        Map<Id,Decimal> oppIdVsTotalRevenue=new map<Id,Decimal>();
        Map<Id,Date> oppIdVsprojectedCloseMonth=new map<Id,Date>();
        Map<Id, Decimal> oppVsCancelledRevenue=new map<Id,Decimal>();

        for( AggregateResult ar:[select opportunity__c opp,Stage__c stage ,sum(amount__c) totalRevenue, max(Month__c) projectedCloseMonth 
                                                   from Revenue_Line__c where opportunity__c in:oppIdAffected group by opportunity__c,Stage__c ]){
    Id oppId = (Id) ar.get('opp');
    String stage = (String) ar.get('stage');                                                   
      Decimal amount =(Decimal) ar.get('totalRevenue');
        Date latestMonth =(Date) ar.get('projectedCloseMonth');       
           if(stage == 'Active'){
        oppIdVsTotalRevenue.put(oppId,amount);  
         oppIdVsprojectedCloseMonth.put(oppId,latestMonth);
}else if(stage == 'Cancelled'){
        oppVsCancelledRevenue.put(oppId,amount);
    }
                                                       
        
    }
        
        List<Opportunity> oppListToUpdate=new List<Opportunity>();
        for(Id oppId:oppIdAffected){
            
          Opportunity opp=new Opportunity(Id=oppId);
            opp.Total_Revenue__c=oppIdVsTotalRevenue.get(oppId);
            opp.Cancelled_Revenue__c=oppVsCancelledRevenue.get(oppId);
            opp.Projected_Close_Month__c=oppIdVsprojectedCloseMonth.get(oppId);
            if(opp.Total_Revenue__c == null){
      				  opp.Total_Revenue__c = 0;
   				 }
             if(opp.Cancelled_Revenue__c == null){
     				   opp.Cancelled_Revenue__c = 0;
   				 }
            oppListToUpdate.add(opp);
        }
        if(!oppListToUpdate.isEmpty()){
            update oppListToUpdate;
        }
        
        List<Opportunity_Revenue_Alert__e> eventList=new List<Opportunity_Revenue_Alert__e>();
        for(Opportunity opp:oppListToUpdate){
            if(opp.Cancelled_Revenue__c>0.2*opp.Total_Revenue__c){
                eventList.add(new Opportunity_Revenue_Alert__e(
                Opportunity_Id__c = opp.Id,
                Cancelled_Revenue__c =  opp.Cancelled_Revenue__c,
                Total_Revenue__c = opp.Total_Revenue__c));
                
            }
        }
        if(!eventList.isEmpty()){
            EventBus.publish(eventList);
        }
        
        
}
}