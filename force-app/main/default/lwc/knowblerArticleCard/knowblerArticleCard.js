import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import AttachArticleToCase from '@salesforce/apex/SU_Knowbler.KCSPublishController.attachArticleToCase';
import GetArticleFields from '@salesforce/apex/SU_Knowbler.KCSPublishController.getArticleFields';
import PublishArticle from '@salesforce/apex/SU_Knowbler.KCSPublishController.publishArticle';
import IsAttached from '@salesforce/apex/SU_Knowbler.KCSPublishController.isAttached';
import detacharticle from '@salesforce/apex/SU_Knowbler.KCSPublishController.detacharticle';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import knowblerPubsub from 'c/knowblerPubsub';
import getsettingsuid from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getsettingsuid';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerArticleCard extends NavigationMixin(
  LightningElement
) {
  @api item;

  @api cardindex;

  @api draftarticlemode;

  @api newnumber;

  @track containsresolution;

  @track timezone;

  @api query;

  @track kcslabel = 'Attach To Case';

  @api flexipageregionwidth;

  @api currentuserlanguage;

  @api ispublisharticletab = false;

  @api casedata;

  @api casenumber;

  @api jwttoken;

  @api clientSettings;

  @api endpoint;

  @track isattach;

  @track url;

  @track title;

  @track showdetach = false;

  @track caseId;

  @track ishowmodal;

  @track emailbody;

  @api mappingfields;

  @track cmpvisible = true;

  @track isArticleExist = true;

  showArticlePreview = false;

  @api caseclosed;

  @api duplicacylisting = false;

  editArticle;

  calander;

  edit;

  manage;

  attachtocaseimg;

  detachimg;

  copyimg;

  casecommentimg;

  emaillinkimg;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.editArticle = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/edit_article.svg`;
      this.calander = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/calander.svg`;
      this.edit = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/edit.svg`;
      this.manage = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/manage.svg`;
      this.attachtocaseimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/attachtocase.svg`;
      this.detachimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/detach.svg`;
      this.copyimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/Copytoclipboard.svg`;
      this.casecommentimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/Shareviacasecomment.svg`;
      this.emaillinkimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/Sendlinkviaemail.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  showFistTime = false;

  @api cardindexs;

  @track Imglink;

  @track TourStatus;

  @track userId;

  @track items = {};

  offsetLeft;

  offsetTop;

  postion = 'right';

  cardtitle;

  @api cardlength;

  @api destobj;

  @api alldatacategories;

  @track error;

  @track newarticle;

  @track articleattached;

  @track articleId;

  @track resolutionselected;

  @track referenceselected;

  @track commentclicked;

  @track emailclicked;

  connectedCallback() {
    this.caseclosed = false;
    this.timezone = TIME_ZONE;
    this.items = {
      ...this.item
    };
    this.TourStatus = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      Object.keys(this.TourStatus).length &&
      this.TourStatus[window.btoa(encodeURIComponent(Id))]?.status ==
        'InProgress' &&
      this.cardindex == 0 &&
      this.cardindexs == 0
    ) {
      this.showFistTime = true;
    }
    this.cardtitle = `cardtitle${this.cardindex}_${this.cardindexs}`;
    this.isattached();
    this.getcustomsettings();
  }

  isattached() {
    IsAttached({
      articleId: this.item.Id,
      caseId: this.casedata
    })
      .then((result) => {
        this.articleattached = result;
      })
      .catch((error) => {
        this.error = error;
      });
  }

  createCustomUrl(articleObj) {
    const testRegex = /{{.*?}}/g;
    const str = this.clientSettings.base_href;
    let baseHref = this.clientSettings.base_href;
    let baseHrefTemp;

    if (baseHref.includes('{{Title}}')) {
      baseHref = baseHref.replace(
        '{{Title}}',
        articleObj.Title.split(' ')
          .join('-')
          .replace(/[&\/\\#, +()$~%.'":*?<>{}]/g, '-')
          .replace(/-{2,}/g, '-')
      );
    }

    while ((baseHrefTemp = testRegex.exec(str)) !== null) {
      if (baseHrefTemp.index === testRegex.lastIndex) {
        testRegex.lastIndex += 1;
      }
      baseHrefTemp.forEach((match) => {
        baseHref = baseHref.replace(
          match,
          articleObj[match.replace('{{', '').replace('}}', '')]
        );
      });
    }

    return baseHref;
  }

  previewClose() {
    const str = `.${this.cardtitle}_box`;
    $(this.template.querySelector(str)).hide();
  }

  get getCardTitle() {
    return `${this.cardtitle} article_title`;
  }

  get getCardBox() {
    return `${this.cardtitle}_box`;
  }

  renderedCallback() {
    const str = `.${this.cardtitle}_box`;
    $(this.template.querySelector(str)).hide();
  }

  mouseEnter(evt) {
    try {
      this.showArticlePreview = true;
      GetArticleFields({
        recordId: this.item.Id,
        destinationObj: this.destobj
      })
        .then((res) => {
          if (res && res.Id) {
            this.isArticleExist = true;
          } else {
            this.isArticleExist = false;
          }
        })
        .catch((e) => {
          this.isArticleExist = false;
        });
    } catch (error) {
      this.isArticleExist = false;
    }

    this.cmpvisible = true;
    if (this.items?.open == true) return;

    this.items.open = true;
    const elems = evt;
    const curClass = this.cardtitle;
    const str = `.${curClass}_box`;
    const windowHeight = $(window).height();
    const windowWidth = $(window).width();

    const left = evt.clientX;
    const top = evt.clientY;
    const offsetLeft = $(this.template.querySelector(`.${curClass}`)).offset()
      .left;
    this.offsetTop = top;
    const linkHeight = $(this.template.querySelector(`.${curClass}`)).height();
    const linkWidth = $(this.template.querySelector(`.${curClass}`)).width();
    const bottom = windowHeight - top - linkHeight;
    const right = windowWidth - left - linkWidth;
    const topbottom = top < bottom ? bottom : top;
    const leftright = left < right ? right : left;

    const tooltiph = $(
      this.template.querySelector(`.${curClass}_box`)
    ).height();
    const tooltipw = $(this.template.querySelector(`.${curClass}_box`)).width();

    if (topbottom == bottom && leftright == right) {
      var yPos = top;
      var xPos = offsetLeft + linkWidth + 14;
      this.postion = 'right';
      this.offsetLeft = offsetLeft + linkWidth;
      $(this.template.querySelector(`.${curClass}_box`)).css(
        'left',
        `${xPos}px`
      );
      $(this.template.querySelector(`.${this.cardtitle}_box`)).css(
        'right',
        'unset'
      );
    } else if (topbottom == top && leftright == right) {
      var xPos = offsetLeft + linkWidth + 14;
      this.postion = 'right';
      this.offsetLeft = offsetLeft + linkWidth;
      var yPos = top - tooltiph - linkHeight / 2;
      $(this.template.querySelector(`.${curClass}_box`)).css(
        'left',
        `${xPos}px`
      );
      $(this.template.querySelector(`.${this.cardtitle}_box`)).css(
        'right',
        'unset'
      );
    } else if (leftright == left) {
      var yPos = top - tooltiph - linkHeight / 2;
      var xPos = offsetLeft - tooltipw - 16;
      this.postion = 'left';
      this.offsetLeft = offsetLeft;
      if (xPos > 0) {
        $(this.template.querySelector(`.${curClass}_box`)).css(
          'left',
          `${xPos}px`
        );
        $(this.template.querySelector(`.${this.cardtitle}_box`)).css(
          'right',
          'unset'
        );
      } else {
        var xPos = offsetLeft + linkWidth + 14;
        this.postion = 'right';
        this.offsetLeft = offsetLeft + linkWidth;
        var yPos = top - tooltiph - linkHeight / 2;
        $(this.template.querySelector(`.${curClass}_box`)).css(
          'left',
          `${xPos}px`
        );
        $(this.template.querySelector(`.${this.cardtitle}_box`)).css(
          'right',
          'unset'
        );
      }
    } else if (this.cardindex + 1 != this.cardlength) {
      var xPos = offsetLeft + linkWidth + 14;
      this.postion = 'right';
      this.offsetLeft = offsetLeft + linkWidth;
      var yPos = top - tooltiph - linkHeight / 2;
      $(this.template.querySelector(`.${curClass}_box`)).css(
        'left',
        `${xPos}px`
      );
      $(this.template.querySelector(`.${this.cardtitle}_box`)).css(
        'right',
        'unset'
      );
    }

    if (windowHeight > 800) {
      if (top > 640) {
        const previewTopPosition = windowHeight - 615;
        $(this.template.querySelector(`.${curClass}_box`)).css(
          'top',
          `${previewTopPosition}px`
        );
      } else {
        const previewTopPosition = (windowHeight - 630) / 4;
        $(this.template.querySelector(`.${curClass}_box`)).css(
          'top',
          `${previewTopPosition}px`
        );
      }
    } else if (top > 550) {
      const previewTopPosition = windowHeight - 620;
      $(this.template.querySelector(`.${curClass}_box`)).css(
        'top',
        `${previewTopPosition}px`
      );
    } else {
      $(this.template.querySelector(`.${curClass}_box`)).css('top', '20px');
    }

    setTimeout(() => {
      if (this.items.open) {
        $(this.template.querySelector(str)).fadeIn('fast');
        this.template.querySelector('c-knowbler-parent-preview').setDiamand();
      }
    }, 400);

    knowblerPubsub.fireEvent(this.objpageReference, 'getmapping', 'temp');
    this.dispatchEvent(
      new CustomEvent('previewopen', {
        detail: this.items
      })
    );
  }

  parentpreviewposition;

  mouseOut(evt) {
    const previewposition = evt.target.getBoundingClientRect();
    this.parentpreviewposition = previewposition;
    console.log('event.clientX', evt.clientX);
    console.log('event.clientY', evt.clientY);
    console.log('previewposition.X', previewposition.x);
    console.log('previewposition.Y', previewposition.y);
    console.log('previewposition.width', previewposition.width);
    console.log('previewposition.height', previewposition.height);
    if (
      evt.clientX < previewposition.x ||
      evt.clientX > previewposition.x + previewposition.width ||
      evt.clientY < previewposition.y ||
      evt.clientY > previewposition.y + previewposition.height
    ) {
      console.log('target element>>>>', evt.target.value);
      this.cmpvisible = false;
      this.items.open = false;
      const str = `.${this.cardtitle}_box`;
      $(this.template.querySelector(str)).hide();
    }
    this.showArticlePreview = false;
  }

  mouseoutfromcard(evt) {
    if (
      !this.parentpreviewposition ||
      evt.clientX < this.parentpreviewposition.x ||
      evt.clientX >
        this.parentpreviewposition.x + this.parentpreviewposition.width ||
      evt.clientY < this.parentpreviewposition.y ||
      evt.clientY >
        this.parentpreviewposition.y + this.parentpreviewposition.height
    ) {
      this.parentpreviewposition = undefined;
      this.cmpvisible = false;
      this.items.open = false;
      const str = `.${this.cardtitle}_box`;
      $(this.template.querySelector(str)).hide();
    }

    this.showArticlePreview = false;
  }

  openCloseDropdown(event) {
    event.stopPropagation();
    // Dispatched and handled at "articleCards"
    this.dispatchEvent(
      new CustomEvent('dotclick', {
        detail: this.item
      })
    );
  }

  hidePopup() {
    this.showFistTime = false;
    this.TourStatus[window.btoa(encodeURIComponent(Id))].status = 'Completed';
    if (
      this.TourStatus[window.btoa(encodeURIComponent(Id))].creatorSettings
        .showSwitchInstructionTooltip !== false
    ) {
      this.TourStatus[
        window.btoa(encodeURIComponent(Id))
      ].creatorSettings.showSwitchInstructionTooltip = true;
      knowblerPubsub.fireEvent(
        this.objpageReference,
        `showSwitchTooltip${this.newnumber}`,
        true
      );
    }
    localStorage.setItem('TourStatus', JSON.stringify(this.TourStatus));
  }

  openSubTab(event, dotClick = true) {
    event.stopPropagation();
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.item.Id,
        objectApiName: this.destobj,
        actionName: 'view'
      }
    });
    if(dotClick)
      this.dispatchEvent(
        new CustomEvent('dotclick', {
          detail: this.item
        })
      );
  }

  get showEdit() {
    return (
      this.currentuserlanguage?.currentUserEmailId == this.item?.Owner.Email
    );
  }

  openManageScreen = false;

  openManageArticle(event) {
    if(this.item.duplicacyPercentage) return this.openSubTab(event, false)
    // Dispatched and handled at "articleCards"
    this.dispatchEvent(
      new CustomEvent('openmanagescreen', {
        detail: {
          item: this.item,
          showManage: 1
        }
      })
    );
  }

  openEdit() {
    // Dispatched and handled at "articleCards"
    this.dispatchEvent(
      new CustomEvent('openmanagescreen', {
        detail: {
          item: this.item
        }
      })
    );
  }

  openmodal() {
    this.kcslabel = 'Attach To Case';
    this.caseId = this.casedata;
    if (
      this.clientSettings &&
      this.clientSettings.resolution_reference_activated
    ) {
      this.commentclicked = false;
      this.emailclicked = false;
      this.hasresolution();
    } else {
      this.resolutionselected = false;
      this.referenceselected = false;
      this.attachToCase();
    }
  }

  closeattach() {
    this.commentclicked = false;
    this.emailclicked = false;
    this.isattach = false;
  }

  @wire(CurrentPageReference) objpageReference;

  publisharticle() {
    PublishArticle({
      articleId: this.newarticle
    })
      .then((result) => {
        this.attachToCase();
      })
      .catch((error) => {
        const event = new ShowToastEvent({
          title: 'error in attach!',
          message: error.body.message
        });
        this.dispatchEvent(event);
      });
  }

  async attachToCase() {
    let articleSharingUrl = '';
    if (this.clientSettings && this.clientSettings.base_href) {
      const res = await GetArticleFields({
        recordId: this.item.Id,
        destinationObj: this.destobj
      });
      articleSharingUrl = this.createCustomUrl(res);
    } else {
      articleSharingUrl = `${window.location.origin}/lightning/r/${this.destobj}/${this.item.Id}/view`;
    }

    AttachArticleToCase({
      articleId: this.item.Id,
      caseId: this.casedata
    })
      .then((result) => {
        const sendData = {
          articleid: this.item.Id,
          articlenumber: this.item.ArticleNumber,
          url: articleSharingUrl,
          title: this.item.Title,
          index: this.cardindexs,
          resolution: this.resolutionselected,
          reference: this.referenceselected
        };

        knowblerPubsub.fireEvent(
          this.objpageReference,
          `attachtocase${this.newnumber}`,
          sendData
        );

        // Successfully published and attach popup
        this.articleattached = true;
        this.isattach = false;
        this.commentclicked = false;
        this.emailclicked = false;

        this.template
          .querySelector('c-knowbler-modal-component')
          .attachsuccessfull();
      })
      .catch((error) => {
        const event = new ShowToastEvent({
          title: 'error in attach!',
          message: error.body.message
        });
        this.dispatchEvent(event);
      });
  }

  attachreference() {
    this.referenceselected = true;
    this.attachToCase();
  }

  attachresolution() {
    this.resolutionselected = true;

    this.attachToCase();
  }

  async copytoclipboard() {
    let articleSharingUrl = '';
    if (this.clientSettings && this.clientSettings.base_href) {
      const res = await GetArticleFields({
        recordId: this.item.Id,
        destinationObj: this.destobj
      });
      articleSharingUrl = this.createCustomUrl(res);
    } else {
      articleSharingUrl = `${window.location.origin}/lightning/r/${this.destobj}/${this.item.Id}/view`;
    }

    const inp = this.template.querySelector('.copytoclipboardinput');
    inp.disabled = false;
    inp.value = articleSharingUrl;
    inp.select();
    document.execCommand('copy');
    inp.disabled = true;

    const sendData = {
      articleid: this.item.Id,
      articlenumber: this.item.ArticleNumber,
      url: articleSharingUrl,
      title: this.item.Title
    };

    knowblerPubsub.fireEvent(
      this.objpageReference,
      `copytoclipboard${this.newnumber}`,
      sendData
    );

    this.template.querySelector('c-knowbler-modal-component').linkcopy();
  }

  // to refresh data after attaching or detaching the article
  gotohome() {
    this.dispatchEvent(new CustomEvent('gotohome'));
  }

  detacharticle() {
    detacharticle({
      articleId: this.item.Id
    })
      .then((result) => {
        this.articleattached = false;
        this.template
          .querySelector('c-knowbler-modal-component')
          .detachsuccessfull();
      })
      .catch((error) => {
        this.error = error;
      });
  }

  casecommentclicked() {
    this.kcslabel = 'Link via case comment';
    this.emailclicked = false;
    this.commentclicked = true;
    this.caseId = this.casedata;
    if (
      this.clientSettings &&
      this.clientSettings.resolution_reference_activated
    ) {
      this.hasresolution();
    } else {
      this.referenceselected = false;
      this.resolutionselected = false;
      this.commentcreated();
      this.casecomment();
    }
  }

  caseemailclicked() {
    this.kcslabel = 'Send link via email';
    this.commentclicked = false;
    this.emailclicked = true;
    this.caseId = this.casedata;
    if (
      this.clientSettings &&
      this.clientSettings.resolution_reference_activated
    ) {
      this.hasresolution();
    } else {
      this.referenceselected = false;
      this.resolutionselected = false;
      this.emailcreated();
      this.caseemail();
    }
  }

  async commentcreated() {
    this.isattach = false;

    let articleSharingUrl = '';
    if (this.clientSettings && this.clientSettings.base_href) {
      const res = await GetArticleFields({
        recordId: this.item.Id,
        destinationObj: this.destobj
      });
      articleSharingUrl = this.createCustomUrl(res);
    } else {
      articleSharingUrl = `${window.location.origin}/lightning/r/${this.destobj}/${this.item.Id}/view`;
    }

    const sendData = {
      articleid: this.item.Id,
      articlenumber: this.item.ArticleNumber,
      url: articleSharingUrl,
      title: this.item.Title,
      resolution: this.resolutionselected,
      reference: this.referenceselected
    };

    knowblerPubsub.fireEvent(
      this.objpageReference,
      `caseCommentEvent${this.newnumber}`,
      sendData
    );
  }

  async emailcreated() {
    this.isattach = false;
    let articleSharingUrl = '';
    if (this.clientSettings && this.clientSettings.base_href) {
      const res = await GetArticleFields({
        recordId: this.item.Id,
        destinationObj: this.destobj
      });
      articleSharingUrl = this.createCustomUrl(res);
    } else {
      articleSharingUrl = `${window.location.origin}/lightning/r/${this.destobj}/${this.item.Id}/view`;
    }

    const sendData = {
      articleid: this.item.Id,
      articlenumber: this.item.ArticleNumber,
      url: articleSharingUrl,
      title: this.item.Title,
      resolution: this.resolutionselected,
      reference: this.referenceselected
    };

    knowblerPubsub.fireEvent(
      this.objpageReference,
      `sendviaemail${this.newnumber}`,
      sendData
    );
  }

  async casecomment() {
    let articleSharingUrl = '';
    if (this.clientSettings && this.clientSettings.base_href) {
      const res = await GetArticleFields({
        recordId: this.item.Id,
        destinationObj: this.destobj
      });
      articleSharingUrl = this.createCustomUrl(res);
    } else {
      articleSharingUrl = `${window.location.origin}/lightning/r/${this.destobj}/${this.item.Id}/view`;
    }

    this[NavigationMixin.Navigate]({
      type: 'standard__component',
      attributes: {
        componentName: 'c__navigateToCaseComent'
      },
      state: {
        c__caseId: this.casedata,
        c__caseComment: articleSharingUrl
      }
    });
  }

  async caseemail() {
    let articleSharingUrl = '';
    if (this.clientSettings && this.clientSettings.base_href) {
      const res = await GetArticleFields({
        recordId: this.item.Id,
        destinationObj: this.destobj
      });
      articleSharingUrl = this.createCustomUrl(res);
    } else {
      articleSharingUrl = `${window.location.origin}/lightning/r/${this.destobj}/${this.item.Id}/view`;
    }

    this.articleId = this.item.Id;
    this.ishowmodal = true;
    const url = articleSharingUrl;
    this.emailbody = `<a href=${url}>${url} </a>`;
  }

  closeemailmodal() {
    this.ishowmodal = false;
  }

  clickedcommentreference() {
    this.referenceselected = true;
    this.resolutionselected = false;
    this.commentcreated();
    this.casecomment();
  }

  clickedemailreference() {
    this.referenceselected = true;
    this.resolutionselected = false;
    this.emailcreated();
    this.caseemail();
  }

  clickedcommentresolution() {
    this.resolutionselected = true;
    this.referenceselected = false;
    this.commentcreated();
    this.casecomment();
  }

  clickedemailresolution() {
    this.resolutionselected = true;
    this.referenceselected = false;
    this.emailcreated();
    this.caseemail();
  }

  getcustomsettings() {
    getsettingsuid().then((result) => {
      this.uid = result;
    });
  }

  hasresolution() {
    const rawdata = {
      uid: this.uid,
      caseId: this.casedata
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
        if (this.containsresolution && this.commentclicked) {
          this.clickedcommentreference();
        } else if (this.containsresolution && this.emailclicked) {
          this.clickedemailreference();
        } else if (
          this.containsresolution &&
          !this.emailclicked &&
          !this.commentclicked
        ) {
          if (resolutionArticleDetails && resolutionArticleDetails.doc_id) {
            IsAttached({
              articleId: resolutionArticleDetails.doc_id,
              caseId: this.casedata
            })
              .then((result) => {
                if (result) {
                  this.attachreference();
                } else {
                  this.isattach = true;
                }
              })
              .catch((error) => {
                this.error = error;
              });
          } else {
            this.attachreference();
          }
        } else {
          this.isattach = true;
        }
      });
  }
  get isDraft(){
    return this.item.PublishStatus === "Draft" && this.duplicacylisting
  }
  get isPublished(){
    return this.item.PublishStatus === "Online" && this.duplicacylisting
  }
}