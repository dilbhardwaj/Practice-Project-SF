public class InvoiceQueueable implements Queueable, Database.AllowsCallouts {

    private String opportunityId;
    private String lineItemsJson;

    public InvoiceQueueable(String opportunityId, String lineItemsJson) {
        this.opportunityId = opportunityId;
        this.lineItemsJson = lineItemsJson;
    }

    public void execute(QueueableContext ctx) {
        List<InvoiceDTO.LineItemDTO> dtos = (List<InvoiceDTO.LineItemDTO>)
            JSON.deserialize(lineItemsJson, List<InvoiceDTO.LineItemDTO>.class);

        InvoiceDTO.InvoiceResult result =
            InvoiceService.buildInvoice(opportunityId, dtos);

        InvoiceComplete__e event = new InvoiceComplete__e(
            OpportunityId__c     = opportunityId,
            ContentDocumentId__c = result.contentDocumentId
        );
        EventBus.publish(event);
    }
}