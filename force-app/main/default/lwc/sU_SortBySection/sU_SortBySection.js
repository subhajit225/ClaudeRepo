import { LightningElement,wire, api } from 'lwc';
import { fireEvent,registerListener,unregisterListener,dropdownOptions } from 'c/supubsub'; 
import { CurrentPageReference } from 'lightning/navigation'; 
export default class SU_SortBySection extends LightningElement {
    @api eventCode;
    @wire(CurrentPageReference) pageRef; 
    @api translationObject;
    @api sortByCheck;
    DataLoaded = false;
    get options() {
         let finalDropdown = dropdownOptions.map(item=>{
            return { label: this.translationObject[item.key] || item.key , value: item.value }
        })

        return finalDropdown
    }

    connectedCallback() {
        registerListener('sendsortdata'+this.eventCode, this.sendSortData, this);
        this.DataLoaded = true;
    }
    disconnectedCallback(){
        unregisterListener('sendsortdata'+this.eventCode, this.sendSortData, this);
    }
    sendSortData(data) {
        const startSelect = this.template.querySelector('.select-sort');
        if(startSelect) {
            startSelect.value = data.sortby;
        }
    }

    handleChange(event) {
        let typeValue = event.target.value;
        fireEvent(this.pageRef,'checkType'+this.eventCode,typeValue);
        
    }
}