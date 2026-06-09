public class PdfSplitQueueable 
    implements Queueable, Database.AllowsCallouts {

    private Id contentVersionId;

    public PdfSplitQueueable(Id contentVersionId) {
        this.contentVersionId = contentVersionId;
    }

    public void execute(QueueableContext context) {

        ContentVersion cv = [
            SELECT Id, VersionData, Title, FirstPublishLocationId
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ];

        try {
            String pdfContent = cv.VersionData.toString();

            List<PDF_Split_Header__mdt> headers = [
                SELECT Header_Text__c, Document_Name__c
                FROM PDF_Split_Header__mdt
                ORDER BY Header_Text__c ASC
            ];

          
            Map<Integer, PDF_Split_Header__mdt> positionMap = 
                new Map<Integer, PDF_Split_Header__mdt>();

            for (PDF_Split_Header__mdt header : headers) {
                Integer position = pdfContent.indexOf(header.Header_Text__c);
                if (position != -1) {
                    positionMap.put(position, header);
                }
            }

            List<Integer> sortedPositions = new List<Integer>(positionMap.keySet());
            sortedPositions.sort();

            List<ContentVersion> splitDocs = new List<ContentVersion>();

            for (Integer i = 0; i < sortedPositions.size(); i++) {

                Integer startPos = sortedPositions[i];
                Integer endPos;

                if (i == sortedPositions.size() - 1) {
                    endPos = pdfContent.length();
                } else {
                    endPos = sortedPositions[i + 1];
                }

                String sectionContent = pdfContent.substring(startPos, endPos);

                PDF_Split_Header__mdt headerRecord = positionMap.get(startPos);

                ContentVersion splitCv = new ContentVersion();
                splitCv.Title = headerRecord.Document_Name__c;
                splitCv.PathOnClient = 's.pdf';
                splitCv.VersionData = Blob.valueOf(sectionContent);
                splitCv.FirstPublishLocationId = cv.FirstPublishLocationId;
                splitDocs.add(splitCv);
            }

            if (!splitDocs.isEmpty()) {
                insert splitDocs;
            }

            Envelope_Processed__e successEvent = new Envelope_Processed__e();
            successEvent.Envelope_Id__c = cv.Title;
            successEvent.Status__c = 'Completed';
            successEvent.Document_Count__c = splitDocs.size();
            EventBus.publish(successEvent);

        } catch (Exception e) {

            Envelope_Processed__e failEvent = new Envelope_Processed__e();
            failEvent.Envelope_Id__c = cv.Title;
            failEvent.Status__c = 'Failed';
            failEvent.Document_Count__c = 0;
            EventBus.publish(failEvent);
        }
    }
}