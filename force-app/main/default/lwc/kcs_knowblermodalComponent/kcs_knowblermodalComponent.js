import { LightningElement, api, track, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class Kcs_knowblermodalComponent extends LightningElement {
  @api stayleave;

  @api owneremail;

  @api saveprog;

  @api createsuccess;

  errorsuccess = false;

  @api showvideo;

  @api videolink;

  @api showimage;

  @api ispublish;

  @api ispublishnow;

  @api isschedulepublish;

  @api languagechanged;

  @api articlenumber;

  @api parameters;

  @api totalevaluationpoints;

  @api evaluationscore;

  @api contenthealthdata;

  @api ispublishattach;

  @track articleattach;

  @track ispublishnowsuccess;

  @api predicteddatafromcard;

  @api evaluatedata;

  @api alreadyevaluatedflag;

  @track evaluatedsuccess;

  @api largescreen;

  @api newnumber;

  @api articledetails;

  @api destobj;

  stayLeave;

  articleSuccessful;

  saveProgress;

  errorImg;

  close;

  imageInserted;

  videoEmbed;

  smartLink;

  articleUpdate;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.stayLeave = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_stayleave.svg`;
      this.articleSuccessful = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_articlesuccessful.svg`;
      this.saveProgress = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_saveprogress.svg`;
      this.errorImg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/error.svg`;
      this.close = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/close.svg`;
      this.imageInserted = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/image_inserted.svg`;
      this.videoEmbed = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/video_embedded.svg`;
      this.smartLink = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/tick.svg`;
      this.articleUpdate = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/article_updated_successfully.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  errorMessage;

  successData;

  get classKey() {
    if (
      this.stayleave == true ||
      this.evaluatedata ||
      this.createsuccess == true ||
      this.saveprog == true ||
      this.errorsuccess == true ||
      this.showvideo == true ||
      this.showimage == true ||
      this.ispublish == true
    ) {
      return 'displayModal';
    }

    return 'hideModal';
  }

  handleSave() {
    this.videoLink = this.template.querySelector('[data-id="videoLink"]').value;
    const leaveevent = new CustomEvent('handlesave', {
      detail: this.videoLink
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
    }
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
      new CustomEvent('referenceschedule', { detail: this.scheduleDate })
    );
  }

  resolutionschedule(event) {
    const scheduleDate = event.detail;

    this.dispatchEvent(
      new CustomEvent('resolutionschedule', { detail: this.scheduleDate })
    );
  }

  @api async ispublishnowmethod() {
    this.ispublishnowsuccess = true;
    await this.sleep(3000);
    this.dispatchEvent(new CustomEvent('closepublish'));
  }

  @api async isattachmethod() {
    this.articleattach = true;
    await this.sleep(3000);
    this.dispatchEvent(new CustomEvent('closepublish'));
  }

  closeevaluate() {
    this.dispatchEvent(new CustomEvent('closeevaluate'));
  }

  // To show evaluated successfully popup
  @api async evaluatedsuccessmethod() {
    this.evaluatedsuccess = true;
    await this.sleep(3000);
    this.evaluatedsuccess = false;
    this.dispatchEvent(new CustomEvent('refreshlist'));
  }
}