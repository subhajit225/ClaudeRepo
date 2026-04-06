import { LightningElement, api, wire, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { registerListener, unregisterListener } from 'c/knowblerPubsub';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import getDataCategories from '@salesforce/apex/SU_Knowbler.DataCategoryController.getDataCategories';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KcsknowblercardDeatails extends LightningElement {
  @api recordId;

  @track circumference;

  @api largescreen;

  @api mappingfields;

  @api knoblerSupport;

  @api kcssupport;

  @api predictedscore;

  @api articleid;

  @api configrecord;

  @track datacat = [];

  @track recordtypeID = '';

  @track currentArticleDetail = [];

  @track objInfo;

  @api alreadyevaluted;

  @api articlenumber;

  @api ownername;

  @api destobj;

  @api languagechanged;

  @api waiting;

  @api parameters;

  @track evaluatedata;

  @track alreadyevaluatedflag;

  @api articlepredictiondata;

  @api newnumber;

  @api contenthealthdata;

  @track progress;

  @api fullPhotoUrl;

  @track progressBackground;

  @track circularcontainer;

  @track largevalue;

  @track knowblerTemplateExist = false;

  avatarLogoUrl;

  avatarLogo;

  starimg;

  connectedCallback() {
    this.avatarLogoUrl = this.fullPhotoUrl
      ? this.fullPhotoUrl
      : this.avatarLogo;

    registerListener('evaluatepopup', this.closedetail, this);
    if (this.predictedscore == 100) {
      this.largevalue = 'largehundred';
    } else {
      this.largevalue = 'large';
    }
  }

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      loadStyle(
        this,
        `${data}/kcs-agent/kcs_custom_agent/resources/css/lwcCustomStyle.css`
      );
      this.avatarLogo = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/artBoard40Img.png`;
      this.starimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/star.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  closedetail() {
    this.dispatchEvent(new CustomEvent('closedetail'));
  }

  handleFormError(error) {
    this.template.querySelector('c-knowbler-modal-component').showError(error);
  }

  handleViewFormError(error) {
    this.template.querySelector('c-knowbler-modal-component').showError(error);
  }

  @wire(getObjectInfo, { objectApiName: '$destobj' })
  objectInfo({ error, data }) {
    if (data) {
      this.objInfo = data;
      if (this.objInfo?.recordTypeInfos) {
        const b = this.objInfo?.recordTypeInfos;
        const a = Object.keys(b).map((key) => ({ key, ...b[key] }));
        const c = a.find((ele) => ele.name == this.namerecordtype);
        this.recordtypeID = c?.recordTypeId ? c?.recordTypeId : '';
      } else {
        this.recordtypeID = '';
      }
    } else if (error) {
      this.error = error;
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(this.error);
    }
  }

  recursiveCategory(res, elm, lbl) {
    this.label = lbl;
    res.forEach((el) => {
      if (
        elm.DataCategoryName == el.name &&
        elm.DataCategoryGroupName == el.categoryGroup
      ) {
        this.label = el.label;
      } else if (el.listChildCategory.length) {
        this.recursiveCategory(el.listChildCategory, elm, this.label);
      }
    });

    return this.label;
  }

  getDC(currentid) {
    getDataCategories({ parentId: currentid })
      .then((result) => {
        this.datacat = [];
        for (var i = 0; i < result.length; i++) {
          var obj;
          if (
            result[i].DataCategoryGroupName &&
            result[i].DataCategoryGroupName.includes('_del')
          ) {
            obj = {
              label: result[i].DataCategoryGroupName.replace(/_del/g, ''),
              value: []
            };
          } else {
            obj = {
              label: result[i].DataCategoryGroupName,
              value: []
            };
          }
          const index = this.datacat.findIndex(
            (ele) => ele.label == result[i].DataCategoryGroupName
          );
          if (index == -1) {
            obj.value.push(result[i].DataCategoryName);
            this.datacat.push(obj);
          } else {
            this.datacat[index].value.push(result[i].DataCategoryName);
          }
        }
      })
      .catch((error) => {
        this.template
          .querySelector('c-knowbler-modal-component')
          .showError(error);
      });
  }

  @wire(getRecord, { recordId: '$articleid', fields: '$mappingfields' })
  getKnowledgeDetail({ error, data }) {
    if (data) {
      if (this.configrecord.length) {
        this.knowblerTemplateExist = true;
        this.currentArticleDetail = JSON.parse(
          JSON.stringify(this.configrecord[0].mapping)
        );
        const newData = Object.assign({}, data);
        this.currentArticleDetail.forEach((ele) => {
          if (ele.type == 'file') {
            ele.value =
              newData.fields[`${ele.name.replace('__c', '')}__Name__s`].value;
            ele.name = `${ele.name.replace('__c', '')}__Name__s`;
          } else {
            ele.value = newData.fields[ele.name].value;
          }
          if (ele.type == 'textarea') {
            const x = this.objInfo?.fields[ele.name].extraTypeInfo;
            ele[`is${x}`] = true;
          } else {
            ele[`is${ele.type}`] = true;
          }

          return ele;
        });
      } else {
        this.knowblerTemplateExist = false;
      }

      this.getDC(this.articleid);
    } else if (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  renderedCallback() {
    if (!this.alreadyevaluted) {
      if (this.template.querySelector('.container').offsetWidth > 700) {
        if (this.template.querySelector('.evaluatebox'))
          this.template
            .querySelector('.projectedScorebox')
            .style.setProperty('left', '44%');
        else if (this.template.querySelector('.projectedScorebox'))
          this.template
            .querySelector('.projectedScorebox')
            .style.setProperty('left', '40%');
      } else if (
        this.template.querySelector('.container').offsetWidth > 500 &&
        this.template.querySelector('.container').offsetWidth < 700
      ) {
        if (this.template.querySelector('.evaluatebox')) {
          this.template
            .querySelector('.projectedScorebox')
            .style.setProperty('left', '40%');
        } else if (this.template.querySelector('.projectedScorebox'))
          this.template
            .querySelector('.projectedScorebox')
            .style.setProperty('left', '30%');
      } else if (this.template.querySelector('.evaluatebox')) {
        this.template
          .querySelector('.projectedScorebox')
          .style.setProperty('left', '25%');
      } else if (this.template.querySelector('.projectedScorebox')) {
        this.template
          .querySelector('.projectedScorebox')
          .style.setProperty('left', '7%');
      }
    }
    if (this.template.querySelector('.container').offsetWidth < 700) {
      this.template
        .querySelector('.contentHealthSection')
        .style.setProperty('padding', '0 1.5rem');
      this.template
        .querySelector('.fieldData')
        .style.setProperty('padding', '1.5rem 1.5rem');
      if (this.template.querySelector('.alreadyevaluated'))
        this.template
          .querySelector('.alreadyevaluated')
          .style.setProperty('left', '86px');
    } else if (this.template.querySelector('.container').offsetWidth > 700) {
      this.template
        .querySelector('.contentHealthSection')
        .style.setProperty('justify-content', 'center');
      this.template
        .querySelector('.fieldData')
        .style.setProperty('padding', '1.5rem 18%');
      if (this.template.querySelector('.alreadyevaluated'))
        this.template
          .querySelector('.alreadyevaluated')
          .style.setProperty('left', '86px');
    }

    if (this.alreadyevaluted) {
      if (this.template.querySelector('[data-id="progressid"]'))
        var r = this.template
          .querySelector('[data-id="progressid"]')
          .getAttribute('r');
      this.circumference = Math.PI * 2 * r;

      if (this.template.querySelector('[data-id="progressid"]'))
        this.template.querySelector(
          '[data-id="progressid"]'
        ).style.strokeDasharray = this.circumference;
      let percent = 0;
      percent = parseInt(this.predictedscore);
      if (this.template.querySelector('[data-id="progressid"]'))
        this.template.querySelector(
          '[data-id="progressid"]'
        ).style.strokeDashoffset =
          this.circumference - (percent / 100) * this.circumference;
      if (this.template.querySelector('[data-id="containerid"]'))
        this.template
          .querySelector('[data-id="containerid"]')
          .setAttribute('data-pct', percent);
      if (this.template.querySelector('[data-id="large"]'))
        this.template
          .querySelector('[data-id="large"]')
          .setAttribute('data-pct', percent);
      if (this.template.querySelector('[data-id="largehundred"]'))
        this.template
          .querySelector('[data-id="largehundred"]')
          .setAttribute('data-pct', percent);
    }

    if (this.predictedscore == 100) {
      this.progress = 'progressvaluegreen';
      this.progressBackground = 'progressbargreen';
      this.circularcontainer = 'circularcontainergreen';
    } else if (this.predictedscore >= 71 && this.predictedscore < 99) {
      this.progress = 'progressvalueblue';
      this.progressBackground = 'progressbarblue';
      this.circularcontainer = 'circularcontainerblue';
    } else if (this.predictedscore >= 41 && this.predictedscore <= 70) {
      this.progress = 'progressvalueyellow';
      this.progressBackground = 'progressbaryellow';
      this.circularcontainer = 'circularcontaineryellow';
    } else if (this.predictedscore >= 0 && this.predictedscore <= 40) {
      this.progress = 'progressvaluered';
      this.progressBackground = 'progressbarred';
      this.circularcontainer = 'circularcontainerred';
    } else {
      this.progress = 'progressvaluered';
      this.progressBackground = 'progressbarred';
      this.circularcontainer = 'circularcontainerred';
    }
  }

  handlehover() {
    this.template
      .querySelector('.predictedScoreText')
      .style.setProperty('color', 'white');
    this.template
      .querySelector('.projectedScore')
      ?.querySelector('span')
      ?.querySelector('img')
      ?.style.setProperty('filter', 'brightness(0%) invert(1)');
  }

  handlehoverout() {
    this.template
      .querySelector('.predictedScoreText')
      .style.setProperty('color', '#7E34EC');
    this.template
      .querySelector('.projectedScore')
      ?.querySelector('span')
      ?.querySelector('img')
      ?.style.setProperty('filter', 'none');
  }

  handlealreadyevaluated() {
    this.evaluatedata = true;
    this.alreadyevaluatedflag = true;
    this.dispatchEvent(new CustomEvent('evaluateopen'));
  }

  closeevaluate() {
    this.evaluatedata = false;
    this.dispatchEvent(new CustomEvent('evaluateclose'));
  }

  handlePredictedScore() {
    this.evaluatedata = true;

    this.dispatchEvent(new CustomEvent('evaluateopen'));
  }

  get addEvaluateDataClass() {
    return this.evaluatedata ? 'container stop-overflow' : 'container';
  }
}