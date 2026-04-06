import { LightningElement,wire,api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import Id from '@salesforce/user/Id';
import { refreshApex } from '@salesforce/apex';
import getContactConfig from '@salesforce/apex/PC_PortalNavigationApexController.getContactWelcomeWizardConfig';
import updateContact from '@salesforce/apex/PC_PortalNavigationApexController.updateContactRecord';

export default class PC_WelcomeWizard_lwc extends LightningElement {
    userId = Id;
    showTermsOfUse = false;
    showPersonaQuestions = false;
    showEventPromo = false;
    showResources = false;
    showWelcomeVideo = false;
    userRec;
    contactRec = {};
    showNext = false;
    showFinish = false;
    showWelcomeWizard = true;
    termsUpdated = false;
    contactId;
    conRecToUpdate = {};
    isEventPromo = false;
    @api _contactRecord = {};
    error;
    showSpinner = true;
    welcomeVidDisabled = false;
    eventBannerDisabled = false;
    pageName = '';
    showAmplifyTerms = false;

    connectedCallback() {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });
        this.showSpinner = true;
        this.pageName = window.document.title;
    }

    @wire(getContactConfig, { partnerUserId: '$userId' })
    wiredContacts(wireResult){
        const { data, error } = wireResult;
        this.userRec = wireResult;
        if(data){
            //console.log("contactRec", data);
            this.contactRec = data;
            this._contactRecord = data.Contact;
            this.contactId = data.ContactId;
            this.setWizardVisibilty();
        }
        if(error) {
            console.error(error)
        }
    }

    setWizardVisibilty(){
        this.showSpinner = true;
        if(this.pageName == 'Home'){
            this.showAmplifyTerms = false;
            if(this.contactRec.Contact.Persona_Captured__c){
                var currentDate = new Date();
                currentDate = currentDate.setFullYear(currentDate.getFullYear() - 1);
                var personaCapturedLastDate = Date.parse(this.contactRec.Contact.Persona_Captured__c);
            }

            if(!this.contactRec.Contact.Partner_Terms_of_Use__c){
                this.showPersonaQuestions = false;
                this.showWelcomeVideo = false;
                this.showTermsOfUse = true;
                this.showSpinner = false;
            }else if((!this.contactRec.Contact.Primary_Role__c || !this.contactRec.Contact.Persona_Captured__c) || personaCapturedLastDate < currentDate){
                this.showTermsOfUse = false;
                this.showWelcomeVideo = false;
                this.showPersonaQuestions = true;
                this.showSpinner = false;
            }else if(!this.contactRec.Contact.Partner_Welcome_Video__c && !this.welcomeVidDisabled){
                this.showTermsOfUse = false;
                this.showPersonaQuestions = false;
                this.showWelcomeVideo = true;
                this.showFinish = false;
                this.showNext = true;
                this.showSpinner = false;
            }else if(!this.contactRec.Contact.Partner_Promo_Banner__c && !this.eventBannerDisabled){
                this.showTermsOfUse = false;
                this.showPersonaQuestions = false;
                this.showWelcomeVideo = false;
                this.showEventPromo = true;
                this.showNext = true;
                if(this.isEventPromo){
                    this.showEventPromo = false;
                    this.showNext = false;
                    this.showResources = true;
                    this.showFinish = true;
                }
                this.showSpinner = false;
            }else if(this.contactRec.Contact.Partner_Promo_Banner__c){
                this.showWelcomeWizard = false;
                this.showSpinner = false;
            }else {
                this.showWelcomeWizard = false;
                this.showSpinner = false;
            }
        }else if(this.pageName == 'Lead Dashboard'){
            if(!this.contactRec.Contact.Partner_Rubrik_Amplify_Terms__c){
                this.showPersonaQuestions = false;
                this.showWelcomeVideo = false;
                this.showTermsOfUse = false;
                this.showEventPromo = false;
                this.showResources = false;
                this.showAmplifyTerms = true;
                this.showSpinner = false;
            }else {
                this.showAmplifyTerms = false;
                this.showWelcomeWizard = false;
                this.showSpinner = false;
            }
        }
    }

    handleCallWizardVisibility(event){
        this.showSpinner = true;
        return refreshApex(this.userRec);
    }

    handleNext(event){
        this.showSpinner = true;
        if(this.showWelcomeVideo){
            this.conRecToUpdate.Id = this.contactId;
            this.conRecToUpdate.Partner_Welcome_Video__c = true;
            this.saveContact(event);
        }else if(this.showEventPromo){
            this.isEventPromo = true;
            this.setWizardVisibilty();
        }
    }

    handleFinish(event){
        this.showSpinner = true;
        if(this.showResources){
            this.conRecToUpdate.Id = this.contactId;
            this.conRecToUpdate.Partner_Promo_Banner__c = true;
            this.saveContact(event);
        }
    }

    saveContact(event){
        updateContact({ conRec: this.conRecToUpdate })
            .then((result) => {
                console.log('Contact Updated!'+result);
                this.handleCallWizardVisibility(event);
            })
            .catch((error) => {
                console.log(error);
            });
    }

    handleWelcomeVideoCall(event){
        let welcomeDetail = event.detail;
        if(!welcomeDetail){
            this.showWelcomeVideo = false;
            this.welcomeVidDisabled = true;
            this.setWizardVisibilty();
        }
    }

    handlePromoBannerCall(event){
        let eventBannerDetail = event.detail;
        if(!eventBannerDetail){
            this.showEventPromo = false;
            this.eventBannerDisabled = true;
            this.setWizardVisibilty();
        }
    }
}