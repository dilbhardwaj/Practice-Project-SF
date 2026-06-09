public class DocuSignRetryController {
    @auraEnabled(cacheable=true)
    public static void retryProcessing(id envelopeEventId){
        Envelope_Event__c evt=[Select Envelope_Id__c, Retry_Count__c from Envelope_Event__c where id=:envelopeEventId];
        if(evt.Retry_Count__c<3){
            System.enqueueJob(new DocuSignEnvelopeProcessor(envelopeEventId));
        }else{
            throw new AuraHandledException('Retry count excedded 3');
        }
    }
    @AuraEnabled(cacheable=true)
public static List<ContentVersion> getSplitDocuments(Id opportunityId) {
    List<ContentVersion> allDocs = [
        SELECT Id, Title, FileExtension, ContentDocumentId
        FROM ContentVersion
        WHERE FirstPublishLocationId = :opportunityId
        AND IsLatest = true
        ORDER BY CreatedDate ASC
    ];

    List<ContentVersion> splitDocs = new List<ContentVersion>();
    for (ContentVersion cv : allDocs) {
        if (!cv.Title.startsWith('SignedEnvelope_')) {
            splitDocs.add(cv);
        }
    }
    return splitDocs;
}
    @auraEnabled(cacheable=true)
    public static Envelope_Event__c getEnvelopeEvent(Id opportunityId){
        return [select id, status__c, retry_count__c, Envelope_id__c from Envelope_Event__c where Opportunity__c=:opportunityId order by createdDate desc limit 1][0];
    }
}