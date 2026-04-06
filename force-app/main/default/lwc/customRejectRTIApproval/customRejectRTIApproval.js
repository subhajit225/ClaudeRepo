import { LightningElement,api,wire,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import CATEGORY_FIELD from '@salesforce/schema/sbaa__Approval__c.Categories__c';
import FEEDBACK_FIELD from '@salesforce/schema/sbaa__Approval__c.Feedback_Groups__c';
import REJECTION_REASON_FIELD from '@salesforce/schema/sbaa__Approval__c.Rejection_Reason__c';
import REJECTION_COMMENT_FIELD from '@salesforce/schema/sbaa__Approval__c.Rejection_Reason_RTI_Comments__c';
import { getRecord,updateRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
export default class CustomRejectRTIApproval extends LightningElement {
    
    @api recordId;
    @wire(getRecord,{ recordId: "$recordId", fields: [CATEGORY_FIELD,FEEDBACK_FIELD,REJECTION_REASON_FIELD,REJECTION_COMMENT_FIELD] })
    getApprovalRecordData ({error, data}) {
        if (error) {
            // TODO: Error handling
            console.log(error)
        } else if (data) {
            // TODO: Data handling
            this.ApprovalRecord=data;
            let Category=getFieldValue(this.ApprovalRecord,CATEGORY_FIELD);
            let feedback=getFieldValue(this.ApprovalRecord,FEEDBACK_FIELD);
            let rejectionReason=getFieldValue(this.ApprovalRecord,REJECTION_REASON_FIELD);
            let rejectionComment=getFieldValue(this.ApprovalRecord,REJECTION_COMMENT_FIELD);
            console.log('Indside this'+Category);
            console.log('Indside this'+feedback);
            console.log('Indside this'+rejectionReason);
            console.log('Indside this'+rejectionComment);
            
           if(Category!=null || feedback!=null )
            {       
                if(rejectionReason==null){
                this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: "Kindly update Rejection Reason and Rejection Reason(RTI) comments before rejecting this approval ",
                  variant: "Error",
                  mode: 'sticky'
                }),
                );
                this.closeModal();
            }
            else if(rejectionReason=='Other' && rejectionComment==null){
                this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: "Kindly update Rejection Reason (RTI) Comments when Other is selected in Rejection reason ",
                  variant: "Error",
                  mode: 'sticky'
                }),
                );
                this.closeModal();
        }
            else{
                this.closeModal();
                window.location.assign("https://rubrikinc--sbaa.vf.force.com/apex/Reject?scontrolCaching=1&id="+this.recordId);
                } 
        }
        else{
            this.closeModal();
            window.location.assign("https://rubrikinc--sbaa.vf.force.com/apex/Reject?scontrolCaching=1&id="+this.recordId);
            }  
    }

}
            closeModal(event){
                this.dispatchEvent(new CloseActionScreenEvent());
            }

              

            
}