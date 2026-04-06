import { LightningElement, track, wire, api } from 'lwc';
import getsettingsuid from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getsettingsuid';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';
import IsAttached from '@salesforce/apex/SU_Knowbler.KCSPublishController.isAttached';
import knowblerPubsub from 'c/knowblerPubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class knowblerPublishArticleOptions extends LightningElement {
  value = '';

  publishNow = false;

  schedulePublish = false;

  @track scheduleDate;

  @track disabledate = true;

  @track publishAndAttach = false;

  @track isReference;

  @track isResolution;

  @api caseid;

  @api clientSettings;

  @api casenumber;

  @api jwttoken;

  @track uid;

  @api isattach = false;

  @api endpoint;

  @api ispublishattach;

  @track ispublishnowsuccess;

  @track containsresolution;

  @track resolutionchecked = true;

  @api commentclicked;

  @api emailclicked;

  @api kcslabel = 'Attach To Case';

  saveProgress;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.saveProgress = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_saveprogress.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  // to pass the case id
  @wire(CurrentPageReference) pagerf;

  hasresolution() {
    const rawdata = {
      uid: this.uid,
      caseId: this.caseid
    };
    const url = `${this.endpoint}/kcs-anlytics/rest/anlytics/track/checkResolutionStatus`;
    fetch(url, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        accept: '/',
        'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'ngrok-skip-browser-warning': true,
        Authorization: `Bearer ${this.jwttoken}`
      },
      body: JSON.stringify(rawdata)
    })
      .then((response) => {
        if (response.status != 200) {
          knowblerPubsub.fireEvent(
            this.CurrentPageReference,
            'apierroroccurs',
            'error'
          );
        }

        return response.json();
      })
      .then((data) => {
        this.containsresolution = data.data.resolutionStatus;
        const resolutionArticleDetails = data.data.details;
        if (this.containsresolution) {
          if (resolutionArticleDetails && resolutionArticleDetails.doc_id) {
            IsAttached({
              articleId: resolutionArticleDetails.doc_id,
              caseId: this.caseid
            })
              .then((result) => {
                if (result) {
                  this.isReference = true;
                  this.okattachhandler();
                } else {
                  this.publishAndAttach = true;
                }
              })
              .catch((error) => {
                this.error = error;
              });
          } else {
            this.isReference = true;
            this.okattachhandler();
          }
        } else {
          this.publishAndAttach = true;
        }
      });
  }

  get options() {
    return [
      { label: 'Publish Now', value: 'publish now' },
      { label: 'Schedule Publish On', value: 'Schedule publish' }
    ];
  }

  get optionsToAttachToCase() {
    return [
      { label: 'Helpful / Reference', value: 'Reference' },
      { label: 'Resolution', value: 'Resolution' }
    ];
  }

  get optionsToAttachToCaseenabled() {
    return [{ label: 'Helpful / Reference', value: 'Reference' }];
  }

  get optionsToAttachToCasedisabled() {
    return [{ label: 'Resolution', value: 'Resolution' }];
  }

  connectedCallback() {
    this.getcustomsettings();
  }

  getcustomsettings() {
    getsettingsuid().then((result) => {
      this.uid = result;
      if (this.ispublishattach) {
        if (
          this.clientSettings &&
          this.clientSettings.resolution_reference_activated
        ) {
          this.hasresolution();
        } else {
          this.isReference = true;
          this.okattachhandler();
        }
      }
    });
  }

  get publishAndScheduleCondition() {
    return this.publishAndAttach || this.ispublishattach;
  }

  //  to check for selected radio button for publish now and schedule publish
  get mindate() {
    let today = new Date();
    const day = new Date();
    day.setDate(today.getDate() + 1);
    const dd = String(day.getDate()).padStart(2, '0');
    const mm = String(day.getMonth() + 1).padStart(2, '0');
    const yyyy = day.getFullYear();
    today = `${mm}/${dd}/${yyyy}`;

    return today;
  }

  handleRadioChange(event) {
    const selectedOption = event.detail.value;

    if (selectedOption == 'publish now') {
      this.publishNow = true;
      this.disabledate = true;
      Promise.resolve().then(() => {
        const inputEle = this.template.querySelector('.dateValidation');
        inputEle.reportValidity();
      });
      this.template.querySelector('.dateValidation').value = null;
    } else {
      this.publishNow = false;
    }
    if (selectedOption == 'Schedule publish') {
      this.schedulePublish = true;
      this.disabledate = false;
    } else {
      this.schedulePublish = false;
    }
    this.template.querySelector('.publishokbutton').disabled = false;

    const select = this.template.querySelector('.publishokbutton');
    if (select.classList.contains('disableButton'))
      select.classList.remove('disableButton');
  }

  //  to check for selected radio button for reference and resolution
  handlePublishAndAttach(event) {
    const selectedOption = event.detail.value;
    if (selectedOption == 'Reference') {
      this.isReference = true;
      this.isResolution = false;
    } else if (selectedOption == 'Resolution') {
      this.isResolution = true;
      this.isReference = false;
    }

    this.template.querySelector('.okbutton').disabled = false;
    const select = this.template.querySelector('.okbutton');
    if (select.classList.contains('disableButton'))
      select.classList.remove('disableButton');
  }

  okattachhandler() {
    if (this.isReference) {
      this.dispatchEvent(new CustomEvent('referencenow'));
    } else if (this.isResolution) {
      this.dispatchEvent(new CustomEvent('resolutionnow'));
    }
  }

  //  to handle the scheduledate match the org date
  handleDateChange(event) {
    const selectedDate = event.detail.value;
    const addADay = new Date(selectedDate);
    addADay.setDate(addADay.getDate() + 1);
    this.scheduleDate = addADay;
    Promise.resolve().then(() => {
      const inputEle = this.template.querySelector('.dateValidation');
      inputEle.reportValidity();
    });
  }

  okhandler() {
    const validdate = this.template
      .querySelector('.dateValidation')
      .reportValidity();

    if (validdate) {
      if (this.publishNow && !this.ispublishattach) {
        this.dispatchEvent(new CustomEvent('publishnow'));
      } else if (
        this.schedulePublish &&
        this.scheduleDate &&
        !this.ispublishattach
      ) {
        this.dispatchEvent(
          new CustomEvent('schedulepublish', { detail: this.scheduleDate })
        );
      }
    }
  }

  // to close the popup
  closePublishModal() {
    this.dispatchEvent(new CustomEvent('closemodal'));
  }

  closeattachPublishModal() {
    this.publishAndAttach = false;
    this.dispatchEvent(new CustomEvent('closemodal'));
  }

  closeattach() {
    this.dispatchEvent(new CustomEvent('closeattach'));
  }

  // to attach article
  attacharticlehandler() {
    if (this.commentclicked && this.isReference) {
      this.dispatchEvent(new CustomEvent('clickedcommentreference'));
    } else if (this.emailclicked && this.isReference) {
      this.dispatchEvent(new CustomEvent('clickedemailreference'));
    } else if (this.commentclicked && this.isResolution) {
      this.dispatchEvent(new CustomEvent('clickedcommentresolution'));
    } else if (this.emailclicked && this.isResolution) {
      this.dispatchEvent(new CustomEvent('clickedemailresolution'));
    } else if (this.isReference) {
      this.dispatchEvent(new CustomEvent('attachreference'));
    } else if (this.isResolution) {
      this.dispatchEvent(new CustomEvent('attachresolution'));
    }
  }
}