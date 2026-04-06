import { LightningElement,api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import { NavigationMixin } from "lightning/navigation";
import getWelcomeWizardVideoDetails from '@salesforce/apex/PC_PortalNavigationApexController.getWelcomeWizardVideoConfig';

export default class Pc_welcomeWizardVideo_lwc extends NavigationMixin(LightningElement) {
    wizardVideoUrl;
    wizardHeadline;
    wizardSubHeading;
    wizardNavigateURL;
    buttonNavigateText;
    wizardConfig;
    @api _showVideoModal = false;


    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });

        getWelcomeWizardVideoDetails()
        .then(result=>{
            this.wizardConfig = result[0];
            console.log(JSON.stringify(this.wizardConfig));
            if(this.wizardConfig == undefined){
                this._showVideoModal = false;
                this.callParent();
            }else {
                this._showVideoModal = true;
                //this.callParent();
                this.wizardVideoUrl = this.wizardConfig.Image_Url__c;
                this.wizardHeadline = this.wizardConfig.Headline__c;
                this.wizardSubHeading = this.wizardConfig.Description__c;
                this.buttonNavigateText = this.wizardConfig.Navigate_Text__c;
                this.wizardNavigateURL = this.wizardConfig.Navigate_Url__c;
            }
        })
        .catch(error=>{
            this.error =JSON.stringify(error);
            //alert(this.error);
        });
    }

    handleExploreClick(event){
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": this.wizardNavigateURL
            }
        },true);
    }

    callParent(){
        this.dispatchEvent(new CustomEvent('showvidmodal',{
            detail: this._showVideoModal
        }));
    }
}