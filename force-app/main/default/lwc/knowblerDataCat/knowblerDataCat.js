import { LightningElement, api, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerDataCat extends LightningElement {
  @api items;

  chkVal;

  up;

  down;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.up = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/up.svg`;
      this.down = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/down.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  handleChange(event) {
    this.chkVal = event.target.label;
    const index = this.items.findIndex(
      (res) => res.label == event.target.label
    );
    const ob = JSON.parse(JSON.stringify(this.items));
    ob[index].checked = !ob[index].checked;
    const eve = new CustomEvent('changevalue', {
      detail: { item: ob }
    });
    this.dispatchEvent(eve);
  }

  handleUpDown(event) {
    const ob = JSON.parse(JSON.stringify(this.items));
    ob[event.currentTarget.dataset.id].expanded =
      !ob[event.currentTarget.dataset.id].expanded;
    const eve = new CustomEvent('changevalue', {
      detail: { item: ob }
    });
    this.dispatchEvent(eve);
  }

  dcChangeValue(event) {
    const ob = JSON.parse(JSON.stringify(this.items));
    const index = ob.findIndex((res) => res.label == event.detail.parent);
    if (index > -1) {
      ob[index].listChildCategory = event.detail.item;
      this.dispatchEvent(
        new CustomEvent('changevalue', {
          detail: { item: ob }
        })
      );
    }
  }
}