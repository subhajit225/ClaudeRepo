import { LightningElement, api, track } from 'lwc';
import CaseRelatedCasesDetail from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseRelatedCases';
import { getRecord } from 'lightning/uiRecordApi';
import { convertToTimezone, trackEvent } from 'c/sU_AiqUtils';


export default class SU_AiqTopRelatedCases extends LightningElement {
    @api caseIds;
    @api recordId;
    @api loggedInUserData;
    @api metaData;
    @api endPoint;
    @api token;
    @api s3endpoint;
    @api uid;
    
    @api isDataError;
    relatedCasesRecords;//variable used for itertion to store related cases records
    @track showRelatedCases = true;//flag variable used to display related cases if there are any
    allCases;
    @track DateCaseModalFlag = false;//flag variable used to toggle date modal popup 
    @track createdChecked = false;// variable used to check whether modal checkbox is selected or not
    closedCases = false;//checkbox variable used to toggle closed cases checkbox value

    //connectedCallback used to fetch related cases for given case on component load based on values of case ids fetched from parent component 
    //array to store the data , before filtering for the closed cases switch
    unFilteredArray = [];
    createdDateSort = false; //variable to check if the array is sorted or not
    todaysDate;
    startDate;
    createdStartDate;
    createdEndDate;
    origin;
    requiredFields;
    tabName;
    relatedCasesLoader = true;
    noClosedCase = false;
    @api
    set sectionName(value) {
        if (value === 'Top Related Cases') {
            this.resetDates();
            this.closedCases = false;
            if (this.relatedCasesRecords && this.relatedCasesRecords.length < this.allCases.length) {
                this.relatedCasesRecords = this.allCases;
                this.showRelatedCases = this.relatedCasesRecords.length > 0;
            }
            this.tabName = value;
        }
    }
    get sectionName() {
        return this.tabName;
    }
    get caseId() {
        return this.isUtility ? this.caseIdForUtility : this.recordId;
    }

  get processedKnowledgeCases() {
    if (!this.relatedCasesRecords) return [];
    return this.relatedCasesRecords.map((cases) => {
        return {
            ...cases,
            localKey: cases.CaseId 
        };
    });
}


