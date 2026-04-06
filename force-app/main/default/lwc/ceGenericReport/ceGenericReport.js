import { LightningElement, api, wire, track } from 'lwc';
import getGroupMetrics from '@salesforce/apex/CeOperationsDashboardController.getGroupMetrics';
import getMetrics from '@salesforce/apex/CeOperationsDashboardController.getMetrics';
import { getColumns, normalizeRecordData } from "c/ceOperationsUtil";

export default class CeGenericReport extends LightningElement {

    @api selectedAccountPeferences
    @api selectedAccountNames
    @api selectedAccountCEMs
    @api name
    @api label
    @api recordId;
    @api isJiraReference;
    @api isClosed;
    @track tableData = [];
    @api groupByValues;
    isLoading = true;
    lastUpdatedInterval = 'a few seconds ago';
    lastUpdatedIntervalJob;
    error;
    @track columns;
    title;
    @track reports = [];

    get reportsloaded(){
        if(this.name == 'tcv_12_priority'){
            return this.groupByValues && this.reports.length == this.groupByValues.length;
        } else {
            return this.reports && this.reports.length
        }
    }
    connectedCallback() {
        if (this.name == 'tcv_12_priority') {
            this.groupByValues = this.groupByValues.map(item => (item === 'Empty' ? null : item));
            this.getGroupByValues(this.name);
        } else {
            this.callGetMetrics(this.name)
        }
    }
    getFilteredBy() {
        let filteredBy = [];
        if (this.selectedAccountNames && this.selectedAccountNames.length) {
            filteredBy.push('Account Names');
        }
        if (this.selectedAccountPeferences && this.selectedAccountPeferences.length) {
            filteredBy.push('Account Preferences');
        }
        if (this.selectedAccountCEMs && this.selectedAccountCEMs.length) {
            filteredBy.push('Account CEMs');
        }
        return filteredBy.join(',');
    }
    
    getGroupByValues(name) {
        if(this.groupByValues){
            this.groupByValues.forEach(d => this.callGetGroupMetrics(name, 'Priority', d));
        }
    }
    insertSortedValue(arrayOfObjects, valueToInsert) {
        const newArray = [...arrayOfObjects];
        let insertIndex = 0;
        while (insertIndex < newArray.length && newArray[insertIndex].title < valueToInsert.title) {
            insertIndex++;
        }
        newArray.splice(insertIndex, 0, valueToInsert);
        return newArray;
    }
    callGetGroupMetrics(metric, groupBy, groupByValue) {
        getGroupMetrics({
            preference: this.selectedAccountPeferences,
            name: this.selectedAccountNames,
            cem: this.selectedAccountCEMs,
            metric: metric,
            groupBy: groupBy,
            groupByValue: groupByValue
        })
            .then(data => {
                if (data.data) {
                    let tableData = normalizeRecordData(data.data, metric);
                    let label_prefix = groupByValue ?  groupByValue : 'Empty';
                    this.reports = this.insertSortedValue(this.reports, { 'columns': getColumns(metric), title: this.label + ' ' + label_prefix, tableData: tableData, error: undefined, name: metric, filteredBy: this.getFilteredBy() });
                    this.error = undefined;
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('CEOD101', error);
                let label_prefix = groupByValue ?  groupByValue : 'Empty';
                this.reports = this.insertSortedValue(this.reports, { 'columns': getColumns(metric), title: this.label + ' ' + label_prefix, tableData: undefined, error: undefined, name: metric, filteredBy: this.getFilteredBy() });
                this.isLoading = false;
                this.error = 'An error occured while retrieving data, please contact your Administrator';
            });
    }
    callGetMetrics(metric) {
        getMetrics({
            preference: this.selectedAccountPeferences,
            name: this.selectedAccountNames,
            cem: this.selectedAccountCEMs,
            metric: metric,
            fullData: true
        })
            .then(data => {
                let columns = getColumns(metric);
                if (data.data) {
                    this.tableData = normalizeRecordData(JSON.parse(JSON.stringify(data.data)), this.name);
                    this.reports.push({ 'columns': columns, title: this.label, tableData: this.tableData, error: undefined, name: metric, filteredBy: this.getFilteredBy() })
                    this.error = undefined;
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('CEOD102', error);
                this.isLoading = false;
                this.error = 'An error occured while retrieving data, please contact your Administrator';
                this.reports.push({ 'columns': getColumns(metric), title: this.label, tableData: [], error: this.error, name: metric, filteredBy: this.getFilteredBy() })
            });
    }
}