import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import quoteLineList from "@salesforce/apex/SwitchPaymentOptionCompController.showQuotesLinesProducts";
import switchPaymentOption from "@salesforce/apex/SwitchPaymentOptionCompController.switchPaymentOption";
// CONTROLLING THE MODAL SIZE USING THIS STATIC RESOURCE
import modal from "@salesforce/resourceUrl/custommodalcss";
import { loadStyle } from "lightning/platformResourceLoader";
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';


export default class SwitchPaymentOptionComponent extends NavigationMixin(LightningElement) {

    @api recordId;
    @track selectedQuoteIDs = [];
    @track quoteLineProductList = [];
    @track isRecordId = false;

    isShowSpinner = false;

    retrievedRecordId = false;
    allQuoteLineList = [];

    renderedCallback() {

        if(!this.retrievedRecordId && this.recordId) {

            this.isRecordId = true;
            this.retrievedRecordId = true;
            if(this.recordId) {

                this.displayQuoteLineProducts();
            }
        }
    }

    connectedCallback() {
        loadStyle(this, modal);
      }

    get paymentOptions() {

        return [
            { label: 'Annual', value: 'Annual' },
            { label: 'Prepay', value: 'Prepay' }
        ];
    }

    async displayQuoteLineProducts() {

        await quoteLineList({
            quoteId : this.recordId
        }).then(result => {

            if(result && result != null && result != '') {

                this.allQuoteLineList = result;
                
                result.forEach (mapper => {

                    let quoteLineWrapper = {};
                    
                    if((mapper.quoteLine.SBQQ__RequiredBy__c == null || mapper.quoteLine.SBQQ__RequiredBy__c == undefined) &&
                        (mapper.quoteLine.Payment_Options__c != null || mapper.quoteLine.Payment_Options__c != undefined) &&
                        mapper.quoteLine.Product_Level__c != 'Support' && mapper.quoteLine.Product_Level__c != 'Hardware' &&
                        mapper.quoteLine.Quote_Line_Type__c != 'New'
                    ) {
                        
                        quoteLineWrapper.quoteLine = mapper.quoteLine;
                        quoteLineWrapper.targetSku = mapper.targetSku;
                        quoteLineWrapper.targetListPrice = mapper.targetListPrice;
                        quoteLineWrapper.targetNetTotal = mapper.targetNetTotal;
                        quoteLineWrapper.currentListPrice = mapper.currentListPrice;
                        
                        if(mapper.quoteLine.Product_Payment_Option__c == 'Prepay' ){
                            quoteLineWrapper.picklistValue = 'Prepay';
                        }else if(mapper.quoteLine.Product_Payment_Option__c == 'Annual'){
                            quoteLineWrapper.picklistValue = 'Annual';
                        }else{
                            quoteLineWrapper.picklistValue = '';
                        }
                        quoteLineWrapper.disableCheckbox = true;
                        quoteLineWrapper.displayComboBox = false;

                        this.quoteLineProductList.push(quoteLineWrapper);
                    }
                })
                this.handlePicklistOption();
            } else {

                this.showToastNotification('Error', 'No data found', 'error');
            }
        }).catch(error => {

            this.showToastNotification('Error', error, 'error');
        });
    }

    // Select all rows
    allSelected(event) {

        let selectedRows = this.template.querySelectorAll('lightning-input');

        selectedRows.forEach (selectedRow => {

            if(selectedRow.type == 'checkbox' && selectedRow.disabled == false) {

                selectedRow.checked = event.target.checked;
            }
        })
    }

