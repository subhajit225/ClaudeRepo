import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getAARrecordTypeId from '@salesforce/apex/AARLWCController.getAARrecordTypeId';
import getAARId from '@salesforce/apex/AARLWCController.getAARId';
import getOpportunity from '@salesforce/apex/AARLWCController.getOpportunity';

export default class AfterActionReviewLWC extends NavigationMixin(LightningElement) {

    @api recordId;
    opp;
    error;
    recTypeId;
    aarId;
    region;
    message;
    showMessage;

    connectedCallback(){
        setTimeout(() => {
            console.log(' recordId '+this.recordId);

            getOpportunity({oppId : this.recordId})
            .then((result) => {
                this.opp = result;
                this.region = this.opp.ETM_Theatre__c != null? this.opp.ETM_Theatre__c : '';
                this.error = undefined;
                if(this.opp.StageName == '7 Closed Lost') {
                    if(this.opp.After_Action_Required__c) {
                        console.log('inside isReq '+this.opp.After_Action_Required__c);
        
                        if(this.opp.After_Action_Form_Submitted__c) {
                            console.log('inside isSub '+this.opp.After_Action_Form_Submitted__c);
                            this.fetchAARId();
                        } else this.getAARForm();
                    } else {
                        this.message = 'This Opportunity is not Applicable for After Action Review.';
                        this.showMessage = true;
                    }
                } else {
                    this.message = 'The Opportunity needs to be Closed Lost to create After Action Review.';
                    this.showMessage = true;
                }
                              
            })
            .catch((error) => {
                this.error = error;
                this.opp = undefined;
                console.log('Error Occured '+ error);
            });
        }, 5);
    }
    

    fetchAARId() {
        getAARId({oppId : this.recordId})
            .then((result) => {
                this.aarId = result;
                this.error = undefined;
                //console.log('showing aarId '+this.aarId);
                
                if(this.aarId) {
                    //console.log('inside aarId if '+this.aarId);
                    this.navigateToViewAARPage();
                } else {
                    console.log('else aarId check '+this.aarId);
                    this.getAARForm();
                }
            })
            .catch((error) => {
                this.error = error;
                this.aarId = undefined;
            });
        
    }

    getAARForm() {
        getAARrecordTypeId({region : this.region})
            .then((result) => {
                this.recTypeId = result;
                this.error = undefined;
                //console.log('showing recTypeid '+this.recTypeId);
                
                this.navigateToNewAAR();
            })
            .catch((error) => {
                this.error = error;
                this.recTypeId = undefined;
            });
    }

    navigateToNewAAR() {

            const defaultValues = encodeDefaultFieldValues({
                Opportunity__c: this.recordId
            });

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'After_Action_Review__c',
                    actionName: 'new'
                },
                state: {
                    recordTypeId: this.recTypeId,
                    defaultFieldValues: defaultValues
                }
            });
    }

    navigateToViewAARPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.aarId,
                objectApiName: 'After_Action_Review__c',
                actionName: 'view'
            },
        });
    }

}