    openSince(start) {
        const date = new Date();
        start = new Date(start);
        const diffTime = Math.abs(start - date);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        let timing = this.getTimeline(diffDays);
        return (timing.years ? timing.years + ' Years ' : '') +
            (timing.months ? timing.months + ' Months ' : '') +
            (timing.weeks ? timing.weeks + ' Weeks ' : '') +
            (timing.days ? timing.days + ' Days ' : '')
    }
    getTimeline(numberOfDays) {
        let years = 0, months = 0, weeks = 0, days = 0;
        let valueReturned = {}; let remainingDays;
        if (numberOfDays > "365") {
            years = Math.floor(numberOfDays / 365);
            remainingDays = Math.floor(numberOfDays % 365);
            if (remainingDays)
                valueReturned = this.getTimeline(remainingDays);
        }
        else if (numberOfDays > "31") {
            months = Math.floor(numberOfDays / 31);
            remainingDays = Math.floor(numberOfDays % 31);
            if (remainingDays)
                valueReturned = this.getTimeline(remainingDays);
        }
        else if (numberOfDays > "7") {
            weeks = Math.floor(numberOfDays / 7);
            remainingDays = Math.floor(numberOfDays % 7);
            if (remainingDays)
                valueReturned = this.getTimeline(remainingDays);
        }
        else days = numberOfDays;
        return {
            years: valueReturned.years ? valueReturned.years : years,
            months: valueReturned.months ? valueReturned.months : months,
            weeks: valueReturned.weeks ? valueReturned.weeks : weeks,
            days: valueReturned.days ? valueReturned.days : days,
        }
    }
    getDateTime(dateTime, setToUtc = false) {
        if (dateTime) {
            var date = new Date(dateTime);
            if (setToUtc) {
                date = new Date(date.getTime() + date.getTimezoneOffset() * 60000);
            }
            if (!date.getTime()) {
                let str = dateTime.replace(/-/g, '/');
                date = new Date(str);
            }
            var dates = date.getDate()
            var month = date.getMonth() + 1;
            if (month < 10) {
                month = "0" + month;
            }
            if (dates < 10) {
                dates = "0" + dates;
            }
            var date_appointment = dates + '-' + month + '-' + date.getFullYear();
            var hours = date.getHours();
            var minutes = date.getMinutes();
            if (minutes < 10)
                minutes = "0" + minutes;
            var suffix = "AM";
            if (hours >= 12) {
                suffix = "PM";
                hours = hours - 12;
            }
            if (hours === 0) {
                hours = 12;
            }
            var current_time = hours + ":" + minutes + " " + suffix;
            return `${date_appointment} | ${current_time}`
        }
        return '';
    }
    connectedCallback() {
        this.resetDates();
        this.requiredFields = {
            'Case': 'Subject , Account.name, Status, CreatedDate,ClosedDate',
            'user': 'name, FullPhotoUrl, Department, Title, IsActive, usertype',
            'CaseComment': ''
        };
        this.origin = window.location.origin;
        if (this.caseIds) {
            CaseRelatedCasesDetail({ sCaseIds: JSON.stringify(this.caseIds), fieldsToFetch: JSON.stringify(this.requiredFields) }).then(response => {
                this.caseResponseData = response;
                let caseList = this.caseResponseData.cases && JSON.parse(this.caseResponseData.cases);
                let caseComments = this.caseResponseData.caseComment && JSON.parse(this.caseResponseData.caseComment);
                let usersData = this.caseResponseData.users && JSON.parse(this.caseResponseData.users);
                let closedCaseCount = this.caseResponseData.closedCaseCount && JSON.parse(this.caseResponseData.closedCaseCount);

                caseList.sort((a, b) => {
                    return this.caseIds.indexOf(a.Id) - this.caseIds.indexOf(b.Id);
                });

                let responseDataVals = [];

                for (let i = 0; i < caseList.length; i++) {
                    let ownerExists = usersData[caseList[i].OwnerId] ? true : false;
                    responseDataVals.push({
                        'AccountName': caseList[i].Account ? caseList[i].Account.Name : '',
                        'CaseId': caseList[i].Id,
                        'CreatedDate': caseList[i].CreatedDate,
                        'CaseSubject': caseList[i].Subject,
                        'caseClosedDate': caseList[i].ClosedDate,
                        'LastCommentByAgent': caseComments[caseList[i].Id + '-' + caseList[i].OwnerId],
                        'OwnerName': ownerExists ? usersData[caseList[i].OwnerId].Name : '',
                        'OwnerTitle': ownerExists ? usersData[caseList[i].OwnerId].Title : '',
                        'OwnerDepartment': ownerExists ? usersData[caseList[i].OwnerId].Department : '',
                        'Icon': ownerExists ? usersData[caseList[i].OwnerId].FullPhotoUrl : '',
                        'isActive': ownerExists ? usersData[caseList[i].OwnerId].IsActive : '',
                        'CaseClosedCount': closedCaseCount[caseList[i].OwnerId],
                        'CaseStatus': caseList[i].Status,
                        caseCreated: this.getDateTime(convertToTimezone(caseList[i].CreatedDate, this.loggedInUserData.TimeZoneSidKey), true),
                        caseClosed: caseList[i].ClosedDate ? caseList[i].ClosedDate : '',
                        closedLabel: caseList[i].ClosedDate && caseList[i].ClosedDate.length ? "Case Closed : " : "Open Since : ",
                        closedSince: caseList[i].ClosedDate && caseList[i].ClosedDate.length ? this.getDateTime(caseList[i].ClosedDate) : this.openSince(caseList[i].CreatedDate),
                        isLastCommentPresent: caseComments[caseList[i].Id + '-' + caseList[i].OwnerId] && caseComments[caseList[i].Id + '-' + caseList[i].OwnerId].length ? true : false,
                        isAccountName: caseList[i].Account && caseList[i].Account.Name && caseList[i].Account.Name.length ? true : false,
                        expanded: false,
                        previewUrl: this.origin + '/' + caseList[i].Id,
                        ownerExists,
                        ownerAndComments: ownerExists || caseComments[caseList[i].Id + '-' + caseList[i].OwnerId] && caseComments[caseList[i].Id + '-' + caseList[i].OwnerId].length,
                        listClass: 'list',
                    });

                }
                this.relatedCasesRecords = responseDataVals;
                this.showRelatedCases = this.relatedCasesRecords.length > 0;
                this.allCases = responseDataVals;
                this.unFilteredArray = responseDataVals;
                this.relatedCasesLoader = false;
            }).catch(error => {
                this.showRelatedCases = false;
                console.log(error);
            });
        }
    }

