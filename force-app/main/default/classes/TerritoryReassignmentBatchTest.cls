@IsTest
private class TerritoryReassignmentBatchTest {
    @IsTest
    static void testBatch() {
        Sales_Territory__c mohaliTerritory = new Sales_Territory__c(Name = 'mohali');
        Sales_Territory__c noidaTerritory = new Sales_Territory__c(Name = 'noida');
        insert new List<Sales_Territory__c>{mohaliTerritory, noidaTerritory};
        Territory_Rule__c rule1 = new Territory_Rule__c(
            Postcode_Prefix__c = 'SW1',
            Territory__c       = mohaliTerritory.Id,
            Priority__c        = 1
        );
        Territory_Rule__c rule2 = new Territory_Rule__c(
            Postcode_Prefix__c = 'M1',
            Territory__c       = noidaTerritory.Id,
            Priority__c        = 2
        );
        insert new List<Territory_Rule__c>{rule1, rule2};
       Contact contact1 = new Contact(
            LastName           = 'Sharma',
            Postcode__c        = 'SW1A 1AA',
            Sales_Territory__c = noidaTerritory.Id  
        );
        Contact contact2 = new Contact(
            LastName           = 'Verma',
            Postcode__c        = 'M1 2AB',
            Sales_Territory__c = noidaTerritory.Id  
        );
        insert new List<Contact>{contact1, contact2};
        Test.startTest();
            Database.executeBatch(new TerritoryReassignmentBatch(), 200);
        Test.stopTest();
    }
}