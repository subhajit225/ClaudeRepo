import { LightningElement,api,wire,track } from 'lwc';
import getCaseDescription from '@salesforce/apex/CaseDetailController.getCaseDescription';
import { refreshApex } from '@salesforce/apex';

export default class LWC_CaseSpecialHandling extends LightningElement {

    @track accountpreference;
    @track headsuptosupportteam;
    @track CaseDetailsSectionHide = false;
    @api recordId;

    @wire(getCaseDescription,{ recordId: '$recordId'})
    wiredDetails(result) {
        if (result.data) {
            var newres = [];
          
            result.data.forEach(function(item){
                newres.push(item);
              });
              this.accountpreference = newres[0].Account_Preference__c;
              this.headsuptosupportteam = newres[0].Account != null ? newres[0].Account.Heads_Up_to_Support_Team__c : '';
              this.caseattr = result;
              console.log('this.CaseDetailsSectionHide before'+ this.CaseDetailsSectionHide);
              if(this.headsuptosupportteam != null){
                this.template.querySelector('.downArrowlwc').classList.remove('slds-hide');
                this.template.querySelector('.downArrowlwc').classList.add('slds-show');
                this.template.querySelector('.rightArrowlwc').classList.remove('slds-show');
                this.template.querySelector('.rightArrowlwc').classList.add('slds-hide');
                this.CaseDetailsSectionHide = true; 
              } else{
                this.template.querySelector('.downArrowlwc').classList.remove('slds-show');
                this.template.querySelector('.downArrowlwc').classList.add('slds-hide');
                this.template.querySelector('.rightArrowlwc').classList.remove('slds-hide');
                this.template.querySelector('.rightArrowlwc').classList.add('slds-show');
                this.CaseDetailsSectionHide = false;
              }
              console.log('this.CaseDetailsSectionHide after'+ this.CaseDetailsSectionHide);

            }

        } 

        hidecasedesc() {
            this.template.querySelector('.downArrowlwc').classList.remove('slds-show');
            this.template.querySelector('.downArrowlwc').classList.add('slds-hide');
            this.template.querySelector('.rightArrowlwc').classList.remove('slds-hide');
            this.template.querySelector('.rightArrowlwc').classList.add('slds-show');
            this.CaseDetailsSectionHide = false; 
            console.log('this.CaseDetailsSectionHide hidecasedesc'+ this.CaseDetailsSectionHide);
        }
        
        showcasedesc() {
            this.template.querySelector('.downArrowlwc').classList.remove('slds-hide');
            this.template.querySelector('.downArrowlwc').classList.add('slds-show');
            this.template.querySelector('.rightArrowlwc').classList.remove('slds-show');
            this.template.querySelector('.rightArrowlwc').classList.add('slds-hide');
            this.CaseDetailsSectionHide = true; 
            console.log('this.CaseDetailsSectionHide showcasedesc'+ this.CaseDetailsSectionHide);
        } 

}