    expandInfoDiv(event) {
        let index = event.currentTarget.dataset.index;
        if (index > -1) {
            this.relatedCasesRecords[index].expanded = this.relatedCasesRecords[index].expanded ? false : true;
            let relatedCasesRecordsBck = this.relatedCasesRecords;
            this.relatedCasesRecords = [];
            this.relatedCasesRecords = relatedCasesRecordsBck;
            this.relatedCasesRecords.forEach((obj, i) => {
                if (index !== i)
                    obj.expanded = false;
                obj.listClass = obj.expanded ? 'list case-expanded' : 'list';
                return obj;
            });
        }
    }
    //method to handle functionality when date modal checkbox is toggled
    handleChangeCreatedDate(event) {
        this.createdChecked = event.target.checked;
        event.target.checked ? 'createSelect' : 'createDeselect';
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
        this.relatedCasesRecords = this.allCases.filter(x => {
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
            return new Date(c.CreatedDate) > createdStartD && new Date(c.CreatedDate) < createdEndD && c.CaseStatus === 'Closed';
        });
        this.showRelatedCases = this.relatedCasesRecords.length > 0;
    }

    //method called when start or end date value in date modal is changed
    handleCreatedDateChange(event) {
        let date = event.currentTarget.value;
        let type = event.currentTarget.dataset.id;
        if (type === 'createdStartDate') {
            this.createdStartDate = date;
            this.createdEndDate = new Date(date) > new Date(this.createdEndDate) ? date : this.createdEndDate;
        } else this.createdEndDate = date;
        this.updateRecords();
    }

    resetDates() {
        let todaysDate = new Date(new Date().setHours(23, 59, 59, 999));
        let startDate = new Date((new Date).setDate(todaysDate.getDate() - 30));

        startDate = new Date(startDate).getFullYear() + '-' + (
            (new Date(startDate).getMonth() + 1) < 10 ? '0' + (new Date(startDate).getMonth() + 1) : (new Date(startDate).getMonth() + 1)
        ) + '-' + (
                (new Date(startDate).getDate()) < 10 ? '0' + (new Date(startDate).getDate()) : (new Date(startDate).getDate())
            );

        todaysDate = new Date(todaysDate).getFullYear() + '-' + (
            (new Date(todaysDate).getMonth() + 1) < 10 ? '0' + (new Date(todaysDate).getMonth() + 1) : (new Date(todaysDate).getMonth() + 1)
        ) + '-' + (
                (new Date(todaysDate).getDate()) < 10 ? '0' + (new Date(todaysDate).getDate()) : (new Date(todaysDate).getDate())
            );
        this.createdStartDate = startDate;
        this.createdEndDate = todaysDate;

        this.startDate = startDate;
        this.todaysDate = todaysDate;

        this.createdChecked = false;
    }

