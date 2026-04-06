import { LightningElement, track, wire } from 'lwc';
import getSavedFilterPreferances from '@salesforce/apex/HeatMapController.getSavedFilterPreferances';

export default class HeatMapDashboard extends LightningElement {
    @track dataAccounts = [];
    columnFiltersAll = {};
    @track allFilterOptions;
    @track columnFilterOptions;
    showRowFilter = false;
    showColumnFilter = false;
    showDatatable = false;
    @track selectedFilters = {};
    @track selectedRowFilter = {};
    @track loadingData = false;
    @track rowSelectedFilters = '';
    @track accountDataForFilters = [];
    @track showBanner = false;

    @track  rowFilterOptions=[
        {Id:'1' , label:'Sales Engineer' , name:'salesEngineer' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -40px;z-index: 30'},
        {Id:'2' , label:'Account Executive' , name:'accountExecutive' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -40px;z-index: 30'},
        {Id:'3' , label:'Account' , name:'account' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -80px;z-index: 30;'},
        {Id:'4' , label:'Theatre' , name:'theatre' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -90px;z-index: 30'},
        {Id:'5' , label:'Area' , name:'area' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -100px;z-index: 30'},
        {Id:'6' , label:'Region' , name:'region' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -100px;z-index: 30'},
        {Id:'7' , label:'Territory' , name:'territory' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -95px;z-index: 30'},
        {Id:'8' , label:'Type' , name:'type' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -100px;z-index: 30'},
        {Id:'9' , label:'Tier' , name:'tier' ,showFilter:false ,sectionStyle:'position: absolute;width: 250px;display: block;margin: 7px 0px 0px -105px;z-index: 30'}, 
    ];

    @track sectionStyleAccountFilter='position: absolute;width: 250px;display: block;margin: 7px 0px 0px -5px;z-index: 30';
    @track  rowFilterOptionsOld = [];
    @track preferredAccounts = [];

    get showWarningVerbiage(){
        return this.showBanner && this.dataAccounts?.length >= 1000;
    }
    
    connectedCallback(){
        this.getSavedFilterPreferancesMethod();
    }

    getSavedFilterPreferancesMethod(){
        this.loadingData = true;
        getSavedFilterPreferances().then(result=>{
            if(result){
                this.rowFilterOptions = this.rowFilterOptions.map(filter => {
                    if (filter.name == 'account') {
                        this.preferredAccounts = (result[filter.name] || []).map(item => {
                            const status = Object.keys(item)[0];
                            const key = Object.keys(item[status])[0];
                            return {
                                id: key,
                                label: item[status][key],
                                value: key,
                                isChecked: status === 'true'
                            };
                        });

                        return {
                            ...filter,
                            value: []
                        };
                    } else {
                        return {
                            ...filter,
                            value: (result[filter.name] || []).map(item => {
                                const status = Object.keys(item)[0];
                                const key = Object.keys(item[status])[0];
                                return {
                                    id: key,
                                    label: item[status][key],
                                    value: key,
                                    isChecked: status === 'true'
                                };
                            })
                        };
                    }
                });

                this.rowFilterOptionsOld = [...this.rowFilterOptions];
                this.showRowFilter = true;

                this.columnFilterOptions = result.columnFilters.map(item => {
                    const [status, obj] = Object.entries(item)[0];
                    const [ColumnName] = Object.keys(obj);
                
                    return {
                        ColumnName: ColumnName,
                        State: status === 'true'
                    };
                });
                this.showColumnFilter = true;
                this.selectedFilters = {...this.parseDataForDatatable(this.rowFilterOptions,this.columnFilterOptions)};
                this.showDatatable = true;
                this.loadingData = false;
            }
        });
    }

    parseDataForDatatable(rowData,columnData){
        let result = {};
        rowData.forEach(item => {
            if(item.name != 'account'){
                let checkedValues = item.value.filter(val => val.isChecked).map(val => val.value);
                result[item.name] = checkedValues.length > 0 ? checkedValues : [];
            }else{
                result[item.name] = [];
            }
            
        });
        let columnFilters = columnData.filter(item => item.State).map(item => item.ColumnName);
        result.columnFilters = columnFilters;
        return result;
    }

    handleGetAccDetails(event){
        const accountDetails = event.detail;
        this.dataAccounts = accountDetails.slice();
        if(this.dataAccounts?.length>=1000){
            this.showBanner = true;
        }
        this.template.querySelector('c-heat-map-header-section').recalculateHeaderData(this.dataAccounts);
    }

    handleColumnFilterChange(event){
        let updatedSelections = JSON.parse(event.detail.selectedColumnFilter);
        this.columnFilterOptions.forEach(item => {
            item.State = updatedSelections.includes(item.ColumnName);
        });
        this.selectedFilters = {...this.parseDataForDatatable(this.rowFilterOptions,this.columnFilterOptions)};
        this.template.querySelector('c-heat-map-data-table').getUpdatedColumnData(this.selectedFilters);
    }

    handleFilterSelection(event) {
        let selectedOption = event.detail.optionSelected;
        this.rowFilterOptions = this.rowFilterOptions.map(record => {
            const updatedValue = record.value.map(item => {
                if (item.id === selectedOption.id) {
                    return {...item,isChecked: !item.isChecked};
                }
                return item;
            });
            return {...record,value: updatedValue};
        });
        this.preferredAccounts = this.rowFilterOptions.filter(item => {
                return item.name === "account";
        })[0].value;

        if(selectedOption.key === 'account'){
            this.template.querySelector('c-heat-map-data-table').handleFilteration(selectedOption);
        }
    }

    handleResetRowFilter(event){
        if(event.detail === 'Reset Filters'){
            this.rowFilterOptions.forEach(filter => {
                filter.value.forEach(value => {
                    value.isChecked = false;
                });
            });
            this.rowFilterOptionsOld = [...this.rowFilterOptions];
            this.selectedFilters = {...this.parseDataForDatatable(this.rowFilterOptions,this.columnFilterOptions)};
            this.template.querySelector('c-heat-map-data-table').getUpdatedRowData(this.selectedFilters);
            // this.template.querySelector('c-heat-map-data-table').resetAccountFilters();
        }
    }

    handleApplyRowFilter(event){
        if(event.detail === 'Apply Filters'){
            this.preferredAccounts = [];
            this.rowFilterOptionsOld = [...this.rowFilterOptions];
            this.selectedFilters = {...this.parseDataForDatatable(this.rowFilterOptions,this.columnFilterOptions)};
            this.template.querySelector('c-heat-map-data-table').getUpdatedRowData(this.selectedFilters);
        }
    }

    handleAccountRowFilters(event){
        this.accountDataForFilters = [...event.detail];
        let selectedIdsSet = this.preferredAccounts?.length ? new Set(this.preferredAccounts?.filter(value => value.isChecked).map(value => value.id)) : null;

        this.rowFilterOptions = this.rowFilterOptions.map(item => {
            if (item.name === "account") {
                item.value = this.accountDataForFilters.map(account => ({
                    id: account.accountId,
                    label: account.accountName,
                    value: account.accountId,
                    isChecked: selectedIdsSet?.size ? selectedIdsSet.has(account.accountId) : account.state
                    // isChecked : account.state
                }));
            }
            return item;
        });

        if(!this.preferredAccounts?.length){
            this.preferredAccounts = this.rowFilterOptions.filter(item => {
                return item.name === "account";
            })[0].value;
        }

        this.rowFilterOptionsOld = [...this.rowFilterOptions];
        this.rowFilterOptions.forEach(option => {
            option.showFilter = false;
        });
        this.template.querySelector('c-heat-map-row-filters').updateRowFiltersWithAccount(this.rowFilterOptions);
    }
    
    handleSelectAndClearAll(event){
        let filterName = event.detail.filterName;
        let buttonClicked = event.detail.buttonClicked;

        this.rowFilterOptions = this.rowFilterOptions.map(rowItem => {
            if(rowItem.name === filterName){
                let updatedValue = rowItem.value.map(item => {
                    return { ...item, isChecked: buttonClicked === 'Select All' };
                });
                return { ...rowItem, value: updatedValue };
            }
            return rowItem;
        });
        
        if(filterName === 'account'){
            if(buttonClicked == 'Select All'){
                this.preferredAccounts = this.rowFilterOptions.filter(item => {
                    if(item.name === "account"){
                        return item.value;
                    }
                });
            }else if(buttonClicked == 'Clear All'){
                this.preferredAccounts = [];
            }
            this.template.querySelector('c-heat-map-data-table').handleSelectAndClearAll(buttonClicked);
        }
    }

    handleCloseBanner(event){
        this.showBanner = false;
    }

    handlePageLoad(event){
        let isReadOnly = event.detail;
        if(isReadOnly){
           	this.template.querySelector('.mainDiv').classList.add('overlayClass')
        }else{
        	this.template.querySelector('.mainDiv').classList.remove('overlayClass')
        }
    }
    
}