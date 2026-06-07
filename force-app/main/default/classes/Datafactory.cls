@isTest
public class Datafactory {
    public static List<Revenue_Line__c> getRevenueLineWithRelatedOpp(){
        List<Revenue_Line__c> revenueLineList=new List<Revenue_Line__c>();
        List<Opportunity> oppList=new List<Opportunity>();
        
        for(Integer i=0;i<200;i++){
            Opportunity opp=new Opportunity(StageName='Prospecting',closeDate=Date.Today(),Name='opp'+i);
            oppList.add(opp);
        }
        if(!oppList.isEmpty()){
            insert oppList;
        }
         for(Integer i=0;i<200;i++){
            Revenue_Line__c rl=new Revenue_Line__c(Amount__c=100,Stage__c='Active',Month__c=Date.Today(),Opportunity__c=oppList[i].Id);
            revenueLineList.add(rl);
        }
        
        return revenueLineList;
    }
    
    public static List<Account> getAccounts(){
        List<Account> accList=new List<Account>();
        for(Integer i=0;i<250;i++){
            Account acc=new Account(Name='Test Account'+i,Industry='Agriculture');
            accList.add(acc);
        }
        return accList;
        
        
    }
}