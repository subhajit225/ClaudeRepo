import { LightningElement, track, api } from 'lwc';
import caseKnowledgeArticlesDetail from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseKnowledgeArticlesDetails';

export default class SU_TopArticles extends LightningElement {
    @api caseIds;
    @track items = [];
    knowledgeArticleRecords;//variable used to store and iterate over the fetched Knowledge articles related to current case
    allKnowledgeArticleRecords;//variable used to store all articles
    knowledgeArticleRecordsFiltered // to keep backup with filters 
    @track showArticles = true;//flag variable used to toggle display of data in Top Articles tab
    @track DateModalFlag = false;//flag variable used to toggle display of date modal popup in the component 
    @track createdChecked = false;//variable used to store value of created date checkbox in date modal popup
    @track updatedChecked = false;//variable used to store value of updated date checkbox in date modal popup
    @api maincontainerwidth;
    tabName;
    loadItemsCount = 10;
    @api
    set sectionName(value){
        if (value == 'Top Articles') {
            this.resetDates();
            if (this.knowledgeArticleRecords && this.knowledgeArticleRecords.length < this.allKnowledgeArticleRecords.length) {
                this.knowledgeArticleRecords = this.allKnowledgeArticleRecords.slice(0, this.loadItemsCount);
                this.showArticles = this.knowledgeArticleRecords.length > 0;
            }
            this.tabName = value;
        }
    };
    get sectionName(){
        return this.tabName;
    }
    todaysDate;
    startDate;
    createdStartDate;
    createdEndDate;
    updatedStartDate;
    updatedEndDate;
    origin;
    caseFields;
    
    getAttachCase(num) {
        let digits = 1;           //used for decimal digits
        const lookup = [
          { value: 1, symbol: "" },
          { value: 1e3, symbol: "k" },
          { value: 1e6, symbol: "M" },
          { value: 1e9, symbol: "G" },
          { value: 1e12, symbol: "T" },
          { value: 1e15, symbol: "P" },
          { value: 1e18, symbol: "E" }
        ];
        const rx = /\.0+$|(\.[0-9]*[1-9])0+$/;
        let lookupArr = lookup.slice().reverse();
        let itemIndex = -1;
        lookupArr.some(function(item, i) {
          if (num >= item.value) {itemIndex=i;return true;}
        });
        return itemIndex > -1 ? (num / lookupArr[itemIndex].value).toFixed(digits).replace(rx, "$1") + lookupArr[itemIndex].symbol : "0";
    }
    getDateTime(dateTime) {
        if (dateTime) {
            var date = new Date(dateTime);
            var off_to_deduct = date.getTimezoneOffset();
            if (!date.getTime()) {
                str = dateTime.replace(/-/g, '/');
                date = new Date(str);
            }
            var off_to_deduct = date.getTimezoneOffset();
            var dates = date.getDate()
            var month = date.getMonth() + 1;
            if(month < 10){
               month = "0" + month;
            }
            if (dates < 10){
                dates = "0" + dates;
            }
            var date_appointment = dates+ '-' + month + '-' + date.getFullYear();
            var hours = date.getHours();
            var minutes = date.getMinutes();
            if (minutes < 10)
                minutes = "0" + minutes;
            var suffix = "AM";
            if (hours >= 12) {
                suffix = "PM";
                hours = hours - 12;
            }
            if (hours == 0) {
                hours = 12;
            }
            var current_time = hours + ":" + minutes + " " + suffix;
            return date_appointment + " " + '| ' +current_time;
        } else {
            return '';
        }
    }
   
