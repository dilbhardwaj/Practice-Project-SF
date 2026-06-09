@RestResource(URLMapping='/docusign/webhook')
global class DocuSignWebhookController {
	@httpPost
    global static void doPost(){

        RestRequest req=RestContext.request;
        RestResponse res=RestContext.response;
        
        String rawBody=req.requestBody.toString();
        String receivedSignature=req.Headers.get('X-DocuSign-Signature-1');
        
        String secretKey=[select HMAC_Secret_Key__c from DocuSign_Config__mdt limit 1].HMAC_Secret_Key__c;
        String computedSignature =EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA256',Blob.valueOf(rawBody),Blob.valueOf(secretKey)));
        System.debug('RECEIVED BODY: ' + rawBody);
System.debug('RECEIVED SIGNATURE: ' + receivedSignature);
System.debug('COMPUTED SIGNATURE: ' + computedSignature);
        if(receivedSignature!=computedSignature){
            res.statusCode=400;
            res.responseBody=Blob.valueOf('Invalid Signature');
            return;
        }
        
        Map<String,Object> payLoad=(Map<String,Object>)JSON.deserializeUntyped(rawBody);
        String EnvelopeId=(String)payLoad.get('envelopeId');
        String OpportunityId=(String)payLoad.get('opportunityId');
        
        Envelope_Event__c evt =new Envelope_Event__c();
        evt.Envelope_Id__c=EnvelopeId;
        evt.Opportunity__c=OpportunityId;
        evt.Status__c='Received';
        evt.Raw_Payload__c=rawBody;
        evt.Retry_Count__c=0;
        
        Database.upsert(evt,Envelope_Event__c.Envelope_Id__c);
        System.enqueueJob(new DocuSignEnvelopeProcessor(evt.Id));
        res.statusCode=201;
        
        
    }
}