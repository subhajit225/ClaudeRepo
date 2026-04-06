import { LightningElement, api, track } from 'lwc';
import Id from '@salesforce/user/Id';

export default class KnowblerArticleTab extends LightningElement {
  @api tabs;

  @track tabcontent = 0;

  @track tabData;

  @api activevalue;

  @track activenew;

  @api draftarticlemode;

  @track tabclicked = false;

  tempFilterMapping;

  @api
  get fromtab() {}

  set fromtab(data) {
    if (data && data.change) {
      this.tabcontent = this.tabData.tabcontent || 0;
      if (this.template.querySelector('lightning-tabset')) {
      }
    }
  }

  findKeyByValue(obj, value) {
    return Object.keys(obj).find((key) => obj[key] === value);
  }

  connectedCallback() {
    if (this.draftarticlemode) {
      this.tempFilterMapping = {
        0: 'myDraft',
        1: 'Published'
      };
    } else {
      this.tempFilterMapping = {
        0: 'allDraft',
        1: 'myDraft',
        2: 'Published'
      };
    }
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      localStorageValue[window.btoa(encodeURIComponent(Id))]?.knowblerView ===
        0 ||
      localStorageValue[window.btoa(encodeURIComponent(Id))]?.knowblerView ===
        '0'
    ) {
      if (
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings
          ?.filters?.articleListing === ''
      ) {
        localStorageValue[
          window.btoa(encodeURIComponent(Id))
        ].creatorSettings.filters.articleListing =
          this.tempFilterMapping[this.activevalue];
      } else {
        const localStorageListingValue =
          localStorageValue[window.btoa(encodeURIComponent(Id))]
            ?.creatorSettings?.filters?.articleListing;
        const foundKey = this.findKeyByValue(
          this.tempFilterMapping,
          localStorageListingValue
        );
        if (foundKey) {
          this.activevalue = foundKey;
        }
        this.handleActive();
      }
      localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));
    }
  }

  @api
  get query() {
    return this.tabcontent;
  }

  set query(data) {
    this.tabData = JSON.parse(JSON.stringify(data));
    this.tabcontent = data.tabcontent || 0;
    this.activevalue = this.tabcontent;
  }

  handleActive(event) {
    const pretabcontent = this.tabcontent;
    this.tabcontent =
      event && event.target && event.target.value
        ? event.target.value
        : this.activevalue;
    this.activevalue = this.tabcontent;
    if (!this.tabData?.articleCretae && this.tabcontent != pretabcontent) {
      const selectedEvent = new CustomEvent('hanldevaluechange', {
        detail: {
          tabcontent: this.tabcontent,
          count: this.tabs[this.tabcontent].count
        }
      });
      this.dispatchEvent(selectedEvent);
    } else if (this.tabcontent != pretabcontent) {
      const selectedEvent = new CustomEvent('hanldesectionchange', {
        detail: { tabcontent: this.tabcontent }
      });
      this.dispatchEvent(selectedEvent);
    }
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    localStorageValue[
      window.btoa(encodeURIComponent(Id))
    ].creatorSettings.filters.articleListing =
      this.tempFilterMapping[this.activevalue];
    localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));
  }
}