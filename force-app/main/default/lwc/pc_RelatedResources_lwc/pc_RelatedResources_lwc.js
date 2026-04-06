import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getRelatedResourcesUrl from '@salesforce/apex/PC_PortalNavigationApexController.getRelatedResourcesUrl';

export default class Pc_RelatedResources_lwc extends NavigationMixin(LightningElement) {
    details= [];
    title;
    description;
    buttonLabel;
    pageName = '';

    connectedCallback(){
      Promise.all([
          loadStyle( this, PartnerCommunityResource + '/PartnerCommunityFolder/PartnerCommunityCSS.css')
          ]).then(() => {
              //console.log("File path-->"+ PartnerCommunityResource);
          })
          .catch(error => {
              console.log( error.body.message );
          });
    }

    @wire(getRelatedResourcesUrl, {portalPageName: '$pageName'})
    wiredData({ error, data }) {
      if (data) {
        console.log('Data Related Resource', JSON.stringify(data));
        this.title = data[0].Card_Title__c;
        this.description = data[0].Description__c;
        this.buttonLabel = data[0].Menu_Label__c;
        this.navigatePage = data[0].Navigate_Url__c;
        for(var i=1; i<data.length; i++){
          this.details.push({
            Id : data[i].Id,
            Navigate_Url__c : data[i].Navigate_Url__c,
            Menu_Label__c : data[i].Menu_Label__c,
            target : data[i].Link_Type__c === 'External URL'?'_blank':'_self'
          })
        }
      } else if (error) {
        console.error('Error:', error);
      }
    }

    handleClick(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.navigatePage
            }
        });
    }

    connectedCallback() {
      this.pageName = window.document.title;
      console.log('pageName'+this.pageName);
    }
}