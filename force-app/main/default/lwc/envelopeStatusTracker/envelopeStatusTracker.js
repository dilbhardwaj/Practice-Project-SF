import { LightningElement,api,track,wire } from 'lwc';
import {getRecord,getFieldValue} from 'lightning/uiRecordApi';
import { subscribe, onError } from 'lightning/empApi';
import STATUS_FIELD from '@salesforce/schema/Envelope_Event__c.Status__c';
import ENVELOPE_ID_FIELD from '@salesforce/schema/Envelope_Event__c.Envelope_Id__c';
import retryProcessing from '@salesforce/apex/DocuSignRetryController.retryProcessing';
import getSplitDocuments from '@salesforce/apex/DocuSignRetryController.getSplitDocuments';
import getEnvelopeEvent from '@salesforce/apex/DocuSignRetryController.getEnvelopeEvent';
import { refreshApex } from '@salesforce/apex';


export default class EnvelopeStatusTracker extends LightningElement {
    @api recordId;
    @track status;
    @track errorMessage;
    @track isLoading=true;
    @track splitDocuments=[];
    @track EnvelopeEventId;

    wiredEnvelopeResult;
    @wire(getEnvelopeEvent,{opportunityId:'$recordId'})
    wiredEnvelopeEvent({error,data}){
    console.log('WIRE ERROR: ', JSON.stringify(error));
        if(data){

            this.status=data.Status__c;
            this.EnvelopeEventId=data.Id;
            this.isLoading=false;
            if(data.status__c==='Completed'){
                this.loadSplitDocuments();
            }
        }else if(error){
            this.errorMessage='No envelope found for this opportunity';
            this.isLoading=false;
        }
    }

    

 connectedCallback() {
    // load documents on initial render too
    this.loadSplitDocuments();

    subscribe('/event/Envelope_Processed__e', -1, (event) => {
        this.handlePlatformEvent(event);
    }).then(response => {
        console.log('Subscribed: ', JSON.stringify(response));
        this.subscription = response;
    });
}

    handlePlatformEvent(event){
        const payLoad=event.data.payload;
        this.status=payLoad.status__c;

        if(this.status=='Completed'){
            this.loadSplitDocuments();
        }
    }

    loadSplitDocuments() {
    getSplitDocuments({ opportunityId: this.recordId })
        .then(result => {
            console.log('SPLIT DOCS RESULT: ', JSON.stringify(result));
            console.log('SPLIT DOCS COUNT: ', result.length);
            
            this.splitDocuments = result.map(doc => {
                return {
                    ...doc,
                    downloadUrl: '/sfc/servlet.shepherd/version/download/' + doc.Id
                };
            });

            console.log('SPLIT DOCS AFTER MAP: ', JSON.stringify(this.splitDocuments));
        })
        .catch(error => {
            console.log('SPLIT DOCS ERROR: ', JSON.stringify(error));
            this.errorMessage = 'Error loading documents';
        });
}

    handleRetry(){
        this.isLoading=true;
        this.errorMessage=null;

        retryProcessing({envelopeEventId:this.EnvelopeEventId})
        .then(()=>{
            this.status='Processing';
            this.isLoading=false;

        })
        .catch(error=>{
            this.errorMessage=error.body.message;
            this.isLoading=false;
        })
    }

    get isFailedStatus(){
        return this.status==='Failed'
    }
    get hasSplitDocuments(){
        return this.splitDocuments && this.splitDocuments.length>0;
    }
}