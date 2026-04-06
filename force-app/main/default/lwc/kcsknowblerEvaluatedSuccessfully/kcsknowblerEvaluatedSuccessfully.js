import { LightningElement, api, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KcsknowblerEvaluatedSuccessfully extends LightningElement {
  @api evaluatedsuccess;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.successimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_articlesuccessful.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  successmsg = 'Successfully evaluated';
}