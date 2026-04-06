import { LightningElement, wire, api } from 'lwc';
import { fireEvent, registerListener, unregisterListener, dropdownOptions } from 'c/authsupubsub_b6b3_13';
import { CurrentPageReference } from 'lightning/navigation';
export default class SU_AuthSortBySection extends LightningElement {
    @wire(CurrentPageReference) pageRef;
    @api translationObject;
    @api sortByCheck;
    @api DataLoaded = false;
    get options() {
        let finalDropdown = dropdownOptions.map(item=>{
            return { label: this.translationObject[item.key] || item.key , value: item.value }
        })

         return finalDropdown
    }
    connectedCallback() {
        registerListener('sendsortdata', this.sendSortData, this);
        this.DataLoaded = true;
    }
    
    disconnectedCallback() {
        unregisterListener('sendsortdata', this.sendSortData, this);
    }

    sendSortData(data) {
        const startSelect = this.template.querySelector('.select-sort');
        if (startSelect) {
            startSelect.value = data.sortby;
        }
    }
    handleChange(event) {
        let typeValue = event.target.value;
        fireEvent(null, 'checkType', typeValue);

    }
}