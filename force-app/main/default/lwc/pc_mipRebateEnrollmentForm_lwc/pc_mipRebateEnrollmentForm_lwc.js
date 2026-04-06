import { LightningElement, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadMIPForm from '@salesforce/apex/PC_PortalNavigationApexController.loadMIPForm'; 
import generateMIPContract from '@salesforce/apex/PC_PortalNavigationApexController.generateMIPContract'; 
export default class Pc_mipRebateEnrollmentForm_lwc extends LightningElement {
    @track spinnerLoad = true;
    @track showForm = false;
    @track configName;
    @track partnerAccountName;
    @track partnerAccountId;
    @track cdmId;
    @track cdmName;
    @track agreementText;
    @track descriptionText;
    @track contactId;
    @track formTitle;
    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });

        loadMIPForm()
        .then(result=>{
            console.log('result'+JSON.stringify(result));
            if(result.u.ContactId != null){
                this.partnerAccountName = result.u.Contact.Account.Name;
                this.partnerAccountId = result.u.Contact.AccountId;
                this.cdmId = result.u.Contact.Account.OwnerId;
                this.cdmName = result.u.Contact.Account.Owner.Name;
            }
            this.formTitle = result.pConfig.Headline__c;
            this.configName = result.pConfig.Name;
            this.agreementText = result.pConfig.Image_Text__c;
            this.descriptionText = result.pConfig.Card_Title__c;
            this.startDate = result.pConfig.Program_Start_Date__c;
            this.endDate = result.pConfig.Program_End_Date__c;
            this.fiscalPeriod = result.pConfig.Fiscal_Period__c;
            this.spinnerLoad = false;
            if(result.pConfig.Id != null){
                this.showForm = true;
            }
        })
        .catch(error=>{
            console.log('error->'+error);
        });
    }

    handleSelectedContact(event){
        this.contactId = event.detail.Id;
    }

    handleClearSelection(){
        this.contactId = null;
    }

    handleSubmit(){
        console.log('Save');
        this.spinnerLoad = true;
        let jsonData = {
            accId : this.partnerAccountId,
            conId : this.contactId,
            usrId : this.cdmId,
            accName : this.partnerAccountName,
            sDate : this.startDate,
            eDate : this.endDate,
            fPeriod : this.fiscalPeriod,
            agrText : this.agreementText
        }
        generateMIPContract({ formData : JSON.stringify(jsonData)})
        .then(result=>{
            this.spinnerLoad = false;
            this.handleClearSelection();
            this.showToastEvent('SUCCESS','MIP Rebate Enrollment Successful','success');

        }).catch(error=>{
            console.log(error);
            this.spinnerLoad = false;
            this.showToastEvent('ERROR','Something unexpected occurred','error');
        });
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