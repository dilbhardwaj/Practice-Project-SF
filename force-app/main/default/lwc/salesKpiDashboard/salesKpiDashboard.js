import {LightningElement,wire} from 'lwc';
import {MessageContext,subscribe,unsubscribe, publish} from 'lightning/messageService';
import REGION_FILTER from '@salesforce/messageChannel/RegionFilter__c';
import getKpiSummary from '@salesforce/apex/KpiController.getKpiSummary';
import getTopOpportunities from '@salesforce/apex/KpiController.getTopOpportunities';
import getTop50Opportunities from '@salesforce/apex/KpiController.getTop50Opportunities';


export default class SalesKpiDashboard extends LightningElement {
    value;
    cardSelected;
    isDetailLoading=false;
    region ='North';
    selectedCardId;
    isLoading ;
    pipeline;
    wonRevenue;
    winRate;
    avgDealSize ;
    opportunities ;
    intervalId ;
    subscription ;

    pipelineTrend = 'flat'; wonRevenueTrend = 'flat';
    winRateTrend = 'flat'; avgDealSizeTrend = 'flat';

    @wire(MessageContext)
    messageContext;
    
    @wire(getTopOpportunities,{region:'$region', cardId: '$selectedCardId'})
    wiredOpportunities({data,error}){
        this.isDetailLoading = false; 
        if(data) this.opportunities=data;
        if(error) console.error(error);
    }
    
 
    get options(){
        return [
            { label:'North', value:'North'},
            { label:'South', value:'South'},
            { label:'East', value:'East'},
            { label:'West', value:'West'},
        ];
    }
    handleChange(event) {
       this.region=event.detail.value;
       publish(this.messageContext,REGION_FILTER,{region:this.region});
       this.loadData();
    }

    connectedCallback() {
        this.loadData();
        this.intervalId=setInterval(()=>{
            this.loadData();
        },30000);
        this.subscription=subscribe(this.messageContext,REGION_FILTER,(message)=>{
            this.region=message.region;
            this.loadData();
        })
    }
    disconnectedCallback() {
        clearInterval(this.intervalId);
        unsubscribe(this.subscription);
    }
    handleCardSelect(event){
        const cardId=event.detail.cardId;
        this.selectedCardId=cardId;
        this.cardSelected=true;
        this.isDetailLoading = true; 
       
    }
    loadData(){
        this.isLoading=true;
        getKpiSummary({region:this.region})
     .then((result) => {
    

    this.pipeline    = result.totalOpenPipeline;
    this.wonRevenue  = result.totalWonRevenue;
    this.winRate     = result.winRate;
    this.avgDealSize = result.avgDealSize;
})
        .catch((error)=>{
            this.error=error;

        })
        .finally(()=>{
            this.isLoading=false;
        })
    }
    get hasOpportunities(){
        if(this.opportunities!=null && this.opportunities.length>0){
            return true;
        }else{
            return false;
        }
    }
    get regionOptions(){
        return this.options;
    }

 

}