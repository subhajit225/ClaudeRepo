import { LightningElement } from 'lwc';
import getDebugSet from '@salesforce/apex/EntitlementMissingScriptClass.getDebugSet';

export default class MyButtonComponent extends LightningElement {
    classDebugs;
    loaded = true;
    startDate;
    endDate;
    endDateError = '';
    disableFilterBTN = false;
    isAsc = false;
    isDsc = false;
    isRecordCountSort = false;
    isCategorySort = false;
    sortedDirection = 'asc';
    sortedColumn;

    connectedCallback() {
        this.calculateQuarterDates();
        this.handleFilterClick();
    }
    calculateQuarterDates() {
        const today = new Date();
        const currentMonthNumber = today.getMonth();

        let QAStartMonth;
        if (currentMonthNumber >= 2 && currentMonthNumber <= 4) { // February - April
            QAStartMonth = 2; // February
        } else if (currentMonthNumber >= 5 && currentMonthNumber <= 7) { // May - July
            QAStartMonth = 5; // May
        } else if (currentMonthNumber >= 8 && currentMonthNumber <= 10) { // August - October
            QAStartMonth = 8; // August
        } else { // November - January
            QAStartMonth = 11; // November
        }
        console.log('QAStartMonth', QAStartMonth);
        const qtStartDate = new Date(today.getFullYear(), QAStartMonth - 1, 1);
        const qtEndDate = new Date(today.getFullYear(), QAStartMonth + 2, 0);
        const offset = today.getTimezoneOffset();
        this.startDate = new Date(qtStartDate.getTime() - offset * 60000).toISOString().split('T')[0];
        this.endDate = new Date(qtEndDate.getTime() - offset * 60000).toISOString().split('T')[0];
    }
    // Handler for button click
    handleFilterClick() {
        this.loaded = false;
        getDebugSet({UIstartDate : this.startDate, UIendDate : this.endDate})
            .then((result) => {
                this.loaded = true;
                this.classDebugs = result;
                console.log('logs::', this.classDebugs);
            })
            .catch((error) => {
                this.loaded = true;
                console.error('Error:', error);
            });
    }
    validateDates(event) {
        const { label, value } = event.target;

        if (label === 'Start Date') {
            this.startDate = value;
        } else if (label === 'End Date') {
            this.endDate = value;
        }

        if (this.endDate < this.startDate) {
            this.endDateError = 'The End Date should not be lesser than the Start Date';
            this.disableFilterBTN = true;
        } else {
            this.endDateError = '';
            this.disableFilterBTN = false;
        }
    }
    sortRecordCount(event) {
        this.isRecordCountSort = true;
        this.isCategorySort = false;

        this.sortData(event.currentTarget.dataset.id, event.currentTarget.dataset.type);
    }
    sortCategory(event){
        this.isRecordCountSort = false;
        this.isCategorySort = true;

        this.sortData(event.currentTarget.dataset.id, event.currentTarget.dataset.type);    
    }
    sortData(sortColumnName, columnType) {
        // check previous column and direction
        console.log('sortColumnName::', sortColumnName);
        console.log('sortColumnType::', columnType);
        if (this.sortedColumn === sortColumnName) {
            this.sortedDirection = this.sortedDirection === 'asc' ? 'desc' : 'asc';
        } 
        else {
            this.sortedDirection = 'asc';
        }
        this.isAsc = (this.sortedDirection === 'asc');
        this.isDsc = (this.sortedDirection === 'desc');
        
        // check reverse direction
        let isReverse = this.sortedDirection === 'asc' ? 1 : -1;
        console.log('isReverse::', isReverse);
        this.sortedColumn = sortColumnName;

        // sort the data
        this.classDebugs = JSON.parse(JSON.stringify(this.classDebugs)).sort((a, b) => {
            if(columnType == 'number'){
                a = a[sortColumnName] ? a[sortColumnName] : ''; // Handle null values
                b = b[sortColumnName] ? b[sortColumnName] : '';
            }
            else{
                a = a[sortColumnName] ? a[sortColumnName].toLowerCase() : ''; // Handle null values
                b = b[sortColumnName] ? b[sortColumnName].toLowerCase() : '';
            }
            return a > b ? 1 * isReverse : -1 * isReverse;
        });;
    }
}