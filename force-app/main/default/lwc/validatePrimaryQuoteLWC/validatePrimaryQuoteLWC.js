import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Primary_Field from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Primary__c";
import Opportunity_Field from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Opportunity2__c";
import Account_Field from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c";
import validateQuoteFromApex from '@salesforce/apex/QuoteValidationController.compareEntitlementAllWithNewPrimaryQuote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ValidatePrimaryQuoteLWC extends LightningElement {
    @api recordId;
    columns = [
        {
            label: 'Quote Line ', fieldName: 'quoteNameUrl', type: 'url',
            typeAttributes: {
                label: { fieldName: 'quoteLineNumber' },
                target: '_blank'
            }
        },
        {
            fieldName: 'productName', label: 'Product Name ', type: 'text',
            cellAttributes: {
                class: 'slds-text-color_error ',
            }
        },
        {
            fieldName: 'entitlementIdsForResponse', label: 'Entitlement Ids', type: 'text',
            cellAttributes: {
                class: 'slds-text-color_error',
            }
        }
    ]
    tableData = [];
    listOfInvalidOppIds = [];
    showDtable = false;
    showLoader = true;
    errorMessage;
    showOppLinks = false;

    @wire(getRecord, { recordId: "$recordId", fields: [Primary_Field, Account_Field, Opportunity_Field] })
    wiredRecord({ error, data }) {
        if (error) {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error loading contact",
                    message,
                    variant: "error",
                }),
            );
        } else if (data) {
            if (data.fields.SBQQ__Primary__c.value == false) {
                this.validatePrimaryQuote(data.fields.SBQQ__Opportunity2__c.value, data.fields.SBQQ__Account__c.value, false);
            } else {
                this.validatePrimaryQuote(data.fields.SBQQ__Opportunity2__c.value, data.fields.SBQQ__Account__c.value, true);
                //this.showLoader = false;
                this.errorMessage = 'This quote is primary quote. ';
                //console.log('This quote is primary quote');
            }
        }
    }

    validatePrimaryQuote(oppId, accountId, isFromPrimary = false) {

        validateQuoteFromApex({
            quoteIds: [this.recordId],
            oppids: [oppId],
            accountIds: [accountId],
            accIdWithQuoteIds : null

        }).then(res => {
            console.log(res);
            if ((res == null || res.length == 0) && isFromPrimary == false) {
                this.errorMessage = 'You can mark this Quote as primary';
            } else if (res.length > 0) {
                let dt = JSON.parse(JSON.stringify(res));
                let dataToShow = [];
                dt.forEach(ele => {                
                    if(ele.opportunityId){
                        let index = this.listOfInvalidOppIds.findIndex(element => element.oppId == ele.opportunityId);
                        if(index == -1){
                            this.listOfInvalidOppIds.push({
                                oppId : ele.opportunityId,
                                oppName : ele.opportunityName,
                                oppUrl : `/${ele.opportunityId}`
                            });
                        }
                    }else{
                        ele.quoteNameUrl = `/${ele.quoteLineId}`                        
                        dataToShow.push(ele);
                    }                                    
                });
                if(isFromPrimary == true){
                    this.errorMessage += 'Quote cannot be unchecked primary. Please check below for further details.';
                }
                this.tableData = dataToShow;
                if(this.listOfInvalidOppIds.length > 0){
                    this.showOppLinks = true;
                }
                this.showDtable = true;
            }
        }).catch(err => {
            console.log('Error ', err);
        }).finally(() => {
            this.showLoader = false;
        })
    }

}