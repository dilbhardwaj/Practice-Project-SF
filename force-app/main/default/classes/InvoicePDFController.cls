public without sharing class InvoicePDFController {

    public Invoice__c invoice          { get; set; }
    public List<Invoice_Line__c> lines { get; set; }
    public String errorMessage         { get; set; }

    public InvoicePDFController() {
        String invoiceId = ApexPages.currentPage().getParameters().get('id');
        System.debug('VF Controller received id: ' + invoiceId);

        if (String.isBlank(invoiceId)) {
            errorMessage = 'No Id provided';
            invoice = new Invoice__c();
            lines   = new List<Invoice_Line__c>();
            return;
        }

        List<Invoice__c> invList = [
            SELECT Id, Invoice_Number__c, Status__c,
                   Total_Net__c, Total_Tax__c, Total_Gross__c,
                   Opportunity__r.Account.Name
            FROM Invoice__c
            WHERE Id = :invoiceId
            LIMIT 1
        ];

        if (invList.isEmpty()) {
            errorMessage = 'Invoice not found: ' + invoiceId;
            invoice = new Invoice__c();
            lines   = new List<Invoice_Line__c>();
            return;
        }

        invoice = invList[0];
        lines = [
            SELECT Product_Name__c, Quantity__c, Unit_Price__c,
                   Tax_Rate__c, Line_Total__c
            FROM Invoice_Line__c
            WHERE Invoice__c = :invoiceId
            ORDER BY CreatedDate ASC
        ];
    }
}