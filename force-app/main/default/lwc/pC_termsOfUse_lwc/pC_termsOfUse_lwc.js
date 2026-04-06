import { LightningElement,wire,api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import basepath from '@salesforce/community/basePath';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import updateContact from '@salesforce/apex/PC_PortalNavigationApexController.updateContactRecord';

export default class PC_termsOfUse_lwc extends LightningElement {
    baseUrl = basepath;
    partnerType = 'All';
    masterUrl;
    error;
    @api contact = {};
    contactUpdate = {};

    connectedCallback() {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
            });
            this.openMasterModal();
    }

    openMasterModal(){
        if(this.partnerType != "" && this.contact.Email != ""){
            if(this.baseUrl.search('/s') >= 0){
                var temp = this.baseUrl.split('/s');
                this.baseUrl = temp[0];
            }
            this.masterUrl = this.baseUrl + '/apex/Pactsafe?groupType=TermsOfUse&partnerType=' + this.partnerType +'&email=' + this.contact;
            window.addEventListener("message", (event) => {
                if (event.data.name === "TermsOfUse") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        this.showSpinner = true;
                        //Update Field On Contact
                        this.saveContact();
                    }else{

                    }
                }
            });
        }
    }

    saveContact(){
        this.contactUpdate.Id = this.contact.Id;
        this.contactUpdate.Partner_Terms_of_Use__c = true;
        updateContact({ conRec: this.contactUpdate })
            .then((result) => {
                this.callParentModal();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Terms Updated",
                        variant: "success"
                    })
                );
            })
            .catch((error) => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error Updating Terms",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }

    callParentModal(){
        const callParent = new CustomEvent("callwizardvisibilty",{
            detail : this.contactUpdate
        });
        this.dispatchEvent(callParent);
    }
}