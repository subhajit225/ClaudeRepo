import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getAccounts from '@salesforce/apex/CeOperationsDashboardController.getAccounts';
import getAccountOptions from '@salesforce/apex/CeOperationsDashboardController.getAccountOptions';
import getCEMOptions from '@salesforce/apex/CeOperationsDashboardController.getCEMOptions';
import getPicklistValues from '@salesforce/apex/CeOperationsDashboardController.getPicklistValues';
import getMetrics from '@salesforce/apex/CeOperationsDashboardController.getMetrics';
import { getColumns, normalizeRecordData, getColorScheme, reorderKeyToLast,getPriorityGrouping } from "c/ceOperationsUtil";
import Id from "@salesforce/user/Id";
const DELAY = 300;
export default class CeOperationsDashboard extends NavigationMixin(LightningElement) {
    constructor() {
        super();
        this.setDefaultCEM('constructor');
    }
    F_ACCOUNT_PREFERENCE = 'Account_Preference__c';
    FIELDS = [
        'Account_SAM__r.Name',
        'Name',
        'Account_Preference__c',
        'CX_Summary_Status__c',
        'CX_Challenges__c',
        'CX_Customer_Health__c'
    ];
    name = '';
    @track showOptions = {
        'cem-change': true,
        'name-change': true,
        'preference-change': true
    };

    @track selectedAccountPeferences = [];
    @track selectedAccountNames = [];
    @track selectedAccountCEMs = [];
    @track filteredAccounts = [];
    accountPreferences = [];
    @track accountPreferenceOptions = [];

    @track accountOptions = [];
    @track cemOptions = [];
    @track objectInfo;
    @track totalClosedCases;
    @track totalOpenCases;
    @track isLoading = {
        accountPreferenceOptions: true,
        accountOptions: true,
        cemOptions: true,
        datatable: true,
        open_cases: true,
        closed_cases: true,
        tcv_12_priority: true,
        tcv_12: true,
        jiras: true,
        rfes: true,
        avg_ttr_12: true,
        avg_ttr_12_priority: true,
        open_p1: true
    };
    @track searchaccountOptions = '';
    @track searchcemOptions = '';
    @track wiredSearchaccountOptions = '';
    @track wiredSearchcemOptions = '';
    @track popoverVisible = false;
    wiredCasesMetrics
    version;
    @track metrics = {
        'open_cases': 'N/A',
        'closed_cases': 'N/A',
        'tcv_12_priority': 'N/A',
        'tcv_12': 'N/A',
        'jiras': 'N/A',
        'rfes': 'N/A',
        'avg_ttr_12': 'N/A',
        'avg_ttr_12_priority': 'N/A',
        'open_p1': 'N/A'
    };
    oneTimeOperation = false;
    userId = Id;
    wiredCEMOptionsSwitch = 0;
    wiredAccountOptionsSwitch = 0;
    optionsCallContext = '';
    get columns() {
        return getColumns('accounts');
    }
    str(obj) {
        return obj ? JSON.parse(JSON.stringify(obj)) : 'null'
    }
    logState(name, data) {
    }
    get popoverClass() {
        return `slds-popover slds-nubbin_left-top ${this.popoverVisible ? 'slds-show' : 'slds-hide'}`;
    }

    togglePopover() {
        this.popoverVisible = !this.popoverVisible;
    }
    setDefaultCEM(log) {
        this.logState('setDefaultCEM', log)
        if (!this.oneTimeOperation) {
            this.selectedAccountCEMs = [Id]
            this.oneTimeOperation = true;
        }
    }

    refreshMetrics() {
        this.logState('refreshMetrics')
        let metrics = ['open_p1', 'open_cases', 'jiras', 'rfes', 'tcv_12_priority'];
        metrics.forEach(m => this.callGetMetrics(m));
    }

