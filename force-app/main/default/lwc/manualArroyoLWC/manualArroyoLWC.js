import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import modal from "@salesforce/resourceUrl/quickActionWidthLWCCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import getDetails from '@salesforce/apex/OpportunityManualOverride.getDetails';
import saveItem from '@salesforce/apex/OpportunityManualOverride.saveItem';
export default class ManualArroyoOLIscreen extends NavigationMixin(LightningElement) {
    @api recordId;
    @track acvAmount;
    @track subsumedACV;
    @track subsumedTCV;
    @track new_expansionACV;
    @track new_expansionTCV;
    @track core_new_expansionACV;
    @track nas_new_expansionACV;
    @track saas_new_expansionACV;
    @track ncd_new_expansionACV; //SAL26-1291
    @track subsumed_renewal_churnACV;
    @track subsumed_renewal_churnTCV;
    @track comp_uplift_acv; //SAL26-1277
     @track recordWrapDetails = {};
    
    @track disableButtons = false;
    @track showLoader = false;
    connectedCallback(){
      
        loadStyle(this, modal);
        this.showLoader = true;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            console.log(' recordId..!', this.recordId);
            getDetails({
                'recordId' : this.recordId
            }).then(result => {
                console.log(' oppDetails..!');         
                console.log(result);
                this.recordWrapDetails = result[0];
               if(result[0].errMsg != ''){
                   this.showToast('', result[0].errMsg, result[0].variant, 'pester');
                   this.disableButtons = true;
               }
               this.acvAmount = this.recordWrapDetails.acvAmount;
               this.subsumedACV = this.recordWrapDetails.subsumedACV;
               this.subsumedTCV = this.recordWrapDetails.subsumedTCV;
               this.new_expansionACV = this.recordWrapDetails.new_expansionACV;
               this.new_expansionTCV = this.recordWrapDetails.new_expansionTCV;
               this.core_new_expansionACV = this.recordWrapDetails.core_new_expansionACV;
               this.nas_new_expansionACV = this.recordWrapDetails.nas_new_expansionACV;
               this.saas_new_expansionACV = this.recordWrapDetails.saas_new_expansionACV;
               this.ncd_new_expansionACV = this.recordWrapDetails.ncd_new_expansionACV; //SAL26-1291
               this.subsumed_renewal_churnACV = this.recordWrapDetails.subsumed_renewal_churnACV;
               this.subsumed_renewal_churnTCV = this.recordWrapDetails.subsumed_renewal_churnTCV;
               this.comp_uplift_acv = this.recordWrapDetails.comp_uplift_acv; //SAL26-1277
               this.showLoader = false;
            }).catch(error => {
                this.showLoader = false;
                    console.log('error..!', error);
                    this.showToast('', error, 'error', 'pester');
                });
        }, 100);
    }

    handleACVChange(event){
        this.acvAmount = event.target.value;
    }
    handleSubACVChange(event){
        this.subsumedACV = event.target.value;  
    }
    handleNewExpACVChange(event){
        this.new_expansionACV = event.target.value;
    }
    handleSubTCVChange(event){
        this.subsumedTCV = event.target.value;
    }
    handleNewExpTCVChange(event){
        this.new_expansionTCV = event.target.value;
    }
    handleCoreNewExpACVChange(event){
        this.core_new_expansionACV = event.target.value;
    }
    handleNasNewExpACVChange(event){
        this.nas_new_expansionACV = event.target.value;
    }
    handleSaaSNewExpACVChange(event){
        this.saas_new_expansionACV = event.target.value;
    }
    //SAL26-1291
    handleNCDNewExpACVChange(event){
        this.ncd_new_expansionACV = event.target.value;
    }
    handleSubsumedRenewalChurnACV(event){
        this.subsumed_renewal_churnACV = event.target.value;
    }
    handleSubsumedRenewalChurnTCV(event){
        this.subsumed_renewal_churnTCV = event.target.value;
    }
    handleFieldChange(event){//SAL26-1277
        const fieldName = event.target.dataset.fieldname;
        this[fieldName] = event.target.value;
    }

    handleSubmit(event){ 
        this.showLoader = true;
        if(this.core_new_expansionACV == '' || this.core_new_expansionACV == undefined || isNaN(this.core_new_expansionACV)){this.core_new_expansionACV = 0;}
        if(this.nas_new_expansionACV == '' || this.nas_new_expansionACV == undefined || isNaN(this.core_new_expansionACV)){this.nas_new_expansionACV = 0;}
        if(this.saas_new_expansionACV == '' || this.saas_new_expansionACV == undefined || isNaN(this.core_new_expansionACV)){this.saas_new_expansionACV = 0;}
        if(this.ncd_new_expansionACV == '' || this.ncd_new_expansionACV == undefined || isNaN(this.ncd_new_expansionACV)){this.ncd_new_expansionACV = 0;} //SAL26-1291
        if(this.subsumed_renewal_churnACV == '' || this.subsumed_renewal_churnACV == undefined || isNaN(this.core_new_expansionACV)){this.subsumed_renewal_churnACV = 0;}
        if(this.subsumed_renewal_churnTCV == '' || this.subsumed_renewal_churnTCV == undefined || isNaN(this.core_new_expansionACV)){this.subsumed_renewal_churnTCV = 0;}
        if(!this.comp_uplift_acv || isNaN(this.comp_uplift_acv) || this.comp_uplift_acv < 0){//SAL26-1277
            this.comp_uplift_acv = 0;
        }
        var core = parseFloat(this.core_new_expansionACV);
        var nas = parseFloat(this.nas_new_expansionACV);
        var saas = parseFloat(this.saas_new_expansionACV);
        var ncd = parseFloat(this.ncd_new_expansionACV); //SAL26-1291
        var new_ExpACV = parseFloat(this.new_expansionACV).toFixed(5);
        var coreAndPls = parseFloat(core) + parseFloat(nas) + parseFloat(saas) + parseFloat(ncd); //SAL26-1291
        coreAndPls = coreAndPls.toFixed(5);
        if(parseFloat(new_ExpACV) != parseFloat(coreAndPls)){
            this.showToast('', 'New/Expansion ACV should be always summation of Core & PLS New/Expansion ACV values', 'error', 'pester');
            this.showLoader = false;
        }else{
            saveItem({
                    'recordId' : this.recordId,
                    'acvAmount' : this.acvAmount,
                    'subsumedACV' : this.subsumedACV,
                    'subsumedTCV' : this.subsumedTCV,
                    'new_expansionACV' : this.new_expansionACV,
                    'new_expansionTCV' : this.new_expansionTCV,
                    'core_new_expansionACV' : this.core_new_expansionACV,
                    'nas_new_expansionACV' : this.nas_new_expansionACV,
                    'ncd_new_expansionACV' : this.ncd_new_expansionACV, //SAL26-1291
                    'saas_new_expansionACV' : this.saas_new_expansionACV,
                    'subsumed_renewal_churnACV' : this.subsumed_renewal_churnACV,
                    'subsumed_renewal_churnTCV' : this.subsumed_renewal_churnTCV,
                    'comp_uplift_acv' : this.comp_uplift_acv //SAL26-1277

                }).then(result => {
                    this.showLoader = false;
                    console.log(' save manual arroyo override..!');         
                    console.log(this.recordId);
                    console.log(result);
                    if(result === true){
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId : this.recordId,
                                actionName : 'view'
                            }
                        }); 
                    }
                }).catch(error => {
                    this.showLoader = false;
                    console.log('error..!', error);
                    this.showToast('', error.body.message, 'error', 'pester');
                }); 
        }
    }

    handleCancel(event){ 
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    } 
}