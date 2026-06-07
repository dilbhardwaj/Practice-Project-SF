trigger ContractPlatformEventTrigger on Contract_Change_Event__e (after insert) {
    List<Contract_Audit__b> auditRecords = new List<Contract_Audit__b>();

    for (Contract_Change_Event__e event : Trigger.new) {
        auditRecords.add(new Contract_Audit__b(
            Contract_Id__c  = event.Contract_Id__c,
            Field_Name__c   = event.Field_Name__c,
            Old_Value__c    = event.Old_Value__c,
            New_Value__c    = event.New_Value__c,
            Changed_By__c   = event.Changed_By__c,
            Change_Time__c  = event.Change_Time__c
        ));
    }

    if (!auditRecords.isEmpty()) {
        Database.insertImmediate(auditRecords);
    }
}