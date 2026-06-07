@isTest
public class TestERPSync {

    public class HttpMockFactory implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public HttpMockFactory(Integer statusCode, String responseBody){
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }

    @testSetup
    static void setupData(){
        List<Account> accList = new List<Account>();
        for(Integer i=0; i<10; i++){   
            accList.add(new Account(
                name = 'test account '+i,
                sync_status__c = 'Pending',
                sync_retry_count__c = 0
            ));
        }
        insert accList;
    }

  @isTest
static void testScheduler(){
    Test.setMock(HttpCalloutMock.class, new HttpMockFactory(200,'{"status":"ok"}'));
    Test.startTest();
    new ERPSyncScheduler().execute(null);
    Test.stopTest();
}

    @isTest
    static void testSuccessPath(){
        List<Id> accountIds=new List<Id>();
        for(Account acc:[select id from Account limit 10]){
            accountIds.add(acc.id);
        }

        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(200,'{"status":"ok"}'));
        Test.startTest();
        System.enqueuejob(new ERPSyncQueueable(accountIds,0));
        Test.stopTest();    
    }

    @isTest
    static void testRetryPath(){
        List<Id> accountIds=new List<Id>();
        for(Account acc:[select id from Account limit 10]){
            accountIds.add(acc.id);
        }

        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(500,'Internal Server Error'));
        Test.startTest();
        System.enqueuejob(new ERPSyncQueueable(accountIds,1));
        Test.stopTest();
    }

    @isTest
    static void testFailPath(){
        List<Id> accountIds=new List<Id>();
        for(Account acc:[select id from Account limit 10]){
            accountIds.add(acc.id);
        }
        Test.setMock(HttpCalloutMock.class, new HttpMockFactory(500,'Internal Server Error'));
        Test.startTest();
        System.enqueuejob(new ERPSyncQueueable(accountIds,2));
        Test.stopTest();

    }
}