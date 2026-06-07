import { LightningElement,api } from 'lwc';

export default class KpiCard extends LightningElement {
    @api title;
    @api value;
    @api trend;
    @api cardId;
    handleClick(){
        const cardselect=new CustomEvent('cardselect',{
            detail:{cardId:this.cardId},
            bubbles:true,
            composed:true
        });
    this.dispatchEvent(cardselect);
        
    }


}