    //connectedCallback called on component load used to load results into variable by using case ids fetched from parent component
    connectedCallback() {
        this.resetDates();
        this.caseFields = {
            'knowledgeArticle': 'Title,CreatedDate,LastModifiedDate',
            'userFields': 'FullPhotoUrl,Title,IsActive,Name'
        };
        this.origin = window.location.origin;
        if (this.caseIds) {
            caseKnowledgeArticlesDetail({ sCaseIds: JSON.stringify(this.caseIds), fieldsToFetch: JSON.stringify(this.caseFields)}).then(response => {

                let countData = JSON.parse(response.count);
                let usersData = JSON.parse(response.users);
                let versionData = JSON.parse(response.version);
                let responseData = [];
                for(let i = 0; i < countData.length; i++){
                    let x = countData[i];
                    let count = x.split('=')[1];
                    let id = x.split('=')[0];

                    responseData.push({
                        'Title': versionData[id].Title,
                        'CreatedDate': versionData[id].CreatedDate,
                        'LastModifiedDate': versionData[id].LastModifiedDate,
                        'OwnerName': usersData[versionData[id].OwnerId].Name,
                        'OwnerId': versionData[id].OwnerId,
                        'Icon': usersData[versionData[id].OwnerId].FullPhotoUrl,
                        'Role': usersData[versionData[id].OwnerId].Title,
                        'isActive': usersData[versionData[id].OwnerId].IsActive,
                        caseCreatedDate: this.getDateTime(versionData[id].CreatedDate),
                        lastModifiedDate: this.getDateTime(versionData[id].LastModifiedDate),
                        previewUrl: this.origin +'/'+ versionData[id].Id,
                        articleCount: this.getAttachCase(count),
                        listClass: 'list'
                    });
                }
                this.knowledgeArticleRecords = responseData.slice(0, this.loadItemsCount);
                this.allKnowledgeArticleRecords = responseData;
                this.knowledgeArticleRecordsFiltered = responseData;
                this.showArticles = responseData.length !== 0;
            }).catch(error => {
                this.showArticles = false;
                console.log(error);
            });
        }
    }

    resetDates() {
        let todaysDate = new Date(new Date().setHours(23, 59, 59, 999));
        let startDate = new Date((new Date).setDate(todaysDate.getDate() - 30));

        startDate = new Date(startDate).getFullYear()+'-'+ (
                (new Date(startDate).getMonth() + 1) < 10 ? '0'+(new Date(startDate).getMonth() + 1) : (new Date(startDate).getMonth() + 1)
            )+ '-' + (
                (new Date(startDate).getDate()) < 10 ? '0'+(new Date(startDate).getDate()) : (new Date(startDate).getDate())
            );

        todaysDate = new Date(todaysDate).getFullYear()+'-'+ (
                (new Date(todaysDate).getMonth() + 1) < 10 ? '0'+(new Date(todaysDate).getMonth() + 1) : (new Date(todaysDate).getMonth() + 1)
            )+ '-' + (
                (new Date(todaysDate).getDate()) < 10 ? '0'+(new Date(todaysDate).getDate()) : (new Date(todaysDate).getDate())
            );
        this.createdStartDate = startDate;
        this.createdEndDate = todaysDate;
        this.updatedStartDate = startDate;
        this.updatedEndDate = todaysDate;

        this.startDate = startDate;
        this.todaysDate = todaysDate;
        this.createdChecked = false;
        this.updatedChecked = false;
    }
                     
    handleScroll(event) {
        if( event.target.scrollHeight - event.target.clientHeight < event.target.scrollTop + 20) {
            if( this.loadItemsCount < this.knowledgeArticleRecordsFiltered.length) {
                this.loadItemsCount = this.loadItemsCount + 2;
                this.knowledgeArticleRecords = this.knowledgeArticleRecords.concat(this.knowledgeArticleRecordsFiltered.slice(this.knowledgeArticleRecords.length , this.loadItemsCount));
            }
        }
    }
    
