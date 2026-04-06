import { LightningElement, api, track, wire } from 'lwc';
import getVFOrigin from '@salesforce/apex/SU_Knowbler.EditorController.getVFOrigin';
import { getDataConnectorSourceFields } from 'lightning/analyticsWaveApi';

export default class KnowblerEditor extends LightningElement {
  siteURL;

  @api fieldname;

  @api fieldvalue;

  @wire(getVFOrigin)
  vfOrigin;

  vforg;

  myVal;

  type;

  knowblerInstanceId;

  backdrope = false;

  @api destobj;

  @api exp;

  @track frameheight;

  connectedCallback() {
    this.knowblerInstanceId = Math.floor(Math.random() * 10000);
    this.siteURL = `/apex/su_knowbler__editor?fieldname=${this.fieldname}&instanceId=${this.knowblerInstanceId}`;
    // Binding EventListener here when Data received from VF
    window.addEventListener('message', this.handleVFResponse.bind(this));
  }

  renderedCallback() {
    const framewidth = this.template.querySelector(
      `[data-id ="alertModal"]`
    ).offsetWidth;

    if (framewidth > 500) {
      this.frameheight = '370px';
    } else {
      this.frameheight = '460px';
    }
  }

  msg = '';

  receivedMessage = '';

  error;

  get displayModal() {
    if (this.backdrope) {
      return 'displayModal';
    }
  }

  get geTClass() {
    if (this.backdrope) return 'geTClass modal';
  }

  handleVFResponse(message) {
    if (
      message?.origin?.split('.').length &&
      this.vfOrigin?.data?.split('.').length &&
      message?.origin?.split('.')[0] === this.vfOrigin?.data?.split('.')[0]
    ) {
      this.vforg = message?.origin;
      this.receivedMessage = message.data;
      if (message.data.fieldname == this.fieldname) {
        this.type = message.data.type;
        this.myVal = message.data.myVal;
        switch (message.data.type) {
          case 'backdrope':
            if (message.data.instanceId == this.knowblerInstanceId) {
              this.backdrope = true;
              break;
            }
          case 'close':
            this.backdrope = false;
            break;
          case 'change':
            if (this.fieldvalue && this.fieldvalue != '') {
              this.handleFiretoVF({
                updateValue: 'update',
                data: this.fieldvalue
              });
            }
            break;
          case 'smart':
            if (message.data.instanceId == this.knowblerInstanceId) {
              this.openSmartLinkPopup(
                message.data?.value ? message.data?.value : ''
              );
            }
            break;
          case 'video':
            if (message.data.instanceId == this.knowblerInstanceId) {
              this.openPopup(message.data?.value ? message.data?.value : '');
            }
            break;
          case 'image':
            if (message.data.instanceId == this.knowblerInstanceId) {
              this.openImagePopup();
            }
            break;
          case 'update':
            this.dispatchEvent(
              new CustomEvent('editorvaluechange', {
                detail: {
                  value: message.data.myVal,
                  fieldname: this.fieldname
                }
              })
            );
            break;
        }
      }
    }
  }

  handleFiretoVF(data) {
    // Firing an event to send data to VF
    if (
      this.template.querySelector('iframe') &&
      this.template.querySelector('iframe').contentWindow
    )
      this.template
        .querySelector('iframe')
        .contentWindow.postMessage(data, this.vforg);
  }

  openPopup(data) {
    this.template.querySelector('c-knowbler-modal-component').showVideo(data);
  }

  openImagePopup() {
    this.template.querySelector('c-knowbler-image-rte-modal').openmodal();
  }

  openSmartLinkPopup(data) {
    this.template
      .querySelector('c-knowbler-smart-link-rte-modal')
      .openmodal(data);
  }

  handleSmartLink(event) {
    this.handleFiretoVF({ type: 'smartLink', data: event.detail });
    this.template
      .querySelector('c-knowbler-modal-component')
      .showSuccess({ type: 'smartLink', message: 'Smart Link Saved' });
  }

  handleSave(event) {
    this.handleFiretoVF({ type: 'image', data: event.detail });
    this.template
      .querySelector('c-knowbler-modal-component')
      .showSuccess({ type: 'image', message: 'Image Inserted' });
  }

  handleVideo(event) {
    this.handleFiretoVF({ type: 'video', data: event.detail });
    this.template
      .querySelector('c-knowbler-modal-component')
      .showSuccess({ type: 'video', message: 'Video Embedded' });
  }
}