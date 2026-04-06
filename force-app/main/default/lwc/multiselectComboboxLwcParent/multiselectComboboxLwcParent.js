import { LightningElement, api, track } from 'lwc';

export default class MultiselectComboboxLwcParent extends LightningElement {
  @track selectedValueList = [];
  // @api options;

  @api
  get options() {
    return this._options;
  }

  set options(value) {
    this._options = value;
  }

  @track _options;
  
  @api label;
  @api disabled = false;
  // connectedCallback() {
  //   console.log('tttt parent', JSON.parse(JSON.stringify(this.options)));
  // }

  //for multiselect picklist
  handleSelectOptionList(event) {
    this.selectedValueList = event.detail;
    let ev = new CustomEvent('selectoptionparent', { detail: this.selectedValueList });
    this.dispatchEvent(ev);
  }
}