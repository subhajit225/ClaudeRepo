import { api, LightningElement, track } from 'lwc';
import HeatMapRowFilterStyle from '@salesforce/resourceUrl/HeatMapStyles';
import updateSelectedRowFilters from '@salesforce/apex/HeatMapController.updateSelectedRowFilters';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class HeatMapRowFilters extends LightningElement {

    @api rowFilterOptions;
    @api sectionStyleAccountFilter="";
    @track rowOptions;
    @track rowOptionsOld;
    @track accountDetails;
    showRowData = false;
    @track rowFilterMapping = {
        "salesEngineer": "Row_Filter_Sales_Engineer",
        "accountExecutive": "Row_Filter_Account_Executive",
        "account": "Row_Filter_Account",
        "theatre": "Row_Filter_Theatre",
        "area": "Row_Filter_Area",
        "region": "Row_Filter_Region",
        "territory": "Row_Filter_Territory",
        "type": "Row_Filter_Type",
        "tier": "Row_Filter_Tier"
    };
    @track updatedFilterValues=[];

    @api updateRowFiltersWithAccount(updatedValues){
        this.rowOptions = [...updatedValues];
        let accountIndex = this.rowOptions.findIndex(item => item.name === 'account');
        this.accountDetails = accountIndex !== -1 ? this.rowOptions.splice(accountIndex, 1) : [];        
        this.rowOptionsOld = [...this.rowOptions];
    }

    @track showAccountFilter = false;
    
    connectedCallback(){
        document.addEventListener('click', this.handleDocumentClick);
        this.rowOptions = JSON.parse(JSON.stringify(this.rowFilterOptions));
        let accountIndex = this.rowOptions.findIndex(item => item.name === 'account');
        this.accountDetails = accountIndex !== -1 ? this.rowOptions.splice(accountIndex, 1) : [];
        this.rowOptionsOld = [...this.rowOptions];
        this.showRowData = true;
        Promise.all([
            loadStyle(this, HeatMapRowFilterStyle )
        ]).catch(error => {
            console.log('Error loading styles: ' + JSON.stringify(error));
        });
    }

    handleClick(event) {
        const buttonName = event.target.name;
        const index = this.findIndexByName(buttonName);

        this.rowOptions.forEach((option, i) => {
            option.showFilter = (i === index) ? !option.showFilter : false;
        });

         this.showAccountFilter = false;

        event.stopPropagation(); // to stop the global connected callback event.
    }


    findIndexByName(name) {
        return this.rowOptions.findIndex(option => option.name === name);
    }

    handleDocumentClick = () => {
        this.rowOptions.forEach(option => {
            option.showFilter = false;
        });
        this.showAccountFilter = false;
    }
    
    handleChildClick(event) {
        event.stopPropagation();
    }
    
    handleFilterSelection(event) {
        let userSelectedRecord = { ...event.detail.optionSelected };
        this.rowOptions = this.updateSelection(this.rowOptions, userSelectedRecord);
    }
    
    handleSelectedAccounts(event) {
        let userSelectedRecord = { ...event.detail.optionSelected };
        this.accountDetails = this.updateSelection(this.accountDetails, userSelectedRecord);
        
        if (userSelectedRecord.key === 'account') {
            this.updateSelectedAccounts();
        }
    }
    
    updateSelection(records, selectedRecord) {
        return records.map(record => ({
            ...record,
            value: record.value.map(item => 
                item.id === selectedRecord.id
                    ? { ...item, isChecked: selectedRecord.isChecked }
                    : item
            ),
        }));
    }
    
    updateSelectedAccounts() {
        const updatedAccountValues = this.getUpdatedFilterValues(this.accountDetails, 'account', "Row_Filter_Account");
        this.updateRowFilters(updatedAccountValues);
    }
    
    handleApplyFilters() {
        console.log('@@@@@@ this.rowOptions: ',this.rowOptions);
        
        this.rowOptionsOld = [...this.rowOptions];
        this.dispatchEvent(new CustomEvent('applyfilterevent', { detail: 'Apply Filters' }));
        this.updateRowFilterSelectionsHandler();
    }
    
    handleResetFilters() {
        this.rowOptions.forEach(filter => {
            filter.value.forEach(value => value.isChecked = false);
        });
        this.rowOptionsOld = [...this.rowOptions];
        this.dispatchEvent(new CustomEvent('resetfilterevent', { detail: 'Reset Filters' }));
        this.updateRowFilterSelectionsHandler();
    }
    
    updateRowFilterSelectionsHandler() {
        let selectedRowFilterJSON = this.buildSelectedRowFilterJSON();
        selectedRowFilterJSON['account'] = ""; // Ensuring account is empty initially
    
        let updatedFilterValues = this.buildUpdatedFilterValues(selectedRowFilterJSON);
        this.updateRowFilters(updatedFilterValues);
    }
    
    buildSelectedRowFilterJSON() {
        let filterJSON = {};
        this.rowOptions.forEach(item => {
            filterJSON[item.name] = item.value.filter(val => val.isChecked).map(val => val.value).join(';');
        });
        return filterJSON;
    }
    
    buildUpdatedFilterValues(selectedRowFilterJSON) {
        return Object.entries(selectedRowFilterJSON)
            .filter(([key]) => this.rowFilterMapping[key])
            .map(([key, value]) => ({
                key: this.rowFilterMapping[key],
                value
            }));
    }
    
    updateRowFilters(updatedValues) {
        updateSelectedRowFilters({ updatedValues: JSON.stringify(updatedValues) })
            .then(result => {
                if (result !== 'Success') {
                    console.error('Error occurred while updating row filters');
                }
            })
            .catch(error => {
                console.error(error);
            });
    }
    
    handleAccountFilters(event) {
        const filterName = event.target.name;
        this.showAccountFilter = !this.showAccountFilter;
        this.rowOptions.forEach(option => option.showFilter = false);
        event.stopPropagation();
    }
    
    handleSelectAndClearAll(event) {
        const { filterName, buttonClicked } = event.detail;
        const isSelectAll = buttonClicked === 'Select All';
    
        if (filterName === 'account') {
            this.accountDetails = this.toggleAllSelections(this.accountDetails, 'account', isSelectAll);
            this.updateSelectedAccounts();
        } else {
            this.rowOptions = this.toggleAllSelections(this.rowOptions, filterName, isSelectAll);
            let selectedRowFilterJSON = this.buildSelectedRowFilterJSON();
            let updatedFilterValues = this.buildUpdatedFilterValues(selectedRowFilterJSON);
            this.updateRowFilters(updatedFilterValues);
        }
    }
    
    toggleAllSelections(records, filterName, isChecked) {
        return records.map(record => ({
            ...record,
            value: record.value.map(item => ({
                ...item,
                isChecked: record.name === filterName ? isChecked : item.isChecked
            }))
        }));
    }
    
    getUpdatedFilterValues(dataSet, filterName, keyName) {
        return dataSet
            .filter(item => item.name === filterName)
            .map(item => ({
                key: keyName,
                value: item.value.filter(val => val.isChecked).map(val => val.value).join(';')
            }));
    }        

}