    handlePicklistOption() {

        if(this.quoteLineProductList != null && this.quoteLineProductList.length != 0) {

            this.quoteLineProductList.forEach(quoteLineWrapper => {

                //if(quoteLineWrapper.quoteLine.SBQQ__Product__r.Name.endswith('PP')) {
                if(quoteLineWrapper.quoteLine.SBQQ__Product__r.Product_Payment_Option__c == 'Prepay') {

                    quoteLineWrapper.disableCheckbox = false;
                    quoteLineWrapper.displayComboBox = true;
                    quoteLineWrapper.picklistValue = 'Prepay';
                //else if(quoteLineWrapper.quoteLine.SBQQ__Product__r.Name.endswith('PA')) {
                }
                else if(quoteLineWrapper.quoteLine.SBQQ__Product__r.Product_Payment_Option__c == 'Annual') {

                    quoteLineWrapper.disableCheckbox = false;
                    quoteLineWrapper.displayComboBox = true;
                    quoteLineWrapper.picklistValue = 'Annual';
                }
            })
        }
    }

    handlePaymentOptionPickList(event) {

        this.quoteLineProductList.forEach(quoteLineWrapper => {

            if(quoteLineWrapper.quoteLine.Id == event.target.name) {

                quoteLineWrapper.picklistValue = event.target.value;
            }
        })
    }

    handleCancel() {
        window.open('/'+this.recordId, '_top');
        //this.navigateToRecordViewPage();
    }

