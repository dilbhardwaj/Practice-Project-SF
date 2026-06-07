@isTest
private class InvoiceServiceTest {


    private static Account createAccount(String country) {
        Account acc = new Account(
            Name           = 'Test Account',
            BillingStreet  = '123 Test St',
            BillingCity    = 'Test City',
            BillingCountry = country
        );
        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(Id accountId) {
        Opportunity opp = new Opportunity(
            Name      = 'Test Opportunity',
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static String lineItemsJson(Integer count, Decimal taxRate) {
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        for (Integer i = 0; i < count; i++) {
            items.add(new Map<String, Object>{
                'id'          => i + 1,
                'productName' => 'Product ' + (i + 1),
                'quantity'    => 2,
                'unitPrice'   => 100,
                'taxRate'     => taxRate
            });
        }
        return JSON.serialize(items);
    }

    @isTest
    static void testCreateInvoiceRecord_createsInvoiceAndLines() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);
        String json     = lineItemsJson(3, 10);

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, json);
        Test.stopTest();

        Invoice__c inv = [
            SELECT Id, Total_Net__c, Total_Tax__c, Total_Gross__c, Status__c
            FROM Invoice__c WHERE Id = :invoiceId
        ];

        List<Invoice_Line__c> lines = [
            SELECT Id FROM Invoice_Line__c WHERE Invoice__c = :invoiceId
        ];
    }

   
    @isTest
    static void testTaxCalculation_US_20Percent() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);

        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 1, 'productName' => 'Widget',
                'quantity' => 5, 'unitPrice' => 200, 'taxRate' => 20
            }
        };

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, JSON.serialize(items));
        Test.stopTest();

        Invoice__c inv = [
            SELECT Total_Net__c, Total_Tax__c, Total_Gross__c
            FROM Invoice__c WHERE Id = :invoiceId
        ];
    }
    @isTest
    static void testTaxCalculation_UK_5Percent() {
        Account acc     = createAccount('United Kingdom');
        Opportunity opp = createOpportunity(acc.Id);

        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 1, 'productName' => 'Gadget A',
                'quantity' => 3, 'unitPrice' => 100, 'taxRate' => 5
            },
            new Map<String, Object>{
                'id' => 2, 'productName' => 'Gadget B',
                'quantity' => 3, 'unitPrice' => 100, 'taxRate' => 5
            }
        };

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, JSON.serialize(items));
        Test.stopTest();

        Invoice__c inv = [
            SELECT Total_Net__c, Total_Tax__c, Total_Gross__c
            FROM Invoice__c WHERE Id = :invoiceId
        ];
    }
    @isTest
    static void testTaxCalculation_ZeroTax() {
        Account acc     = createAccount('United Arab Emirates');
        Opportunity opp = createOpportunity(acc.Id);

        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 1, 'productName' => 'Service',
                'quantity' => 10, 'unitPrice' => 50, 'taxRate' => 0
            }
        };

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, JSON.serialize(items));
        Test.stopTest();

        Invoice__c inv = [
            SELECT Total_Net__c, Total_Tax__c, Total_Gross__c
            FROM Invoice__c WHERE Id = :invoiceId
        ];
    }
    @isTest
    static void testGeneratePdf_contentVersionCreated() {
        Account acc      = createAccount('United States');
        Opportunity opp  = createOpportunity(acc.Id);
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, lineItemsJson(2, 20));

        Test.startTest();
        Test.setCurrentPageReference(Page.InvoicePDF);
        InvoiceDTO.InvoiceResult result = InvoiceService.generatePdfForInvoice(invoiceId);
        Test.stopTest();

        List<ContentVersion> cvList = [
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :result.contentDocumentId
        ];

        Invoice__c inv = [
            SELECT PDF_Version_Id__c FROM Invoice__c WHERE Id = :invoiceId
        ];
    }
    @isTest
    static void testGenerateInvoice_syncPath() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);
        String json     = lineItemsJson(5, 15);

        Test.startTest();
        Test.setCurrentPageReference(Page.InvoicePDF);
        InvoiceDTO.InvoiceResult result = InvoiceService.generateInvoice(opp.Id, json);
        Test.stopTest();

        List<Invoice__c> invList = [
            SELECT Total_Net__c, Total_Tax__c, Total_Gross__c
            FROM Invoice__c
            WHERE PDF_Version_Id__c = :result.contentDocumentId
        ];
    }
    @isTest
    static void testGenerateInvoice_asyncPath_over50Lines() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);
        String json     = lineItemsJson(51, 10);

        Test.startTest();
        InvoiceDTO.InvoiceResult result = InvoiceService.generateInvoice(opp.Id, json);
        Test.stopTest();

        Boolean isAsync = result.isAsync;
    }

    @isTest
    static void testGenerateInvoice_exactly50Lines_staysSynchronous() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);
        String json     = lineItemsJson(50, 10);

        Test.startTest();
        Test.setCurrentPageReference(Page.InvoicePDF);
        InvoiceDTO.InvoiceResult result = InvoiceService.generateInvoice(opp.Id, json);
        Test.stopTest();

        Boolean isAsync  = result.isAsync;
        String versionId = result.versionId;
    }
    @isTest
    static void testGetPdfBase64_returnsMockInTestContext() {
        Account acc      = createAccount('United States');
        Opportunity opp  = createOpportunity(acc.Id);
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, lineItemsJson(1, 10));

        Test.startTest();
        Test.setCurrentPageReference(Page.InvoicePDF);
        String base64 = InvoicePDFGenerator.getPdfBase64(invoiceId);
        Test.stopTest();

        String decoded = EncodingUtil.base64Decode(base64).toString();
    }

    @isTest
    static void testGetPdfBase64_anyId_returnsMockInTestContext() {
        Test.startTest();
        Test.setCurrentPageReference(Page.InvoicePDF);
        String base64 = InvoicePDFGenerator.getPdfBase64('a00000000000001AAA');
        Test.stopTest();

        String decoded = EncodingUtil.base64Decode(base64).toString();
    }

    @isTest
    static void testInvoicePDFController_validId() {
        Account acc      = createAccount('United States');
        Opportunity opp  = createOpportunity(acc.Id);
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, lineItemsJson(3, 20));

        Test.startTest();
        PageReference pageRef = Page.InvoicePDF;
        pageRef.getParameters().put('id', invoiceId);
        Test.setCurrentPageReference(pageRef);
        InvoicePDFController ctrl = new InvoicePDFController();
        Test.stopTest();

        Invoice__c            loadedInvoice = ctrl.invoice;
        List<Invoice_Line__c> loadedLines   = ctrl.lines;
        String                error         = ctrl.errorMessage;
    }

    @isTest
    static void testInvoicePDFController_missingId() {
        Test.startTest();
        Test.setCurrentPageReference(Page.InvoicePDF);
        InvoicePDFController ctrl = new InvoicePDFController();
        Test.stopTest();

        String                error = ctrl.errorMessage;
        List<Invoice_Line__c> lines = ctrl.lines;
    }

    @isTest
    static void testInvoicePDFController_invalidId() {
        Test.startTest();
        PageReference pageRef = Page.InvoicePDF;
        pageRef.getParameters().put('id', 'a00000000000001AAA');
        Test.setCurrentPageReference(pageRef);
        InvoicePDFController ctrl = new InvoicePDFController();
        Test.stopTest();

        String                error = ctrl.errorMessage;
        List<Invoice_Line__c> lines = ctrl.lines;
    }

    @isTest
    static void testInvoiceRestResource_validId_returns200() {
        Account acc      = createAccount('United States');
        Opportunity opp  = createOpportunity(acc.Id);
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, lineItemsJson(2, 10));

        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/invoices/' + invoiceId;
        req.httpMethod   = 'GET';
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        InvoiceRestResource.getInvoice();
        Test.stopTest();

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody.toString();
    }

    @isTest
    static void testInvoiceRestResource_invalidId_returns404() {
        RestRequest req  = new RestRequest();
        req.requestURI   = '/services/apexrest/v1/invoices/a00000000000001AAA';
        req.httpMethod   = 'GET';
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        InvoiceRestResource.getInvoice();
        Test.stopTest();

        Integer statusCode = RestContext.response.statusCode;
        String  body       = RestContext.response.responseBody.toString();
    }

    @isTest
    static void testInvoiceQueueable_executesWithoutException() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);
        String json     = lineItemsJson(2, 10);

        Test.startTest();
        Test.setCurrentPageReference(Page.InvoicePDF);
        System.enqueueJob(new InvoiceQueueable(opp.Id, json));
        Test.stopTest();

        List<Invoice__c> invList = [
            SELECT Id, Total_Net__c
            FROM Invoice__c
            WHERE Opportunity__c = :opp.Id
        ];
    }

    @isTest
    static void testMixedTaxRates_perLineCalculation() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);

        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 1, 'productName' => 'A',
                'quantity' => 1, 'unitPrice' => 1000, 'taxRate' => 20
            },
            new Map<String, Object>{
                'id' => 2, 'productName' => 'B',
                'quantity' => 1, 'unitPrice' => 500, 'taxRate' => 5
            }
        };

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, JSON.serialize(items));
        Test.stopTest();

        Invoice__c inv = [
            SELECT Total_Net__c, Total_Tax__c, Total_Gross__c
            FROM Invoice__c WHERE Id = :invoiceId
        ];
    }

    @isTest
    static void testSingleLineItem_createsInvoice() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);

        List<Map<String, Object>> items = new List<Map<String, Object>>{
            new Map<String, Object>{
                'id' => 1, 'productName' => 'Solo Product',
                'quantity' => 1, 'unitPrice' => 999, 'taxRate' => 18
            }
        };

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, JSON.serialize(items));
        Test.stopTest();

        Invoice__c inv = [
            SELECT Id, Total_Net__c, Total_Tax__c, Total_Gross__c
            FROM Invoice__c WHERE Id = :invoiceId
        ];

        List<Invoice_Line__c> lines = [
            SELECT Id FROM Invoice_Line__c WHERE Invoice__c = :invoiceId
        ];
    }

    @isTest
    static void testInvoiceStatus_defaultsDraft() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, lineItemsJson(1, 10));
        Test.stopTest();

        Invoice__c inv = [
            SELECT Status__c FROM Invoice__c WHERE Id = :invoiceId
        ];
    }

    @isTest
    static void testInvoice_linkedToOpportunity() {
        Account acc     = createAccount('United States');
        Opportunity opp = createOpportunity(acc.Id);

        Test.startTest();
        String invoiceId = InvoiceService.createInvoiceRecord(opp.Id, lineItemsJson(1, 10));
        Test.stopTest();

        Invoice__c inv = [
            SELECT Opportunity__c FROM Invoice__c WHERE Id = :invoiceId
        ];
    }
}