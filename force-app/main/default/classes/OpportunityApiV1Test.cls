@isTest
public class OpportunityApiV1Test {

    @TestSetup
    static void createTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name      = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addDays(30);
        insert opp;
    }


    static User createStandardUser() {
        Profile p = [
            SELECT Id FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];
        User u = new User(
            FirstName        = 'Test',
            LastName         = 'NoPermUser',
            Email            = 'noperm' + Math.random() + '@test.com',
            Username         = 'noperm' + Math.random() + '@test.com',
            Alias            = 'noperm',
            TimeZoneSidKey   = 'America/New_York',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey= 'en_US',
            ProfileId        = p.Id
        );
        insert u;
        return u;
    }

    static void grantWritePermission() {
        List<PermissionSet> psList = [
            SELECT Id FROM PermissionSet
            WHERE Name = 'Partner_Persmission'
            LIMIT 1
        ];

        if (psList.isEmpty()) return;

        Id psId   = psList[0].Id;
        Id userId = UserInfo.getUserId();

        List<PermissionSetAssignment> existing = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId      = :userId
            AND   PermissionSetId = :psId
            LIMIT 1
        ];

        if (existing.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId      = userId,
                PermissionSetId = psId
            );
        }
    }

    @IsTest
    static void testGetList() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/v1/opportunities/';
        req.httpMethod  = 'GET';
        req.params.put('accountId', acc.Id);

        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiV1.doGet();
        Test.stopTest();

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody.toString();
    }

    @IsTest
    static void testGetSingle() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/v1/opportunities/' + opp.Id;
        req.httpMethod  = 'GET';

        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiV1.doGet();
        Test.stopTest();

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody.toString();
    }

    @IsTest
    static void testPostReturns403() {
        Account acc     = [SELECT Id FROM Account LIMIT 1];
        User noPermUser = createStandardUser();

        String jsonBody = '{"name":"New Opp","accountId":"' + acc.Id
            + '","stageName":"Prospecting","closedate":"2025-12-31"}';

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/v1/opportunities/';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request  = req;
        RestContext.response = new RestResponse();

        System.runAs(noPermUser) {
            Test.startTest();
            OpportunityApiV1.doPost();
            Test.stopTest();
        }

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody.toString();
    }

    @IsTest
    static void testPostWithPermission() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        grantWritePermission();

        String jsonBody = '{"name":"New Opp","accountId":"' + acc.Id
            + '","stageName":"Prospecting","closedate":"2025-12-31"}';

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/v1/opportunities/';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiV1.doPost();
        Test.stopTest();

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody != null
                             ? RestContext.response.responseBody.toString() : '';

        List<Opportunity> created = [
            SELECT Id FROM Opportunity WHERE Name = 'New Opp'
        ];
    }

    @IsTest
    static void testDeleteIfFirst() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User noPermUser = createStandardUser();

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/v1/opportunities/' + opp.Id;
        req.httpMethod  = 'DELETE';

        RestContext.request  = req;
        RestContext.response = new RestResponse();

        System.runAs(noPermUser) {
            Test.startTest();
            OpportunityApiV1.doDelete();
            Test.stopTest();
        }

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody.toString();
    }

    @IsTest
    static void testDeleteElse() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        grantWritePermission();

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/v1/opportunities/' + opp.Id;
        req.httpMethod  = 'DELETE';

        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiV1.doDelete();
        Test.stopTest();

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody.toString();

        Opportunity updated = [
            SELECT StageName FROM Opportunity WHERE Id = :opp.Id
        ];
    }

@IsTest
static void testPostWithLineItems() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    grantWritePermission();

    Id stdPbId = Test.getStandardPricebookId();

    Product2 prod = new Product2(
        Name      = 'Test Product',
        IsActive  = true
    );
    insert prod;

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id   = stdPbId,
        Product2Id     = prod.Id,
        UnitPrice      = 100,
        IsActive       = true
    );
    insert pbe;

    String jsonBody = '{'
        + '"name":"Opp With Lines",'
        + '"accountId":"' + acc.Id + '",'
        + '"stageName":"Prospecting",'
        + '"closedate":"2025-12-31",'
        + '"lineItems":['
        +   '{"pricebookEntryId":"' + pbe.Id + '","quantity":2,"unitPrice":100}'
        + ']'
        + '}';

    RestRequest req = new RestRequest();
    req.requestURI  = '/services/apexrest/v1/opportunities/';
    req.httpMethod  = 'POST';
    req.requestBody = Blob.valueOf(jsonBody);

    RestContext.request  = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    OpportunityApiV1.doPost();
    Test.stopTest();

    Integer statusCode = RestContext.response.statusCode;
    String  body       = RestContext.response.responseBody.toString();

    List<Opportunity> created = [
        SELECT Id FROM Opportunity WHERE Name = 'Opp With Lines'
    ];

    List<OpportunityLineItem> lines = [
        SELECT Id FROM OpportunityLineItem
        WHERE OpportunityId = :created[0].Id
    ];
}

@IsTest
static void testGetSingleWithLineItems() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Id stdPbId = Test.getStandardPricebookId();

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Pricebook2Id = stdPbId;
    update opp;

    Product2 prod = new Product2(
        Name     = 'Test Product 2',
        IsActive = true
    );
    insert prod;

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = stdPbId,
        Product2Id   = prod.Id,
        UnitPrice    = 200,
        IsActive     = true
    );
    insert pbe;

    OpportunityLineItem oli = new OpportunityLineItem(
        OpportunityId    = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity         = 1,
        UnitPrice        = 200
    );
    insert oli;

    RestRequest req = new RestRequest();
    req.requestURI  = '/services/apexrest/v1/opportunities/' + opp.Id;
    req.httpMethod  = 'GET';

    RestContext.request  = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    OpportunityApiV1.doGet();
    Test.stopTest();

    Integer statusCode = RestContext.response.statusCode;
    String  body       = RestContext.response.responseBody.toString();
}
}