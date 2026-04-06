import { LightningElement, api, wire } from 'lwc';
// Close Quick Action Modal
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AreasOfImprovementQuickAction extends LightningElement {
    
    @api recordId
    @api fields = ['Lessons_Learned__c.Lessons_Learned_Number__c']

    handleCloseAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}