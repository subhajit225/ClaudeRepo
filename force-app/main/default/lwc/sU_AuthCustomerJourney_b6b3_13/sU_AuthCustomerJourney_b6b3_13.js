import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCommunityCustomSettings from '@salesforce/apex/su_vf_console.SU_LtngCaseAnalyticsCTRL.getCommunityCustomSettings';

export default class SU_AuthCustomerJourney extends LightningElement {
    @track resultActual;
    @track customerJourneyFilterListPopup = false;
    @track isChecked = true;
    @track allChecked = true;
    @track isLoading = true;
    @track responseData = false;
    @api height;
    @api label;
    ccaseId;
    @track endPoint = '';
    @track bearer = '';
    @wire(CurrentPageReference) currentPageReference;
   
    async connectedCallback() {
        this.ccaseId = this.currentPageReference && this.currentPageReference.attributes.recordId || '';
        this.getCommunityCustomSettings(this.ccaseId);
    }

   getCommunityCustomSettings(id) {
        getCommunityCustomSettings({ caseId: id }).then(result => {
            if (result) {
                this.bearer = result.token;
                this.endPoint = result.endPoint;
                this.uid = result.uid;
                this.getCustomerJourneyDetails();
            } else {
                this.customSettingErrorMessage = 'Please configure your SearchUnify and try again.';
            }
        })
        .catch(error => {
            console.log('[error]', error);
        });
    }

    getCustomerJourneyDetails() {
        const self = this;
        self.isLoading = true;
        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/admin/contentSources/byCaseUidAuth?uid=" + this.uid;
        xmlHttp.withCredentials = true;
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.bearer);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.send();
        xmlHttp.onreadystatechange = function () {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    self.isLoading = false;
                    if (result.statusCode === 200) {
                        self.resultActual = result;
                        self.resultActual.filters = result.filters.map(item => ({
                            filterName: item,
                            isChecked: self.isChecked,
                        }));
                        self.dataLoaded = true;
                    } else if(result.message == 'No data found') {
                        self.dataLoaded = false;
                    } else if(result.message == 'Invalid Authentication') {
                        this.customSettingErrorMessage = 'Please configure your SearchUnify and try again.';
                        // self.getCommunityCustomSettings(self.ccaseId);
                    }
                }
            }
        }
    }

    get customerJourneyLabel() {
        return this.label != '' ? this.label : 'SU Analytics On Case';
    }

    get customerJourneyDivHeight() {
        return this.height != '' ? 'height:' + this.height + 'px;' : 'height:400px';
    }
    get customerJourneyTotalActivities() {
        return this.resultActual &&  this.resultActual.array && this.resultActual.array.length;
    }

    get customerJourneyArray() {
        if (this.resultActual && this.resultActual.array) {
            this.resultActual.array.forEach(item => {
                if (item.ActivityType === 'Page Views' || item.ActivityType === 'Conversions' || item.ActivityType === 'Visited Support') {
                    item.showAnchorTag = true;
                } else {
                    item.showAnchorTag = false;
                }
            });
            return this.resultActual.array;
        }
    }

    get customerJourneyFilters() {
        this.setAllFilterValue();
        return this.resultActual && this.resultActual.filters;
    }


    showHideCheckboxes() {
        this.customerJourneyFilterListPopup = !this.customerJourneyFilterListPopup;
    }

    checkUncheckAll(event) {
        let selectedAllFilter = event.currentTarget.dataset.id;
        let suAnalyticsTypeId = this.template.querySelectorAll('[data-id="suAnalyticsTypeId"]');
        if (suAnalyticsTypeId && selectedAllFilter) {
            for (let i = 0; i < suAnalyticsTypeId.length; i++) {
                if (!event.currentTarget.checked) {
                    suAnalyticsTypeId[i].parentElement.classList.add('hide_CustomerJourney');
                    this.handleFiltersOnAll(false);
                } else {
                    if (suAnalyticsTypeId[i].parentElement.classList.contains('hide_CustomerJourney')) {
                        suAnalyticsTypeId[i].parentElement.classList.remove('hide_CustomerJourney');
                        this.handleFiltersOnAll(true);
                    }
                }
            }
        }
    }

    handleFiltersOnAll(allInputChecked) {
        if (allInputChecked) {
            this.resultActual && this.resultActual.filters.forEach(item => {
                item.isChecked = true;
            })
        } else {
            this.resultActual && this.resultActual.filters.forEach(item => {
                item.isChecked = false;
            })
        }
        this.customerJourneyFilters;
    }

    checkUncheck(event) {
        let selectedFilter = event.currentTarget.dataset.id;
        let suAnalyticsTypeId = this.template.querySelectorAll('[data-id="suAnalyticsTypeId"]');
        if (suAnalyticsTypeId && selectedFilter) {
            for (let i = 0; i < suAnalyticsTypeId.length; i++) {
                if (selectedFilter == suAnalyticsTypeId[i].innerHTML && event.currentTarget.checked) {
                    if (suAnalyticsTypeId[i].parentElement.classList.contains("hide_CustomerJourney")) {
                        this.checkMarkFilterInput(selectedFilter, true);
                        suAnalyticsTypeId[i].parentElement.classList.remove("hide_CustomerJourney");
                    }
                } else if (selectedFilter == suAnalyticsTypeId[i].innerHTML && !event.currentTarget.checked) {
                    this.checkMarkFilterInput(selectedFilter, false);
                    suAnalyticsTypeId[i].parentElement.classList.add("hide_CustomerJourney");
                }
            }
            this.setAllFilterValue();
        }
    }

    setAllFilterValue() {
        let allFilterInput = this.resultActual && this.resultActual.filters.every(item => item.isChecked);
        if (allFilterInput) {
            this.allChecked = true
        } else {
            this.allChecked = false;
        }
    }

    checkMarkFilterInput(selectedFilter, checked) {
        this.resultActual.filters.forEach(item => {
            if (selectedFilter === item.filterName) {
                item.isChecked = checked ? true : false;
            }
        });
    }
}