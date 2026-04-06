import { LightningElement, api, wire } from 'lwc';
// Close Quick Action Modal
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RrtQuestionsAndFeedbackQuickAction extends LightningElement {
    
    @api recordId
    @api fields = ['Escalation__c.Escalation_Ransomware_Number__c', 
                    'Escalation__c.Escalation_Support_Number__c'];
    
    handleCloseAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}