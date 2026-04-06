import { LightningElement, wire } from 'lwc';
import getAccreditedDetails from '@salesforce/apex/PC_PortalNavigationApexController.getAccreditedDetails';
import {NavigationMixin} from "lightning/navigation";

export default class Pc_learningTrack_lwc extends NavigationMixin(LightningElement) {
    fetchedCourseDetails = [];

    @wire(getAccreditedDetails)
    wiredData({ error, data }) {
      if (data) {
        console.log('Data', JSON.stringify(data));
        this.fetchedCourseDetails = data;
      } else if (error) {
        console.error('Error:', error);
      }
    }

    handleClick(){

      const config = {
        type: 'standard__webPage',
        attributes: {
            url: 'https://rubrik.docebosaas.com/partners'
        }
	};
    this[NavigationMixin.Navigate](config);
    }
}