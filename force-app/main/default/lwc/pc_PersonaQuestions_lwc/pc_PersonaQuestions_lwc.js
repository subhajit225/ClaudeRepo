import { LightningElement, wire, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import PersonaQuestions from '@salesforce/resourceUrl/PCPersonaQuestions';
import getPersonaQuestionsDetails from '@salesforce/apex/PC_PortalNavigationApexController.getPersonaQuestionsDetails';
import updateContact from '@salesforce/apex/PC_PortalNavigationApexController.updateContactRecord';

export default class Pc_PersonaQuestions_lwc extends LightningElement {
    isShowModal = true;
    showLoader = false;
    error;
    cardList = [];
    stylePath = PartnerCommunityResource;
    @api conid; 
    contactRec = {};

    connectedCallback(){
        console.log('m here');
        Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityFolder/PartnerCommunityCSS.css')
        ]).then(() => {
            //console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error );
        });

        this.getPersonaDetails();
    }

    getPersonaDetails(){
        getPersonaQuestionsDetails()
        .then(result=>{
            console.log('--->'+JSON.stringify(result));
            this.cardList = result;
        })
        .catch(error=>{
            console.log('--<'+JSON.stringify(error));
        });
    }

    handleClick(event){
        let role = event.currentTarget.dataset.role;
        if(role){
            this.contactRec.Id = this.conid;
            this.contactRec.Primary_Role__c = role;
            this.contactRec.Persona_Captured__c = new Date().toJSON().slice(0, 10);
            this.showLoader = true;
            this.saveContact();
        }
    }

    saveContact(){
        updateContact({ conRec: this.contactRec })
            .then((result) => {
                window.location.reload();
            })
            .catch((error) => {
                console.log(error);
            });
    }
}