import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import PDS_1 from '@salesforce/label/c.PDS_1';
import PDS_2 from '@salesforce/label/c.PDS_2';
import PDS_3 from '@salesforce/label/c.PDS_3';
import PDS_4 from '@salesforce/label/c.PDS_4';
import FirstName from '@salesforce/schema/Contact.FirstName';
import LastName from '@salesforce/schema/Contact.LastName';
import JobTitle from '@salesforce/schema/Contact.Title';
import Email from '@salesforce/schema/Contact.Email';
import CompanyName from '@salesforce/schema/Contact.mkto71_Inferred_Company__c';
import preferredDistributorSelection from '@salesforce/apex/PC_PortalNavigationApexController.preferredDistributorSelection';
import DistributorNames from '@salesforce/label/c.PDS_Distributor_Names';
export default class Pc_preferredDistributorSelection_lwc extends LightningElement {

    rubrikFaqLink;
    formDescription1 = PDS_1;
    formDescription2 = PDS_2 + PDS_3;
    formDescription3 = PDS_4;
    distiValue;
    @track distiOptions = [];
    @track distributorNames = DistributorNames;
    emailRegex = '^([\\w.-]+)@(\\[(\\d{1,3}\\.){3}|(?!hotmail|googlemail|gmail|yahoo|gmx|ymail|outlook)(([a-zA-Z\\d-]+\\.)+))([a-zA-Z]{2,4}|\\d{1,3})(\\]?)$';
    fieldNames ={
        firstName : FirstName.fieldApiName,
        lastName : LastName.fieldApiName,
        jobTitle : JobTitle.fieldApiName,
        companyName : CompanyName.fieldApiName,
        email : Email.fieldApiName
    };
    @track contactRec = {
        [FirstName.fieldApiName] : "",
        [LastName.fieldApiName] : "",
        [JobTitle.fieldApiName] : "",
        [CompanyName.fieldApiName] : "",
        [Email.fieldApiName] : ""
    }
    showSpinner = false;
    isDisabled = false;

    connectedCallback(){
        Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
        })
        .catch(error => {
            console.log( error.body.message );
        });

        console.log('dNames->'+this.distributorNames);
        let disArray = this.distributorNames.split(';');
        for(let i =0; i<disArray.length; i++){
            this.distiOptions.push({label :disArray[i] , value:disArray[i]});
        }
    }

    handleChangeEvent(event){
        this.contactRec[event.target.name] = event.target.value;
    }

    handleRadioChange(event){
        this.distiValue = event.target.value;
    }

    handleAccept(event){
        console.log('--->'+JSON.stringify(this.contactRec));
        console.log('-distributor->'+this.distiValue);
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.formDetails');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }else{
                inputField.reportValidity();
            }
        });
        if(isValid){
            this.showSpinner = true;
            preferredDistributorSelection({conObj : this.contactRec, distributorName : this.distiValue})
            .then(result=>{
                console.log('result->'+result);
                if(result == 'success'){
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: 'Form Submitted: An email confirmation has been sent.',
                        duration:' 3000',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.showSpinner = false;
                    this.isDisabled = true;
                }
            })
            .catch(error=>{
                console.log('error->'+error);
                this.showSpinner = false;
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Preferred Distributor Selection Failure',
                    duration:' 3000',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            });
        }
    }

}