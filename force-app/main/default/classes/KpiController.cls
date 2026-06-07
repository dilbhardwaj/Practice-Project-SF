public class KpiController {
	@auraEnabled(Cacheable=false)
    public static Map<String,Decimal> getKpiSummary(String region){
        Decimal totalWonRevenue =0;
        Decimal totalOpenPipeline =0;
        Decimal winRate=0;
        Decimal avgDealSize=0;
        Decimal numClosedLost=0;
        Integer numClosedWon=0;
        List<Opportunity> oppList=[select id, amount, stagename from Opportunity where region__c=:region];
        for(Opportunity opp:oppList){
            if(opp.StageName=='Closed Won'){
                totalWonRevenue=totalWonRevenue+opp.Amount;
                numClosedWon++;
            }
             if(opp.StageName == 'Closed Lost'){
     		   numClosedLost++;  
  			  }
           
            if(opp.StageName!='Closed Won' && opp.StageName!='Closed Lost'){
                totalOpenPipeline=totalOpenPipeline+opp.Amount;
            }
            
        }
      	Decimal totalClosed = numClosedWon + numClosedLost;
		winRate = totalClosed > 0 ? (numClosedWon * 100) / totalClosed : 0;
		avgDealSize = numClosedWon > 0 ? totalWonRevenue / numClosedWon : 0;
        Map<String,Decimal> summaryVsValue=new Map<String,Decimal>();
        summaryVsValue.put('totalOpenPipeline',totalOpenPipeline);
        summaryVsValue.put('totalWonRevenue',totalWonRevenue);
        summaryVsValue.put('winRate',winRate);
        summaryVsValue.put('avgDealSize',avgDealSize);
        
        return summaryVsValue;
    } 
    
   @AuraEnabled(cacheable=true)
	public static List<Opportunity> getTopOpportunities(String region, String cardId){
    
    if(cardId == 'pipeline'){
        return [select Id, Name, StageName, Amount, CloseDate from Opportunity where Region__c = :region and StageName != 'Closed Won' and StageName != 'Closed Lost'
                ORDER BY Amount DESC LIMIT 5];
    }
    else if(cardId == 'wonRevenue' || cardId == 'avgDealSize'){
        return [select Id, Name, StageName, Amount, CloseDate from Opportunity where Region__c = :region and StageName = 'Closed Won' order by Amount desc limit 5];
    }
    else if(cardId == 'winRate'){
        return [select Id, Name, StageName, Amount, CloseDate from Opportunity where Region__c = :region and (StageName = 'Closed Won' or StageName = 'Closed Lost') order by Amount desc limit 5];
    }
    else {
        return [select Id, Name, StageName, Amount, CloseDate from Opportunity where Region__c = :region order by Amount desc limit 5];
    }
}
    
    @auraEnabled(Cacheable=false)
    public static List<Opportunity> getTop50Opportunities(String region){
        return [select id,name,stageName, closedate,amount from Opportunity where region__c=:region order by amount desc limit 50];
    }
}