import { LightningElement, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerConfigurationCheck extends LightningElement {
  configuartionError;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.configuartionError = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/configuration_error.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }
}