    async handleSave() {
        let quotLinesToBeUpdated = [];
        let parentQliIdVsPicklistValues = [];
        let childQliIdVsAlldata = [];
        let selectedRows = this.template.querySelectorAll('lightning-input');
        //let isConditionMatched = true;

        this.selectedQuoteIDs = [];

        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].checked && selectedRows[i].type === 'checkbox' && selectedRows[i].dataset.id != undefined) {
                this.selectedQuoteIDs.push(selectedRows[i].dataset.id);
            }
        }
        this.selectedQuoteIDs.forEach(quoteId => {

            this.quoteLineProductList.forEach(quoteLineWrapper => {

                if(quoteLineWrapper.quoteLine.Id == quoteId) {
                    //parentQliIdVsPicklistValues.qlid=quoteId;
                    //parentQliIdVsPicklistValues.picklistValue=quoteLineWrapper.picklistValue;
                    let parentQuoteLineWrapper = {};

                    if(
                        quoteLineWrapper.quoteLine.Product_Payment_Option__c == 'Prepay' &&
                        quoteLineWrapper.picklistValue == 'Annual'
                    ) {
                        if( quoteLineWrapper.quoteLine.SBQQ__Product__r.Name.endsWith('PP')){

                            parentQuoteLineWrapper.quoteLine = quoteLineWrapper.quoteLine;
                            parentQuoteLineWrapper.changedName = quoteLineWrapper.quoteLine.SBQQ__Product__r.Name.slice(0,-2)+'PA';
                            parentQuoteLineWrapper.picklistValue = 'Annual';
                            quotLinesToBeUpdated.push(parentQuoteLineWrapper);
                            parentQliIdVsPicklistValues.push(parentQuoteLineWrapper);
                        }else{

                            parentQuoteLineWrapper.quoteLine = quoteLineWrapper.quoteLine;
                            parentQuoteLineWrapper.changedName = quoteLineWrapper.quoteLine.SBQQ__Product__r.Name;
                            parentQuoteLineWrapper.picklistValue = 'Annual';
                            quotLinesToBeUpdated.push(parentQuoteLineWrapper);
                            parentQliIdVsPicklistValues.push(parentQuoteLineWrapper);
                        }
                    } else if(
                        quoteLineWrapper.quoteLine.Product_Payment_Option__c == 'Annual' &&
                        quoteLineWrapper.picklistValue == 'Prepay'
                    ) {
                        if(quoteLineWrapper.quoteLine.SBQQ__Product__r.Name.endsWith('PA')) {

                            parentQuoteLineWrapper.quoteLine = quoteLineWrapper.quoteLine;
                            parentQuoteLineWrapper.changedName = quoteLineWrapper.quoteLine.SBQQ__Product__r.Name.slice(0,-2)+'PP';
                            parentQuoteLineWrapper.picklistValue = 'Prepay';
                            quotLinesToBeUpdated.push(parentQuoteLineWrapper);
                            parentQliIdVsPicklistValues.push(parentQuoteLineWrapper);
                        }else{

                            parentQuoteLineWrapper.quoteLine = quoteLineWrapper.quoteLine;
                            parentQuoteLineWrapper.changedName = quoteLineWrapper.quoteLine.SBQQ__Product__r.Name;
                            parentQuoteLineWrapper.picklistValue = 'Prepay';
                            quotLinesToBeUpdated.push(parentQuoteLineWrapper);
                            parentQliIdVsPicklistValues.push(parentQuoteLineWrapper);
                        }
                    }
                    else if(
                        quoteLineWrapper.quoteLine.Product_Payment_Option__c == 'Prepay' &&
                        quoteLineWrapper.picklistValue == 'Prepay'
                    ) {
                        parentQuoteLineWrapper.quoteLine = quoteLineWrapper.quoteLine;
                        parentQuoteLineWrapper.changedName = quoteLineWrapper.quoteLine.SBQQ__Product__r.Name.slice(0,-2)+'PP';
                        parentQuoteLineWrapper.picklistValue = 'Prepay';
                        quotLinesToBeUpdated.push(parentQuoteLineWrapper);
                        parentQliIdVsPicklistValues.push(parentQuoteLineWrapper);
                    }
                    else if(
                        quoteLineWrapper.quoteLine.Product_Payment_Option__c == 'Annual' &&
                        quoteLineWrapper.picklistValue == 'Annual'
                    ) {
                        parentQuoteLineWrapper.quoteLine = quoteLineWrapper.quoteLine;
                        parentQuoteLineWrapper.changedName = quoteLineWrapper.quoteLine.SBQQ__Product__r.Name;
                        parentQuoteLineWrapper.picklistValue = 'Annual';
                        quotLinesToBeUpdated.push(parentQuoteLineWrapper);
                        parentQliIdVsPicklistValues.push(parentQuoteLineWrapper);
                    }
                }
            })
        })
    
        this.selectedQuoteIDs.forEach(quoteId => {
            this.allQuoteLineList.forEach(quoteLinewrap => {
                     
                if(
                      (quoteLinewrap.quoteLine.SBQQ__RequiredBy__c != null && quoteLinewrap.quoteLine.SBQQ__RequiredBy__c != undefined && 
                        quoteLinewrap.quoteLine.SBQQ__RequiredBy__c == quoteId) && 
                    (
                        quoteLinewrap.quoteLine.Product_Level__c != 'Hardware' ||
                        quoteLinewrap.quoteLine.Product_Level__c == ''
                    )
                ) {
                    
                    let quoteLineWrapper = {};
                   
                    parentQliIdVsPicklistValues.forEach(wrapper=>{
                        if(quoteLinewrap.quoteLine.SBQQ__RequiredBy__c==wrapper.quoteLine.Id){
                            quoteLineWrapper.picklistValue=wrapper.picklistValue;
                        }
                    })

                    if(
                        quoteLinewrap.quoteLine.Product_Payment_Option__c == 'Prepay' &&
                        quoteLineWrapper.picklistValue == 'Annual'
                    ) {
                        if(quoteLinewrap.quoteLine.SBQQ__Product__r.Name.endsWith('PP')) {
                            quoteLineWrapper.quoteLine = quoteLinewrap.quoteLine;
                            quoteLineWrapper.changedName = quoteLinewrap.quoteLine.SBQQ__Product__r.Name.slice(0,-2)+'PA';
                            quoteLineWrapper.picklistValue = 'Annual';
                            childQliIdVsAlldata.push(quoteLineWrapper);
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }else{
                            quoteLineWrapper.quoteLine = quoteLinewrap.quoteLine;
                            quoteLineWrapper.changedName = quoteLinewrap.quoteLine.SBQQ__Product__r.Name;
                            quoteLineWrapper.picklistValue = 'Annual';
                            childQliIdVsAlldata.push(quoteLineWrapper);
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }
                    } else if(
                        quoteLinewrap.quoteLine.Product_Payment_Option__c == 'Annual' &&
                        quoteLineWrapper.picklistValue == 'Prepay'
                    ) {
                        
                        if(quoteLinewrap.quoteLine.SBQQ__Product__r.Name.endsWith('PA')) {
                            quoteLineWrapper.quoteLine = quoteLinewrap.quoteLine;
                            quoteLineWrapper.changedName = quoteLinewrap.quoteLine.SBQQ__Product__r.Name.slice(0,-2)+'PP';
                            quoteLineWrapper.picklistValue = 'Prepay';
                            childQliIdVsAlldata.push(quoteLineWrapper);
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }else {
                            quoteLineWrapper.quoteLine = quoteLinewrap.quoteLine;
                            quoteLineWrapper.changedName = quoteLinewrap.quoteLine.SBQQ__Product__r.Name;
                            quoteLineWrapper.picklistValue = 'Prepay';
                            childQliIdVsAlldata.push(quoteLineWrapper);
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }
                    }
                    else if(
                        quoteLinewrap.quoteLine.Product_Payment_Option__c == 'Annual' &&
                        quoteLineWrapper.picklistValue == 'Annual'
                    ) {
                        quoteLineWrapper.quoteLine = quoteLinewrap.quoteLine;
                        quoteLineWrapper.changedName = quoteLinewrap.quoteLine.SBQQ__Product__r.Name;
                        quoteLineWrapper.picklistValue = 'Annual';
                        childQliIdVsAlldata.push(quoteLineWrapper);
                        quotLinesToBeUpdated.push(quoteLineWrapper);
                    }
					else if(
                        quoteLinewrap.quoteLine.Product_Payment_Option__c == 'Prepay' &&
                        quoteLineWrapper.picklistValue == 'Prepay'
                    ) {
                        quoteLineWrapper.quoteLine = quoteLinewrap.quoteLine;
                        quoteLineWrapper.changedName = quoteLinewrap.quoteLine.SBQQ__Product__r.Name;
                        quoteLineWrapper.picklistValue = 'Prepay';
                        childQliIdVsAlldata.push(quoteLineWrapper);
                        quotLinesToBeUpdated.push(quoteLineWrapper);

                    } 
                }
            })
        })

        childQliIdVsAlldata.forEach(childQuoteLines => {
            this.allQuoteLineList.forEach(quoteLineAll => {
                if(( quoteLineAll.quoteLine.SBQQ__RequiredBy__c != null && quoteLineAll.quoteLine.SBQQ__RequiredBy__c != undefined &&
                    quoteLineAll.quoteLine.SBQQ__RequiredBy__c == childQuoteLines.quoteLine.Id )&&
                    (
                        quoteLineAll.quoteLine.Product_Level__c != 'Hardware' ||
                        quoteLineAll.quoteLine.Product_Level__c == ''
                    )
                ) {
                    let quoteLineWrapper = {};

                    if(
                        quoteLineAll.quoteLine.Product_Payment_Option__c == 'Prepay' &&
                        childQuoteLines.picklistValue == 'Annual'
                    ) {
                        if(quoteLineAll.quoteLine.SBQQ__Product__r.Name.endsWith('PP')) {
                            quoteLineWrapper.quoteLine = quoteLineAll.quoteLine;
                            quoteLineWrapper.changedName = quoteLineAll.quoteLine.SBQQ__Product__r.Name.slice(0,-2)+'PA';
                            quoteLineWrapper.picklistValue = 'Annual';
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }else{
                            quoteLineWrapper.quoteLine = quoteLineAll.quoteLine;
                            quoteLineWrapper.changedName = quoteLineAll.quoteLine.SBQQ__Product__r.Name;
                            quoteLineWrapper.picklistValue = 'Annual';
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }
                    } else if(
                        quoteLineAll.quoteLine.Product_Payment_Option__c == 'Annual' &&
                        childQuoteLines.picklistValue == 'Prepay'
                    ) {
                        if(quoteLineAll.quoteLine.SBQQ__Product__r.Name.endsWith('PA')) {
                            quoteLineWrapper.quoteLine = quoteLineAll.quoteLine;
                            quoteLineWrapper.changedName = quoteLineAll.quoteLine.SBQQ__Product__r.Name.slice(0,-2)+'PP';
                            quoteLineWrapper.picklistValue = 'Prepay';
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }else {
                            quoteLineWrapper.quoteLine = quoteLineAll.quoteLine;
                            quoteLineWrapper.changedName = quoteLineAll.quoteLine.SBQQ__Product__r.Name;
                            quoteLineWrapper.picklistValue = 'Prepay';
                            quotLinesToBeUpdated.push(quoteLineWrapper);
                        }
                    }
                    else if(
                        quoteLineAll.quoteLine.Product_Payment_Option__c == 'Annual' &&
                        childQuoteLines.picklistValue == 'Annual'
                    ) {
                        quoteLineWrapper.quoteLine = quoteLineAll.quoteLine;
                        quoteLineWrapper.changedName = quoteLineAll.quoteLine.SBQQ__Product__r.Name;
                        quoteLineWrapper.picklistValue = 'Annual';
                        quotLinesToBeUpdated.push(quoteLineWrapper);
                    }
					else if(
                        quoteLineAll.quoteLine.Product_Payment_Option__c == 'Prepay' &&
                        childQuoteLines.picklistValue == 'Prepay'
                    ) {
                        quoteLineWrapper.quoteLine = quoteLineAll.quoteLine;
                        quoteLineWrapper.changedName = quoteLineAll.quoteLine.SBQQ__Product__r.Name;
                        quoteLineWrapper.picklistValue = 'Prepay';
                        quotLinesToBeUpdated.push(quoteLineWrapper);
                    } /*else {

                        isConditionMatched = false;
                    }*/
                }
            })
        })

        let errorCount = 0;
        //if(isConditionMatched == true) {
            errorCount = 0;
            let quoteLineWrapper = JSON.stringify(quotLinesToBeUpdated);
            
            this.isShowSpinner = true;
              await switchPaymentOption({
                quoteLineDataWrapper : quoteLineWrapper
            }).then(result => {
                let faliureErrors='';
                result.forEach(updateWrapperList => {

                    updateWrapperList.forEach(updateWrapper => {

                        if(updateWrapper.isSuccess == false) {
                            faliureErrors+=updateWrapper.message + '\n';

                            errorCount += 1;
                        }
                        else if(updateWrapper.isSuccess == true) {

                            this.showToastNotification('success', updateWrapper.message, 'success');
                        }
                    })
                });
                if(errorCount>0){
                    this.showToastNotification('error', faliureErrors, 'error');
                }
            }).catch(error => {

                this.isShowSpinner = false;
                this.showToastNotification('error', error, 'error');
            });
        //}
        /*else {
            errorCount += 1;
            this.showToastNotification('Error', 'Already has same payment option', 'error');
        }*/

        this.isShowSpinner = false;
          if(errorCount == 0) {

            //this.navigateToRecordViewPage();
            window.open('/'+this.recordId, '_top');
        } 
    }
    recordPageUrl;
    navigateToRecordViewPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'SBQQ__Quote__c',
                actionName: 'view',
            },
        });
    }

    showToastNotification(toastTitle, toastMessage, toastVariant) {

        const evt = new ShowToastEvent({
            title: toastTitle,
            message: toastMessage,
            variant: toastVariant
        });
        this.dispatchEvent(evt);
    }
}