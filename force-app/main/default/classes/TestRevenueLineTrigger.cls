@isTest
public class TestRevenueLineTrigger {
	@testSetup
    static void dataSetup(){
            List<Revenue_Line__c> revenueLineList=Datafactory.getRevenueLineWithRelatedOpp();
			if(!revenueLineList.isEmpty()){
      			  insert revenueLineList;
  				  }    
    }
    
    @isTest
    static void testInsert(){
    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today()
    );
    insert opp;

    Revenue_Line__c rl = new Revenue_Line__c(
        Amount__c = 100,
        Stage__c = 'Active',
        Month__c = Date.today(),
        Opportunity__c = opp.Id
    );
        

    Test.startTest();
    insert rl;
    Test.stopTest();
   
    }
    @isTest
    static void testUpdate(){
        List<Revenue_Line__c> activeRevenueLineList=[select Id, Amount__c,Stage__c,Month__c,Opportunity__c from Revenue_Line__c where Stage__c='Active' ];
        for(Revenue_Line__c rl:activeRevenueLineList){
            rl.Stage__c='Cancelled';
        }
         Test.startTest();
        if(!activeRevenueLineList.isEmpty()){
       		 update activeRevenueLineList;
  			} 
        Test.stopTest();
    }
    @isTest
    static void testDelete(){
        List<Revenue_Line__c> activeRevenueLineList=[select Id, Amount__c,Stage__c,Month__c,Opportunity__c from Revenue_Line__c limit 200];
         Test.startTest();
        if(!activeRevenueLineList.isEmpty()){
       		 delete activeRevenueLineList;
  			} 
        Test.stopTest();
    }
    @isTest
    static void testUndelete(){
        List<Revenue_Line__c> activeRevenueLineList=[select Id from Revenue_Line__c limit 200];
       
         Test.startTest();
        if(!activeRevenueLineList.isEmpty()){
            delete activeRevenueLineList;
            TriggerHelper.isTriggerExecuted = false;
       			List<Revenue_Line__c> deletedRevenueLineList=[select Id from Revenue_Line__c  where id in:activeRevenueLineList all rows];
            		undelete deletedRevenueLineList;
  			} 
        Test.stopTest();
    }
    
}