/*<Created By: Ashish thakur 20 April, 2022>
    <Reason>
    To make LWC component for Recent Case Section. 
    </Reason>*/


    import { LightningElement, api, track, wire } from 'lwc';
    import getCaseRecLWC from '@salesforce/apex/CaseDetailControllerLWC.getCaseRecLWC';
    import getFiveCaseRecordsLWC from '@salesforce/apex/CaseDetailControllerLWC.getFiveCaseRecordsLWC';
    import { NavigationMixin } from 'lightning/navigation';
    
    
    export default class lGT_RecentCaseComponentLWC extends NavigationMixin(LightningElement) {
        @track caseList = [];
        SpinnerForCluster = false;
        showButton = true;
        showLess = true;
        showError = false;
        @track showCases = true;
        errorMessage = '';
        originalCaseList = [];
        @track currentfield = 'LastModifiedDate';
        @api recordId;
        @track currentSortingOrder = 'desc';
        @track Desc = true;
        isCNumber = false;
        isStatus = false;
        isSubject = false;
        isPriority = false;
        isOwner = false;
        isCluster = false;
        isResolution = false;
        isLastModified = true;
        isCreatedDate = false;
        @track showdetail = false;
        @track CurrentCaseId;
        NavigateToAllCases = false;
    
        connectedCallback() {
    
            var windowUrl = window.location.href;
            let newUrl = new URL(windowUrl).searchParams;
            if (newUrl.get('c__ws') !== null && newUrl.get('c__ws') !== undefined) {
                this.showdetail = true;
                this.showless = false;
                this.originalCaseList = [];
                let urlContain = newUrl.get('c__ws');
                this.recordId = urlContain;
            }
            else {
                if (this.recordId === undefined) {
                    this.CurrentCaseId = windowUrl.split('/');
                    for (var a = 0; a < this.CurrentCaseId.length; a++) {
                        if (this.CurrentCaseId[a].includes('500') && !this.CurrentCaseId[a].includes('ws=')) {
                            this.showdetail = true;
                            this.recordId = this.CurrentCaseId[a];
                        }
                    }
                }
            }
    
            if (this.NavigateToAllCases === true) {
                this.getRecentCases();
            }
            else {
                this.getFiveRecentCases();
            }
        }
    
        handleToggleSection() {
            this.getFiveRecentCases();
        }
    
        getFiveRecentCases() {
            this.SpinnerForCluster = true;
            getFiveCaseRecordsLWC(
                {
                    caseId: this.recordId,
                    field: this.currentfield,
                    order: this.currentSortingOrder
    
                })
                .then((result) => {
                    this.SpinnerForCluster = false;
                    this.showCases = true;
                    if (result !== null && result !== undefined) {
                        this.caseList = [];
                        this.originalCaseList = [];
                        for (var i = 0; i < result.length; i++) {
                            if (result[i] !== undefined) {
                                this.caseList.push(result[i]);
                            }
                        }
                        if (result.length < 5) {
    
                            this.showButton = false;
                        }
                        if (this.showdetail == true) {
                            this.showLess = false;
                        }
                        if (this.showLess == true) {
                            for (var i = 0; i < 5; i++) {
                                if (result[i] !== undefined) {
                                    this.originalCaseList.push(result[i]);
                                }
                            }
                        }
                        else {
                            this.getRecentCases();
                        }
    
                    }
                }).catch((error) => {
    
                });
    
    
        }
    
        getRecentCases() {
            this.SpinnerForCluster = true;
            getCaseRecLWC(
                {
                    caseId: this.recordId,
                    field: this.currentfield,
                    order: this.currentSortingOrder
    
                })
                .then((result) => {
                    this.SpinnerForCluster = false;
                    this.showCases = true;
                    if (result !== null && result !== undefined) {
                        this.caseList = [];
                        this.originalCaseList = [];
                        for (var i = 0; i < result.length; i++) {
                            if (result[i] !== undefined) {
                                this.caseList.push(result[i]);
                            }
                        }
                        if (this.showdetail == true) {
                            this.showLess = false;
                        }
                        for (var i = 0; i < result.length; i++) {
                            if (result[i] !== undefined) {
                                this.originalCaseList.push(result[i]);
                            }
                        }
                    }
                }).catch((error) => {
    
                });
    
    
        }
    
        showAllRecords() {
            this.originalCaseList = [];
            this.showLess = !this.showLess;
            this.NavigateToAllCases = true;
            this.showLess = true;
            this.showdetail = false;
            this.getFiveRecentCases();
            let pageReference = {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/Recent_Cases?c__ws=' + this.recordId
                }
            };
            this[NavigationMixin.Navigate](pageReference, false);
    
        }
    
    
    
        getCasesOnEnter(event) {
            if (event.keyCode === 13) {
                var inp = this.template.querySelector("lightning-input");
                var clusterUuidValue = inp.value;
                this.searchCase(clusterUuidValue);
            }
    
        }
        getCases(event) {
            var inp = this.template.querySelector("lightning-input");
            var clusterUuidValue = inp.value;
    
            this.searchCase(clusterUuidValue);
        }
        searchCase(clusterUuidValue) {
            var clusterUuidToLowerCase = clusterUuidValue.toLowerCase();
            var clusterUuidVal = clusterUuidToLowerCase.trim();
            if (clusterUuidVal == '' || clusterUuidVal == null) {
                this.showError = false;
                this.showCases = true;
                this.showButton = true;
                this.showLess = true;
                this.getFiveRecentCases();
            }
            else {
                this.originalCaseList = [];
                for (var i = 0; i < this.caseList.length; i++) {
                    if (this.caseList[i].Cluster__r && this.caseList[i].Cluster__r.Name.toLowerCase().includes(clusterUuidVal)) {
                        this.originalCaseList.push(this.caseList[i]);
                    }
                }
                if (this.originalCaseList.length == 0) {
                    this.errorMessage = 'No Records Available';
                    this.showError = true;
                    this.showButton = false;
                }
                else {
                    this.showError = false;
                    this.showCases = true;
                    this.showButton = true;
                }
            }
        }
        openDetailPage(event) {
            let pageReference = {
                type: 'standard__recordPage',
                attributes: {
    
                    recordId: event.target.dataset.id,
                    actionName: 'view'
    
                }
            };
            // this[NavigationMixin.Navigate](pageReference, true);
            this[NavigationMixin.Navigate](pageReference, false);
        }
    
        Sorttable(event) {
            var fieldName = event.target.name;
            //var sortDirection = event.target.dataset.id;
            if (fieldName == 'CaseNumber') {
                this.isCNumber = true;
                this.isStatus = false;
                this.isSubject = false;
                this.isPriority = false;
                this.isOwner = false;
                this.isCluster = false;
                this.isResolution = false;
                this.isLastModified = false;
                this.isCreatedDate = false;
    
            }
            else if (fieldName == 'Status') {
                this.isCNumber = false;
                this.isStatus = true;
                this.isSubject = false;
                this.isPriority = false;
                this.isOwner = false;
                this.isCluster = false;
                this.isResolution = false;
                this.isLastModified = false;
                this.isCreatedDate = false;
    
            }
            else if (fieldName == 'Subject') {
                this.isCNumber = false;
                this.isStatus = false;
                this.isSubject = true;
                this.isPriority = false;
                this.isOwner = false;
                this.isCluster = false;
                this.isResolution = false;
                this.isLastModified = false;
                this.isCreatedDate = false;
    
            }
            else if (fieldName == 'Priority') {
                this.isCNumber = false;
                this.isStatus = false;
                this.isSubject = false;
                this.isPriority = true;
                this.isOwner = false;
                this.isCluster = false;
                this.isResolution = false;
                this.isLastModified = false;
                this.isCreatedDate = false;
            }
            else if (fieldName == 'Owner.Name') {
                this.isCNumber = false;
                this.isStatus = false;
                this.isSubject = false;
                this.isPriority = false;
                this.isOwner = true;
                this.isCluster = false;
                this.isResolution = false;
                this.isLastModified = false;
                this.isCreatedDate = false;
            }
            else if (fieldName == 'Resolution__c') {
                this.isCNumber = false;
                this.isStatus = false;
                this.isSubject = false;
                this.isPriority = false;
                this.isOwner = false;
                this.isCluster = false;
                this.isResolution = true;
                this.isLastModified = false;
                this.isCreatedDate = false;
            }
            else if (fieldName == 'Cluster__c') {
                this.isCNumber = false;
                this.isStatus = false;
                this.isSubject = false;
                this.isPriority = false;
                this.isOwner = false;
                this.isCluster = true;
                this.isResolution = false;
                this.isLastModified = false;
                this.isCreatedDate = false;
                fieldName = 'Cluster__r.uuid__c';
            }
            else if (fieldName == 'LastModifiedDate') {
                this.isCNumber = false;
                this.isStatus = false;
                this.isSubject = false;
                this.isPriority = false;
                this.isOwner = false;
                this.isCluster = false;
                this.isResolution = false;
                this.isLastModified = true;
                this.isCreatedDate = false;
            }
            else if (fieldName == 'CreatedDate') {
                this.isCNumber = false;
                this.isStatus = false;
                this.isSubject = false;
                this.isPriority = false;
                this.isOwner = false;
                this.isCluster = false;
                this.isResolution = false;
                this.isLastModified = false;
                this.isCreatedDate = true;
            }
    
            if (fieldName != this.currentfield) {
                this.currentSortingOrder = 'desc';
                this.Desc = true;
    
                //sortDirection = 'asc';
    
                this.currentfield = fieldName
            }
            else {
                if (this.currentSortingOrder == 'desc') {
                    this.currentSortingOrder = 'asc';
                    this.Desc = false;
                }
                else {
                    this.currentSortingOrder = 'desc';
                    this.Desc = true;
                }
            }
    
            this.getFiveRecentCases();
            //this.sortData(fieldName, this.currentSortingOrder);
    
    
        }
    
    
    
    }