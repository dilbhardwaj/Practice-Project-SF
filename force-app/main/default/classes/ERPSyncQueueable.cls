public class ERPSyncQueueable implements Queueable,Database.AllowsCallouts {
    private List<Id> accountIds;
    private Integer retryCount;
    private static final Integer batchSize = 10;
    public ERPSyncQueueable(List<Id> accountIds,Integer count){
        this.accountIds=accountIds;
        this.retryCount=count;
    }
    public void execute(QueueableContext qc){
        ERP_Config__mdt config=[select endpoint_URL__c, Timeout_ms__c, Max_Retries__c from ERP_Config__mdt limit 1];
        List<Id> currentBatch = new List<Id>();
        List<Id> remainingIds = new List<Id>();
        for(Integer i=0;i<accountIds.size();i++){
            if(i<10){
                currentBatch.add(accountIds[i]);
            }else{
                remainingIds.add(accountIds[i]);
            }
        }
       List<Account> accountsToSync=[select id, Sync_Status__c,Sync_Retry_Count__c,Last_Sync_Time__c from Account where id in:currentBatch ];        
        HttpRequest req=new HttpRequest();
        req.setEndPoint(config.endpoint_URL__c);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setTimeout((Integer)config.Timeout_ms__c);
        req.setBody(JSON.serialize(accountsToSync));
        
        HttpResponse res = new Http().send(req);
        if(res.getStatusCode()==200){
            List<account> accToUpdate=new List<Account>();
            for(Account acc:accountsToSync){
               Account a=new Account();
                a.Id=acc.Id;
                a.Sync_Status__c='Synced';
                a.Last_Sync_Time__c=DateTime.now();
                a.Sync_Retry_Count__c=0;
                accToUpdate.add(a);
            }
            update accToUpdate;
if(!remainingIds.isEmpty() && !Test.isRunningTest()){
    System.enqueuejob(new ERPSyncQueueable(remainingIds,0));
}        }else{
            if(retryCount+1<(Integer)config.Max_Retries__c){
                List<Account>accListTry2=[select id, Sync_Status__c,Sync_Retry_Count__c,Last_Sync_Time__c from Account where id in:currentBatch];
                List<account> ToUpdate=new List<Account>();

                for(Account acc:accListTry2){
                    if(acc.Sync_Retry_Count__c==null){
                        acc.Sync_Retry_Count__c=0+1;
                    }else{
                        acc.Sync_Retry_Count__c=acc.Sync_Retry_Count__c+1;
                    }
                    ToUpdate.add(acc);
                }
                update ToUpdate;
if(!Test.isRunningTest()){
    System.enqueuejob(new ERPSyncQueueable(accountIds,retryCount+1));
}            }else{
                List<Account> toUpdateaccount=new List<Account>();
                List<Error_Log__c> errLogList=new List<Error_Log__c>();
                for(Account acc:accountsToSync){
                    Account a=new Account();
               		 a.Id=acc.Id;
                	 a.Sync_Status__c='Failed';
               		 a.Last_Sync_Time__c=DateTime.now();
                     toUpdateaccount.add(a);
                    
                    Error_Log__c errorLog=new Error_Log__c();
                    errorLog.Account__c=acc.Id;
                    errorLog.Response_Body__c =res.getBody();
                    errorLog.Error_Time__c=DateTime.now();
                    errLogList.add(errorLog);
                }
                update toUpdateaccount;
                insert errLogList;
                List<ERP_Sync_Failed__e> events = new List<ERP_Sync_Failed__e>();
                for(Account acc : accountsToSync){
                    events.add(new ERP_Sync_Failed__e(Account_Id__c = acc.Id,Failed_At__c  = DateTime.now()));
                }
                EventBus.publish(events);
                if(!remainingIds.isEmpty() && !Test.isRunningTest()){
    System.enqueueJob(new ERPSyncQueueable(remainingIds, 0));
}
            }
        }       
    }
}