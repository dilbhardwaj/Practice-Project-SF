trigger AccountContactSync on Account (after insert,after update) {
    if(trigger.isAfter && trigger.isInsert){
        AccountContactSyncHandler.handleAfterInsert(Trigger.New);
    }
    if(trigger.isAfter && trigger.isUpdate){
        AccountContactSyncHandler.handleAfterUpdate(Trigger.New);
    }
}

//100 SOQL limit
//150DML limit


/*
 ============ BROKEN CODE — DO NOT USE IN PRODUCTION ============ 

trigger AccountContactSync on Account (after insert, after update) { 
    for (Account acc : Trigger.new) { 
        List<Contact> contacts = [SELECT Id, Email FROM Contact   // SOQL in loop 
                                  WHERE AccountId = :acc.Id]; 

        for (Contact c : contacts) { 
            c.Description = acc.Industry; 
            update c;                              // DML in loop 
        } 

        List<Opportunity> opps = [SELECT Id FROM Opportunity   // SOQL in loop 
                                  WHERE AccountId = :acc.Id 
                                  AND StageName != 'Closed Won']; 

        if (opps.size() > 0) { 
            Opportunity o = new Opportunity(); 
            o.AccountId = acc.Id; 
            o.Name = acc.Name + ' - Auto Opp'; 
            o.StageName = 'Prospecting'; 
            o.CloseDate = Date.today().addDays(30); 
            insert o;                              // DML in loop 

        } 

        Account a = [SELECT Id, Rating FROM Account   // SOQL in loop 
                     WHERE Id = :acc.Id LIMIT 1]; 

        if (a.Rating == null) { 
            acc.Rating = 'Cold'; 
            update acc;                           // update Trigger.new in loop 

        } 

    } 

} */