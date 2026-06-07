@isTest
private class ContractTriggerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contract c = new Contract(AccountId= acc.Id,StartDate= Date.today(),ContractTerm = 12,Status = 'Draft',TCV__c = 10000,Discount__c = 5,Payment_Terms__c = '30');
        insert c;
    }

    @isTest
    static void testFieldChangesPublishEvents() {
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        Test.enableChangeDataCapture();
        Test.startTest();
            c.TCV__c       = 20000;      
            c.Discount__c  = 10;          
            c.Payment_Terms__c = '60'; 
            update c;
        Test.stopTest();
    }

    @isTest
    static void testNoChangeDoesNotPublish() {
        Contract c = [SELECT Id, TCV__c FROM Contract LIMIT 1];
        Test.enableChangeDataCapture();
        Test.startTest();
            c.Description = 'Changed description only';
            update c;
        Test.stopTest();

     
    
    }
}