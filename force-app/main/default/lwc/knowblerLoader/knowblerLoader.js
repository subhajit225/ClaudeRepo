import { LightningElement, api, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerLoader extends LightningElement {
  searchLoading;

  create_article_loading;

  @api flexipageregionwidth;

  getLayoutSize = 12;

  @api kcsheight;

  @api fromarticle;

  @api fromcreation;

  loaderCard = [];

  @api loadingcard;

  @api showloader;

  range(start, end) {
    this.loaderCard = Array(end - start + 1)
      .fill()
      .map((_, idx) => start + idx);
  }

  connectedCallback() {
    this.range(1, 12);
  }

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.searchLoading = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/search_icon_loading.svg`;
      this.create_article_loading = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/search_loading.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  get getSmallLayout() {
    if (this.flexipageregionwidth == 'SMALL') {
      return (this.getLayoutSize = 12);
    }
    if (this.flexipageregionwidth == 'MEDUIM') {
      return (this.getLayoutSize = 6);
    }

    return (this.getLayoutSize = 3);
  }

  kcsheightfun() {
    if (!this.kcsheight) return;
    const layoutHeight = parseInt(this.kcsheight, 10);
    this.cardHeight = layoutHeight - 145;
    this.cardHeight += 'px';
  }

  renderedCallback() {
    if (this.flexipageregionwidth) {
      this.kcsheightfun();
      if (this.template.querySelector('.loading'))
        this.template.querySelector('.loading').style =
          `height:${this.cardHeight}`;
    }
  }
}