    chartConfiguration
    prepareChart(data, error) {
        if (error) {
            this.chartConfiguration = undefined;
        } else if (data) {
            let value = [];
            let chartLabel = [];
            let bgColors = []
            let chartData = data;
            const groupedPriorities = {};
            chartData.forEach(d => {
                let groupedKey = getPriorityGrouping(d.Priority);
                if(groupedPriorities.hasOwnProperty(groupedKey)){
                    groupedPriorities[groupedKey]+=d.expr0;
                } else {
                    groupedPriorities[groupedKey]=d.expr0;
                }
            });
            var sortedGroupPiorities = {}
            Object.keys(groupedPriorities).sort().map(cl=> { sortedGroupPiorities[cl]=groupedPriorities[cl]})
            sortedGroupPiorities = reorderKeyToLast(sortedGroupPiorities, 'None')
            value = Object.values(sortedGroupPiorities);
            chartLabel = Object.keys(sortedGroupPiorities)
            bgColors = Object.keys(sortedGroupPiorities).map(k=>getColorScheme(k));            
            this.chartConfiguration = {
                type: 'horizontalBar',
                data: {
                    datasets: [{
                        label: 'Count',
                        data: value,
                        backgroundColor: bgColors,
                        
                    }
                    ],
                    labels: chartLabel,
                },
                options: {
                    legend: {
                        display: false
                    },
                    scales: {
                        xAxes: [{
                        ticks: {
                            beginAtZero: true,
                            min: 0
                        }    
                        }]
                    },
                },
            };
        }
    }
    callGetMetrics(metric) {
        this.isLoading[metric] = true;
        getMetrics({
            preference: this.selectedAccountPeferences,
            name: this.selectedAccountNames,
            cem: this.selectedAccountCEMs,
            metric: metric,
            fullData: false
        })
            .then(data => {
                this.logState('getMetrics', data)
                if (metric == 'tcv_12_priority') {
                    this.prepareChart(data.data, null)
                } else {
                    this.metrics[metric] = data["data"][0].expr0;
                }
                this.isLoading[metric] = false;
            })
            .catch(error => {
                this.isLoading[metric] = false;
                this.metrics[metric] = 'N/A'
                console.error('CEOD201', error);
            });
    }

    @wire(getCEMOptions, {
        context: '$optionsCallContext',
        defaults: '$selectedAccountCEMs',
        preference: '$selectedAccountPeferences',
        name: '$selectedAccountNames',
        search: '$wiredSearchcemOptions',
        wiredSwitch: '$wiredCEMOptionsSwitch'
    })
    wiredCEMOptions(result) {
        this.handleWireResult(result, 'cemOptions', this.cemOptions, this.selectedAccountCEMs);
    }

    @wire(getAccountOptions, {
        context: '$optionsCallContext',
        defaults: '$selectedAccountNames',
        preference: '$selectedAccountPeferences',
        cem: '$selectedAccountCEMs',
        search: '$wiredSearchaccountOptions',
        wiredSwitch: '$wiredAccountOptionsSwitch'
    })
    wiredAccountOptions(result) {
        this.handleWireResult(result, 'accountOptions', this.accountOptions, this.selectedAccountNames);

    }
    handleWireResult(result, loadingKey, options, selectedOptions) {
        this.isLoading[loadingKey] = !result.data && !result.error;
        if (result.data) {
            options.splice(0, options.length)
            const uniqueIdsSet = new Set();
            options.push(
                ...result.data.reduce((uniqueOptions, option) => {
                    if (!uniqueIdsSet.has(option.Id)) {
                        uniqueIdsSet.add(option.Id);
                        uniqueOptions.push({
                            label: option.Name,
                            value: option.Id
                        });
                    }
                    return uniqueOptions;
                }, [])
            );
            this.updateSelectedOptions(options, selectedOptions);

            let elements = this.template.querySelectorAll('c-ce-multi-select-pick-list');

            if (elements) {
                elements.forEach(element => {
                    if (this.eventType == 'search') {
                        if (this.name == element.name) {
                            element.refresh(this.name, JSON.parse(JSON.stringify(Boolean(this.showOptions[element.name]))));
                        }
                    } else {
                        element.refresh(this.name, JSON.parse(JSON.stringify(Boolean(this.showOptions[element.name]))));
                    }
                });
            }
        }
        else if (result.error) {
            console.error(`wire error for ${loadingKey}:`, result.error);
        }
    }

    @wire(getAccounts, {
        fields: '$FIELDS',
        preference: '$selectedAccountPeferences',
        name: '$selectedAccountNames',
        cem: '$selectedAccountCEMs'
    })
    wiredAccounts({
        error,
        data
    }) {
        this.logState('getAccounts')
        this.isLoading.datatable = !data && !error;

        if (data) {
            this.refreshMetrics();
            this.filteredAccounts = normalizeRecordData(data, 'accounts')
            this.setAccountPeferenceOptions(this.filteredAccounts);
        }
        else if (error) {
        }
    }
    getAccountPreferencePicklistValuesCalled = false;
    async setAccountPeferenceOptions(accounts) {
        if (!(this.selectedAccountNames.length || this.selectedAccountCEMs.length)) {
            this.accountPreferenceOptions = JSON.parse(JSON.stringify(this.accountPreferences));
        }
        else {
            let availablePreferences = new Set();
            accounts.forEach(a => {
                if (a[this.F_ACCOUNT_PREFERENCE]) {
                    const values = a[this.F_ACCOUNT_PREFERENCE].split(';').map(v => v.trim());
                    values.forEach(v => {
                        if (v) {
                            availablePreferences.add(v);
                        }
                    });
                }
            });
            if (!this.getAccountPreferencePicklistValuesCalled) {
                try {
                    const data = await getPicklistValues({ objectName: 'Account', fieldName: this.F_ACCOUNT_PREFERENCE });
                    if (data) {
                        this.accountPreferences = data;
                        this.getAccountPreferencePicklistValuesCalled = true;
                    }
                } catch (error) {
                    console.error('CEOD202', error);
                }
            }
            this.accountPreferenceOptions = this.accountPreferences.filter(p => availablePreferences.has(p.value));
        }

        this.updateSelectedOptions(this.accountPreferenceOptions, this.selectedAccountPeferences);

        this.template.querySelectorAll('c-ce-multi-select-pick-list').forEach(element => {
            if (element.name == 'preference-change') {
                setTimeout(() => {
                    element.refresh(this.name, JSON.parse(JSON.stringify(Boolean(this.showOptions[element.name]))));
                }, 0)
            }
        });

    }

