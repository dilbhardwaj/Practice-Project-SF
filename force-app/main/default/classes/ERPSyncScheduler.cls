public class ERPSyncScheduler implements Schedulable {
    public void execute (SchedulableContext sc){
        List<Account> accList=[select id, name, sync_status__c from Account where sync_status__c='Pending' limit 5000];
        List<Id> accountIds=new List<Id>();
        for(Account acc:accList){
            accountIds.add(acc.Id);
        }
        System.enqueuejob(new ERPSyncQueueable(accountIds,0));
    }
}