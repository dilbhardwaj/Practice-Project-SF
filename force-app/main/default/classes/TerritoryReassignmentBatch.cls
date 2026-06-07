public class TerritoryReassignmentBatch implements Database.Batchable<SObject>, Database.Stateful { 
    public List<Territory_Rule__c> allRules = new List<Territory_Rule__c>();
    public Integer totalProcessed = 0;
    public Integer totalChanged = 0;
    public Map<String, Integer> changesPerTerritory = new Map<String, Integer>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        allRules = [select Id, Postcode_Prefix__c, Territory__c, Priority__c from Territory_Rule__c order by Priority__c asc];
        return Database.getQueryLocator('select Id, Postcode__c, Sales_Territory__c from Contact where Postcode__c != null');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for (SObject record : scope) {
            Contact con = (Contact) record;
            totalProcessed++;
            Id correctTerritory = findTerritory(con.Postcode__c);
            if (correctTerritory != con.Sales_Territory__c) {
                totalChanged++;
                String oldTerritory = con.Sales_Territory__c != null? String.valueOf(con.Sales_Territory__c): 'No Territory';
                Integer currentCount = changesPerTerritory.get(oldTerritory);
                if (currentCount == null) {
                    currentCount = 0;
                }
                changesPerTerritory.put(oldTerritory, currentCount + 1);
                con.Sales_Territory__c = correctTerritory;
                contactsToUpdate.add(con);
            }
        }
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
    public void finish(Database.BatchableContext bc) {
        String details = 'Breakdown by old territory:\n';
        for (String oldTerritory : changesPerTerritory.keySet()) {
            Integer count = changesPerTerritory.get(oldTerritory);
            details += count ;
        }
        Batch_Summary__c summary = new Batch_Summary__c();
        summary.Total_Processed__c = totalProcessed;
        summary.Total_Changed__c   = totalChanged;
        summary.Details__c         = details;
        summary.Run_Date__c        = System.now();
        insert summary;
    }
    private Id findTerritory(String postcode) {
        if (String.isBlank(postcode)) {
            return null;
        }
        String upperPostcode = postcode.toUpperCase();
        for (Territory_Rule__c rule : allRules) {
            if (upperPostcode.startsWith(rule.Postcode_Prefix__c.toUpperCase())) {
                return rule.Territory__c;
            }
        }
        return null;
    }
}