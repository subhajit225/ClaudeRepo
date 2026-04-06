import { LightningElement, api, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class kcsTour extends LightningElement {
  @api flexipageregionwidth;

  @api value = 'stepOne';

  @api nextLabel = 'Next';

  @api next = false;

  @api userlanguage;

  @api showContentHealth;

  @api showmodal = false;

  @api
  get step() {}

  set step(data) {
    if (data) this.value = data;
    if (this.value == 'stepThree') this.nextLabel = "Let's start";
  }

  tourTitle1 = 'In-the-moment Knowledge Capture';

  tourTitle2 = 'Efficient Reuse of Support Knowledge';

  tourTitle3 = 'Optimization of Content with Analytics';

  tourSummary1 =
    'Knowbler overcomes the biggest challenge of support knowledge creation by making KCS a part of workflows and populating new articles as a by-product of agent’s resolutions.';

  tourSummary2 =
    'Knowbler helps agents edit and attach resolutions for known issues to cases for easier discovery and lower turnaround time.';

  tourSummary3 =
    'Knowbler comes with a robust reporting module that helps managers monitor the performance of KCS-generated content and quantify KCS success.';

  inTheMomentImage;

  efficientReuseImage;

  optimizationOfContentImage;

  get options() {
    return [
      { label: '', value: 'stepOne' },
      { label: '', value: 'stepTwo' },
      { label: '', value: 'stepThree' }
    ];
  }

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.inTheMomentImage = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/In_the_moment.svg`;
      this.efficientReuseImage = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/efficient_resue.svg`;
      this.optimizationOfContentImage = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/optimization_of_content.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  handleOnStepClick(event) {
    this.value = event.detail.value;
    if (this.value == 'stepThree') this.nextLabel = "Let's start";
    if (this.value == 'stepOne' || this.value == 'stepTwo') {
      this.nextLabel = 'Next';
    }
    this.dispatchEvent(new CustomEvent('setstep', { detail: this.value }));
  }

  get isStepOne() {
    return this.value === 'stepOne';
  }

  get isStepTwo() {
    return this.value === 'stepTwo';
  }

  get isStepThree() {
    return this.value === 'stepThree';
  }

  get isEnableNext() {
    return !!this.next;
  }

  get listScreen() {
    return !this.next;
  }

  get showOnSmallScreen() {
    return this.flexipageregionwidth === 'SMALL';
  }

  handleNext() {
    switch (this.value) {
      case 'stepOne':
        this.value = 'stepTwo';
        break;
      case 'stepTwo':
        this.value = 'stepThree';
        this.nextLabel = "Let's start";
        break;
      case 'stepThree':
        this.handleOnSkip();
        break;
    }

    this.dispatchEvent(new CustomEvent('setstep', { detail: this.value }));
  }

  handleOnSkip() {
    const tourStatus = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};

    const tour = {
      email: window.btoa(
        encodeURIComponent(this.userlanguage.currentUserEmailId)
      ),
      status: 'InProgress',
      creatorSettings: {
        showSwitchInstructionTooltip: null,
        filters: {
          articleListing: '',
          language: ''
        }
      },
      reviewerSettings: {
        showSwitchInstructionTooltip: true,
        filters: {
          agentFilter: '',
          language: ''
        }
      }
    };
    if (this.showContentHealth) {
      tour.knowblerView = 1;
    } else {
      tour.knowblerView = 0;
    }

    if (tourStatus && tourStatus[window.btoa(encodeURIComponent(Id))]) {
      tourStatus[window.btoa(encodeURIComponent(Id))] = {
        ...tourStatus[window.btoa(encodeURIComponent(Id))],
        ...tour
      };
    } else {
      tourStatus[window.btoa(encodeURIComponent(Id))] = tour;
    }

    localStorage.setItem('TourStatus', JSON.stringify(tourStatus));
    this.next = true;
    this.dispatchEvent(new CustomEvent('tourcompleted'));
  }
}