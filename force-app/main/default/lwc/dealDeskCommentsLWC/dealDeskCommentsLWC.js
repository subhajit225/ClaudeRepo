import { LightningElement, api, wire,track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import BODY_FIELD from '@salesforce/schema/Deal_Desk_Comments__c.Body__c';
import PARENTID_FIELD from '@salesforce/schema/Deal_Desk_Comments__c.ParentId__c';
import RECIPIENTID_FIELD from '@salesforce/schema/Deal_Desk_Comments__c.Recipient_Ids__c';
import RECIPIENTNAME_FIELD from '@salesforce/schema/Deal_Desk_Comments__c.Recipient_Names__c';
import createFeedItemRec from '@salesforce/apex/dealDeskCommentsController.createDDCommentsRec';
import getFeedItemList from '@salesforce/apex/dealDeskCommentsController.getddCommentsList';

/*const columns = [
    { label: 'Id', fieldName: 'Id' },
    { label: 'Name', fieldName: 'Name' },
]; */

export default class DealDeskCommentsLWC extends NavigationMixin(LightningElement) {
    //columns = columns;
    @api recordId;
    @track commentBody = '';
    @track selectedRecords = [];
    @track selectedRecordsLength;
    @track recipientIds = '';
    @track recipientNames = '';
    @track isLoaded=true;

    handleselectedUserRecords(event) {
        this.recipientIds='';
        this.recipientNames='';
        this.selectedRecords = [...event.detail.selRecords]
        this.selectedRecordsLength = this.selectedRecords.length;
        for (let i = 0; i < this.selectedRecords.length; i++) {
                if(i==0){
                    this.recipientIds=this.selectedRecords[i].Id;
                    this.recipientNames=this.selectedRecords[i].Name;
                }
                else{
                    this.recipientIds = this.recipientIds+","+this.selectedRecords[i].Id;
                    this.recipientNames = this.recipientNames+","+this.selectedRecords[i].Name;
                }
        }
        console.log('this.recipientIds----------->' + this.recipientIds);
        console.log('this.recipientNames----------->' + this.recipientNames);
    }

    @wire(getFeedItemList, {parentId: '$recordId' })
    comments;

    recFeedItem = {
        Body__c: this.commentBody,
        ParentId__c: this.recordId,
        Recipient_Ids__c: this.recipientIds,
        Recipient_Names__c: this.recipientNames
    };

    handleChange(event) {
        this.recFeedItem.Body__c = event.target.value;
    }

    handleSelect(event) {
        const userCommentId = event.detail;
        let userId = this.comments.data.find(
            (comment) => comment.Id === userCommentId
        ).CreatedBy.Id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: userId,
                objectApiName: 'User',
                actionName: 'view'
            }
        });
    }
// INVALID_TYPE_ON_FIELD_IN_RECORD, Body: value not of required type: : [Body__c]
    handlePostClick(event) {
        this.isLoaded = false;
        this.recFeedItem.ParentId__c = this.recordId;
        this.recFeedItem.Recipient_Ids__c = this.recipientIds;
        this.recFeedItem.Recipient_Names__c = this.recipientNames;
        console.log('Value--> ' + JSON.stringify(this.recFeedItem));
        if(this.recFeedItem.Body__c!=''){
            createFeedItemRec({ 'ddCommentRec': this.recFeedItem })
            .then((response) => {
                this.commentBody = '';
                this.recipientIds = '';
                this.recipientNames = '';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Comment Posted!',
                        variant: 'success'
                    })
                );
                refreshApex(this.comments);
                this.isLoaded = true;
             })
            .catch((error) => {
                this.isLoaded = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
            this.resetChildSearchResults();
            this.resetCommentBody();
        }
        else if(this.recFeedItem.Body__c==''){
            this.isLoaded = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Comment cannot be empty',
                    variant: 'Error'
                })
            );
        }
        
        }

        resetChildSearchResults(){
            const objChild = this.template.querySelector('c-multiselect-lookup-l-w-c');
            objChild.resetSearchResults();
        }
        resetCommentBody(){
            this.template.querySelector('lightning-textarea').value='';
            this.recFeedItem.Body__c = '';
        }
        
}