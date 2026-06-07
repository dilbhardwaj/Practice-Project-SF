public class AccountContactSyncHandler {
    public static void handleAfterInsert(List<Account> accList){
         helper(accList);
    }
    
    public static void handleAfterUpdate(List<Account> accList){
        helper(accList);
    }
    
    public static void helper(List<Account> accList){
        
        Map<Id,Account> accIdVsAccount =new Map<Id,Account>();
        List<Account> accListToUpdate=new List<Account>();
        for(Account acc:accList){
            accIdVsAccount.put(acc.Id,acc);
            if(acc.Rating==null){
               Account a=new Account(id=acc.Id,rating='Cold');
                accListToUpdate.add(a);
            }
        }
        List<Contact>conListToUpdate=new List<Contact>();
        for(Contact con:[select id, email,AccountId,description from contact where accountId in:accIdVsAccount.keySet()]){
            con.Description=accIdVsAccount.get(con.AccountId).Industry;
            conListToUpdate.add(con);
        }
        
		Set<Id> accountsWithOpenOpps = new Set<Id>();
		for(Opportunity opp : [select Id, AccountId from Opportunity where AccountId in :accIdVsAccount.keySet() AND StageName != 'Closed Won' AND StageName != 'Closed Lost']){
   			 accountsWithOpenOpps.add(opp.AccountId);
		}

		List<Opportunity> oppsToInsert = new List<Opportunity>();
        Auto_Opp__mdt autoOppCreationConfig=Auto_Opp__mdt.getInstance('For_Trigger');
		for(Account acc : accList){
  			  if(!accountsWithOpenOpps.contains(acc.Id) && autoOppCreationConfig.autoOppCreation__c ){
      			  oppsToInsert.add(new Opportunity(
         		   AccountId = acc.Id,
           			 Name      = acc.Name + ' - Auto Opp',
           			 StageName = 'Prospecting',
            		CloseDate = Date.today().addDays(30)
        ));
    }
}
        if(!accListToUpdate.isEmpty()){
            update accListToUpdate;
        }
        if(!conListToUpdate.isEmpty()){
            update conListToUpdate;
        }
        if(!oppsToInsert.isEmpty()){
            insert oppsToInsert;
        }
        
    }
}