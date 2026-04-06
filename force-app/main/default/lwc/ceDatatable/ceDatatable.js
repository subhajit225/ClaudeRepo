import { LightningElement, api, track } from 'lwc';
import {getSortedData} from 'c/ceOperationsUtil'
export default class CeDatatable extends LightningElement {

    @api columns;
    @track displayData = [];
    @api dtData = [];
    @api error;
    @api sortedBy;
    @api sortedDirection;
    @api maxHeight = 400;
    totalNumberOfRows = 50; 
    recordCount = 20;
    loadMoreStatus;
    totalRecountCount = 0;
    targetDatatable;
    connectedCallback() {
        this.totalRecountCount = this.dtData.length;
        this.displayData = this.dtData.slice(0, this.recordCount);
    }

    get enableInfinteLoading() {
        return this.totalRecountCount > this.totalNumberOfRows;
    }

    get hasData(){
        return Boolean(this.totalRecountCount);
    }
    get styleInfinteLoading(){
        return `height: ${this.maxHeight}px;`
    }
    get style(){
        return `max-height: ${this.maxHeight}px;`
    }
    dataFullyLoaded() {
        this.loadMoreStatus = 'No more data to load';
        setTimeout(() => {
            this.getRecords();
        }, 2000);
    }
    getRecords() {
        this.recordCount = (this.recordCount > this.totalRecountCount) ? this.totalRecountCount : this.recordCount;
        this.displayData = this.dtData.slice(0, this.recordCount);
        this.loadMoreStatus = '';
        if (this.targetDatatable) {
            this.targetDatatable.isLoading = false;
        }

    }
    handleLoadMore(event) {
        if (this.recordCount == this.totalRecountCount){
            return;
        }

        event.preventDefault();
        this.recordCount = this.recordCount + 20;
        event.target.isLoading = true;
        this.targetDatatable = event.target;

        setTimeout(() => {
            this.getRecords();
        }, 1000);

    }
    handleColumnSorting(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortedDirection);
    }

    sortData(fieldName, direction) {
        this.dtData = getSortedData(fieldName, direction, this.dtData);
        this.connectedCallback();
    }
    handleRowAction(event) {
        this.dispatchEvent(new CustomEvent("rowaction", { detail: event.detail }));
    }
}