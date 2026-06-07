@RestResource(urlMapping='/v1/invoices/*')
global without sharing class InvoiceRestResource {

    @HttpGet
    global static void getInvoice() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        String invoiceId = req.requestURI.substringAfterLast('/');

        try {
            Invoice__c inv = [
                SELECT Id, Invoice_Number__c, Total_Net__c, Total_Tax__c,
                       Total_Gross__c, Status__c, PDF_Version_Id__c,
                       Opportunity__r.Name
                FROM Invoice__c
                WHERE Id = :invoiceId
            ];

            List<Invoice_Line__c> lines = [
                SELECT Product_Name__c, Quantity__c, Unit_Price__c,
                       Tax_Rate__c, Line_Total__c
                FROM Invoice_Line__c
                WHERE Invoice__c = :invoiceId
                ORDER BY CreatedDate
            ];

            Map<String, Object> payload = new Map<String, Object>{
                'invoice'   => inv,
                'lineItems' => lines
            };

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serializePretty(payload));
            res.addHeader('Content-Type', 'application/json');

        } catch (QueryException e) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error":"Invoice not found"}');
        }
    }
}