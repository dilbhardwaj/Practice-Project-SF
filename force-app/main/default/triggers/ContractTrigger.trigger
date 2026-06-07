trigger ContractTrigger on Contract (after update) {
    List<Contract_Change_Event__e> events = new List<Contract_Change_Event__e>();

    for (Contract newRec : Trigger.new) {
        Contract oldRec = Trigger.oldMap.get(newRec.Id);

        if (newRec.TCV__c != oldRec.TCV__c) {
            events.add(new Contract_Change_Event__e(
                Contract_Id__c  = newRec.Id,
                Field_Name__c   = 'TCV__c',
                Old_Value__c    = String.valueOf(oldRec.TCV__c),
                New_Value__c    = String.valueOf(newRec.TCV__c),
                Changed_By__c   = UserInfo.getUserId(),
                Change_Time__c  = DateTime.now()
            ));
        }

        if (newRec.Discount__c != oldRec.Discount__c) {
            events.add(new Contract_Change_Event__e(
                Contract_Id__c  = newRec.Id,
                Field_Name__c   = 'Discount__c',
                Old_Value__c    = String.valueOf(oldRec.Discount__c),
                New_Value__c    = String.valueOf(newRec.Discount__c),
                Changed_By__c   = UserInfo.getUserId(),
                Change_Time__c  = DateTime.now()
            ));
        }

        if (newRec.Payment_Terms__c != oldRec.Payment_Terms__c) {
            events.add(new Contract_Change_Event__e(
                Contract_Id__c  = newRec.Id,
                Field_Name__c   = 'Payment_Terms__c',
                Old_Value__c    = String.valueOf(oldRec.Payment_Terms__c),
                New_Value__c    = String.valueOf(newRec.Payment_Terms__c),
                Changed_By__c   = UserInfo.getUserId(),
                Change_Time__c  = DateTime.now()
            ));
        }
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
    }
}