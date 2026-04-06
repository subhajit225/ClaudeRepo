import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getWelcomePageDetails from '@salesforce/apex/PC_PortalNavigationApexController.getWelcomePageDetails';
export default class Pc_homePageWelcome_lwc extends LightningElement {
    welcomeBanner;
    welcomeDescription;
    videoUrl;

    connectedCallback()
    {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });

        getWelcomePageDetails()
        .then(result=>{
            this.welcomeBanner = 'Welcome, '+ result.userName;
            this.welcomeDescription = result.pageRecord.Description__c;
            this.videoUrl = result.pageRecord.Image_Url__c;
        })
        .catch(error=>{
            console.log('-->'+JSON.stringify(error));
        });
    }
}