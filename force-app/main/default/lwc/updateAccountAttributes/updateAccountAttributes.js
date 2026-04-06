import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getIndustrySubcategoryPicklistValues from '@salesforce/apex/UpdateAccountAttributesController.getIndustrySubcategoryPicklistValues';
import getIndustryCategoryValues from '@salesforce/apex/UpdateAccountAttributesController.getIndustryCategoryValues';
import submitAccountAttributesForm from '@salesforce/apex/UpdateAccountAttributesController.submitAccountAttributesForm';
import searchAccounts from '@salesforce/apex/UpdateAccountAttributesController.searchAccounts';
import { getRecord } from 'lightning/uiRecordApi';

const ACCOUNT_TYPE_FIELD = 'Account.Type';

export default class UpdateAccountAttributes extends NavigationMixin(LightningElement) {
    @api recordId;

    accountType = '';
    selectedAttributes = [];
    industrySubcategoryPicklistValues = [];
    industryPicklistValues = [];
    selectedIndustryCategory = ''; // Track selected Industry Category for dependent picklist
    isSubmitting = false; // Track if form is being submitted

    // Website fields
    url = '';
    sfTicket = '';
    approver = '';

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_TYPE_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountType = data.fields.Type.value;
        } else if (error) {
            this.showToast('Error', 'Error fetching Account record: '+error, 'error');
        }
    }

    @wire(getIndustryCategoryValues)
    wiredIndustryCategoryValues({ error, data }) {
        if (data) {
            this.industryPicklistValues = data.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            this.showToast('Error', 'Error fetching Industry Category values: '+error, 'error');
        }
    }

    // Load Industry Subcategory values dynamically based on selected Industry
    loadIndustrySubcategoryValues() {
        if (this.selectedIndustryCategory) {
            getIndustrySubcategoryPicklistValues({ selectedIndustry: this.selectedIndustryCategory })
                .then(data => {
                    this.industrySubcategoryPicklistValues = data.map(item => ({
                        label: item.label,
                        value: item.value
                    }));
                })
                .catch(error => {
                    this.showToast('Error', 'Error fetching Industry Subcategory picklist values: '+error, 'error');
                    this.industrySubcategoryPicklistValues = [];
                });
        } else {
            // If no Industry selected, load all values
            getIndustrySubcategoryPicklistValues({ selectedIndustry: null })
                .then(data => {
                    this.industrySubcategoryPicklistValues = data.map(item => ({
                        label: item.label,
                        value: item.value
                    }));
                })
                .catch(error => {
                    this.showToast('Error', 'Error fetching Industry Subcategory picklist values: '+error, 'error');
                    this.industrySubcategoryPicklistValues = [];
                });
        }
    }

    connectedCallback() {
        // Load initial subcategory values
        this.loadIndustrySubcategoryValues();
    }

    // Computed property for submit button label
    get submitButtonLabel() {
        return this.isSubmitting ? 'Submitting...' : 'Submit';
    }

    // Hierarchy fields
    parentId = '';
    parentIdDisplay = '';
    overrideDetails = '';
    globalparentId = '';
    globalParentIdDisplay = '';
    overrideRequestor = '';
    overrideFlag = false;
    parentAccountOptions = [];
    globalParentAccountOptions = [];
    parentSearchTimeout;
    globalParentSearchTimeout;

    // Fortune/Forbes fields
    fortuneType = '';
    fortuneRank = '';
    fortuneMainSub = '';

    // Account Attributes fields
    selectedAccountAttributes = [];
    attributeOverrideValues = {};
    overrideSource = '';

    attributeOptions = [
        { label: 'Website', value: 'Website' },
        { label: 'Hierarchy', value: 'Hierarchy' },
        { label: 'Fortune/Forbes', value: 'Fortune/Forbes' },
        { label: 'Account Attributes', value: 'Account Attributes' }
    ];

    typeOptions = [
        { label: 'Fortune', value: 'Fortune' },
        { label: 'Forbes', value: 'Forbes' }
    ];

    mainSubOptions = [
        { label: 'Main', value: 'Main' },
        { label: 'Sub', value: 'Sub' }
    ];

    attributePicklistOptions = [
        { label: 'Annual Revenue', value: 'Annual Revenue' },
        { label: 'GU Revenue', value: 'GU Revenue' },
        { label: 'DUNS', value: 'DUNS' },
        { label: 'Industry Category', value: 'Industry Category' },
        { label: 'Industry Subcategory', value: 'Industry Subcategory' },
        { label: 'Out-of-Business Flag', value: 'Out-of-Business Flag' },
        { label: 'SIC Code', value: 'SIC Code' },
        { label: 'Tradestyle', value: 'Tradestyle' }
    ];

    outOfBusinessFlagOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    get isWebsiteSelected() {
        return this.selectedAttributes.includes('Website');
    }

    get isCustomerAccount() {
        return this.accountType === 'Customer';
    }

    get isSfTicketNoRequired() {
        return this.isWebsiteSelected && this.isCustomerAccount;
    }

    get isApproversNameRequired() {
        return this.isWebsiteSelected && this.isCustomerAccount;
    }

    get isHierarchySelected() {
        return this.selectedAttributes.includes('Hierarchy');
    }

    get isFortuneForbesSelected() {
        return this.selectedAttributes.includes('Fortune/Forbes');
    }

    get isAccountAttributesSelected() {
        return this.selectedAttributes.includes('Account Attributes');
    }

    get hasSelectedAccountAttributes() {
        return this.selectedAccountAttributes && this.selectedAccountAttributes.length > 0;
    }

    get isAnnualRevenueSelected() {
        return this.selectedAccountAttributes && this.selectedAccountAttributes.includes('Annual Revenue');
    }

    get showParentDropdown() {
        return this.parentAccountOptions && this.parentAccountOptions.length > 0;
    }

    get showGlobalParentDropdown() {
        return this.globalParentAccountOptions && this.globalParentAccountOptions.length > 0;
    }

    get attributeOverrideFieldsList() {
        return this.selectedAccountAttributes.map(attr => ({
            value: attr,
            label: `Override Value - ${attr}`,
            overrideValue: this.attributeOverrideValues[attr] || '',
            isIndustrySubcategory: attr === 'Industry Subcategory',
            isIndustryCategory: attr === 'Industry Category',
            isDUNS: attr === 'DUNS',
            isAnnualRevenue: attr === 'Annual Revenue',
            isGURevenue: attr === 'GU Revenue',
            isSICCode: attr === 'SIC Code',
            isOutOfBusinessFlag: attr === 'Out-of-Business Flag'
        }));
    }

    handleAttributeChange(event) {
        this.selectedAttributes = event.detail.value;

        if (!this.isWebsiteSelected) {
            this.url = '';
            this.sfTicket = '';
            this.approver = '';
        }

        if (!this.isHierarchySelected) {
            this.parentId = '';
            this.parentIdDisplay = '';
            this.overrideDetails = '';
            this.globalparentId = '';
            this.globalParentIdDisplay = '';
            this.overrideRequestor = '';
            this.overrideFlag = false;
            this.parentAccountOptions = [];
            this.globalParentAccountOptions = [];
        }

        if (!this.isFortuneForbesSelected) {
            this.fortuneType = '';
            this.fortuneRank = '';
            this.fortuneMainSub = '';
        }

        if (!this.isAccountAttributesSelected) {
            this.selectedAccountAttributes = [];
            this.attributeOverrideValues = {};
            this.overrideSource = '';
        }
    }

    handleUrlChange(event) {
        this.url = event.detail.value;
    }

    handleSfTicketChange(event) {
        this.sfTicket = event.detail.value;
    }

    handleApproverChange(event) {
        this.approver = event.detail.value;
    }

    handleParentIdChange(event) {
        event.preventDefault();
        const value = event.currentTarget.dataset.value;
        if (value) {
            // Find the selected option before clearing the array
            const selectedOption = this.parentAccountOptions.find(opt => opt.value === value);
            this.parentId = value;
            this.parentIdDisplay = selectedOption ? selectedOption.label : '';
            this.parentAccountOptions = [];
        }
    }

    handleParentAccountSearch(event) {
        const searchTerm = event.target.value;
        this.parentIdDisplay = searchTerm;

        // Clear previous timeout
        if (this.parentSearchTimeout) {
            clearTimeout(this.parentSearchTimeout);
        }

        if (searchTerm && searchTerm.length > 0) {
            // Add delay to avoid too many API calls
            this.parentSearchTimeout = setTimeout(() => {
                searchAccounts({ searchTerm: searchTerm })
                    .then(result => {
                        this.parentAccountOptions = result;
                    })
                    .catch(error => {
                        this.showToast('Error', 'Error searching accounts: '+error, 'error');
                    });
            }, 300);
        } else {
            this.parentAccountOptions = [];
        }
    }

    handleOverrideDetailsChange(event) {
        this.overrideDetails = event.detail.value;
    }

    handleGlobalParentIdChange(event) {
        event.preventDefault();
        const value = event.currentTarget.dataset.value;
        if (value) {
            // Find the selected option before clearing the array
            const selectedOption = this.globalParentAccountOptions.find(opt => opt.value === value);
            this.globalparentId = value;
            this.globalParentIdDisplay = selectedOption ? selectedOption.label : '';
            this.globalParentAccountOptions = [];
        }
    }

    handleGlobalParentAccountSearch(event) {
        const searchTerm = event.target.value;
        this.globalParentIdDisplay = searchTerm;

        // Clear previous timeout
        if (this.globalParentSearchTimeout) {
            clearTimeout(this.globalParentSearchTimeout);
        }

        if (searchTerm && searchTerm.length > 0) {
            // Add delay to avoid too many API calls
            this.globalParentSearchTimeout = setTimeout(() => {
                searchAccounts({ searchTerm: searchTerm })
                    .then(result => {
                        this.globalParentAccountOptions = result;
                    })
                    .catch(error => {
                        this.showToast('Error', 'searching accounts: '+error, 'error');
                    });
            }, 300);
        } else {
            this.globalParentAccountOptions = [];
        }
    }

    handleClearParentId() {
        this.parentId = '';
        this.parentIdDisplay = '';
        this.parentAccountOptions = [];
    }

    handleClearGlobalParentId() {
        this.globalparentId = '';
        this.globalParentIdDisplay = '';
        this.globalParentAccountOptions = [];
    }

    handleOverrideRequestorChange(event) {
        this.overrideRequestor = event.detail.value;
    }

    handleOverrideFlagChange(event) {
        this.overrideFlag = event.detail.checked === true;
    }

    handleFortuneTypeChange(event) {
        this.fortuneType = event.detail.value;
    }

    handleFortuneRankChange(event) {
        this.fortuneRank = event.detail.value;
    }

    handleFortuneMainSubChange(event) {
        this.fortuneMainSub = event.detail.value;
    }

    handleAccountAttributesChange(event) {
        this.selectedAccountAttributes = event.detail.value;

        const newOverrideValues = {};
        this.selectedAccountAttributes.forEach(attr => {
            newOverrideValues[attr] = this.attributeOverrideValues[attr] || '';
        });
        this.attributeOverrideValues = newOverrideValues;
    }

    handleAttributeOverrideValueChange(event) {
        const attribute = event.target.dataset.attribute;
        const value = event.detail.value;
        this.attributeOverrideValues = { ...this.attributeOverrideValues, [attribute]: value };

        // If Industry Category changed, reload Industry Subcategory values
        if (attribute === 'Industry Category') {
            this.selectedIndustryCategory = value;
            this.loadIndustrySubcategoryValues();

            // Clear the Industry Subcategory value since the options changed
            if (this.attributeOverrideValues['Industry Subcategory']) {
                this.attributeOverrideValues = {
                    ...this.attributeOverrideValues,
                    'Industry Subcategory': ''
                };
            }
        }
    }

    handleOverrideSourceChange(event) {
        this.overrideSource = event.detail.value;
        this.attributeOverrideValues = { ...this.attributeOverrideValues, 'Override Source': this.overrideSource };
    }

    handleSubmit() {
        // Prevent multiple submissions
        if (this.isSubmitting) {
            return;
        }

        // Validate all lightning-input components
        const allValid = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.checkValidity();
        }, true);

        const allComboboxValid = [...this.template.querySelectorAll('lightning-combobox')].reduce((validSoFar, comboCmp) => {
            return validSoFar && comboCmp.checkValidity();
        }, true);

        const allRecordPickerValid = [...this.template.querySelectorAll('lightning-record-picker')].reduce((validSoFar, pickerCmp) => {
            return validSoFar && pickerCmp.checkValidity();
        }, true);

        const allDualListboxValid = [...this.template.querySelectorAll('lightning-dual-listbox')].reduce((validSoFar, dualCmp) => {
            return validSoFar && dualCmp.checkValidity();
        }, true);

        if (!allValid || !allComboboxValid || !allRecordPickerValid || !allDualListboxValid) {
            // Report validity to show error messages on fields
            [...this.template.querySelectorAll('lightning-input')].forEach(inputCmp => {
                inputCmp.reportValidity();
            });
            [...this.template.querySelectorAll('lightning-combobox')].forEach(comboCmp => {
                comboCmp.reportValidity();
            });
            [...this.template.querySelectorAll('lightning-record-picker')].forEach(pickerCmp => {
                pickerCmp.reportValidity();
            });
            [...this.template.querySelectorAll('lightning-dual-listbox')].forEach(dualCmp => {
                dualCmp.reportValidity();
            });

            this.showToast('Validation Error', 'Please fill in all required fields', 'error');
            return;
        }

        // Disable submit button
        this.isSubmitting = true;

        // Transform Out-of-Business Flag value from Yes/No to TRUE/FALSE/blank
        const transformedAttributeOverrideValues = { ...this.attributeOverrideValues };
        if (transformedAttributeOverrideValues['Out-of-Business Flag']) {
            const oobValue = transformedAttributeOverrideValues['Out-of-Business Flag'];
            if (oobValue === 'Yes') {
                transformedAttributeOverrideValues['Out-of-Business Flag'] = 'TRUE';
            } else if (oobValue === 'No') {
                transformedAttributeOverrideValues['Out-of-Business Flag'] = 'FALSE';
            }
        }

        const formData = {
            selectedAttributes: this.selectedAttributes,
            website: {
                flag : this.isWebsiteSelected,
                url: this.url,
                sfTicket: this.sfTicket,
                approver: this.approver
            },
            hierarchy: {
                flag : this.isHierarchySelected,
                parentId: this.parentId,
                overrideDetails: this.overrideDetails,
                globalparentId: this.globalparentId,
                overrideRequestor: this.overrideRequestor,
                overrideFlag: this.overrideFlag
            },
            fortuneForbes: {
                flag : this.isFortuneForbesSelected,
                fortuneType: this.fortuneType,
                fortuneRank: this.fortuneRank,
                fortuneMainSub: this.fortuneMainSub
            },
            accountAttributes: {
                flag : this.isAccountAttributesSelected,
                selectedAccountAttributes: this.selectedAccountAttributes,
                attributeOverrideValues: transformedAttributeOverrideValues
            }
        };

        submitAccountAttributesForm({ accountId: this.recordId, formData: formData })
            .then(() => {
                this.showToast('Success', 'Override is successful', 'success');
                // Keep button disabled on success - don't re-enable
                // Close the modal/popup after a short delay to allow toast to display
                setTimeout(() => {
                    // Dispatch close event for modal
                    this.dispatchEvent(new CustomEvent('close'));
                    // Navigate back to the record
                    this.navigateToRecord(this.recordId);
                }, 1500);
            })
            .catch(error => {
                // Re-enable submit button on failure
                this.isSubmitting = false;
                this.showToast('Error', error.body.message || 'An error occurred while submitting the form', 'error');
            });
    }

    /**
     * @description Generic method to show toast notifications
     * @param title The title of the toast
     * @param message The message to display
     * @param variant The variant (success, error, warning, info)
     */
    showToast(title, message, variant = 'info') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    /**
     * @description Generic method to navigate to a record page
     * @param recordId The record ID to navigate to
     * @param actionName The action to perform (view, edit, etc.)
     */
    navigateToRecord(recordId, actionName = 'view') {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: actionName
            }
        });
    }

    handleCancel() {
        // Reset form fields
        this.selectedAttributes = [];
        this.url = '';
        this.sfTicket = '';
        this.approver = '';
        this.parentId = '';
        this.parentIdDisplay = '';
        this.overrideDetails = '';
        this.globalparentId = '';
        this.globalParentIdDisplay = '';
        this.overrideRequestor = '';
        this.overrideFlag = false;
        this.parentAccountOptions = [];
        this.globalParentAccountOptions = [];
        this.fortuneType = '';
        this.fortuneRank = '';
        this.fortuneMainSub = '';
        this.selectedAccountAttributes = [];
        this.attributeOverrideValues = {};
        this.overrideSource = '';

        // Close the modal/popup
        this.dispatchEvent(new CustomEvent('close'));

        // Navigate back to the record
        this.navigateToRecord(this.recordId);
    }
}