import { LightningElement, api, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class knowblerArticleSearchbar extends LightningElement {
  @api flexipageregionwidth;

  @api searchtext = '';

  showcross = true;

  searchIcon;

  crossIcon;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.searchIcon = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/search_icon_loading.svg`;
      this.crossIcon = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/close.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  handleInputChange(event) {
    if (
      (event.detail && event.detail.value == '') ||
      (event.detail && event.detail.value && event.detail.value.trim().length)
    ) {
      const selectedEvent = new CustomEvent('searchvaluechange', {
        detail: event.detail.value.trim()
      });
      this.dispatchEvent(selectedEvent);
    }
  }

  clearData() {
    if (this.template.querySelector('.custom-input')) {
      this.template.querySelector('.custom-input').style = 'width: 100%;';
    }
  }

  changeFocus() {
    if (
      this.template.querySelector('.custom-input') &&
      this.flexipageregionwidth == 'SMALL'
    ) {
      this.template.querySelector('.custom-input').style = 'width: 100%';
    }
  }
}