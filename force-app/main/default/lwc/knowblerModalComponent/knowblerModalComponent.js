import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';
import knowblerPubsub from 'c/knowblerPubsub';

export default class KnowblerModalComponent extends LightningElement {
  @wire(CurrentPageReference) pageRef;

  @api draftarticlemode;

  @api stayleave;

  @api saveprog;

  @api createsuccess;

  @api uniqueNumber;

  @api newnumber;

  errorsuccess = false;

  showArticleNotExistsPopup = false;

  @api kcslabel;

  @api showvideo;

  @api videolink;

  @api showimage;

  @api clientSettings;

  @api ispublish;

  @api ispublishnow;

  @api isschedulepublish;

  @api caseid;

  @api casenumber;

  @api jwttoken;

  @api endpoint;

  @api isattach;

  @track attachsuccesfull;

  @track detachsuccesfull;

  @api ispublishattach;

  @track articleattach;

  @track ispublishnowsuccess;

  @track linkcopied;

  @api commentclicked;

  @api emailclicked;

  errorMessage;

  openApiError = false;

  openRegenerateTemplateErrorPopup = false;

  openDifferentCaseRegenerationPopup = false;

  openWarningRegenerationPopup = false;

  openNoRegenerationPopup = false;

  openRegenerateModal = false;

  openAIRetryError = false;

  modeSwitchCaseError = false;

  @track calculatedContentHealth = {
    "link_accuracy_score": null,
    "metadata_accuracy_score": null,
    "title_accuracy_score": null,
    "uniqueness_score": null
  }
  showHealthCalculationModal = false;
  showHealthCalculationLoader = false;
  showHealthCalculationScore = false;
  showHealthCalculationError = false;

  @track unique;
  @track complete;
  @track contentClear;
  @track accurateTitle;
  @track linksValid;
  @track metadataCorrect;
  @track finalScore;

  successData;

  stayLeave;

  modeSwitchErrorPopupImg;

  articleSuccessful;

  saveProgress;

  errorImg;

  close;

  imageInserted;

  videoEmbed;

  smartLink;

  articleUpdate;

  articleNotExists;

  aiError;

