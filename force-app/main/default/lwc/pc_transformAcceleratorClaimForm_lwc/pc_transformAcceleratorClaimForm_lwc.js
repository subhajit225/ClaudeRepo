import { LightningElement, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import INCENTIVE from '@salesforce/schema/Incentives__c';
import recordTypeId from '@salesforce/label/c.Transform_Accelerator_Claim_Record_Type';
import saveIncentive from '@salesforce/apex/PC_PortalNavigationApexController.saveIncentiveData';
export default class Pc_transformAcceleratorClaimForm_lwc extends LightningElement {

    showSpinner = false;
    type;
    url;
    @track optionsType = [];
    @track fileNames='';
    @track fileIds = [];

    @wire(getPicklistValuesByRecordType, {recordTypeId: recordTypeId, objectApiName : INCENTIVE})
    recordTypeValues({error,data}){
        if(data){
            this.optionsType = data.picklistFieldValues.Type__c.values;
        }else if(error){
            console.log(error);
        }
    }
    
    connectedCallback() {
        Promise.all([loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')])
        .then(() => {
        })
        .catch(error => {
            console.log( error.body.message );
        });
    }

    handleTypeChange(event){
        this.type = event.target.value;
    }

    handleURLChange(event){
        this.url = event.target.value;
    }

    handleUploadFinished(event){
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        if(uploadedFiles.length > 0){
            for(let i=0; i< uploadedFiles.length; i++){
                this.fileIds.push(uploadedFiles[i].documentId);
                this.fileNames = this.fileNames + uploadedFiles[i].name + ',';
            }
            this.fileNames.substring(0, this.fileNames.length-1);
        }
        console.log('No. of files uploaded : ' + JSON.stringify(uploadedFiles));
    }

    handleSubmit(event){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.formClass');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }else{
                inputField.reportValidity();
            }
        });
        if(this.fileNames.length == 0){
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Please upload a file',
                duration:' 3000',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        }
        if(isValid && this.fileNames.length > 0){
            this.showSpinner = true;
            saveIncentive({filesToInsert : this.fileIds, url : this.url, type : this.type})
            .then(result=>{
                console.log('result->'+result);
                if(result =='success'){
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: 'Claim submitted successfully',
                        duration:' 3000',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.fileNames = '';
                    this.url = '';
                    this.type='';
                }else{
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Claim submission error'+ result,
                        duration:' 3000',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                }
                this.showSpinner = false;
            })
            .catch(error=>{
                console.log('error'+JSON.stringify(error));
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Claim submission error'+ result,
                    duration:' 3000',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                this.showSpinner = false;
            });
        }
    }

}