    expandInfoDiv(event){
        let index = event.currentTarget.dataset.index;
        if (index > -1) {
            this.knowledgeArticleRecords[index].expanded = this.knowledgeArticleRecords[index].expanded ? false : true ;
            let knowledgeArticleRecordsBck = this.knowledgeArticleRecords;
            this.knowledgeArticleRecords = [];
            this.knowledgeArticleRecords = knowledgeArticleRecordsBck;
            this.knowledgeArticleRecords.forEach((obj,i) =>{
                if (index != i)
                    obj.expanded = false ;
                obj.listClass = obj.expanded ? 'article-expanded list' : 'list'
                return obj; 
            });
        }
    }
    //method that toggles the display of date modal popup in the component
    openDateModal() {
        this.DateModalFlag = !this.DateModalFlag ? true : false;
        let r = this.template.querySelector("[data-id='createdStartDate']");
        console.log('created adte ',r);
    }
    //method that is used when Created Date checkbox value is changed in date modal popup
    handleChangeCreatedDate(event) {
        this.createdChecked = event.target.checked;
        let pass = event.target.checked ? 'createSelect' : 'createDeselect';
        let r = this.template.querySelector('[data-id="createdStartDate"]');
        console.log('created adte ',r);
        this.updateRecords(pass);
    }
    //method that is used when Updated Date checkbox value is changed in date modal popup
    handleChangeUpdatedDate(event) {
        this.updatedChecked = event.target.checked;
        let pass = event.target.checked ? 'updateSelect' : 'updateDeselect';
        this.updateRecords(pass);
    }
    //method that filters the data being displayed when value of checkbox is toggled in Date Modal Popup using the values in the date fields
    updateRecords(){
        this.knowledgeArticleRecords = [];
        this.knowledgeArticleRecordsFiltered = this.allKnowledgeArticleRecords;

        let createdEndD = new Date(new Date(this.createdEndDate).setHours(23, 59, 59, 999));
        let createdStartD = new Date(new Date(this.createdStartDate).setHours(0, 0, 0, 0));

        let updatedEndD = new Date(new Date(this.updatedEndDate).setHours(23, 59, 59, 999));
        let updatedStartD = new Date(new Date(this.updatedStartDate).setHours(0, 0, 0, 0));
        this.knowledgeArticleRecordsFiltered = this.knowledgeArticleRecordsFiltered.filter(c => {
            if (!this.createdChecked && !this.updatedChecked) return true;
            else if (this.createdChecked && this.updatedChecked)
                return (new Date(c.CreatedDate) > createdStartD && new Date(c.CreatedDate) < createdEndD && new Date(c.LastModifiedDate) > updatedStartD && new Date(c.LastModifiedDate) < updatedEndD);
            else if (this.createdChecked)
                return new Date(c.CreatedDate) > createdStartD && new Date(c.CreatedDate) < createdEndD;
            else
                return new Date(c.LastModifiedDate) > updatedStartD && new Date(c.LastModifiedDate) < updatedEndD;
        });
        this.loadItemsCount = 10;
        this.knowledgeArticleRecords = this.knowledgeArticleRecordsFiltered.slice(0, this.loadItemsCount);
        if(this.createdChecked && this.updatedChecked && this.maincontainerwidth < 500)
            this.template.querySelector('.filter-fixed-height').style = 'height: 57px;';
        else this.template.querySelector('.filter-fixed-height').style = 'height: unset;';
        this.showArticles = this.knowledgeArticleRecords.length > 0;
    }
    //method called when value of start or end date is changed in date modal popup for either Created Date or Updated Date
    handleCreatedDateChange(event) {
        let date = event.currentTarget.value;
        let type = event.currentTarget.dataset.id;
        if (type == 'createdStartDate') {
            this.createdStartDate = date;
            this.createdEndDate = new Date(date) > new Date(this.createdEndDate) ? date : this.createdEndDate;
        } else this.createdEndDate = date;
        this.updateRecords();
   }

    handleUpdatedDateChange(event) {
        let date = event.currentTarget.value;
        let type = event.currentTarget.dataset.id;
        if (type == 'updatedStartDate') {
            this.updatedStartDate = date;
            this.updatedEndDate = new Date(date) > new Date(this.updatedEndDate) ? date : this.updatedEndDate;
        } else this.updatedEndDate = date;
        this.updateRecords();
    }
}