  calculateHealthLoader;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.stayLeave = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_stayleave.svg`;
      this.modeSwitchErrorPopupImg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/modeSwitchErrorImg.svg`;
      this.articleSuccessful = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_articlesuccessful.svg`;
      this.saveProgress = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_saveprogress.svg`;
      this.errorImg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/error.svg`;
      this.imageInserted = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/image_inserted.svg`;
      this.videoEmbed = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/video_embedded.svg`;
      this.smartLink = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/tick.svg`;
      this.articleUpdate = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/article_updated_successfully.svg`;
      this.close = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/close.svg`;
      this.articleNotExists = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/article-no-longer-exists.png`;
      this.openAIRetry = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/Open-AI-retry.svg`;
      this.aiError = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/ai-error.svg`;
      this.calculateHealthLoader = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/calculate-health-loader.gif';

    } else if (error) {
      console.error('Error:', error);
    }
  }

  get classKey() {
    if (
      this.stayleave == true ||
      this.createsuccess == true ||
      this.saveprog == true ||
      this.errorsuccess == true ||
      this.showvideo == true ||
      this.showimage == true ||
      this.ispublish == true ||
      this.openApiError == true ||
      this.openRegenerateModal == true ||
      this.openAIRetryError == true ||
      this.modeSwitchCaseError == true ||
      this.showHealthCalculationModal ==true ||
      this.showDuplicateArticle == true 
    ) {
      return 'displayModal';
    }

    return 'hideModal';
  }

  showModeChangeConfirmationPopup() {
    this.modeSwitchCaseError = true;
  }

  hideSwitchModeConfirmationPopup() {
    this.modeSwitchCaseError = false;
  }

  @track uniquePrediction;
  @track accurateTitlePrediction;
  @track linksPrediction;
  @track metaDataPrediction;

  overAllContentHealth(data, contentStandard = 70) { 
    let totalCount = 0;
    let count = 0;
    this.uniquePrediction = data.uniqueness_score == null ? false : true;
    this.accurateTitlePrediction = data.title_accuracy_score == null ? false : true;
    this.linksPrediction = data.link_accuracy_score == null ? false : true;
    this.metaDataPrediction = data.metadata_accuracy_score == null ? false : true;
    if(this.uniquePrediction && this.unique) {
      ++totalCount;
      if(data.uniqueness_score >= contentStandard){
        ++count;
      }
    }
    if(this.accurateTitlePrediction && this.accurateTitle) {
      ++totalCount;
      if(data.title_accuracy_score >= contentStandard){
        ++count;
      }
    }
    if(this.linksPrediction && this.linksValid) {
      ++totalCount;
      if(data.link_accuracy_score >= contentStandard){
        ++count;
      }
    }
    if(this.metaDataPrediction && this.metadataCorrect) {
      ++totalCount;
      if(data.metadata_accuracy_score >= contentStandard){
        ++count;
      }
    }

    if (this.count == 0) {
      this.finalScore = 0;
    } else {
      this.finalScore = parseInt(((count/totalCount)*100),10);
    }
  }

  visibleParameter(parameters) {
    this.unique = ( parameters.unique == 1 || parameters.unique == "1" ) ? true : false;
    this.complete = ( parameters.complete == 1 || parameters.complete == "1" ) ? true : false;
    this.contentClear = ( parameters.contentClear == 1 || parameters.contentClear == "1" ) ? true : false;
    this.accurateTitle = ( parameters.accurateTitle == 1 || parameters.accurateTitle == "1" ) ? true : false;
    this.linksValid = ( parameters.linksValid == 1 || parameters.linksValid == "1" ) ? true : false;
    this.metadataCorrect = ( parameters.metadataCorrect == 1 || parameters.metadataCorrect == "1" ) ? true : false;
  }

  hideContentHealthModal() {
    this.showHealthCalculationModal = false;
  }

  @api
  showContentHealthModal(val){
    this.showHealthCalculationModal = true;
    if (val.state === 'showLoader') {
      this.showHealthCalculationLoader = true;
      this.showHealthCalculationScore = false;
      this.showHealthCalculationError = false;
    }
    if (val.state === 'showHealthScore') {
      this.showHealthCalculationLoader = false;
      this.showHealthCalculationScore = true;
      this.showHealthCalculationError = false;
      const data = JSON.parse(JSON.stringify(val.data));
      const parameters = JSON.parse(JSON.stringify(val?.settings?.parameters));
      const contentStandard = JSON.parse(JSON.stringify(val?.settings?.contentStandard));
      this.visibleParameter(parameters)
      this.overAllContentHealth(data);
      this.calculatedContentHealth = {
        ...data,
        title_accuracy_score:Math.round(data.title_accuracy_score *100)/100,    
        metadata_accuracy_score: Math.round(data.metadata_accuracy_score*100)/100,
        link_accuracy_score: Math.round(data.link_accuracy_score *100)/100,
        uniqueness_score: Math.round(data.uniqueness_score * 100) /100
      };
    }
    if (val.state === 'showCalculateHealthError') {
      this.showHealthCalculationLoader = false;
      this.showHealthCalculationScore = false;
      this.showHealthCalculationError = true;
    }
  }

  switchKnowblerMode() {
    knowblerPubsub.fireEvent(
      this.pageRef,
      `actionSwitchKnowblerMode${this.uniqueNumber}`,
      true
    );
  }

  renderedCallback() {
    knowblerPubsub.registerListener(
      `actionSwitchShowConfirmationPopup${this.newnumber}`,
      this.showModeChangeConfirmationPopup,
      this
    );

    if (this.template.querySelector('.displayModal')) {
      const display = this.template.querySelector('.displayModal');

      if (display.offsetWidth > 700) {
        if (this.template.querySelector('.modalSuccess'))
          this.template
            .querySelector('.modalSuccess')
            .style.setProperty('width', '328px');
        if (this.template.querySelector('.publishsuccess'))
          this.template
            .querySelector('.publishsuccess')
            .style.setProperty('width', '328px');
      }
    }
  }

  handleSave() {
    this.videoLink = this.template.querySelector('[data-id="videoLink"]').value;
    const iframeRegex =
      /^<iframe.*src="https?:\/\/[a-zA-Z0-9-\.]+\.[a-zA-Z]{2,}(\/\S*)?".*><\/iframe>$/;

    if (!iframeRegex.test(this.videoLink)) {
      this.errorsuccess = true;
      this.errorMessage = 'Invalid Iframe';

      return;
    }
    const leaveevent = new CustomEvent('handlesave', {
      detail: (this.videoLink +=
        '<p><span style="display: none">Video</span></p>')
    });
    this.dispatchEvent(leaveevent);
    this.showvideo = false;
  }

  handleLeave() {
    const leaveevent = new CustomEvent('leave', {
      details: false
    });
    this.dispatchEvent(leaveevent);
  }

  changeCSSStay() {
    const x = this.template.querySelector('[data-id="alertModal"]');
    x.classList.remove('displayModal');
    this.hideModal = false;
    this.stayleave = false;
  }

  retryAutoGenerationTitle() {
    this.cancelRetry();
    this.dispatchEvent(new CustomEvent('autogenerate'));
  }

  cancelRetry() {
    const x = this.template.querySelector('[data-id="alertModal"]');
    x.classList.remove('displayModal');
    this.openAIRetryError = false;
  }

  errorModal() {
    if (this.errorsuccess) {
      if (this.template.querySelector('[data-id="errorModal"]')) {
        const x = this.template.querySelector('[data-id="errorModal"]');
        x.classList.remove('displayModal');
      }
      this.errorsuccess = false;
    }
    if (this.showvideo) {
      this.showvideo = false;
    }
    if (this.showimage) {
      this.showimage = false;
    }
    if (this.ispublish) {
      this.dispatchEvent(new CustomEvent('closemodal'));
    }
  }

  @api
  check() {
    this.stayleave = true;
  }

  @api
  showError(error) {
    const errorData = error?.detail?.output?.fieldErrors;
    if (
      errorData &&
      Object.keys(errorData).length &&
      errorData[Object.keys(errorData)[0]].length
    ) {
      this.errorMessage = errorData[Object.keys(errorData)[0]][0].message;
      this.errorsuccess = true;
    } else {
      this.errorMessage =
        error?.body?.message || error?.detail?.message || 'Error';
      this.errorsuccess = true;
      if (
        error?.status === 404 &&
        error?.body?.message === 'The requested resource does not exist'
      ) {
        this.showArticleNotExistsPopup = true;
        this.errorMessage = 'Article no longer exists!';
      } else {
        this.showArticleNotExistsPopup = false;
      }
    }
  }
  @track contextLimitDisplay= false;
  @track tpmErrorDisplay= false;

  @api
  showOpenApiError(event) {
    this.openApiError = true;
    if (event === 1 || event === '1') {
      this.contextLimitDisplay = true;
      this.tpmErrorDisplay= false;
    }
    if (event === 2 || event === '2') {
      this.tpmErrorDisplay = true;
      this.contextLimitDisplay = false;
    }
  }

  hideOpenApiError() {
    this.openApiError = false;
    this.contextLimitDisplay = false;
    this.tpmErrorDisplay = false;
  }

  @api
  showRegenerateModal(val) {
    this.openRegenerateModal = true;
    if (val === 'openRegenerateTemplateErrorPopup') {
      this.openRegenerateTemplateErrorPopup = true;
    }
    if (val === 'openNoRegenerationPopup') {
      this.openNoRegenerationPopup = true;
    }
    if (val === 'openDifferentCaseRegenerationPopup') {
      this.openDifferentCaseRegenerationPopup = true;
    }
    if (val === 'openWarningRegenerationPopup') {
      this.openWarningRegenerationPopup = true;
    }
  }

  hideRegenerateModal() {
    this.openRegenerateModal = false;

    this.openNoRegenerationPopup = false;
    this.openRegenerateTemplateErrorPopup = false;

    if (
      this.openDifferentCaseRegenerationPopup ||
      this.openWarningRegenerationPopup
    ) {
      this.openDifferentCaseRegenerationPopup = false;
      this.openWarningRegenerationPopup = false;
      this.dispatchEvent(new CustomEvent('closeregeneration'));
    }
  }

  continueRegeneration() {
    this.openDifferentCaseRegenerationPopup = false;
    this.openRegenerateModal = false;
    this.dispatchEvent(new CustomEvent('continueregeneration'));
  }

  regenerateArticleField() {
    this.openWarningRegenerationPopup = false;
    this.openRegenerateModal = false;
    this.dispatchEvent(new CustomEvent('regeneratearticlefield'));
  }

  get getRegenerationOkBtn() {
    return (
      this.openNoRegenerationPopup || this.openRegenerateTemplateErrorPopup
    );
  }

  @api
  showOpenApiRetryError() {
    this.openAIRetryError = true;
  }

  hideOpenApiRetryError() {
    this.openAIRetryError = false;
  }

  sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  @api
  async showSuccess(data) {
    this.successMessage = data.message;
    this.successData = data;
    this.successData[`is${data.type}`] = true;
    this.createsuccess = true;
    await this.sleep(3000);
    this.createsuccess = false;
  }

  @api
  showVideo(data) {
    this.videolink = data;
    this.showvideo = true;
  }

  @api showImage() {
    this.showimage = true;
  }

  closePublishModal() {
    this.dispatchEvent(new CustomEvent('closemodal'));
  }

  publishnow() {
    this.dispatchEvent(new CustomEvent('publishnow'));
  }

  schedulepublish(event) {
    const scheduleDate = event.detail;

    this.dispatchEvent(
      new CustomEvent('schedulepublish', { detail: scheduleDate })
    );
  }

  referencenow() {
    this.dispatchEvent(new CustomEvent('referencenow'));
  }

  resolutionnow() {
    this.dispatchEvent(new CustomEvent('resolutionnow'));
  }

  referenceschedule(event) {
    const scheduleDate = event.detail;

    this.dispatchEvent(
      new CustomEvent('referenceschedule', { detail: scheduleDate })
    );
  }

  resolutionschedule(event) {
    const scheduleDate = event.detail;

    this.dispatchEvent(
      new CustomEvent('resolutionschedule', { detail: scheduleDate })
    );
  }

  @api async ispublishnowmethod() {
    this.ispublish = false;
    this.saveprog = false;
    this.ispublishnowsuccess = true;
    await this.sleep(3000);

    if (this.draftarticlemode) {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '1' }));
    } else {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '2' }));
    }
  }

  @api async ispublishschedulenowmethod() {
    this.ispublish = false;
    this.saveprog = false;
    this.ispublishnowsuccess = true;
    await this.sleep(3000);
    if (this.draftarticlemode) {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '0' }));
    } else {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '1' }));
    }
  }

  @api async isattachmethod() {
    this.isattach = false;
    this.ispublish = false;
    this.articleattach = true;
    await this.sleep(3000);
    if (this.draftarticlemode) {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '1' }));
    } else {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '2' }));
    }
  }

  @api async isattachschedulemethod() {
    this.isattach = false;
    this.ispublish = false;
    this.articleattach = true;
    await this.sleep(3000);
    if (this.draftarticlemode) {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '0' }));
    } else {
      this.dispatchEvent(new CustomEvent('closepublish', { detail: '1' }));
    }
  }

  closeattach() {
    this.dispatchEvent(new CustomEvent('closeattach'));
  }

  attachresolution() {
    this.dispatchEvent(new CustomEvent('attachresolution'));
  }

  attachreference() {
    this.dispatchEvent(new CustomEvent('attachreference'));
  }

  clickedcommentreference() {
    this.dispatchEvent(new CustomEvent('clickedcommentreference'));
  }

  clickedemailreference() {
    this.dispatchEvent(new CustomEvent('clickedemailreference'));
  }

  clickedcommentresolution() {
    this.dispatchEvent(new CustomEvent('clickedcommentresolution'));
  }

  clickedemailresolution() {
    this.dispatchEvent(new CustomEvent('clickedemailresolution'));
  }

  @api async attachsuccessfull() {
    this.isattach = false;
    this.attachsuccesfull = true;
    await this.sleep(3000);
    this.attachsuccesfull = false;
  }

  @api async detachsuccessfull() {
    this.isattach = false;
    this.detachsuccesfull = true;
    await this.sleep(3000);
    this.detachsuccesfull = false;
  }

  @api async linkcopy() {
    this.linkcopied = true;
    await this.sleep(3000);
    this.linkcopied = false;
  }
}