    //func to toggle the sort menu
    sortByButtonHandler() {
        const sortMenuHolder = this.template.querySelector('.sort-menu-holder');
        sortMenuHolder.style.display = (sortMenuHolder.style.display === 'block') ? 'none' : 'block';
    }

    //function to toggle for the closed cases svg
    closedCasesCheckedHandler() {
        const svgContainer = this.template.querySelector('.svg-holder-closed-cases');
        const svgBox = this.template.querySelector('.view-svg-container');
        svgContainer.style.display = (svgContainer.style.display === 'block') ? 'none' : 'block';
        svgBox.style.border = "1px solid #f48b00";
    }

    relatedCasesClasses(event) {
        const index = event.currentTarget.dataset.index;
        if (index % 2 === 0) {
            return "related-case-holder backgroundColorBasedOnIndex";
        }
        return "related-case-holder";
    }

    //function to sort for the created Date
    handleSort() {
        if (this.closedCases) { //closed cases filter is on
            let sortedArray = [...this.relatedCasesRecords];

            sortedArray.sort((a, b) => {
                const dateA = this.parseDate(a.caseCreated);
                const dateB = this.parseDate(b.caseCreated);
                return dateA - dateB;
            });

            this.relatedCasesRecords = [...sortedArray];
        } else {
            if (this.createdDateSort) { // true -> already sorted, again unsort 
                this.relatedCasesRecords = [...this.unFilteredArray];
            } else {
                let sortedArray = [...this.unFilteredArray];

                sortedArray.sort((a, b) => {
                    const dateA = this.parseDate(a.caseCreated);
                    const dateB = this.parseDate(b.caseCreated);
                    return dateA - dateB;
                });

                this.relatedCasesRecords = [...sortedArray];
            }
        }
        this.createdDateSort = !this.createdDateSort;
        this.sortByButtonHandler(); //closing the menu on button click

        trackEvent({
            ...this.metaData,
            feature_category: "Top Related Cases",
            feature_name: "Sort By Created Date",
            interaction_type: 'click',
            feature_description: "Cases data sorted by created date",
            metric: {}
        }, this.loggedInUserData);
    }

    parseDate(dateStr) {
        const [datePart, timePart] = dateStr.split(' | ');
        const [day, month, year] = datePart.split('-').map(Number);
        const [time, period] = timePart.split(' ');
        let [hours, minutes] = time.split(':').map(Number);

        if (period === 'PM' && hours !== 12) {
            hours += 12;
        } else if (period === 'AM' && hours === 12) {
            hours = 0;
        }

        return new Date(year, month - 1, day, hours, minutes);
    }


    filterRecords() {
        const svgContainer = this.template.querySelector('.svg-holder-closed-cases');
        const svgBox = this.template.querySelector('.view-svg-container');

        if (this.closedCases) { //true -> already filtered, so unselect
            this.relatedCasesRecords = [...this.unFilteredArray];
            svgBox.style.border = "1px solid #CCD9F3";
        } else {
            this.relatedCasesRecords = this.unFilteredArray.filter(record => record.CaseStatus === "Closed");
            svgBox.style.border = "1px solid #F48B00";
        }

        this.closedCases = !this.closedCases;

        this.showRelatedCases = (this.relatedCasesRecords.length === 0) ? false : true;
        svgContainer.style.display = (svgContainer.style.display === 'block') ? 'none' : 'block';
        trackEvent({
            ...this.metaData,
            feature_category: "Top Related Cases",
            feature_name: "Filter By Case Status",
            interaction_type: 'click',
            feature_description: "Filtered cases data by case status.",
            metric: { case_status: this.closedCases ? 'Close' : 'any' }
        }, this.loggedInUserData);

    }

    casePreview() {
        trackEvent({
            ...this.metaData,
            feature_category: "Top Related Cases",
            feature_name: "Case Preview",
            interaction_type: 'click',
            feature_description: "Clicked on preview icon",
            metric: {}
        }, this.loggedInUserData);
    }
}