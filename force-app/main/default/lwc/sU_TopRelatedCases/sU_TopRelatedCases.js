import { LightningElement, api, track } from 'lwc';
import CaseRelatedCasesDetail from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseRelatedCases';

export default class SU_TopRelatedCases extends LightningElement {
    @api caseIds;
    relatedCasesRecords;//variable used for itertion to store related cases records
    @track showRelatedCases = true;//flag variable used to display related cases if there are any
    allCases;
    @track DateCaseModalFlag = false;//flag variable used to toggle date modal popup 
    @track createdChecked = false;// variable used to check whether modal checkbox is selected or not
    closedCases = false;//checkbox variable used to toggle closed cases checkbox value
    //connectedCallback used to fetch related cases for given case on component load based on values of case ids fetched from parent component 
    todaysDate;
    startDate;
    createdStartDate;
    createdEndDate;
    origin;
    requiredFields;
    tabName;
    @api
    set sectionName(value){
        if (value == 'Top Related Cases') {
            this.resetDates();
            this.closedCases = false;
            if (this.relatedCasesRecords && this.relatedCasesRecords.length < this.allCases.length) {
                this.relatedCasesRecords = this.allCases;
                this.showRelatedCases = this.relatedCasesRecords.length > 0;
            }
            this.tabName = value;
        }
    };
    get sectionName(){
        return this.tabName;
    }
    openSince(start){
        const date = new Date();
        start = new Date(start);
        const diffTime = Math.abs(start - date);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        let timing = this.getTimeline(diffDays);
        return(timing.years ? timing.years +' Years ': '' ) + 
              (timing.months ? timing.months +' Months ' : '') +
              (timing.weeks ? timing.weeks +' Weeks ': '') +
              (timing.days ? timing.days +' Days ' : '')
    }
    getTimeline(numberOfDays) {
        let years = 0, months = 0, weeks = 0, days = 0;
        let valueReturned = {}; let remainingDays;
        if (numberOfDays >"365"){
            years = Math.floor(numberOfDays/365);
            remainingDays = Math.floor(numberOfDays%365);
            if (remainingDays)
                valueReturned = this.getTimeline(remainingDays);
        }
        else if (numberOfDays > "31"){
            months = Math.floor(numberOfDays/31);
            remainingDays = Math.floor(numberOfDays%31);
            if (remainingDays)
                valueReturned = this.getTimeline(remainingDays);
        }
        else if(numberOfDays >"7"){
            weeks = Math.floor(numberOfDays/7);
            remainingDays = Math.floor(numberOfDays%7);
            if (remainingDays)
                valueReturned = this.getTimeline(remainingDays);
            else days = 0;
        }
        else days = numberOfDays;
        return {
            years: valueReturned.years ? valueReturned.years : years,
             months: valueReturned.months ? valueReturned.months : months,
             weeks: valueReturned.weeks ? valueReturned.weeks : weeks,
             days: valueReturned.days ? valueReturned.days : days,
        }
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
     connectedCallback() {
        this.resetDates();
        this.requiredFields = {
                'Case': 'Subject , Account.name, Status, CreatedDate,ClosedDate',
                'user': 'name, FullPhotoUrl, Department, Title, IsActive, usertype',
                'CaseComment':''
        };
        this.origin = window.location.origin;
        if (this.caseIds) {
            CaseRelatedCasesDetail({ sCaseIds: JSON.stringify(this.caseIds), fieldsToFetch: JSON.stringify(this.requiredFields)}).then(response => {
                this.caseResponseData = response;
                let caseList =  JSON.parse(this.caseResponseData.cases);
                let caseComments = JSON.parse(this.caseResponseData.caseComment);
                let usersData = JSON.parse(this.caseResponseData.users);
                let closedCaseCount = JSON.parse(this.caseResponseData.closedCaseCount);                

                caseList.sort((a, b) => {
                    return this.caseIds.indexOf(a.Id) - this.caseIds.indexOf(b.Id);
                });   

                let responseDataVals = [];
                
                for(let i = 0; i < caseList.length; i++){
                    let ownerExists = usersData[caseList[i].OwnerId] ? true : false;
                    responseDataVals.push({
                        'AccountName': caseList[i].Account ? caseList[i].Account.Name : '',
                        'CaseId': caseList[i].Id,
                        'CreatedDate': caseList[i].CreatedDate,
                        'CaseSubject': caseList[i].Subject,
                        'caseClosedDate': caseList[i].ClosedDate,
                        'LastCommentByAgent': caseComments[caseList[i].Id+ '-'+caseList[i].OwnerId],
                        'OwnerName': ownerExists ? usersData[caseList[i].OwnerId].Name : '',
                        'OwnerTitle': ownerExists ? usersData[caseList[i].OwnerId].Title : '',
                        'OwnerDepartment': ownerExists ? usersData[caseList[i].OwnerId].Department : '',
                        'Icon': ownerExists ? usersData[caseList[i].OwnerId].FullPhotoUrl : '',
                        'isActive': ownerExists ? usersData[caseList[i].OwnerId].IsActive : '',
                        'CaseClosedCount': closedCaseCount[caseList[i].OwnerId],
                        'CaseStatus': caseList[i].Status,
                        caseCreated: this.getDateTime(caseList[i].CreatedDate),
                        caseClosed:  caseList[i].ClosedDate ? caseList[i].ClosedDate : '', 
                        closedLabel: caseList[i].ClosedDate && caseList[i].ClosedDate.length ?  "Case Closed : " : "Open Since : ",
                        closedSince: caseList[i].ClosedDate && caseList[i].ClosedDate.length ? this.getDateTime(caseList[i].ClosedDate)  : this.openSince(caseList[i].CreatedDate),
                        isLastCommentPresent: caseComments[caseList[i].Id+ '-'+caseList[i].OwnerId] && caseComments[caseList[i].Id+ '-'+caseList[i].OwnerId].length ? true : false,
                        isAccountName: caseList[i].Account && caseList[i].Account.Name && caseList[i].Account.Name.length ? true : false,
                        expanded: false,
                        previewUrl: this.origin +'/'+ caseList[i].Id,
                        ownerExists,
                        ownerAndComments: ownerExists || caseComments[caseList[i].Id+ '-'+caseList[i].OwnerId] && caseComments[caseList[i].Id+ '-'+caseList[i].OwnerId].length,
                        listClass: 'list',
                    });
                   
                }
                this.relatedCasesRecords = responseDataVals;
                this.showRelatedCases = this.relatedCasesRecords.length > 0;
                this.allCases = this.relatedCasesRecords;
            }).catch(error => {
                this.showRelatedCases = false;
                console.log(error);
            });
        }      
    }
    
    expandInfoDiv(event){
        let index = event.currentTarget.dataset.index;
        if (index > -1) {
            this.relatedCasesRecords[index].expanded = this.relatedCasesRecords[index].expanded ? false : true ;
            let relatedCasesRecordsBck = this.relatedCasesRecords;
            this.relatedCasesRecords = [];
            this.relatedCasesRecords = relatedCasesRecordsBck;
            this.relatedCasesRecords.forEach((obj,i) =>{
                if (index != i)
                    obj.expanded = false ;
                obj.listClass = obj.expanded ? 'list case-expanded' : 'list';
                return obj; 
            });
        }
    }
    //method to handle functionality when date modal checkbox is toggled
    handleChangeCreatedDate(event) {
        this.createdChecked = event.target.checked;
        let pass = event.target.checked ? 'createSelect' : 'createDeselect';
        this.updateRecords();
    }
    //method to toggle display of date modal popup
    openDateCaseModal(event) {
        this.DateCaseModalFlag = !this.DateCaseModalFlag ? true : false;
        event.currentTarget.blur();
    }
    //method used to filter cases based on toggle value of Closed Cases checkbox 
    handleClosedCases(event) {
        this.closedCases = event.target.checked; 
        this.relatedCasesRecords = this.allCases.filter(x=>{
            return event.target.checked ? x.CaseStatus === 'Closed' : true;
        });
        this.updateRecords();
    }
    //method to filter related case records based on the value selected in Date modal popup
    updateRecords() {
        let createdEndD = new Date(new Date(this.createdEndDate).setHours(23, 59, 59, 999));
        let createdStartD = new Date(new Date(this.createdStartDate).setHours(0, 0, 0, 0));

        this.relatedCasesRecords = this.allCases.filter(c => {
            if (!this.createdChecked && !this.closedCases) return true;
            else if (this.createdChecked && !this.closedCases) return new Date(c.CreatedDate) > createdStartD && new Date(c.CreatedDate) < createdEndD;
            else if (!this.createdChecked && this.closedCases) return c.CaseStatus === 'Closed';
            else return new Date(c.CreatedDate) > createdStartD && new Date(c.CreatedDate) < createdEndD && c.CaseStatus === 'Closed';
        });
        this.showRelatedCases = this.relatedCasesRecords.length > 0;
    }
    
    //method called when start or end date value in date modal is changed
    handleCreatedDateChange(event) {
        let date = event.currentTarget.value;
        let type = event.currentTarget.dataset.id;
        if (type == 'createdStartDate') {
            this.createdStartDate = date;
            this.createdEndDate = new Date(date) > new Date(this.createdEndDate) ? date : this.createdEndDate;
        } else this.createdEndDate = date;
        this.updateRecords();
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

        this.startDate = startDate;
        this.todaysDate = todaysDate;

        this.createdChecked = false;
    }
}