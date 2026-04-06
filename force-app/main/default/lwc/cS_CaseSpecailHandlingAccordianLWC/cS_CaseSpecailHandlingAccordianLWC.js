import {LightningElement,api,track,wire} from 'lwc';
import techCollateral from '@salesforce/resourceUrl/CSH_Icons';
import getRecords from '@salesforce/apex/CS_CaseSpecialHandlingController.getRecords';
import updateDateField from '@salesforce/apex/CS_CaseSpecialHandlingController.updateDateField';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {registerRefreshContainer,unregisterRefreshContainer,REFRESH_ERROR,REFRESH_COMPLETE_WITH_ERRORS,REFRESH_COMPLETE} from "lightning/refresh";
import {refreshApex} from '@salesforce/apex';
import checkObjectAccess from '@salesforce/apex/CS_CaseSpecialHandlingController.checkObjectAccess';
export default class CS_CaseSpecailHandlingAccordianLWC extends LightningElement {

@api recordId;
@track isLoading = false;
@track categoryMessageList;
@track activeSections = [];
@track imageData = [];
@track accountId;
allowMultipleSectionsOpen = true;
@track specialHandlingObjects;
@track CaseDetailsSectionHide = true;
@api objectName = 'Case_Special_Handling__c';
hasAccess;
wireSpecialHandlingObjects;
refreshHandlerID;
_iconValue = "all";
accountName

get iconValue() {
   return this._iconValue;
}

set iconValue(value) {
   this._iconValue = value;
   this.activeSections = this.getCategoriesValue(value, this.specialHandlingObjects);
}

    @wire(checkObjectAccess, { objectName: '$objectName' })
    wiredAccess({ error, data }) {
        if (data !== undefined) {
            this.hasAccess = data;
        } else if (error) {
            this.hasAccess = false;
            console.error('Error:', error);
        }
    }

    
   connectedCallback() {
      this.refreshContainerID = registerRefreshContainer(this.template.host, this.refreshContainer.bind(this));
   }

   disconnectedCallback() {
      unregisterRefreshContainer(this.refreshHandlerID);
   }

   refreshContainer(refreshPromise) {
      this.isLoading = true;
      refreshApex(this.wireSpecialHandlingObjects)

      return refreshPromise.then((status) => {
         if (status === REFRESH_COMPLETE) {
            this.isLoading = false;
         } else if (status === REFRESH_COMPLETE_WITH_ERRORS) {
            this.isLoading = false;
         } else if (status === REFRESH_ERROR) {
            this.isLoading = false;
            console.error("Major error with refresh.");
         }
      });

}

merged(specialHandlingObjects) {
    const data = specialHandlingObjects.filter(record => {
        if (record.Icon__c) {
           // return record.Show_Icon__c;
           return true;
        } else {
            return false;
        }
    });

    const mergedData = data.map(record => {
        let tooltipdata = record.Message__c;
        
        if (tooltipdata && tooltipdata.length > 100) {
            tooltipdata = tooltipdata.substring(0, 100) + '...';
        }

        return {
            value: record.Icon__c.replace(/\s/g, ''),
            url: techCollateral + '/images/' + record.Icon__c.replace(/\s/g, '') + '.PNG',
            tooltipdata: tooltipdata,
            name: record.Icon__c
        };
    });

    this.imageData = mergedData;
    return mergedData;
}


   @wire(getRecords, {
      recordId: '$recordId',queryLimit: null,filter:null
   })
   wiredGetRecords(result) {
      this.wireSpecialHandlingObjects = result;
      if (result.data) {
         this.specialHandlingObjects = result.data;
         this.mergedData = this.merged(result.data);
         this.categoryMessageList = this.getCategoriesAndMessages(result.data);
         this.accountId = result.data.length > 0 ? result.data[0].Account_Id__c : null;
         if(!this.accountId){
          this.CaseDetailsSectionHide = false;
         }
      } else if (result.error) {
         console.error(result.error);
      }
   }

   getCategoriesValue(iconValue, specialHandlingObjects) {
      let uniqueCategories = [];
      const specialHandlingObjectsForIcon = specialHandlingObjects.filter(obj => obj.Icon__c == iconValue);
      specialHandlingObjectsForIcon.forEach(obj => {
         if (!uniqueCategories.includes(obj.Category__c)) {
            uniqueCategories.push(obj.Category__c);
         }
      });
      return uniqueCategories;
   }

   getCategoriesAndMessages(specialHandlingObjects) {

      let categoryMessageMap = specialHandlingObjects.reduce((messages, customObject) => {
         let category = customObject.Category__c;
         let message = customObject.Message__c;
         let objectId = customObject.Id;
         if (category) {
            messages[category] = messages[category] || [];
            messages[category].push({
               id: objectId,
               message: message
            });
         }
         return messages;
      }, {});
      
      let categoryMessageList = Object.entries(categoryMessageMap).map(([category, messages]) => ({
         category,
         messages
      }));

      return categoryMessageList;
   }

   handleExpandAllClick(event) {
      const iconValueWithSpaces = event.currentTarget.dataset.name;
      this.isLoading = true;
      setTimeout(() => {
         this.isLoading = false;
      }, 1000);
      if (!this.iconValue || this.iconValue !== iconValueWithSpaces) {
         this.iconValue = iconValueWithSpaces;
      } else {
         this.iconValue = "all";
         this.activeSections = [];
      }
   }
   handleMenuSelect(event) {
      const selectedValue = event.detail.value;
      updateDateField({
            recordId: selectedValue
         })
         .then(result => {
            this.isLoading = true;
            setTimeout(() => {
               this.isLoading = false;
               this.dispatchEvent(
                  new ShowToastEvent({
                     title: 'Success',
                     message: result,
                     variant: 'success'
                  })
               );
            }, 2000);

         })
         .catch(error => {
            this.dispatchEvent(
               new ShowToastEvent({
                  title: 'Error',
                  message: error.body.message,
                  variant: 'error'
               })
            );
         });
   }

   get iconName() {
        return this.CaseDetailsSectionHide ? 'utility:chevrondown' : 'utility:chevronright';
    }

    toggleSection() {
        this.CaseDetailsSectionHide = !this.CaseDetailsSectionHide;
    }
}