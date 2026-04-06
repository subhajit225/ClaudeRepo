import { LightningElement, api, track, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerImageRteModal extends LightningElement {
  showimage;

  errorMsg = 'Error:Check Code';

  message;

  @track messageIsHtml = false;

  @track showToastBar = false;

  imageUploadMethod = 'uploadImg';

  fileData;

  file;

  imgResult;

  webAddressUrl;

  imageFileValidation = false;

  urlImage;

  autoCloseTime = 2000;

  close;

  fileImg;

  get imageUploadMethodClass() {
    if (this.imageUploadMethod == 'uploadImg') {
      return 'uploadImgButton selectedButton';
    }

    return 'uploadImgButton';
  }

  get imageBtnDisabled() {
    if (
      (this.imgResult != '' &&
        this.imgResult != undefined &&
        this.imgResult != null) ||
      (this.webAddressUrl != '' &&
        this.webAddressUrl != undefined &&
        this.webAddressUrl != null)
    ) {
      return false;
    }

    return true;
  }

  get imageUploadWebAddressMethodClass() {
    if (this.imageUploadMethod == 'imgWebAddress') {
      return 'uploadImgWebAddress selectedButton';
    }

    return 'uploadImgWebAddress';
  }

  get uploadImageData() {
    if (this.imageUploadMethod == 'uploadImg') {
      return true;
    }

    return false;
  }

  get webAddressImgData() {
    if (this.imageUploadMethod == 'imgWebAddress') {
      return true;
    }

    return false;
  }

  getImageUrl(event) {
    this.webAddressUrl = event.currentTarget.value;
  }

  uploadImg(event) {
    this.imageFileValidation = false;
    this.webAddressUrl = '';
    const dataId = event.currentTarget.dataset.id;
    this.imageUploadMethod = dataId;
    const methodId = this.template.querySelector(`[data-id="${dataId}"]`);

    methodId.classList.add('selectedButton');
  }

  uploadImgUsingWebAddress(event) {
    const dataId = event.currentTarget.dataset.id;
    this.imageUploadMethod = dataId;
    const methodId = this.template.querySelector(`[data-id="${dataId}"]`);

    methodId.classList.add('selectedButton');
  }

  openfileUpload(event) {
    const file = event.target.files[0];
    this.file = file;
    const reader = new FileReader();
    reader.onload = () => {
      const base64 = reader.result.split(',')[1];
      this.imgResult = reader.result;
      this.fileData = {
        filename: file.name,
        base64,
        recordId: this.recordId
      };
    };
    reader.readAsDataURL(file);
  }

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.close = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/close.svg`;
      this.fileImg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/File.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  insertImgURL() {
    const theUrl = this.template.querySelector('[data-id="webAddress"]').value;
    if (
      theUrl.length === 0 ||
      (theUrl.indexOf('https://') === -1 && theUrl.indexOf('http://') === -1)
    ) {
      this.imageFileValidation = true;
    } else if (
      (theUrl.indexOf('https://') != -1 &&
        theUrl.split('https://')[1].length === 0) ||
      (theUrl.indexOf('http://') != -1 &&
        theUrl.split('http://')[1].length === 0)
    ) {
      this.imageFileValidation = true;
    } else {
      try {
        this.message = 'Image Inserted';
        this.showToastBar = true;
        this.getIconName = 'utility:success';
        this.imageFileValidation = false;
        this.closePopup();
        const template = `<img src="${theUrl}"/>`;
        this.handleSave(template);
        this.fileData = '';
        this.webAddressUrl = '';
      } catch (exception) {
        this.imageFileValidation = true;
      }
    }
  }

  insertImg(event) {
    const { file } = this;
    const fileSize = Math.round(file.size / 1024);
    if (fileSize <= 1024) {
      this.imageFileValidation = false;
      const result = this.imgResult;
      const template = `<img class="cke_widget_element" alt="upload-image-tag" src="${result}"/>`;
      this.handleSave(template);
      this.fileData = '';
      this.closePopup();
    } else {
      this.imageFileValidation = true;
    }
  }

  handleSave(event) {
    const leaveevent = new CustomEvent('imagesave', {
      detail: event
    });
    this.dispatchEvent(leaveevent);
    this.showimage = false;
  }

  closePopup() {
    this.showimage = false;
  }

  @api
  openmodal() {
    this.showimage = true;
  }
}