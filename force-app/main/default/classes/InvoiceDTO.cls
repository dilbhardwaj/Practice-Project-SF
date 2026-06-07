public class InvoiceDTO {

    public class LineItemDTO {
        public String  productName;
        public Decimal quantity;
        public Decimal unitPrice;
        public Decimal taxRate;
    }

    public class InvoiceResult {
        @AuraEnabled public String  contentDocumentId;
         @AuraEnabled public String  versionId; 
        @AuraEnabled public Boolean isAsync;
    }
}