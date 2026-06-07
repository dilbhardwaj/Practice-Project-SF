public class AccountTriggerHandler {
	public static void GrandparentHandler(List<Account> accList) {
        Set<Id> parentIds = new Set<Id>();
        for (Account acc : accList) {
            if (acc.Account__c != null) {
                parentIds.add(acc.Account__c);
            }
        }
        if (parentIds.isEmpty()) return;
        Map<Id, Account> parentMap = new Map<Id, Account>([SELECT Id, FirstParent__c FROM Account WHERE Id IN :parentIds]);
        for (Account acc : accList) {
            if (acc.Account__c != null && parentMap.containsKey(acc.Account__c)) {
					Account parentAcc = parentMap.get(acc.Account__c);
						if (parentAcc.FirstParent__c != null) {
  							  acc.FirstParent__c = parentAcc.FirstParent__c;
						} else {
  							  acc.FirstParent__c = parentAcc.Id;
						}        
            }
        }
    }
    public static void GrandChildHandler(List<Account> accList) {
        Set<Id> grandParentIds = new Set<Id>();
        for (Account acc : accList) {
            if (acc.FirstParent__c != null) {
                grandParentIds.add(acc.FirstParent__c);
            }
        }
        if (grandParentIds.isEmpty()) return;
        Map<Id, Account> grandParentMap = new Map<Id, Account>([SELECT Id, LastChild__c FROM Account WHERE Id IN :grandParentIds]);
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accList) {
            if (acc.FirstParent__c != null && grandParentMap.containsKey(acc.FirstParent__c)) {
                Account gp = grandParentMap.get(acc.FirstParent__c);
                gp.LastChild__c = acc.Id;
                accountsToUpdate.add(gp);
            }
        }
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}