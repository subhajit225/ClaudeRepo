import { LightningElement, api, track, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerParentPreview extends LightningElement {
  @api rangerId;

  @api left;

  @api maincontainerwidth;

  @api top;

  @api isArticleExist;

  @api eventCode;

  @api postion;

  @api item;

  @api destobj;

  @api recordtypeid;

  @track Userdetail = {};

  clientWidth;

  divHeight;

  oldrangerId;

  @api cmpvisible;

  articleNotExists;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.articleNotExists = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/article-no-longer-exists.png`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  @api alldatacategories;

  connectedCallback() {
    this.Userdetail = JSON.parse(JSON.stringify(this.item));
  }

  renderedCallback() {
    const container = this.template.querySelector('.container');
  }

  @api
  setDiamand() {
    if (this.template.querySelector('div.mainContainer')) {
      this.template
        .querySelector('div.container')
        .style.setProperty('top', `${this.top}px`);
    }
    if (this.postion == 'left') {
      this.template
        .querySelector('div.container')
        .style.setProperty('left', `${this.left - 25}px`);
      this.template
        .querySelector('div.container')
        .style.setProperty('border-top', ' 2px  solid #d8dde6');
      this.template
        .querySelector('div.container')
        .style.setProperty('border-right', ' 2px  solid #d8dde6');
      this.template
        .querySelector('div.container')
        .style.setProperty('border-bottom', ' 0px  solid #d8dde6');
      this.template
        .querySelector('div.container')
        .style.setProperty('border-left', ' 0px  solid #d8dde6');
    } else {
      this.template
        .querySelector('div.container')
        .style.setProperty('left', `${this.left + 3}px`);
      this.template
        .querySelector('div.container')
        .style.setProperty('border-bottom', ' 2px  solid #d8dde6');
      this.template
        .querySelector('div.container')
        .style.setProperty('border-left', ' 2px  solid #d8dde6');
      this.template
        .querySelector('div.container')
        .style.setProperty('border-top', ' 0px  solid #d8dde6');
      this.template
        .querySelector('div.container')
        .style.setProperty('border-right', ' 0px  solid #d8dde6');
    }
  }

  keepopen() {
    this.dispatchEvent(new CustomEvent('keepopen'));
  }
}