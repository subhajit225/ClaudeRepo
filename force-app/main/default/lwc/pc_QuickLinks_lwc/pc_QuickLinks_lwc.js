import { LightningElement,wire } from 'lwc';
import getLinkNameAndUrl from '@salesforce/apex/PC_PortalNavigationApexController.getLinkNameAndUrl';
export default class Pc_QuickLinks_lwc extends LightningElement {
    details = []
    pageName = '';
    showLinks = false;

    @wire(getLinkNameAndUrl, {portalPageName: '$pageName'})
    wiredData({ error, data }) {
      if (data) {
        for(var i=0; i<data.length; i++){
          this.details.push({
            id : data[i].Id,
            navigateURL : data[i].Navigate_Url__c,
            navigateText : data[i].Navigate_Text__c,
            target : data[i].Link_Type__c === 'External URL'?'_blank':'_self'
          })
        }
        console.log('getLinkNameAndUrl'+JSON.stringify(this.details));
        this.showLinks = true;
      } else if (error) {
        console.error('NameUrlError:', error);
      }

    }

    connectedCallback() {
      this.pageName = window.document.title;
      console.log('pageName'+this.pageName);
    }
}