    updateSelectedOptions(options, selectedOptions) {
        this.logState('updateSelectedOptions')
        const availableOptions = new Set(options.map(o => o.value));
        let hasAllTheOptions = selectedOptions.every(item => availableOptions.has(item));
        if (selectedOptions.length && !hasAllTheOptions) {
            let remainingOptions = selectedOptions.filter(value => availableOptions.has(value));
            selectedOptions.length = 0;
            selectedOptions.push(...remainingOptions);
        }
    }

    callHandleAction(action, value) {
        this.logState('callHandleAction')
        this.isLoading.datatable = true;
        this.handleAction({
            target: {
                dataset: {
                    action: action,
                    value: value
                }
            }
        });
    }
    handlePreferenceChange(event) {
        this.name = event.detail.name;
        this.callHandleAction('preference-change', event.detail.value);
    }
    handleAccountNameChange(event) {
        this.name = event.detail.name;
        this.callHandleAction('name-change', event.detail.value);
    }
    handleCemChange(event) {
        this.name = event.detail.name;
        this.callHandleAction('cem-change', event.detail.value);
    }
    setLoadingOnFilters(filter, isLoading, byPassFilter) {
        this.logState('setLoadingOnFilters')
        if (byPassFilter || filter != 'preference-change') {
            this.isLoading.accountPreferenceOptions = isLoading;
        }
        if (byPassFilter || filter != 'name-change') {
            this.isLoading.accountOptions = isLoading;
        }
        if (byPassFilter || filter != 'cem-change') {
            this.isLoading.cemOptions = isLoading;
        }
        this.isLoading.open_cases = true;
        this.isLoading.closed_cases = true;
    }

    handleAction(event) {
        this.eventType = 'select'
        this.logState('handleAction', event)
        const action = event.target.dataset.action;
        this.optionsCallContext = action;
        let value = event.target.dataset.value;

        switch (action) {
            case 'preference-change':
                this.selectedAccountPeferences = undefined;
                this.selectedAccountPeferences = value;
                if (!(Array.isArray(value) && value.length)) {
                    this.setAccountPeferenceOptions(this.filteredAccounts);
                }
                break;
            case 'name-change':
                this.selectedAccountNames = undefined;
                this.selectedAccountNames = value;
                break;
            case 'cem-change':
                this.selectedAccountCEMs = undefined;
                this.selectedAccountCEMs = value;
                break;
            default:
                break;
        }
        this.setLoadingOnFilters(action, true, false)
    }

    assignWithDelay(name, searchKey) {
        this.delayTimeout = setTimeout(() => {

            switch (name) {
                case 'name-change':
                    this.wiredSearchaccountOptions = searchKey;
                    break;
                case 'cem-change':
                    this.wiredSearchcemOptions = searchKey;
                    break;
            }
        }, DELAY);
    }
    eventType;
    handleSearch(event) {
        this.logState('handleSearch', event.detail)
        let searchString = event.detail.value;
        this.name = event.detail.name;
        this.eventType = event.detail.type;

        this.showOptions[event.detail.name] = event.detail.showOptions
        this.optionsCallContext = event.detail.name;
        this.assignWithDelay(event.detail.name, searchString);
    }

    handleNavigateToReports(event) {
        this.logState('handleNavigateToReports', event)
        let cDef = 'c:ceGenericReport';
        let groupByValues = this.chartConfiguration ? this.chartConfiguration.data.labels : [];
        let compDefinition = {
            componentDef: cDef,
            attributes: {
                'selectedAccountPeferences': this.selectedAccountPeferences,
                'selectedAccountNames': this.selectedAccountNames,
                'selectedAccountCEMs': this.selectedAccountCEMs,
                'name': event.detail.name,
                'label': event.detail.label,
                'groupByValues': groupByValues
            }
        };

        let encodedCompDef = btoa(JSON.stringify(compDefinition));
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: "/one/one.app#" + encodedCompDef
            }
        });
    }
}