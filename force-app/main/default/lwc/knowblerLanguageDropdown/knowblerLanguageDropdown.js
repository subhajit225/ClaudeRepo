import { LightningElement, api, track, wire } from 'lwc';
import getPickListValues from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getPickListValues';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';
import knowblerPubsub from 'c/knowblerPubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { getDataConnectorSourceFields } from 'lightning/analyticsWaveApi';
import Id from '@salesforce/user/Id';

export default class KnowblerLanguageDropdown extends LightningElement {
  @api flexipageregionwidth;

  articleLanguageIcon;

  articleLanguageIconlarge;

  arrowDown;

  close;

  tick;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.articleLanguageIcon = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/Web.svg`;
      this.articleLanguageIconlarge = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/article_language.svg`;
      this.arrowDown = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/arrow_down.svg`;
      this.close = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/close.svg`;
      this.tick = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/tick.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  @wire(CurrentPageReference) pagerf;

  @track pickListValues = [];

  @track selectedLanguage;

  @track selectedLanguages;

  @track currentIndex;

  @track currentuserlanguages = {};

  renderedCallback() {}

  @api
  get currentuserlanguage() {}

  set currentuserlanguage(data) {
    if (data) {
      this.currentuserlanguages = JSON.parse(JSON.stringify(data));
      if (this.pickListValues.length) this.defaultLanguage();
    }
  }

  @api
  get picklistvalues() {
    return this.pickListValues;
  }

  set picklistvalues(data) {
    if (data) this.pickListValues = JSON.parse(JSON.stringify(data));
    if (Object.keys(this.currentuserlanguages).length) this.defaultLanguage();
  }

  get getSmallLayout() {
    return this.flexipageregionwidth == 'SMALL';
  }

  showModal = false;

  openModal() {
    knowblerPubsub.fireEvent(this.pagerf, 'disableArticleButton');
    this.showModal = !this.showModal;
    this.defaultLanguage();
    this.addRemoveClass(this.currentIndex);
  }

  closeModal() {
    knowblerPubsub.fireEvent(this.pagerf, 'enableArticleButton');
    this.showModal = false;
  }

  defaultLanguage() {
    if (this.pickListValues) {
      this.currentIndex = this.pickListValues.findIndex(
        (elm) => elm.value == this.currentuserlanguages.currentUserLanguage
      );
      if (this.currentIndex > -1) {
        this.selectedLanguage = this.pickListValues[this.currentIndex];
      } else {
        this.selectedLanguage = this.pickListValues[0];
        this.selectLanguage(0);
      }
    }
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings
        ?.filters?.language &&
      this.selectedLanguage.value !==
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings
          ?.filters?.language
    ) {
      const localStorageLanguageValue =
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings
          ?.filters?.language;
      const selectedLanguageObj = this.pickListValues.filter(
        (item) => item.value === localStorageLanguageValue
      );
      this.selectedLanguage = selectedLanguageObj[0];
      this.changeLanguage();
    }
  }

  selectLanguage(event) {
    if (event?.currentTarget?.dataset?.id) {
      const { id } = event.currentTarget.dataset;
      this.addRemoveClass(id);
    } else {
      this.addRemoveClass(event);
      this.changeLanguage();
    }
  }

  changeLanguage() {
    knowblerPubsub.fireEvent(this.pagerf, 'enableArticleButton');
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (this.selectedLanguages) {
      this.selectedLanguage = { ...this.selectedLanguages };
      if (
        localStorageValue[window.btoa(encodeURIComponent(Id))].creatorSettings
          .filters.language !== this.selectedLanguage.value
      ) {
        localStorageValue[
          window.btoa(encodeURIComponent(Id))
        ].creatorSettings.filters.language = this.selectedLanguage.value;
        localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));
      }
    } else if (
      this.selectedLanguage.value &&
      localStorageValue[window.btoa(encodeURIComponent(Id))].creatorSettings
        .filters.language !== this.selectedLanguage.value
    ) {
      const localStorageLanguageValue =
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings
          ?.filters?.language;
      const selectedLanguageObj = this.pickListValues.filter(
        (item) => item.value === localStorageLanguageValue
      );
      this.selectedLanguage = selectedLanguageObj[0];
      localStorageValue[
        window.btoa(encodeURIComponent(Id))
      ].creatorSettings.filters.language = this.selectedLanguage.value;
      localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));
    }
    this.closeModal();
    this.dispatchEvent(
      new CustomEvent('languagevaluechange', {
        detail: {
          records: this.selectedLanguage
        }
      })
    );
  }

  addRemoveClass(id) {
    setTimeout(() => {
      const badgeClass = this.template.querySelectorAll('.language_drop');
      if (badgeClass.length) {
        badgeClass &&
          badgeClass.forEach((element) => {
            if (element.classList.contains('active'))
              element.classList.remove('active');
          });
        badgeClass[id].classList.add('active');
      }
    }, 100);
    const values = [...this.pickListValues];
    values.map((elm) => (elm.isDefaultValue = false));
    values[id].isDefaultValue = true;
    this.selectedLanguages = values[id];
    this.pickListValues = [...values];
  }
}