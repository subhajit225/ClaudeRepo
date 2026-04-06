import { LightningElement, api } from 'lwc';

export default class ContactsModal extends LightningElement {
    @api showModal;
    @api modalTitle;
    @api contacts = [];

    columns = [
        {
            label: 'Name',
            fieldName: 'contactUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Title', fieldName: 'Title' },
        { label: 'Key CXO Stakeholder Title', fieldName: 'Key_CXO_Stakeholder_Title__c'},
        { label: 'Product Persona', fieldName: 'Product_Persona__c'},
        {
            label: 'Email',
            fieldName: 'emailLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Email' }, target: '_blank' }
        }
    ];

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}