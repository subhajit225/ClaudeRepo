import { LightningElement, wire, track, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import makeLinkOfAttachment from '@salesforce/apex/SU_Knowbler.ArticleAttachment.makeLinkOfAttachment';
import describeDataCateogryGroupStructuresSample from '@salesforce/apex/SU_Knowbler.DataCategoryController.describeDataCateogryGroupStructuresSample';
import getDataCategories from '@salesforce/apex/SU_Knowbler.DataCategoryController.getDataCategories';
import getRecordRelatedFiles from '@salesforce/apex/SU_Knowbler.FileUploaderClass.getRelatedFilesByRecordId';

export default class KnowblerChildPreview extends LightningElement {
  @api kid;

  @api destobj;

  @track toggleShow = false;

  @track mapp;

  @track mappingfields;

  @track objInfo;

  @track currentArticleDetail;

  @api recordtypeid;

  fields;

  @track fieldmap;

  @api recordId;

  titleImage;

  attachLink;

  @api cmpvisible;

  @track allFilesList = [];

  @track loadFilesList = true;

  baseUrl = '';
  
  @track hasFileUploadPermission = true;

  connectedCallback() {
    this.baseUrl = window.location.origin;
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
      const fileInfos = await getRecordRelatedFiles({ recordId: this.kid});
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
      this.hasFileUploadPermission = false;
      console.error('Error checking permission:', error);
    }
  }

  @wire(getObjectInfo, { objectApiName: '$destobj' })
  objectInfo({ error, data }) {
    if (data) {
      this.objInfo = data;
    } else if (error) {
      this.error = error;
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(this.error);
    }
  }

  @wire(getRecord, { recordId: '$kid', fields: '$mappingfields' })
  getKnowledgeDetail({ error, data }) {
    if (data) {
      this.setMapping(data);
    } else if (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  handleEditFormError(error) {
    this.template.querySelector('c-knowbler-modal-component').showError(error);
  }

  handleViewFormError(error) {
    this.template.querySelector('c-knowbler-modal-component').showError(error);
  }

  handleLoad(event) {
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

  setMapping(newData) {
    this.currentArticleDetail = [];
    this.myRecordID = this.kid;
    this.mapp.forEach((ele) => {
      const otype = this.objInfo?.fields[ele].dataType;
      let olabel = this.objInfo?.fields[ele].label;

      if (olabel === 'User ID') {
        switch (ele) {
          case 'AssignedById':
            olabel = 'Assigned By';
            break;
          case 'ArchivedById':
            olabel = 'Archived By';
            break;
          case 'ArticleArchivedById':
            olabel = 'Article Archived By';
            break;
          case 'ArticleCreatedById':
            olabel = 'Article Created By';
            break;
          default:
            break;
        }
      }

      const obj = {
        name: ele,
        label: ele === 'CreatedById' ? 'Created By' : olabel,
        type: otype
      };

      this.currentArticleDetail.push(obj);
    });

    this.currentArticleDetail.map((ele) => {
      if (ele.name.indexOf('__Name__s') > -1) {
        const elem = this.objInfo?.fields[ele.name].compoundFieldName;
        ele.type = 'File';
        ele.label = elem?.indexOf('__c') ? elem.slice(0, -3) : elem;
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
  }

  getmapping(data) {
    this.fieldmap = data;
  }

  handleAttachment(event) {}
}