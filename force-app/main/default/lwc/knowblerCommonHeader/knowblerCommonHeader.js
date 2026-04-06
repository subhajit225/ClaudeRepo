import { LightningElement, api, track, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import knowblerPubsub from 'c/knowblerPubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerCommonHeader extends LightningElement {
  @api maxview;

  @api flexipageregionwidth;

  @api kcsheight;

  @api displayTourScreen;

  @api showContentHealth;

  @api isContentHealthActive;

  @api uniqueNumber;

  @api newnumber;

  @api currentcaseid;

  totalKnowblerHeight;

  minScreen;

  maxScreen;

  knowbler_logo;

  showSwitchInstructionTooltip = false;

  isBackgroundCasePresent = true;

  @wire(CurrentPageReference) pagerf;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.minScreen = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/minScreen.svg`;
      this.maxScreen = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/maxScreen.svg`;
      this.knowbler_logo = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/Knowbler-logo.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  @wire(getRecord, { recordId: '$currentcaseid', fields: 'Id' })
  wiredRecord({ error, data }) {
    if (data) {
      if (data.apiName && data.apiName === 'Case') {
        this.isBackgroundCasePresent = true;
      } else {
        this.isBackgroundCasePresent = false;
      }
    } else if (error) {
      console.error('Error retrieving record data');
    }
  }

  connectedCallback() {
    knowblerPubsub.registerListener(
      `showSwitchTooltip${this.newnumber}`,
      this.callSwitchInstruction,
      this
    );
    knowblerPubsub.registerListener(
      `actionSwitchKnowblerMode${this.uniqueNumber}`,
      this.switchKnowblerMode,
      this
    );
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      (this.showContentHealth &&
        localStorageValue[window.btoa(encodeURIComponent(Id))]
          ?.reviewerSettings &&
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.reviewerSettings
          .showSwitchInstructionTooltip === true) ||
      (localStorageValue[window.btoa(encodeURIComponent(Id))]
        ?.creatorSettings &&
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings
          .showSwitchInstructionTooltip === true)
    ) {
      this.showSwitchInstructionTooltip = true;
    } else {
      this.showSwitchInstructionTooltip = false;
    }
  }

  callSwitchInstruction(val) {
    this.showSwitchInstructionTooltip = val;
  }

  hideSwitchModeInstructionPopup() {
    this.showSwitchInstructionTooltip = false;
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      localStorageValue &&
      localStorageValue[window.btoa(encodeURIComponent(Id))]
    ) {
      if (this.showContentHealth) {
        localStorageValue[
          window.btoa(encodeURIComponent(Id))
        ].reviewerSettings.showSwitchInstructionTooltip = false;
      } else {
        localStorageValue[
          window.btoa(encodeURIComponent(Id))
        ].creatorSettings.showSwitchInstructionTooltip = false;
      }
    }
    localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));
  }

  @api changeInstructionTooltipBackgroundHeight(value) {
    if (
      this.template.querySelector('.instruction-tooltip_background') &&
      this.maxview
    ) {
      this.template.querySelector('.instruction-tooltip_background').style =
        `height: 100vh`;
    } else if (this.template.querySelector('.instruction-tooltip_background')) {
      this.template.querySelector('.instruction-tooltip_background').style =
        `height: ${parseInt(this.kcsheight, 10) + 60}px`;
    }
  }

  checkArticleCreationFormIsOpen() {
    this.dispatchEvent(new CustomEvent('switchknowblermodeclick'));
  }

  switchKnowblerMode() {
    if (!this.isBackgroundCasePresent) {
      knowblerPubsub.fireEvent(
        this.pagerf,
        `switchKnowblerMode${this.uniqueNumber}`,
        null
      );

      return;
    }
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    let mode = 0;
    if (!this.showContentHealth) {
      mode = 1;
    }
    if (
      localStorageValue &&
      localStorageValue[window.btoa(encodeURIComponent(Id))]
    ) {
      localStorageValue[window.btoa(encodeURIComponent(Id))].knowblerView =
        mode;
    } else {
      localStorageValue[window.btoa(encodeURIComponent(Id))] = {
        knowblerView: mode
      };
    }
    localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));
    knowblerPubsub.fireEvent(
      this.pagerf,
      `switchKnowblerMode${this.uniqueNumber}`,
      this.showContentHealth
    );
  }

  renderedCallback() {
    if (
      this.template.querySelector('.instruction-tooltip_background') &&
      this.maxview
    ) {
      this.template.querySelector('.instruction-tooltip_background').style =
        `height: 100vh`;
    } else if (this.template.querySelector('.instruction-tooltip_background')) {
      let additionHeight = 0;
      if (this.displayTourScreen) {
        additionHeight = 185;
      } else {
        switch (this.flexipageregionwidth) {
          case 'LARGE':
            additionHeight = 63;
            break;
          case 'MEDIUM':
            additionHeight = 49;
            break;
          default:
            additionHeight = 39;
            break;
        }
      }
      this.totalKnowblerHeight = parseInt(this.kcsheight, 10) + additionHeight;
      this.template.querySelector('.instruction-tooltip_background').style =
        `height: ${this.totalKnowblerHeight}px`;
    }
  }

  openModal() {
    this.dispatchEvent(new CustomEvent('modalclick'));
  }
}