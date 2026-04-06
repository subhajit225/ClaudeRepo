import { LightningElement, track, api, wire } from 'lwc';
import getConfiguration from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getConfiguration';
import getUserEmail from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getUserEmail';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import knowblerPubsub from 'c/knowblerPubsub';

export default class Knowbler extends LightningElement {
  @track id = userId;

  @track userData;

  @track homecmp;

  @api kcsHeight;

  @api flexipageRegionWidth;

  @api recordId;

  @track openComponent;

  @api newid;

  @track parameters;

  @track articlecreate;

  @track draftarticlemode;

  @track contentstandard;

  isCasePresent;

  showModal = false;

  uniqueNumber;

  isContentHealthActive = false;

  knowblerViewInLocalStorage;

  modeSwitchCaseError = false;

  isBackgroundCasePresent;

  @track configApiError = false;

  @track contenthealthcmp = false;

  @track reviewerEmailList = [];

  @wire(getRecord, { recordId: '$recordId', fields: 'Id' })
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

  get knowblerHeight() {
    return `height: ${this.kcsHeight}px`;
  }

  connectedCallback() {
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      localStorageValue &&
      localStorageValue[window.btoa(encodeURIComponent(Id))]
    ) {
      this.knowblerViewInLocalStorage =
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.knowblerView;
    }
    localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));

    this.uniqueNumber = Math.floor(Math.random() * 100000 + 1);
    knowblerPubsub.registerListener(
      `switchKnowblerMode${this.uniqueNumber}`,
      this.switchKnowblerMode,
      this
    );
    if (this.newid) {
      this.recordId = this.newid;
      this.kcsHeight = '500';
      this.flexipageRegionWidth = 'SMALL';
    }

    this.userDetail();
    this.getUrl();

    if (this.recordId) {
      this.openComponent = true;
      if (this.recordId.startsWith('500')) {
        this.isCasePresent = true;
      } else {
        this.isCasePresent = false;
      }
    }
  }

  setMinMaxState(event) {
    this.showModal = !!event?.detail;
  }

  switchKnowblerMode(val) {
    if (val === null) {
      this.modeSwitchCaseError = true;

      return;
    }
    if (val) {
      this.contenthealthcmp = false;
      this.articlecreate = true;
    } else {
      this.contenthealthcmp = true;
      this.articlecreate = false;
    }
  }

  hideModeSwitchErrorModal() {
    this.modeSwitchCaseError = false;
  }

  userDetail() {
    getUserEmail({ recordId: this.id })
      .then((result) => {
        this.userData = result;
      })
      .catch((error) => {
        console.log('getUserEmail error : ', error);
      });
  }

  async getUrl() {
    try {
      const data = await getConfiguration();
      if (data == 'error') {
        this.knoblerSupport = [];
        this.noLoading = false;
      } else await this.getKcsConfig(data);
    } catch (error) {}
  }

  async getKcsConfig(data) {
    this.configApiError = false;
    fetch(data, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': true
      }
    })
      .then((response) => {
        if (response.status != 200) {
          this.configApiError = true;
        }

        return response.json();
      })
      .then((repos) => {
        this.knoblerSupport = { ...repos };
        const articlemode = this.knoblerSupport.mapping.length
          ? this.knoblerSupport.mapping[0].draftArticlesMode
          : '';

        if (articlemode != 'All') {
          this.draftarticlemode = true;
        } else {
          this.draftarticlemode = false;
        }

        if (this.knoblerSupport.contentHealth.reviewersEmail) {
          const reviewerEmail =
            this.knoblerSupport.contentHealth.reviewersEmail;
          this.contentstandard =
            this.knoblerSupport.contentHealth.contentStandard;
          this.parameters = this.knoblerSupport.contentHealth.parameters;

          if (Array.isArray(reviewerEmail) && reviewerEmail.length) {
            for (let i = 0; i < reviewerEmail.length; i++) {
              this.reviewerEmailList.push(reviewerEmail[i].email);
            }

            if (this.reviewerEmailList.includes(this.userData)) {
              this.isContentHealthActive = true;
              this.openComponent = true;
              if (
                !this.isBackgroundCasePresent ||
                this.knowblerViewInLocalStorage === undefined ||
                this.knowblerViewInLocalStorage === 1
              ) {
                this.contenthealthcmp = true;
                this.articlecreate = false;
              } else {
                this.articlecreate = true;
                this.contenthealthcmp = false;
              }
            } else {
              this.articlecreate = true;
            }
          } else {
            this.articlecreate = true;
          }
        } else {
          this.articlecreate = true;
        }
        this.noLoading = false;

        return new Promise((resolve) => setTimeout(resolve, 0));
      })
      .catch((error) => {
        this.configApiError = true;
        console.log('Error:', error);
      });
  }

  renderedCallback() {
    if (this.newid) {
      if (this.newid !== this.recordId) {
        this.recordId = this.newid;
        this.openComponent = false;
        setTimeout(() => {
          this.openComponent = true;
          if (this.recordId.startsWith('500')) {
            this.isCasePresent = true;
          } else {
            this.isCasePresent = false;
          }
        }, 500);
      }
      const screenWidth =
        this.template.querySelector('.knowblercomp').offsetWidth;

      const screenHeight =
        this.template.querySelector('.knowblercomp').offsetHeight;

      if (screenWidth > 1300 && screenHeight > 400) {
        if (this.template.querySelector('c-kcs-_-knowbler-home')) {
          this.template.querySelector('c-kcs-_-knowbler-home').maximizeScreen();
        }
        if (this.template.querySelector('c-knowbler-creator-home')) {
          this.template
            .querySelector('c-knowbler-creator-home')
            .maximizeScreen();
        }
      }
    }
  }
}