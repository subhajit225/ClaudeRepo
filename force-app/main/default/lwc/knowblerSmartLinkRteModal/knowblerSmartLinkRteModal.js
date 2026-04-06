import { LightningElement, wire, api, track } from 'lwc';
import getLanguagePicklist from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getPickListValues';
import getPublishStatus from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getPickListValues';
import getKnowledgeArticlesForSmartLink from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getKnowledgeArticlesForSmartLink';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

const DELAY = 300;

export default class KnowblerSmartLinkRteModal extends LightningElement {
  close;

  @api langPicklist;

  @api publishSatusPicklist;

  status = 'Online';

  language = 'en_US';

  @api searchKey;

  @api searchedArticles = [];

  @api label = 'Link to Article';

  @api placeholder = 'search...';

  @api iconName = 'standard:knowledge';

  @api selectedArticleLink;

  @api defaultRecordId = '';

  @api exp;

  hasRecords = true;

  isSearchLoading = false;

  delayTimeout;

  selectedRecord = {};

  showModal = false;

  targetValue;

  isedit = false;

  @api destobj;

  get targetOptions() {
    return [
      { label: 'New Window(_blank)', value: '_blank' },
      { label: 'Topmost Window(_top)', value: '_top' },
      { label: 'Same Window(_self)', value: '_self' },
      { label: 'Parent Window(_parent)', value: '_parent' }
    ];
  }

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.close = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/close.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  @wire(getLanguagePicklist, {
    object_name: '$destobj',
    field_name: 'Language'
  })
  wiredLanguagePicklist({ error, data }) {
    if (data) {
      this.langPicklist = data;
    } else if (error) {
    }
  }

  @wire(getPublishStatus, {
    object_name: '$destobj',
    field_name: 'PublishStatus'
  })
  wiredPublishStatusPicklist({ error, data }) {
    if (data) {
      this.publishSatusPicklist = data.filter((res) => res.label != 'Archived');
    } else if (error) {
    }
  }

  @wire(getKnowledgeArticlesForSmartLink, {
    searchText: '$searchKey',
    status: '$status',
    preferredLanguage: '$language',
    objName: '$destobj',
    exp: '$exp'
  })
  getSearchedArticles({ error, data }) {
    this.isSearchLoading = false;
    if (data) {
      this.hasRecords = data.length != 0;
      this.searchedArticles = JSON.parse(JSON.stringify(data));
      if (this.isedit) {
        this.selectedRecord = this.searchedArticles.find(
          (da) => da.Title == this.searchKey
        );
        if (this.selectedRecord?.Id)
          this.handelSelectedRecord(this.selectedRecord?.Id);
      }
    } else if (error) {
    }
  }

  handleStatusChange(event) {
    this.status = event.detail.value;
  }

  handleLanguageChange(event) {
    this.language = event.detail.value;
  }

  handleKeyChange(event) {
    this.isSearchLoading = true;
    window.clearTimeout(this.delayTimeout);
    const searchKey = event?.target?.value ? event?.target?.value : event;
    this.delayTimeout = setTimeout(() => {
      this.searchKey = searchKey;
    }, DELAY);
    this.toggleResult(event);
  }

  toggleResult(event) {
    const lookupInputContainer = this.template.querySelector(
      '.lookupInputContainer'
    );
    const clsList = lookupInputContainer.classList;
    const whichEvent = event?.target?.getAttribute('data-source')
      ? event?.target?.getAttribute('data-source')
      : 'searchInputField';
    switch (whichEvent) {
      case 'searchInputField':
        clsList.add('slds-is-open');
        break;
      case 'lookupContainer':
        clsList.remove('slds-is-open');
        break;
    }
  }

  handleRemove(event) {
    this.selectedRecord = {};
    this.searchKey = '';

    const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
    searchBoxWrapper.classList.remove('slds-hide');
    searchBoxWrapper.classList.add('slds-show');
    const pillDiv = this.template.querySelector('.pillDiv');
    pillDiv.classList.remove('slds-show');
    pillDiv.classList.add('slds-hide');
  }

  handelSelectedRecord(event) {
    const objId = event?.target?.getAttribute('data-recid')
      ? event?.target?.getAttribute('data-recid')
      : event;
    this.selectedRecord = this.searchedArticles.find(
      (data) => data.Id === objId
    );
    this.handelSelectRecordHelper();
    this.selectedArticleLink = `/articles/${this.language}/knowledge/${this.selectedRecord.UrlName}`;
  }

  handelSelectRecordHelper() {
    if (
      this.template.querySelector('.lookupInputContainer') &&
      this.template
        .querySelector('.lookupInputContainer')
        .classList.contains('slds-is-open')
    )
      this.template
        .querySelector('.lookupInputContainer')
        .classList.remove('slds-is-open');
    if (this.template.querySelector('.searchBoxWrapper')) {
      const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
      if (searchBoxWrapper.classList.contains('slds-show'))
        searchBoxWrapper.classList.remove('slds-show');
      searchBoxWrapper.classList.add('slds-hide');
    }
    if (this.template.querySelector('.pillDiv')) {
      const pillDiv = this.template.querySelector('.pillDiv');
      if (pillDiv.classList.contains('slds-hide'))
        pillDiv.classList.remove('slds-hide');
      pillDiv.classList.add('slds-show');
    }
  }

  handleTargetChange(event) {
    this.targetValue = event.detail.value;
  }

  saveSmartLink() {
    if (this.selectedRecord?.Title != undefined) {
      const data = `<a class="smartLink-tag" target="${this.targetValue}" href="${this.selectedArticleLink}">${this.selectedRecord?.Title}</a>`;
      const leaveevent = new CustomEvent('linksave', {
        detail: data
      });
      this.dispatchEvent(leaveevent);
      this.showModal = false;
    }
  }

  @api
  openmodal(data) {
    this.showModal = true;
    if (typeof data != 'string') {
      this.isedit = true;
      this.targetValue = data?.target;
      this.selectedArticleLink = data?.pathname;
      if (this.selectedArticleLink.length) {
        const arr = this.selectedArticleLink.split('/');
        if (arr.length > 3) this.language = arr[2];
      }
      this.handleKeyChange(data?.text);
    }
  }

  closeModal() {
    this.showModal = false;
  }
}