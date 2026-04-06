import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import basepath from '@salesforce/community/basePath';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLoggedInUserDetails from '@salesforce/apex/PC_PortalNavigationApexController.getLoggedInUserDetails';
import createContract from '@salesforce/apex/PC_PortalNavigationApexController.createContract';
import callReSignPactsafe from '@salesforce/apex/PC_PortalNavigationApexController.callReSignPactsafe';

export default class Pc_partnerAgreement_lwc extends LightningElement {

    @track spinnerLoad = true;
    @track showAgreementLabel = true;
    @track partnerType;
    @track partnerEmail;
    @track partnerAccId;
    @track resellerAgreement = false;
    @track mspAgreement = false;
    @track baseUrl = basepath;
    
    @track openMasterTermsModal = false;

    masterTermsAndConditionsAgreed = false;
    masterUrl = '';
    masterAgreementCheck = false;

    resellerAgreed = false;
    resellerUrl = '';
    resellerAgreementCheck = false;

    mspAgreed = false;
    mspUrl = '';
    mspAgreementCheck = false;

    submitDisabled = true;

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                this.spinnerLoad = false;
            })
            .catch(error => {
                console.log('--33->'+ error.body.message);
                this.spinnerLoad = false;
        });

        getLoggedInUserDetails()
        .then(result=>{
            if(result.ContactId != null){
                this.partnerEmail = result.Contact.Email;
                this.partnerType = result.Contact.Account.Type;
                this.partnerAccId = result.Contact.AccountId;
                this.contactId = result.ContactId;
            }

            if(this.partnerType == 'Reseller'){
                this.resellerAgreement = true;
            }else{
                this.partnerType = 'MSP-Reseller';
                this.mspAgreement = true;
                this.resellerAgreement = true;
            }
            
        })
        .catch(error=>{
            console.log('error in fetching user details->'+error);
        });
    }

    checkSubmitDisabled(){
        if(this.masterAgreementCheck && this.resellerAgreementCheck && (this.partnerType == 'Reseller' || ((this.partnerType == 'MSP-Reseller'|| this.partnerType == 'MSP') && this.mspAgreementCheck))){
            this.submitDisabled = false;
        }
    }


    openMasterModel(){
        if(this.partnerType != null && this.partnerEmail != null){
            if(this.baseUrl.search('/s') >= 0){
                var temp = this.baseUrl.split('/s');
                this.baseUrl = temp[0];
            }
            this.masterUrl = this.baseUrl + '/apex/Pactsafe?groupType=Master&partnerType=' + this.partnerType +'&email=' + this.partnerEmail+'&accid=' + this.partnerAccId;
            this.openMasterTermsModal = true;
            this.masterTermsAndConditionsAgreed = true;
            window.addEventListener("message", (event) => {
                if (event.data.name === "Master") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        this.masterAgreementCheck = true;
                    }else{
                        this.masterAgreementCheck = false;
                    }
                }
                this.openMasterTermsModal = false;
                this.masterTermsAndConditionsAgreed = false;
                this.checkSubmitDisabled();
            });
        }
    }

    openResellerModel(){
        if(this.partnerType != null && this.partnerEmail != null){
            if(this.baseUrl.search('/s') >= 0){
                var temp = this.baseUrl.split('/s');
                this.baseUrl = temp[0];
            }
            this.resellerUrl = this.baseUrl + '/apex/Pactsafe?groupType=Secondary&partnerType=' + this.partnerType +'&email=' + this.partnerEmail+'&accid=' + this.partnerAccId;
            this.openMasterTermsModal = true;
            this.resellerAgreed = true;
            window.addEventListener("message", (event) => {
                if (event.data.name === "Secondary") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        this.resellerAgreementCheck = true;
                    }else{
                        this.resellerAgreementCheck = false;
                    }
                }
                this.openMasterTermsModal = false;
                this.resellerAgreed = false;
                this.checkSubmitDisabled();
            });
        }
    }

    openMSPModel(){
        if(this.partnerType != null && this.partnerEmail != null){
            if(this.baseUrl.search('/s') >= 0){
                var temp = this.baseUrl.split('/s');
                this.baseUrl = temp[0];
            }
            this.mspUrl = this.baseUrl + '/apex/Pactsafe?groupType=Tertiary&partnerType=' + this.partnerType +'&email=' + this.partnerEmail+'&accid=' + this.partnerAccId;
            this.openMasterTermsModal = true;
            this.mspAgreed = true;
            window.addEventListener("message", (event) => {
                if (event.data.name === "Tertiary") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        this.mspAgreementCheck = true;
                    }else{
                        this.mspAgreementCheck = false;
                    }
                }
                this.openMasterTermsModal = false;
                this.mspAgreed = false;
                this.checkSubmitDisabled();
            });
        }
    }

    hideModalBox(){
        this.openMasterTermsModal = false;
        this.masterTermsAndConditionsAgreed = false;
        this.resellerAgreed = false;
        this.mspAgreed = false;
    }

    handleSubmit(event){
        //write save logic
        this.spinnerLoad = true;
        callReSignPactsafe({ partnertype: this.partnerType, email : this.partnerEmail})
          .then(result => {
            let urls = [];
            for(let key in result){
                urls.push(result[key]);
            }
            createContract({ contactId: this.contactId, urls : urls})
              .then(result => {
                if(result == 'SUCCESS'){
                    this.showToastEvent('SUCCESS','Contract Resigned','success');
                    setTimeout(() => {
                        window.location.href = window.location.origin; // Replace with your desired URL
                    }, 1500);
                }else{
                    this.showToastEvent('Error',result,'error')
                }
                this.spinnerLoad = false;
              })
              .catch(error => {
                console.error('Error:', error);
                this.showToastEvent('Error','Something went wrong','error');
                this.spinnerLoad = false;
            });
          })
          .catch(error => {
            this.showToastEvent('Error','Something went wrong','error');
            console.error('Error:', error);
            this.spinnerLoad = false;
        });
        
        //reload the form to initial state and reload the page
        window.load(window.location.origin);

    }


    showToastEvent(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}