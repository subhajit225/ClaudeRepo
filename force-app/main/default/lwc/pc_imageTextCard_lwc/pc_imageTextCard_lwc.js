import { LightningElement,wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getImageTextCard from '@salesforce/apex/PC_PortalNavigationApexController.getImageTextCard';
export default class Pc_imageTextCard_lwc extends LightningElement {
    imageUrl;
    imageText;
    pageName = '';
    imageHeader;

    connectedCallback() {
      Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
            console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
      });
      this.pageName = window.document.title;
      console.log('pageName'+this.pageName);

      this.getDetails();
    }

    getDetails(){
      getImageTextCard({ portalPageName : this.pageName})
      .then(result=>{
        this.imageUrl = result.Image_Url__c;
        this.imageText = result.Description__c;
        this.imageHeader = result.Headline__c;
      })
      .catch(error=>{
        console.log('--<'+JSON.stringify(error));
      });
    }
}