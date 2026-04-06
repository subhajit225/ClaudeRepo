import {LightningElement,api,track,wire} from 'lwc';
import getRecords from '@salesforce/apex/CS_CaseSpecialHandlingController.getRecords';
export default class CS_CaseSpecailHandlingBannerLWC extends LightningElement {

  @api recordId;
    messages = [];
    @wire(getRecords, { recordId: '$recordId',queryLimit: '2',filter:'Show_Banner__c=true order by CreatedDate DESC' })
    wiredRecords({ error, data }) {
       if (data) {
            this.messages = data.map(record => record.Message__c);
        } else if (error) {
            console.error('Error retrieving records:', error);
        }
    }
}