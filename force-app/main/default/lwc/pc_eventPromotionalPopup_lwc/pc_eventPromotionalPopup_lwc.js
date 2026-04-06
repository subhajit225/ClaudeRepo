import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import eventPromotionalConfig from '@salesforce/apex/PC_PortalNavigationApexController.getEventPromotionalConfig';
export default class Pc_eventPromotionalPopup_lwc extends NavigationMixin(LightningElement) {
    //@api isModalOpen = false;
    imageUrl;
    heading;
    subHeading;
    buttonLabel;
    wizardNavigateURL;
    @api _showPromoBannerModal = false;

    @wire (eventPromotionalConfig)
    wiredConfigs({data, error}){
        if(data){
            console.log('data'+JSON.stringify(data));
            if(data == undefined || data == null || data.length == 0){
                this._showPromoBannerModal = false;
                this.callParent();
            }else if(data.length > 0){
                let bannerConfig = data[0];
                this._showPromoBannerModal = true;
                this.heading = bannerConfig.Headline__c;
                this.subHeading = bannerConfig.Image_Text__c;
                this.buttonLabel = bannerConfig.Navigate_Text__c;
                this.wizardNavigateURL = bannerConfig.Navigate_Url__c;
                this.imageUrl = bannerConfig.Image_Url__c;
            }
        }else if(error){
            console.log(error);
        }
    };

    handleSignUp(event){
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": this.wizardNavigateURL
            }
        });
    }

    callParent(){
        this.dispatchEvent(new CustomEvent('showpromobannermodal',{
            detail: this._showPromoBannerModal
        }));
    }
}