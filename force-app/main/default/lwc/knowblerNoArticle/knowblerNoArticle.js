import { LightningElement, api, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerNoArticle extends LightningElement {
  noArticle;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.noArticle = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/no_articles.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  @api flexipageregionwidth;

  translationLocal;
}