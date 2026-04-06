import { LightningElement, api, track, wire } from 'lwc';
import getFieldSetFields from '@salesforce/apex/CS_CustomFieldController.getFieldNames';
import createRiskProfile from '@salesforce/apex/CS_RiskProfileController.createRiskProfile';
import updateRiskProfile from '@salesforce/apex/CS_RiskProfileController.updateRiskProfile';
import getProductPillarInformation from '@salesforce/apex/CS_RiskProfileController.getProductPillarInformation';

import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RetentionCaseGraphQueries from './retentionCaseGraphQueries.js'

import { graphql, refreshGraphQL } from 'lightning/uiGraphQLApi'
import { IsConsoleNavigation, EnclosingTabId } from 'lightning/platformWorkspaceApi';

import { loadStyle } from 'lightning/platformResourceLoader';
import DobuleScrollBarFix from '@salesforce/resourceUrl/DobuleScrollBarFix';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';


let graph;
const REQUIRED = {
    CREATE: ['Risk_Type__c', 'Primary_Risk_Reason__c', 'Secondary_Risk_Reason__c', 'Risk_Reason_Additional_Comments__c', 'Risk_Level__c'],
    EDIT: []
}
export default class Rrm_RiskProfileCreation extends NavigationMixin(LightningElement) {

    @api recordId;
    @api calledFromAura = false;
    @track fields = [];
    @api columns = 2;
    @track isLoading = true;
    isFormValidated = true;

    @api fieldSetName = 'Risk_Profile_Creation';
    selectedPDMFeatures;
    selectedRiskWatchers;
    selectedEntitlements;

    isEntitlementRequired = false;
    isAdoptionRisk = false;
    isComponentRequired = false;


    get selectedEntitlementIds() {
        return this.selectedEntitlements?.map(se => se.id);
    }

    get entitlementIds() {
        return this.selectedEntitlements?.map(se => se.id) || [];
    }

    get selectedPDMFeatureIds() {
        return this.selectedPDMFeatures?.map(se => se.id) || [];
    }

    _originalState = {};

    connectedCallback() {
        Promise.all([
            loadStyle(this, DobuleScrollBarFix),
        ]).then(() => {
            this.rendered = true;
        });
    }

    constructor() {
        super();
        graph = new RetentionCaseGraphQueries();
    }

    get dataLoaded() {
        return Boolean(this.fieldSetFields?.data || this.fieldSetFields?.error);
    }

    get fieldNames() {
        return this.fields.map(f => f.fieldName);
    }

    get quickActionHeader() {
        return (this.isEditMode ? 'Edit Risk Profile' : 'Create Risk Profile');
    }
    get fieldsSTR() {
        return JSON.stringify(this.fieldSetFields);
    }

    get riskProfileRecordId() {
        return this.recordId ? (this.recordId.startsWith('001') ? null : this.recordId) : null;
    }

    get isEditMode() {
        return !this.recordId?.startsWith('001');
    }

    get accountId() {
        return this.isEditMode ? this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.Account__c.value : this.recordId;
    }

    get entitlementLookupFx() {
        return this.riskOrigin == 'Opportunity' ? 'opportunityEntitlements' : 'accountEntitlements';
    }
    get pdmLookupFx() {
        return this.riskOrigin == 'Opportunity' ? 'opportunityPDMs' : 'accountPDMs';
    }
    get fieldSet() {
        return this.isEditMode ? 'Edit_Risk_Profile' : 'New_Risk_Profile';
    }

    isObjectUpdateable(graphqlResult, apiName) {
        return (graphqlResult.data.uiapi.objectInfos.find(obj => obj.ApiName === apiName) || {}).updateable || false;
    }
    isObjectCreatable(graphqlResult, apiName) {

        return (graphqlResult.data.uiapi.objectInfos.find(obj => obj.ApiName === apiName) || {}).createable || false;
    }

    get arePdmsNotCreateable() {
        return !this.isObjectCreatable(this.graphqlResult, 'Risk_Profile_Component__c');
    }

    get areWatchersNotCreateable() {
        return !this.isObjectCreatable(this.graphqlResult, 'Risk_Profile_Watcher__c');
    }

