import { LightningElement, api, track } from "lwc";
import getObjectApiName from "@salesforce/apex/su_vf_console.SUVFConsoleController.getObjectApiName"; //Apex class Method
import getCompactLayoutFields from "@salesforce/apex/su_vf_console.SUVFConsoleController.getCompactLayoutFields"; //Apex class Method

export default class SU_ArticlePreviewParent extends LightningElement {
  @api rangerId;
  @api attachments;
  @api articlerecorexists;
  @api showarticlepreview;
  @api item;
  @api fileattachment;
  @api eventCode;
  @track compactField = [];
  compactLayoutFields;
  firstLoad = true;
  resultset;
  clientWidth;
  divHeight;
  objectName = '';

  connectedCallback() {
    //code
  }

  renderedCallback() {
    if (this.showarticlepreview && this.rangerId && (this.rangerId.startsWith('ka0') || this.rangerId.startsWith('500') || this.rangerId.startsWith('003') || this.rangerId.startsWith('001'))) {
      if (this.articlerecorexists) {
        if (this.rangerId && this.rangerId.startsWith('ka0')) {
          this.fieldName = 'Title';
          this.iconName = 'standard:article';
          this.iconText = 'Article';
        } else if (this.rangerId && this.rangerId.startsWith('500')) {
          this.fieldName = 'Subject';
          this.iconName = 'standard:case';
          this.iconText = 'Case';
        } 
        // else if (this.rangerId && this.rangerId.startsWith('003')) {
        //   this.fieldName = 'Name';
        //   this.iconName = 'standard:contact';
        //   this.iconText = 'Contact';
        // } else if (this.rangerId && this.rangerId.startsWith('001')) {
        //   this.fieldName = 'Name';
        //   this.iconName = 'standard:account';
        //   this.iconText = 'Account';
        // }
        // if (this.firstLoad && this.rangerId) {
        //   this.getCompactLayoutFields();
        //   if (this.firstLoad && this.rangerId != undefined && this.rangerId  && Object.keys(this.item).length) {
        //     this.getObjectApiName();
        //   }
        //   this.firstLoad = false;
        // }
        if (this.firstLoad && this.rangerId) {
          this.getCompactLayoutFields();
          if (this.firstLoad && this.rangerId !== undefined && this.rangerId  && Object.keys(this.item).length) {
            this.getObjectApiName();
          }
          this.firstLoad = false;
        }

        if (this.template.querySelector("div.mainContainer")) {
          this.divHeight = this.template.querySelector("div.mainContainer").clientHeight;
          this.clientWidth = this.template.querySelector("div.mainContainer").clientWidth;
        }
        
        const selectEvent = new CustomEvent("selection", {
          detail: {
            divHeight: this.divHeight,
            clientWidth: this.clientWidth
          }
        });
        this.dispatchEvent(selectEvent);
      }

    }
  }

  crosspreview(event) {
    event.preventDefault();
    const selectEvent = new CustomEvent('closeknowledgewidget', {
      detail: true
    });
    this.dispatchEvent(selectEvent);
  }
  getCompactLayoutFields() {
    getCompactLayoutFields({ knowledgeId: this.rangerId })
      .then(result => {
        try{
          this.resultset = JSON.parse(result);
        } catch{error =>{
          console.error("An error occurred while parsing the JSON:", error);
        }  
        }
        for (let i = 0; i < this.resultset.fieldItems.length; i++) {
          if (this.resultset.fieldItems[i].label !== this.fieldName) {
            this.compactField.push(this.resultset.fieldItems[i].layoutComponents[0].value);
          }
        }
        this.compactLayoutFields = this.compactField;
      })
      .catch(error => {
        console.log('Error occur while getting compact layout fields ', error);
      });
  }

  getObjectApiName() {
    getObjectApiName({ knowledgeId: this.rangerId }).then((result) => {
      this.objectName = result;
      this.error = '';
    })
    .catch((error) => {
      this.error = error;
    });
  }
}