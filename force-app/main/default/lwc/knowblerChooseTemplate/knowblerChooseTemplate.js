import { LightningElement, api, track } from 'lwc';

export default class KnowblerChooseTemplate extends LightningElement {
  @api flexipageregionwidth;

  @api kcssupport;

  @api kcsheight;

  @track kcsSupport;

  @api casenumber;

  @api endpoint;

  @api jwttoken;

  @api clientSettings;

  @api uid;

  connectedCallback() {
    this.kcsSupport = this.kcssupport.filter((res) => res.active == true);

    if (
      this.kcsSupport.length == 1 &&
      this.kcsSupport[0].salesforceExperience == 'Classic'
    ) {
      this.handleSalesforce();
    } else if (this.kcsSupport.length == 1) {
      this.handleRTSelect(this.kcsSupport[0]?.RecordType);
    }
  }

  renderedCallback() {
    if (this.kcssupport.length > 12 && this.flexipageregionwidth == 'SMALL') {
      const removeImage = this.template.querySelector('.bgImage');
      removeImage.classList.remove('bgImage');
    }

    if (this.flexipageregionwidth) {
      const heightcreation = `${Math.floor(this.kcsheight - 50)}px`;
      if (this.template.querySelector('.RTDiv')) {
        if (this.flexipageregionwidth == 'SMALL') {
          if (this.kcssupport.length > 12) {
            this.template.querySelector('.RTDiv').style =
              `height:${heightcreation};`;
          } else {
            this.template.querySelector('.RTDiv').style =
              `height:${heightcreation}; background-image: url('https://80c3-112-196-28-106.ngrok-free.app/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/choose_a_template.svg')`;
          }
        } else {
          this.template.querySelector('.RTDiv').style =
            `height:${heightcreation}; background-image: url('https://80c3-112-196-28-106.ngrok-free.app/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/bgImageTemplate.png')`;
        }
      }
    } else {
      const heightcreation = `${Math.floor(screen.height - 220)}px`;
      if (this.template.querySelector('.RTDiv'))
        this.template.querySelector('.RTDiv').style =
          `height:${heightcreation}; background-image: url('https://80c3-112-196-28-106.ngrok-free.app/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/bgImageTemplate.png')`;
    }
  }

  CloseNewArticle() {
    const recevent = new CustomEvent('recclick', {
      detail: { showArticleList: true }
    });
    this.dispatchEvent(recevent);
  }

  handleRTSelect(event) {
    this.recType = event?.currentTarget?.dataset?.id
      ? event?.currentTarget?.dataset?.id
      : event;
    this.rtflag = false;
    let isAutoGenTitle = false;
    let selectedMapping;
    for (let i = 0; i < this.kcssupport.length; i++) {
      if (this.kcssupport[i].RecordType === this.recType) {
        if (this.kcssupport[i]?.autoGenConfig?.config?.length > 0) {
          isAutoGenTitle = true;
        }
        selectedMapping = this.kcssupport[i];
      }
    }
    const recevent = new CustomEvent('recclick', {
      detail: {
        rec: this.recType,
        flag: false,
        isAutoGenerateTitle: isAutoGenTitle,
        mappingObj: selectedMapping
      }
    });
    this.dispatchEvent(recevent);
  }

  handleSalesforce() {
    this.rtflag = false;
    const recevent = new CustomEvent('recclick', {
      detail: { type: 'classic', flag: false }
    });
    this.dispatchEvent(recevent);
  }

  get getSmallLayout() {
    switch (this.flexipageregionwidth) {
      case 'SMALL':
        this.getLayoutSize = 12;
        break;
      case 'MEDIUM':
        this.getLayoutSize = 6;
        break;
      default:
        this.getLayoutSize = 4;
        break;
    }

    return (
      this.flexipageregionwidth == 'SMALL' ||
      this.flexipageregionwidth == 'MEDIUM' ||
      this.flexipageregionwidth == 'LARGE'
    );
  }
}