    get arePdmsNotAccessible() {
        return this.arePdmsNotCreateable;
    }
    get areWatchersNotAccessible() {
        return this.areWatchersNotCreateable;
    }
    get noEntitlementsSelected() {
        return this.arePdmsNotAccessible || !Boolean(this.selectedEntitlements?.length);
    }
    get graphVariables() {
        return {
            recordId: this.riskProfileRecordId,
        };
    }
    setFieldVisibility(fieldName, isVisible) {
        this.fields.forEach(field => {
            if (field.fieldName == fieldName) {
                field.isVisible = isVisible;
            }
        });
    }
    setFieldValue(fieldName, value) {
        this.fields.forEach(field => {
            if (field.fieldName == fieldName) {
                field.value = value;
            }
        });
    }
    setFieldDisability(fieldName, isDisabled) {
        this.fields.forEach(field => {
            if (field.fieldName == fieldName) {
                field.disabled = isDisabled;
            }
        });
    }
    get riskProfileCreatorId() {
        return this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges.length ?
            this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0]?.node.CreatedById.value : null;
    }
    graphqlResult
    @wire(graphql, {
        query: graph.getGraphQuery(),
        variables: '$graphVariables'
    })
    graphqlQueryResult(result) {
        this.graphqlResult = result
        console.log('this.graphqlResult', this.graphqlResult);

        if (this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges.length) {
            this.riskOrigin = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.Risk_Origin__c.value;
            let dntTrigger = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.Do_Not_Trigger__c.value;
            let dntReason = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.DNT_Reason__c.value;
            let riskType = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0]?.node.Risk_Type__c.value;
            let creatorId = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0]?.node.CreatedById.value;
            let primaryRiskReason = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0]?.node.Primary_Risk_Reason__c.value;

            this.isEntitlementRequired = riskType == 'Entitlement Risk' || primaryRiskReason == 'Adoption';
            this.isAdoptionRisk = primaryRiskReason == 'Adoption';

            if (dntTrigger) {
                this.setFieldVisibility('DNT_Reason__c', true);
            }
            if (dntReason) {
                this.setFieldVisibility('DNT_Snooze__c', dntReason == 'Snooze');
            }
            /*
            if(this.isEditMode && creatorId != CurrentUserId) {
                setTimeout(() => {
                    this.setFieldDisability('Risk_Reason_Additional_Comments__c', true);
                }, 0);
            }
            */

            this.selectedEntitlements = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.Risk_Profile_Entitlements__r.edges.map(edge => ({
                id: edge.node.Entitlement__r.Id,
                title: edge.node.Entitlement__r.Name.value,
                recordId: edge.node.Id
            })) || [];

            this.selectedRiskWatchers = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.Risk_Profile_Watchers__r.edges.map(edge => ({
                id: edge.node.Watcher__r.Id,
                title: edge.node.Watcher__r.Name.value,
                recordId: edge.node.Id
            }));
            this.selectedPDMFeatures = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.Risk_Profile_Components__r.edges.map(edge => ({
                id: edge.node.Bundle_Components_Allocation__r.Id,
                //title: edge.node.PDM_Feature__r.Feature__c.value + ' (' + edge.node.Entitlement__c?.value + ')' + ' (' + edge.node.Status__c.value + ')',
                title: edge.node.Bundle_Components_Allocation__r?.Component_sku_Parsed__c?.value,
                recordId: edge.node.Id,
                relatedRecordId: edge.node.Entitlement__r?.Id
            }));

            this._originalState.productFeatures = this.selectedPDMFeatures;
            this._originalState.watchers = this.selectedRiskWatchers;
            this._originalState.entitlements = this.selectedEntitlements;
        }
        this.errors = this.graphqlResult.errors;
    }


    get graphQLDataLoaded() {
        return this.graphqlResult && (this.graphqlResult?.data || this.graphqlResult?.error);
    }

    fieldSetFields;

    @wire(getFieldSetFields, { operation: '$fieldSet', objectApiName: 'Risk_Profile__c' })
    wiredFieldSetFields(wiredData) {
        this.fieldSetFields = wiredData;
        const { data, error } = this.fieldSetFields;
        if (data) {
            this.processFields(data);
        } else if (error) {
            console.error('Error fetching fieldset fields:', error);
        }
    }

    processFields(fields) {
        this.fields = fields.map(f => {
            let fieldName = f,
                value, disabled = false,
                isVisible = true,
                required = REQUIRED.CREATE.includes(fieldName);

            if (fieldName == 'Account__c') {
                if (!this.isEditMode) {
                    value = this.accountId;
                }
                disabled = true;
            }
            if (['Product_Pillar_1_Component__c', 'Product_Pillar_2_Component__c', 'Risk_Origin__c'].includes(fieldName)) {
                disabled = true;
            }
            /*
            if(fieldName == 'Risk_Reason_Additional_Comments__c' && this.isEditMode  && this.riskProfileCreatorId == CurrentUserId) {
                this.setFieldDisability('Risk_Reason_Additional_Comments__c', true)
            }
            */

            return { fieldName, value, disabled, isVisible, required }
        });

        if (this.isEditMode) {
            let dntTrigger = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.Do_Not_Trigger__c.value;
            let dntReason = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0].node.DNT_Reason__c.value;
            this.setFieldVisibility('DNT_Reason__c', Boolean(dntTrigger));
            this.setFieldVisibility('DNT_Snooze__c', dntReason == 'Snooze');
        }
        this.setFieldVisibility('Product_Pillar_1_Component__c', this.selectedEntitlementIds?.length);
        this.setFieldVisibility('Product_Pillar_2_Component__c', this.selectedEntitlementIds?.length);
    }

    get columnClass() {
        return `slds-col slds-size_1-of-${this.columns} slds-p-around_x-small`;
    }

    get extendedColumnClass() {
        return `slds-col slds-size_1-of-1 slds-p-around_x-small`
    }
    extractKeyValueAttributes(inputObject) {
        if (!inputObject) return {};
        let result = {};
        let allowedKeys = this.fieldNames;
        for (const key in inputObject) {
            if (inputObject.hasOwnProperty(key)) {
                if (!key.endsWith('__r') && inputObject[key].value !== null && allowedKeys.includes(key)) {
                    result[key] = inputObject[key].value;
                }
            }
        }
        return result;
    }

    riskOrigin;
    handleLoad(event) {
        this.isLoading = false;
    }
    @wire(getProductPillarInformation, { entitlementIds: '$entitlementIds', componentIds: '$selectedPDMFeatureIds' })
    wiredProductPillarInformation(result) {

        if (result.error || !result.data) {
            return;
        }
        this.isComponentRequired = this.isEntitlementRequired && result.data.hasComponent;
        if (!this.isComponentRequired && this.refs?.productFeatureLookup) {
            this.refs.productFeatureLookup.errors = [];
        }

        // if (this.isEntitlementRequired) {
        //     this.isComponentRequired = result.data.hasComponent;
        //     if (!result.data.hasComponent) {
        //         this.isComponentRequired = false;
        //         this.refs.productFeatureLookup.errors = [];
        //     }
        // } else {
        //     this.isComponentRequired = false;
        // }
        let productPillar1s = result.data.pillarInfoList.map(pdm => pdm.pillar1);
        let productPillar2s = result.data.pillarInfoList.map(pdm => pdm.pillar2);
        this.fields.forEach(field => {
            if (field.fieldName == 'Product_Pillar_1_Component__c') {
                this.setFieldValue(field.fieldName, productPillar1s.join('\n'));
                this.setFieldVisibility(field.fieldName, this.selectedEntitlementIds?.length);
            }
            if (field.fieldName == 'Product_Pillar_2_Component__c') {
                this.setFieldValue(field.fieldName, productPillar2s.join('\n'));
                this.setFieldVisibility(field.fieldName, this.selectedEntitlementIds?.length);
            }
        });
    }
    handleFieldChange(event) {
        this.error = undefined;
        switch (event.target?.fieldName) {
            case 'Entitlement__c':
                this.refs.productFeatureLookup.setLookupFxParam({ 'Entitlement__c': event.detail.value[0] });
                break;
            case 'Risk_Type__c':
                const primaryRiskReason = this.template.querySelector('[data-field="Primary_Risk_Reason__c"]')?.value;
                this.isEntitlementRequired = event.detail.value == 'Entitlement Risk' || primaryRiskReason == 'Adoption' ? true : false;
                this.isComponentRequired = this.isEntitlementRequired;
                this.isAdoptionRisk = primaryRiskReason == 'Adoption' ? true : false;
                let entitlementValidity = this.isEntitlementRequired ? this.selectedEntitlementIds?.length : true;
                if (entitlementValidity) {
                    this.refs.entitlementLookup.errors = [];
                    this.refs.productFeatureLookup.errors = [];
                }
                break;
            case 'Opportunity__c':
                [...this.template.querySelectorAll('c-cs-multi-select-lookup')].forEach(lkup => {
                    lkup.setLookupFxParam({ Opportunity__c: event.detail.value });
                })
                break;
            case 'Do_Not_Trigger__c':
                let dnt = Boolean(event.detail.value);
                this.setFieldValue('DNT_Reason__c', null);
                this.setFieldVisibility('DNT_Reason__c', dnt);
                if (!dnt) {
                    this.setFieldValue('DNT_Snooze__c', null);
                    this.setFieldVisibility('DNT_Snooze__c', dnt);
                }

                break;
            case 'DNT_Reason__c':
                this.setFieldValue('DNT_Snooze__c', null);
                this.setFieldVisibility('DNT_Snooze__c', event.detail.value == 'Snooze');
                break;
            case 'Primary_Risk_Reason__c':
                const riskType = this.template.querySelector('[data-field="Risk_Type__c"]')?.value;
                this.isEntitlementRequired = event.detail.value == 'Adoption' || riskType == 'Entitlement Risk' ? true : false;
                this.isComponentRequired = this.isEntitlementRequired;
                this.isAdoptionRisk = event.detail.value == 'Adoption' ? true : false;
                let entitlementValidity2 = this.isEntitlementRequired ? this.selectedEntitlementIds?.length : true;
                if (entitlementValidity2) {
                    this.refs.entitlementLookup.errors = [];
                    this.refs.productFeatureLookup.errors = [];
                }
                break;
            default:
                break;
        }
    }
    handleError(event) {

    }
    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Risk Profile created successfully!',
                variant: 'success'
            })
        );
        this.handleCancel();
    }

    handleCancel() {
        this.closeQuickAction();
    }

    handleSelected(event) {
        try {
            switch (event.target.objectApiName) {
                case 'Entitlement':
                    const previousEntitlements = this.selectedEntitlements || [];
                    const previousIds = new Set(previousEntitlements.map(r => r.id));
                    this.selectedEntitlements = event.detail;
                    const currentIds = new Set(this.selectedEntitlements.map(r => r.id));
                    const removedIds = [...previousIds].filter(id => !currentIds.has(id));
                    if (removedIds.length && this.selectedPDMFeatures?.length) {
                        this.selectedPDMFeatures = this.selectedPDMFeatures.filter(
                            feature => !removedIds.includes(feature.relatedRecordId)
                        );
                    }
                    this.refs.productFeatureLookup.setLookupFxParam({ 'Entitlement__c': this.selectedEntitlements.map(r => r.id) });
                    if (!this.selectedEntitlements?.length) {
                        this.selectedPDMFeatures = [];
                        this.setFieldValue('Product_Pillar_1_Component__c', null);
                        this.setFieldVisibility('Product_Pillar_1_Component__c', false);
                        this.setFieldValue('Product_Pillar_2_Component__c', null);
                        this.setFieldVisibility('Product_Pillar_2_Component__c', false);
                    }
                    let entitlementValidity = this.isEntitlementRequired ? this.selectedEntitlementIds?.length : true;
                    if (!entitlementValidity) {
                        if (this.isAdoptionRisk) {
                            this.refs.entitlementLookup.errors = [{ id: 'R02', message: 'When Primary Risk Reason is Adoption, Entitlement is Mandatory' }];
                        } else {
                            this.refs.entitlementLookup.errors = [{ id: 'R01', message: 'When Risk Type is Entitlement Risk, Entitlement is Mandatory' }];
                        }
                        //this.refs.entitlementLookup.errors = [{ id: 'R01', message: 'When Risk Type is Entitlement Risk, Entitlement is Mandatory' }];
                    } else {
                        this.refs.entitlementLookup.errors = [];
                    }
                    break;
                // case 'Product_Feature__c':
                //     this.selectedPDMFeatures = event.detail;
                //     break;
                case 'Bundle_Components_Allocation__c':
                    this.selectedPDMFeatures = event.detail;
                    break;
                case 'User':
                    this.selectedRiskWatchers = event.detail;
                default:
                    break;
            }
        } catch (error) {
            console.error('handleSelected', error)
        }
    }

    validateForm() {
        let formValidity = Array.from(this.template.querySelectorAll("lightning-input-field"))
            .reduce((validSoFar, field) => {
                return (validSoFar && field.reportValidity());
            }, true);
        const riskType = this.template.querySelector('[data-field="Risk_Type__c"]')?.value;
        const primaryRiskReason = this.template.querySelector('[data-field="Primary_Risk_Reason__c"]')?.value;
        let entitlementValidity = this.refs.entitlementLookup.required ? this.selectedEntitlementIds?.length : true;
        if (!entitlementValidity) {
            if (riskType == 'Entitlement Risk' && primaryRiskReason == 'Adoption') {
                this.refs.entitlementLookup.errors = [{ message: 'When Risk Type is Entitlement Risk, Entitlement is Mandatory' }];
            }
            if (primaryRiskReason == 'Adoption' && riskType != 'Entitlement Risk') {
                this.refs.entitlementLookup.errors = [{ message: 'When Primary Risk Reason is Adoption, Entitlement is Mandatory' }];
            } if (primaryRiskReason != 'Adoption' && riskType == 'Entitlement Risk') {
                this.refs.entitlementLookup.errors = [{ message: 'When Risk Type is Entitlement Risk, Entitlement is Mandatory' }];
            }
        } else {
            this.refs.entitlementLookup.errors = [];
        }
        let componentValidity = this.refs.productFeatureLookup.required ? this.selectedPDMFeatureIds?.length : true;
        if (!componentValidity) {
            this.refs.productFeatureLookup.errors = [{ message: 'When Entitlement is required, Component Feature is Mandatory if available' }];
        } else {
            this.refs.productFeatureLookup.errors = [];
        }
        return formValidity && entitlementValidity && componentValidity;
    }
    findDiff(a, b) {
        if (!Boolean(a)) {
            return {}
        }
        if (!Boolean(b)) {
            return a;
        }
        let diff = {};
        for (let key in a) {
            if (a.hasOwnProperty(key)) {
                if (b.hasOwnProperty(key)) {
                    if (a[key] !== b[key]) {
                        diff[key] = a[key];
                    }
                } else {
                    diff[key] = a[key];
                }
            }
        }

        return diff;
    }
    getDiff(original, modified) {

        const originalIds = new Set(original.map(item => item.id));
        const modifiedIds = new Set(modified.map(item => item.id));

        const added = modified.filter(item => !originalIds.has(item.id));
        const removed = original.filter(item => !modifiedIds.has(item.id));

        return { added, removed };
    }
    isEmpty(obj) {
        return Object.keys(obj).length === 0;
    }
    extractStatus(str) {
        const match = str.match(/\(([^()]*)\)\s*$/);
        return match ? match[1] : null;
    }

    async handleSubmit(event) {
        this.error = undefined;
        this.refs.entitlementLookup.errors = [];
        this.refs.productFeatureLookup.errors = [];
        event.preventDefault();
        if (!this.validateForm()) {
            return;
        }
        const fields = {};
        const objects = [];
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(field => {
            fields[field.fieldName] = field.value;
        });
        fields.Entitlement__c = this.selectedEntitlements?.length ? this.selectedEntitlements[0].id : null;
        fields.objectApiName = 'Risk_Profile__c';

        if (this.isEditMode) {
            fields.Operation = 'Update';
            fields.Id = this.recordId;
            let { added: addedProductFeatures, removed: removedProductFeatures } = this.getDiff(this._originalState.productFeatures, this.selectedPDMFeatures);
            let { added: addedWatchers, removed: removedWatchers } = this.getDiff(this._originalState.watchers, this.selectedRiskWatchers);
            let { added: addedEntitlements, removed: removedEntitlements } = this.getDiff(this._originalState.entitlements, this.selectedEntitlements);

            if (addedProductFeatures) {
                objects.push(...addedProductFeatures.map(pdm => ({ Risk_Profile__c: this.recordId, Bundle_Components_Allocation__c: pdm.id, Entitlement__c: pdm.relatedRecordId, objectApiName: 'Risk_Profile_Component__c', Operation: 'Create' })));
            }
            if (removedProductFeatures) {
                objects.push(...removedProductFeatures.map(pdm => ({ Id: pdm.recordId, objectApiName: 'Risk_Profile_Component__c', Operation: 'Delete' })));
            }
            if (addedWatchers) {
                objects.push(...addedWatchers.map(rw => ({ Risk_Profile__c: this.recordId, Watcher__c: rw.id, objectApiName: 'Risk_Profile_Watcher__c', Operation: 'Create' })))
            }
            if (removedWatchers) {
                objects.push(...removedWatchers.map(rw => ({ Id: rw.recordId, objectApiName: 'Risk_Profile_Watcher__c', Operation: 'Delete' })));
            }
            if (addedEntitlements) {
                objects.push(...addedEntitlements.map(ent => ({
                    Risk_Profile__c: this.recordId,
                    Entitlement__c: ent.id,
                    objectApiName: 'Risk_Profile_Entitlement__c',
                    Operation: 'Create'
                })));
            }
            if (removedEntitlements) {
                objects.push(...removedEntitlements.map(ent => ({
                    Id: ent.recordId,
                    objectApiName: 'Risk_Profile_Entitlement__c',
                    Operation: 'Delete'
                })));
            }
            if (!fields.hasOwnProperty('DNT_Reason__c')) {
                fields.DNT_Reason__c = null;
            }
            if (!fields.hasOwnProperty('DNT_Snooze__c')) {
                fields.DNT_Snooze__c = null;
            }
            if (!fields.hasOwnProperty('Product_Pillar_1_Component__c')) {
                fields.Product_Pillar_1_Component__c = null;
            }
            if (!fields.hasOwnProperty('Product_Pillar_2_Component__c')) {
                fields.Product_Pillar_2_Component__c = null;
            }

        } else {
            fields.Operation = 'Create';
            if (Boolean(this.selectedEntitlements)) {
                objects.push(...this.selectedEntitlements.map(ent => ({
                    Entitlement__c: ent.id,
                    objectApiName: 'Risk_Profile_Entitlement__c',
                    Operation: 'Create'
                })));
            }
            if (Boolean(this.selectedPDMFeatures)) {
                objects.push(...this.selectedPDMFeatures.map(pdm => ({ Bundle_Components_Allocation__c: pdm.id, Entitlement__c: pdm.relatedRecordId, objectApiName: 'Risk_Profile_Component__c', Operation: 'Create' })));
            }
            if (Boolean(this.selectedRiskWatchers)) {
                objects.push(...this.selectedRiskWatchers.map(rw => ({ Watcher__c: rw.id, objectApiName: 'Risk_Profile_Watcher__c', Operation: 'Create' })))
            }
        }
        objects.push(fields)
        if (this.isEmpty(objects)) {
            this.notifyUser('Info', 'Nothing to update', 'Info');
            return;
        }
        try {
            this.isLoading = true;
            var result;
            if (this.isEditMode) {
                result = await updateRiskProfile(JSON.parse(JSON.stringify({ objects })));
            } else {
                result = await createRiskProfile(JSON.parse(JSON.stringify({ objects })));
            }

            if (result.data) {
                this.isLoading = false;

                if (this.isEditMode) {
                    this.notifyUser('Success', 'Successfully Updated Risk Profile ', 'success');
                    eval("$A.get('e.force:refreshView').fire();");
                } else {
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.data.Id,
                            actionName: 'view',
                        },
                    }).then(url => {
                        this.notifyUser('Success', 'Successfully Created Risk Profile {0}', 'success', [{ url, label: result.data.Name }]);
                    });
                }

                this.closeQuickAction();
            }
            if (result.error) {
                this.error = result.error;
                this.isLoading = false;
                this.notifyUser('Error', result.error, 'Error');
            }
        } catch (error) {
            this.notifyUser('Error', error.body?.message || error.message, 'Error');
            console.error('error', error);
        }

    }
    @wire(EnclosingTabId) enclosingTabId;
    @wire(IsConsoleNavigation) isConsoleNavigation;
    async closeQuickAction() {
        this.refresh();
        if (this.calledFromAura) {
            if (this.isConsoleNavigation) {
                this.dispatchEvent(new CustomEvent("closetab", {}));
            } else {
                this[NavigationMixin.Navigate]({
                    type: "standard__recordPage",
                    attributes: {
                        recordId: this.recordId,
                        actionName: "view",
                    },
                });

            }
        }


        this.dispatchEvent(new RefreshEvent());

        //eval("$A.get('e.force:refreshView').fire();");

        setTimeout(() => { this.dispatchEvent(new CloseActionScreenEvent()) });
    }
    notifyUser(title, message, variant, messageData) {
        const toastEvent = new ShowToastEvent({ title, message, variant, messageData });
        this.dispatchEvent(toastEvent);
    }
    errorCallback(error, stack) {
        console.error(error, stack)
    }
    @api
    async refresh() {
        try {
            await refreshGraphQL(this.graphqlResult);
        } catch (e) {
            console.error('errror', e)
        }
    }
    handleComponentLoad(event) {
        let Opportunity__c = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0]?.node.Opportunity__c.value;
        let Entitlement__c = this.selectedEntitlements?.length ? this.selectedEntitlements[0]?.id : null;
        let riskType = this.graphqlResult.data?.uiapi.query.Risk_Profile__c.edges[0]?.node.Risk_Type__c.value;

        if (this.accountId) {
            event.target.setLookupFxParam({ accountId: [this.accountId] });
        }
        if (Opportunity__c) {
            event.target.setLookupFxParam({ Opportunity__c: [Opportunity__c] });
        }
        if (Entitlement__c) {
            event.target.setLookupFxParam({ Entitlement__c: [Entitlement__c] });
            // if(riskType == 'Entitlement Risk'){
            //     event.target.required = true;
            // }
        }
        // if(event.target.objectApiName == 'Entitlement'){
        //     Array.from(document.querySelectorAll('lightning-input-field'))
        //     .forEach(field => {
        //         if(field.fieldName == 'Risk_Type__c' && field.value=='Entitlement Risk'){
        //             event.target.required = true;
        //         }
        //     });
        // }

    }

    handleNoEntitlement(event) {
        const primaryRiskReason = this.template.querySelector('[data-field="Primary_Risk_Reason__c"]')?.value;
        const riskType = this.template.querySelector('[data-field="Risk_Type__c"]')?.value;
        if (primaryRiskReason == 'Adoption' || riskType == 'Entitlement Risk') {
            this.isEntitlementRequired = !event.detail.value;//if value from event is true, it means there is no entitlement
            if (!this.isEntitlementRequired) {
                this.isComponentRequired = false;
                if(this.refs?.entitlementLookup){
                    this.refs.entitlementLookup.errors = [];
                }   
                if(this.refs?.productFeatureLookup){
                    this.refs.productFeatureLookup.errors = [];
                }   
            }
        }
    }
    handleNoComponent(event){
        const primaryRiskReason = this.template.querySelector('[data-field="Primary_Risk_Reason__c"]')?.value;
        const riskType = this.template.querySelector('[data-field="Risk_Type__c"]')?.value;
        if (primaryRiskReason == 'Adoption' || riskType == 'Entitlement Risk') {
            this.isComponentRequired = !event.detail.value;//if value from event is true, it means there is no entitlement
            if (!this.isComponentRequired && this.refs?.productFeatureLookup) {
                this.refs.productFeatureLookup.errors = [];
            }
        }
    }
}