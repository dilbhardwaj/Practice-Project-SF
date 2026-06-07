public with sharing class InvoiceService {

    @AuraEnabled
    public static InvoiceDTO.InvoiceResult generateInvoice(
        String opportunityId,
        String lineItemsJson
    ) {
        List<InvoiceDTO.LineItemDTO> dtos = (List<InvoiceDTO.LineItemDTO>)
            JSON.deserialize(lineItemsJson, List<InvoiceDTO.LineItemDTO>.class);

        if (dtos.size() > 50) {
            System.enqueueJob(new InvoiceQueueable(opportunityId, lineItemsJson));
            InvoiceDTO.InvoiceResult ar = new InvoiceDTO.InvoiceResult();
            ar.isAsync = true;
            return ar;
        }

        return buildInvoice(opportunityId, dtos);
    }

    @AuraEnabled
    public static String createInvoiceRecord(
        String opportunityId,
        String lineItemsJson
    ) {
        List<InvoiceDTO.LineItemDTO> dtos = (List<InvoiceDTO.LineItemDTO>)
            JSON.deserialize(lineItemsJson, List<InvoiceDTO.LineItemDTO>.class);

        Opportunity opp = [
            SELECT Id, Account.BillingCountryCode
            FROM Opportunity
            WHERE Id = :opportunityId
        ];
        String countryCode = String.isBlank(opp.Account.BillingCountryCode)
            ? 'US' : opp.Account.BillingCountryCode;

        List<Tax_Config__mdt> configs = [
            SELECT Standard_Rate__c FROM Tax_Config__mdt
            WHERE Country_Code__c = :countryCode LIMIT 1
        ];
        Decimal defaultTaxRate = configs.isEmpty() ? 0 : configs[0].Standard_Rate__c;

        Decimal net = 0, tax = 0;
        for (InvoiceDTO.LineItemDTO dto : dtos) {
            Decimal rate = (dto.taxRate != null) ? dto.taxRate : defaultTaxRate;
            net += dto.quantity * dto.unitPrice;
            tax += dto.quantity * dto.unitPrice * (rate / 100);
        }

        Invoice__c inv = new Invoice__c(
            Opportunity__c = opportunityId,
            Status__c      = 'Draft',
            Total_Net__c   = net,
            Total_Tax__c   = tax,
            Total_Gross__c = net + tax
        );
        insert inv;

        inv = [SELECT Id, Invoice_Number__c FROM Invoice__c WHERE Id = :inv.Id];

        List<Invoice_Line__c> lines = new List<Invoice_Line__c>();
        for (InvoiceDTO.LineItemDTO dto : dtos) {
            Decimal rate = (dto.taxRate != null) ? dto.taxRate : defaultTaxRate;
            lines.add(new Invoice_Line__c(
                Invoice__c      = inv.Id,
                Product_Name__c = dto.productName,
                Quantity__c     = dto.quantity,
                Unit_Price__c   = dto.unitPrice,
                Tax_Rate__c     = rate
            ));
        }
        insert lines;

        return inv.Id;  
    }

    @AuraEnabled
    public static InvoiceDTO.InvoiceResult generatePdfForInvoice(String invoiceId) {
        String pdfBase64 = InvoicePDFGenerator.getPdfBase64(invoiceId);

        Invoice__c inv = [SELECT Id, Invoice_Number__c FROM Invoice__c WHERE Id = :invoiceId];

        ContentVersion cv = new ContentVersion(
            Title                  = 'Invoice_' + inv.Invoice_Number__c,
            PathOnClient           = 'Invoice_' + inv.Invoice_Number__c + '.pdf',
            VersionData            = EncodingUtil.base64Decode(pdfBase64),
            FirstPublishLocationId = inv.Id
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        inv.PDF_Version_Id__c = cv.ContentDocumentId;
        update inv;

        InvoiceDTO.InvoiceResult result = new InvoiceDTO.InvoiceResult();
        result.contentDocumentId = cv.ContentDocumentId;
        result.versionId         = cv.Id;
        result.isAsync           = false;
        return result;
    }

    public static InvoiceDTO.InvoiceResult buildInvoice(
        String oppId,
        List<InvoiceDTO.LineItemDTO> dtos
    ) {
        String invoiceId = createInvoiceRecord(oppId, JSON.serialize(dtos));
        return generatePdfForInvoice(invoiceId);
    }
}