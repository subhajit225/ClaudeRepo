import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import getConfiguration from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getConfiguration';
import getsettings from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getsettings';
import Id from '@salesforce/user/Id';
import jQuery224 from '@salesforce/resourceUrl/SU_Knowbler__jQuery224';
import knowblerPubsub from 'c/knowblerPubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class Kcs_KnowblerHome extends LightningElement {
  @api showModal;

  @track apierror;

  @api parameters;

  @api newid;

  @api recordId;

  @api isContentHealthActive;

  @track uid;

  @track endpoint;

  @track jwttoken;

  @api flexipageRegionWidth;

  @api kcsHeight;

  @api kcsknowblerheight;

  @api flexi;

  @track contentactivate;

  @api showContentHealth;

  next = false;

  @track recordtype;

  @track isTrueCreateArticle = false;

  rtflag = false;

  loadingCard = [];

  @track showList = false;

  @track showDropdown;

  @track knoblerSupport;

  @track noLoading = true;

  @track caseData = {};

  @track language;

  @api createdArticle;

  @track tabcontent = 0;

  @track userLanguage;

  @track TourStatus;

  @track createArtcleMapping;

  @track dataCategories;

  @track destobj = '';

  tourVisible = true;

  @api contentstandard;

  @track step;

  @api contenthealthdata;

  @track evaluatedata;

  @track predictedDataFromCard;

  @track alreadyevaluatedflag;

  @track showdetails;

  @track allarticles;

  @track evaluatedsuccess;

  @track evaluatedatasuccessfully;

  @track noarticles;

  @api currentcaseid;

  @track newnumber;

  @track configRecord = '';

  @track mappingFields = [];

  errorimage;

  contenterrorimg;

  errormsg = 'There seems a problem in establishing a connection with knowbler';

  errorsubmsg = `We are doing our best and will be back soon.`;

  contenterrormsg =
    'Kindly reach out to your admin to enable the content health configuration.';

  noarticlesmess = 'No article to review';

  constructor() {
    super();
    Promise.all([loadScript(this, jQuery224)]);
  }

  @wire(CurrentPageReference) objpageref;

  @wire(getRecord, {
    recordId: Id,
    fields: ['User.Email', 'User.LanguageLocaleKey']
  })
  userDetails({ error, data }) {
    if (data) {
      this.language = data.fields.LanguageLocaleKey.value;
      this.userLanguage = {
        currentUserEmailId: data.fields.Email.value,
        currentUserLanguage: this.language
          ? this.language
          : data.fields.LanguageLocaleKey.value
      };
    } else if (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  connectedCallback() {
    if (this.currentcaseid) this.recordId = this.currentcaseid;
    if (this.kcsknowblerheight && this.flexi) {
      this.kcsHeight = this.kcsknowblerheight;
      this.flexipageRegionWidth = this.flexi;
    } else {
      this.kcsHeight = '500';
    }

    this.range(1, 10);

    this.TourStatus = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};

    if (
      Object.keys(this.TourStatus).length &&
      (this.TourStatus[window.btoa(encodeURIComponent(Id))]?.status ==
        'Completed' ||
        this.TourStatus[window.btoa(encodeURIComponent(Id))]?.status ==
          'InProgress')
    ) {
      this.tourCompleted();
      this.tourVisible = false;
    }
    this.getUrl();

    this.newnumber = Math.floor(Math.random() * 100000 + 1);
    window.addEventListener('message', this.handleVFResponse.bind(this));
    knowblerPubsub.registerListener(
      `opendetails${this.newnumber}`,
      this.opendetailcomponent,
      this
    );
  }

  async getsettingsdata() {
    getsettings().then((result) => {
      this.endpoint = result.backendurl;
      this.uid = result.uid;
      this.jwttoken = result.token;
      loadStyle(
        this,
        `${this.endpoint}/kcs-agent/kcs_custom_agent/${this.uid}/kcs.css`
      );
      loadStyle(
        this,
        `${this.endpoint}/kcs-agent/kcs_custom_agent/resources/css/suCustom.css`
      );
      this.errorimage = `${this.endpoint}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/api.svg`;
      this.contenterrorimg = `${this.endpoint}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/Knowblererror.svg`;
    });
  }

  @track predictedscore;

  @track articleid;

  @track alreadyevaluted;

  @track articlenumber;

  @track articlepredictiondata;

  @track ownername;

  @api languagechanged;

  @api uniqueNumber;

  @track datafromcard;

  @track waiting;

  fullPhotoUrl = '';

  opendetailcomponent(data) {
    this.showdetails = true;
    this.predictedscore = data.predictedscore;
    this.articleid = data.articleid;
    this.alreadyevaluted = data.alreadyevaluted;
    this.articlenumber = data.articlenumber;
    this.articlepredictiondata = data.articlepredictiondata;
    this.ownername = data.ownername;
    this.languagechanged = data.languagechanged;
    this.datafromcard = data.contenthealthdata;
    this.waiting = data.waiting;
    this.fullPhotoUrl =
      data.item && data.item.FullPhotoUrl ? data.item.FullPhotoUrl : '';
    const detailArticle = { ...data.item };
    if (
      this.knoblerSupport.length == 1 &&
      this.knoblerSupport[0].salesforceExperience == 'Classic'
    ) {
      this.configRecord = this.knoblerSupport;
    } else {
      this.configRecord = this.knoblerSupport.filter(
        (res) =>
          res?.RecordType == detailArticle?.RecordType?.Name && res.active
      );
    }

    if (this.configRecord.length) {
      this.configRecord[0].mapping.map((res) => {
        if (res.type == 'file') {
          this.mappingFields.push(
            `${this.configRecord[0].DestinationObject}.${res.name.replace(
              '__c',
              ''
            )}__Name__s`
          );
          this.mappingFields.push(
            `${this.configRecord[0].DestinationObject}.${res.name.replace(
              '__c',
              ''
            )}__Length__s`
          );
          this.mappingFields.push(
            `${this.configRecord[0].DestinationObject}.${res.name.replace(
              '__c',
              ''
            )}__Body__s`
          );
          this.mappingFields.push(
            `${this.configRecord[0].DestinationObject}.${res.name.replace(
              '__c',
              ''
            )}__ContentType__s`
          );
        } else
          this.mappingFields.push(
            `${this.configRecord[0].DestinationObject}.${res.name}`
          );
      });
    }
  }

  clickOnInactiveScreenBtn() {
    knowblerPubsub.fireEvent(
      this.objpageref,
      `actionSwitchKnowblerMode${this.uniqueNumber}`,
      true
    );
  }

  changelanguage(event) {
    this.languagechanged = event.detail.languagechanged;
  }

  handleFullPhotoUrl(event) {
    this.fullPhotoUrl = event.detail.fullPhotoUrl;
  }

  closedetail() {
    this.showdetails = false;
  }

  handleVFResponse(message) {
    if (message?.data?.res) {
      this.dataCategories = JSON.parse(JSON.stringify(message.data.res));
    }
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
    fetch(data, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': true,
        Authorization: `Bearer ${this.jwttoken}`
      }
    })
      .then((response) => {
        if (response.status != 200) {
          this.apierror = true;
        }

        return response.json();
      })
      .then((repos) => {
        this.knoblerSupport = [...repos.mapping];
        this.contentactivate = !repos.contentHealth.activated;
        this.template
          .querySelector('c-knowbler-common-header')
          .changeInstructionTooltipBackgroundHeight(this.contentactivate);
        if (repos.contentHealth && repos.contentHealth.activated) {
          this.showList = true;
        } else {
          this.showList = false;
        }
        this.knoblerSupport = this.knoblerSupport.filter(
          (res) => res.active == true
        );

        if (this.knoblerSupport && this.knoblerSupport.length)
          this.destobj = this.knoblerSupport[0].DestinationObject;

        this.noLoading = false;
        this.getsettingsdata();

        return new Promise((resolve) => setTimeout(resolve, 0));
      })
      .catch((error) => (this.apierror = true));
  }

  renderedCallback() {
    const fullheight = screen.height;
    if (this.newid) {
      this.template.querySelector('.displayHeader').style.display = 'none';
    }

    const heightcreation = Math.floor(parseInt(this.kcsHeight, 10) - 30);
    if (this.template.querySelector('.layout-body'))
      this.template.querySelector('.layout-body').style =
        `height:${heightcreation}px`;
    if (this.flexipageRegionWidth) {
      if (this.template.querySelector('.layout-body')) {
        if (this.flexipageRegionWidth == 'SMALL')
          this.template.querySelector('.layout-body').style = `height:${
            heightcreation + 10
          }px`;
        else if (this.flexipageRegionWidth == 'MEDIUM')
          this.template.querySelector('.layout-body').style = `height:${
            heightcreation + 20
          }px`;
        else
          this.template.querySelector('.layout-body').style = `height:${
            heightcreation + 34
          }px`;
      }
      if (this.template.querySelector('.layout-body-two'))
        this.template.querySelector('.layout-body-two').style =
          `height:${heightcreation}px`;
    } else {
      const height = `${Math.floor(screen.height / 2)}px`;
      if (this.template.querySelector('.layout-body-two'))
        this.template.querySelector('.layout-body-two').style =
          `height:${height}`;
    }
  }

  changeData() {
    this.showDropdown = {
      show: true
    };
  }

  closeModal() {
    this.showModal = false;
    this.dispatchEvent(
      new CustomEvent('changeminmaxview', {
        detail: this.showModal
      })
    );
  }

  tourCompleted() {
    this.next = true;
  }

  modalClick() {
    if (this.showList && !this.showModal && !this.tourVisible) {
      this.template.querySelector('c-kcsknowblerarticle-list').checkEditForm();
    } else if (this.isTrueCreateArticle && !this.showModal) {
      this.showModal = !this.showModal;
      this.dispatchEvent(
        new CustomEvent('changeminmaxview', {
          detail: this.showModal
        })
      );
    } else {
      this.showModal = !this.showModal;
      this.dispatchEvent(
        new CustomEvent('changeminmaxview', {
          detail: this.showModal
        })
      );
    }
  }

  @api
  maximizeScreen() {
    this.showModal = !this.showModal;
    this.dispatchEvent(
      new CustomEvent('changeminmaxview', {
        detail: this.showModal
      })
    );
  }

  get isEnableNext() {
    return !!this.next;
  }

  get tourScreen() {
    return !this.next;
  }

  handleRecTypeClick(event) {
    this.createArtcleMapping = {};
    if (event.detail.rec) {
      this.recordtype = event.detail.rec;
      this.rtflag = event.detail.flag;
      this.isTrueCreateArticle = true;
    }
    if (event.detail.showArticleList) {
      this.rtflag = false;
      this.showList = true;
    }
  }

  handleCreateArticleLeave(event) {
    this.createArtcleMapping = {};
    this.createdArticle = event.detail;
    this.isTrueCreateArticle = false;
    this.showList = true;
  }

  handleBackCreateArticle(event) {
    this.createArtcleMapping = {};
    this.isTrueCreateArticle = false;
    if (this.knoblerSupport?.length > 1) this.rtflag = true;
    else this.showList = true;
  }

  range(start, end) {
    this.loadingCard = Array(end - start + 1)
      .fill()
      .map((_, idx) => start + idx);
  }

  createArticleHome(event) {
    if (event.detail?.language) {
      this.rtflag = true;
      this.showList = false;
      this.language = event.detail?.language;
      this.tabcontent = event.detail?.query?.tabcontent;
    } else if (event.detail?.allArticleData) {
      this.articleScreenData = event.detail?.allArticleData;
      this.tabcontent = event.detail?.allArticleData?.query.tabcontent;
      this.language =
        event.detail?.allArticleData?.userLanguage?.currentUserLanguage;

      if (!event.detail?.flag) {
        this.showModal = !this.showModal;
        this.dispatchEvent(
          new CustomEvent('changeminmaxview', {
            detail: this.showModal
          })
        );
      }
    }
  }

  getArticleData(data) {
    this.createArtcleMapping = {};
    this.createArtcleMapping = data.detail;
    if (!data.detail.flag) {
      this.showModal = !this.showModal;
      this.dispatchEvent(
        new CustomEvent('changeminmaxview', {
          detail: this.showModal
        })
      );
    }
  }

  stepChange(event) {
    this.step = event.detail;
  }

  evaluateopen() {
    this.template
      .querySelector('.details')
      .style.setProperty('overflow-y', 'hidden');
    if (this.template.querySelector('.largescreen'))
      this.template
        .querySelector('.largescreen')
        .style.setProperty('overflow-y', 'hidden');
  }

  evaluateclose() {
    this.template
      .querySelector('.details')
      .style.setProperty('overflow-y', 'scroll');
    if (this.template.querySelector('.largescreen'))
      this.template
        .querySelector('.largescreen')
        .style.setProperty('overflow-y', 'scroll');
  }
}