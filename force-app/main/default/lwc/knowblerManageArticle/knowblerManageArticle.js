import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import describeDataCateogryGroupStructuresSample from '@salesforce/apex/SU_Knowbler.DataCategoryController.describeDataCateogryGroupStructuresSample';
import getDataCategories from '@salesforce/apex/SU_Knowbler.DataCategoryController.getDataCategories';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';
import getRecordRelatedFiles from '@salesforce/apex/SU_Knowbler.FileUploaderClass.getRelatedFilesByRecordId';

const FIELDS = [
  'knowledge__kav.Title',
  'knowledge__kav.Id',
  'knowledge__kav.ArticleNumber'
];
export default class KnowblerManageArticle extends NavigationMixin(
  LightningElement
) {
  editArticle;

  backButton;

  manage;

  edit;

  @api kcsheight;

  @api namerecordtype;

  @api currentid;

  @api detailarticle;

  @api flexipageregionwidth;

  @api mappingfields;

  @track currentArticleDetail = [];

  @api configrecord;

  @api currentuserlanguage;

  @api norecordtype;

  @track objInfo;

  @track datacat = [];

  @track itensAll = [];

  @track label = null;

  @track recordtypeID = '';

  @track mapp = [];

  @api destobj;

  @track allFilesList = [];
  
  @track loadFilesList = true;

  baseUrl = '';
  
  @track hasFileUploadPermission = true;

  @api alldatacategories;

  norecordtypes = false;

  clickData;

  get showdropdown() {
    return this.clickData;
  }

  @api
  set showdropdown(data) {
    this.closeDropdown();
  }

  @wire(describeDataCateogryGroupStructuresSample, {
    allCategories: '$alldatacategories'
  })
  categories({ error, data }) {
    if (data) this.itensAll = [...data];
    else if (error)
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
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
      if (this.norecordtype) {
        this.norecordtypes = true;
      }
    } else if (error) {
      this.error = error;
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(this.error);
    }
  }

  @wire(getRecord, { recordId: '$currentid', fields: '$mappingfields' })
  getKnowledgeDetail({ error, data }) {
    if (data) {
      if (this.configrecord.length) {
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
        this.setMapping(data);
      }
      this.getDC(this.currentid);
    } else if (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  handleLoadView(event) {
    this.mapp = [];
    event.detail.layout.sections.forEach((ele) => {
      ele.layoutRows.forEach((el) => {
        if (el.layoutItems[0].layoutComponents.length > 1) {
          for (let i = 0; i < el.layoutItems[0].layoutComponents.length; i++) {
            if (
              el.layoutItems[0].layoutComponents[i] &&
              el.layoutItems[0].layoutComponents[i].apiName !== null &&
              el.layoutItems[0].layoutComponents[i].componentType !==
                'EmptySpace'
            ) {
              this.mapp.push(el.layoutItems[0].layoutComponents[i].apiName);
            }
          }
        } else if (
          el.layoutItems[0].layoutComponents[0] &&
          el.layoutItems[0].layoutComponents[0].apiName !== null &&
          el.layoutItems[0].layoutComponents[0].componentType !== 'EmptySpace'
        ) {
          this.mapp.push(el.layoutItems[0].layoutComponents[0].apiName);
        }
      });
    });
    const mappingfiel = [];
    this.mapp.forEach((el) => {
      mappingfiel.push(`${this.destobj}.${el}`);
    });
    this.mappingfields = [...[]];
    this.mappingfields = [...mappingfiel];
  }

  handleEditFormError(error) {
    this.template.querySelector('c-knowbler-modal-component').showError(error);
  }

  handleViewFormError(error) {
    this.template.querySelector('c-knowbler-modal-component').showError(error);
  }

  setMapping(newData) {
    this.currentArticleDetail = [];
    this.myRecordID = this.currentid;
    this.mapp.forEach((ele) => {
      const otype = this.objInfo?.fields[ele].dataType;
      const olabel = this.objInfo?.fields[ele].label;

      const obj = {
        name: ele,
        label: olabel,
        type: otype
      };

      this.currentArticleDetail.push(obj);
    });

    this.currentArticleDetail.forEach((ele) => {
      if (ele.name.indexOf('__Name__s') > -1) {
        const elem = this.objInfo?.fields[ele.name].compoundFieldName;
        ele.type = 'File';
        ele.label = elem.indexOf('__c') ? elem.slice(0, -3) : elem;
        ele.value = newData.fields[`${ele.label}__Name__s`].value;
      } else if (
        ele.name.indexOf('__ContentType__s') > -1 ||
        ele.name.indexOf('__Body__s') > -1 ||
        ele.name.indexOf('__Length__s') > -1
      ) {
        this.currentArticleDetail = this.currentArticleDetail.filter(
          (el) => el !== ele
        );
      } else {
        ele.value = newData.fields[ele.name].value;
      }

      return ele;
    });
    this.norecordtypes = false;
  }

  connectedCallback() {
    if (this.detailarticle) {
      this.initials = `${this.detailarticle.Owner.FirstName.charAt(
        0
      )}${this.detailarticle.Owner.LastName.charAt(0)}`;
    }
    this.infoUploadedFiles();
  }

  async infoUploadedFiles() {
    try {
        const fileExtensionTypeMap = {
            'png': 'doctype:image',
            'jpg': 'doctype:image',
            'jpeg': 'doctype:image',
            'gif': 'doctype:image',
            'bmp': 'doctype:image',
            'tiff': 'doctype:image',
            'svg': 'doctype:image',
            'pdf': 'doctype:pdf',
            'doc': 'doctype:word',
            'docx': 'doctype:word',
            'dot': 'doctype:word',
            'dotx': 'doctype:word',
            'xls': 'doctype:excel',
            'xlsx': 'doctype:excel',
            'xlt': 'doctype:excel',
            'xltx': 'doctype:excel',
            'ppt': 'doctype:ppt',
            'pptx': 'doctype:ppt',
            'pot': 'doctype:ppt',
            'potx': 'doctype:ppt',
            'pps': 'doctype:ppt',
            'ppsx': 'doctype:ppt',
            'txt': 'doctype:txt',
            'rtf': 'doctype:txt',
            'csv': 'doctype:csv',
            'html': 'doctype:html',
            'htm': 'doctype:html',
            'xml': 'doctype:xml',
            'zip': 'doctype:zip',
            'rar': 'doctype:zip',
            '7z': 'doctype:zip',
            'tar': 'doctype:zip',
            'gz': 'doctype:zip',
            'mp3': 'doctype:audio',
            'wav': 'doctype:audio',
            'aac': 'doctype:audio',
            'flac': 'doctype:audio',
            'ogg': 'doctype:audio',
            'mp4': 'doctype:video',
            'mov': 'doctype:video',
            'wmv': 'doctype:video',
            'avi': 'doctype:video',
            'mkv': 'doctype:video',
            'flv': 'doctype:video',
            'default': 'doctype:unknown'
        };
      const fileInfos = await getRecordRelatedFiles({ recordId: this.currentid});
      this.hasFileUploadPermission = true;
      const files = fileInfos.map(file => {
        return {
            ...file,
            fileIcon: fileExtensionTypeMap[file?.fileType.toLowerCase()] || fileExtensionTypeMap['default'],
            fileLink: `${this.baseUrl}/${file.documentId}`
        };
      });

      this.allFilesList = files;
      this.loadFilesList = false;      
    } catch (error) {
      console.error('Error checking permission:', error);
      this.hasFileUploadPermission = false;
    }
  }

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.editArticle = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/edit_article.svg`;
      this.backButton = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/back.svg`;
      this.manage = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/manage.svg`;
      this.edit = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/edit.svg`;
    } else if (error) {
      console.error('Error:', error);
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
        this.itensAll.forEach((res) => {
          if (result && result.length) {
            result.forEach((elm) => {
              let response = null;
              response = this.recursiveCategory(
                JSON.parse(res),
                elm,
                this.label
              );
              if (response != null) {
                elm.value = response;
                this.label = null;
              }
            });
          }
        });

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
            obj.value.push(result[i].value);
            this.datacat.push(obj);
          } else {
            this.datacat[index].value.push(result[i].value);
          }
        }
      })
      .catch((error) => {
        this.template
          .querySelector('c-knowbler-modal-component')
          .showError(error);
      });
  }

  get showEdit() {
    if (this.detailarticle && this.detailarticle.PublishStatus == 'Draft') {
      return (
        this.currentuserlanguage?.currentUserEmailId ==
        this.detailarticle?.Owner.Email
      );
    }

    return false;
  }

  kcsheightmanage() {
    if (!this.kcsheight) return;
    const layoutHeight = parseInt(this.kcsheight, 10);
    this.cardHeight = layoutHeight - 95;
    this.cardHeight += 'px';
  }

  renderedCallback() {
    if (this.flexipageregionwidth) {
      this.kcsheightmanage();
      if (this.template.querySelector('.manage_article_main'))
        this.template.querySelector('.manage_article_main').style =
          `height:${this.cardHeight}`;
    } else {
      const height = `${82}vh`;
      if (this.template.querySelector('.manage_article_main'))
        this.template.querySelector('.manage_article_main').style =
          `height:${height}`;
    }
    if (this.detailarticle && this.template.querySelector('.su_bgcolor')) {
      const code = this.template.querySelector('.su_bgcolor');
      code.style.backgroundColor = this.detailarticle.hexCode;
    }
    if (this.mappingfields == null) {
      this.getDC(this.currentid);
    }
  }

  openCloseDropdown(event) {
    event.stopPropagation();
    if (
      this.template
        .querySelector('.edit_button')
        .classList.contains('slds-is-open')
    )
      this.template
        .querySelector('.edit_button')
        .classList.remove('slds-is-open');
    else
      this.template.querySelector('.edit_button').classList.add('slds-is-open');
  }

  closeManageArticle() {
    this.dispatchEvent(new CustomEvent('showeditpage'));
  }

  closeDropdown() {
    if (
      this.template
        .querySelector('.edit_button')
        .classList.contains('slds-is-open')
    )
      this.template
        .querySelector('.edit_button')
        .classList.remove('slds-is-open');
  }

  openSubTab() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.detailarticle.Id,
        objectApiName: this.destobj,
        actionName: 'view'
      }
    });
    if (
      this.template
        .querySelector('.edit_button')
        .classList.contains('slds-is-open')
    )
      this.template
        .querySelector('.edit_button')
        .classList.remove('slds-is-open');
  }

  openEdit() {
    this.dispatchEvent(
      new CustomEvent('managearticle', {
        detail: { item: this.detailarticle, isEdit: true }
      })
    );
  }
}