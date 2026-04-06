import { LightningElement, api, } from 'lwc';
import { getLastUpdatedInterval } from "c/ceOperationsUtil";

export default class CeGenericReportDT extends LightningElement {

    @api name;
    @api label;
    @api columns;
    @api dtData;
    @api error
    @api title
    lastUpdatedInterval = 'a few seconds ago';
    @api isLoaded = false;
    lastUpdatedIntervalJob;
    lastLoadTimestamp;
    @api filteredBy = 'Account CEMs,Account Preferences, Account Names'

    get filterStatus(){
        return  this.filteredBy ? `Filtered by ${this.filteredBy}` : 'No filter selected'
    }
    get hasRecords() {
        return this.dtData && this.dtData.length;
    }
    get totalCount() {
        return this.dtData.length >= 2000 ? '2000+' : this.dtData.length;
    }
    get totalItems() {
        let totalItems = 0;
        if (this.dtData) {
            totalItems = this.dtData.length;
        }
        return totalItems;
    }
    get style() {
        return this.totalItems ? 'slds-page-header__row slds-grid' : "slds-page-header__row slds-grid slds-p-vertical_xx-small";
    }
    connectedCallback() {
        this.lastLoadTimestamp = new Date().getTime();
        if (!this.lastUpdatedIntervalJob) {
            this.lastUpdatedInterval = getLastUpdatedInterval(new Date().getTime(), this.lastLoadTimestamp);
            this.lastUpdatedIntervalJob = setInterval(() => {
                this.lastUpdatedInterval = getLastUpdatedInterval(new Date().getTime(), this.lastLoadTimestamp);
            }, 60000);
        }
    }
    disconnectedCallback() {
        clearInterval(this.lastUpdatedIntervalJob);
        this.lastUpdatedIntervalJob = undefined;
    }
    navigateToRecordDetailPage(event) {
        this.navigateToRecordPage(event.currentTarget.dataset.id, 'view')
    }
    navigateToRecordPage(id, actionName) {
        const pageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: actionName
            }
        };
        this[NavigationMixin.Navigate](pageRef);
    }
}