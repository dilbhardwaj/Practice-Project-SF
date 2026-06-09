public class DocuSignEnvelopeProcessor implements Queueable, Database.allowsCallouts {
	 public id envelopeEventId;
    public DocuSignEnvelopeProcessor( Id envelopeEventId){
        this.envelopeEventId=envelopeEventId;
    }
    
    public void execute(QueueableContext context){
        Envelope_Event__c evt=[select id,Envelope_Id__c,Opportunity__c,Raw_Payload__c,Retry_Count__c,Status__c from Envelope_Event__c where id=:envelopeEventId ];
        try{
            http http=new http();
            HttpRequest req=new HttpRequest();
            req.setEndPoint('callout:DocuSign_NC/envelopes/'+evt.Envelope_Id__c+'/documents/combined');
            req.setMethod('GET');
            HttpResponse res=http.send(req);
            
            evt.Status__c='Processing';
            update evt;
            
            
            ContentVersion cv=new ContentVersion();
            cv.Title='SignedEnvelope_'+evt.Envelope_Id__c;
            cv.pathOnClient='s.pdf';
            cv.FirstPublishLocationId =evt.Opportunity__c;
            cv.versionData=res.getBodyAsBlob();
            
            insert cv;
            
            System.enqueueJob(new PdfSplitQueueable(cv.Id));
            
            evt.status__c='Completed';
            update evt;
            
            Envelope_Processed__e successEvent =new Envelope_Processed__e();
            successEvent.Status__c='Completed';
            successEvent.Envelope_Id__c=evt.Id;
            successEvent.Document_Count__c=1;
            EventBus.publish(successEvent);
        }catch(Exception e){
            evt.status__c='Failed';
            evt.Retry_count__c++;
            evt.Raw_Payload__c = 'ERROR: ' + e.getMessage() 
                       + ' | TYPE: ' + e.getTypeName()
                       + ' | LINE: ' + e.getLineNumber()
                       + ' | STACK: ' + e.getStackTraceString();
            update evt;
            
            Envelope_Processed__e failEvent =new Envelope_Processed__e();
            failEvent.Status__c='Failed';
            failEvent.Envelope_Id__c=evt.Id;
            failEvent.Document_Count__c=0;
            EventBus.publish(failEvent);
            
            if(evt.retry_count__c<3){
                System.enqueueJob(new DocuSignEnvelopeProcessor(evt.Id) );
            }
            
            
        }
            
            
        }
    }