import { LightningElement, api, wire } from "lwc";
// import apex method
import fetchLookupData from "@salesforce/apex/DynamicLookupController.fetchLookupData";
import fetchRecordById from "@salesforce/apex/DynamicLookupController.fetchRecordById";
// dealy apex callout timing in miliseconds
const DELAY = 300;

export default class CustomLookupLwc extends LightningElement {
    // public properties with initial default values
    // TODO: add fields into related object
    // UI properties
    @api label = "custom lookup label"
    @api placeholder = "Search..."
    @api iconName = "standard:account"
    @api helptext
    @api emptyrecordmsg = 'No Records Found....'
    @api meta_entity_label = ''
    @api meta_entity_api = '' 
    @api meta_entity_label2 = ''
    @api meta_entity_api2 = '' 
    @api meta_entity_label3 = '' /* CS21-3825 */
    @api meta_entity_api3 = '' /* CS21-3825 */
    @api meta_entity_label4 = '' /* CS21-3825 */
    @api meta_entity_api4 = '' /* CS21-3825 */

    // single record
    @api defaultRecordId = ""
    
    // CSS: input text field style
    @api isSingleColumn = false
    @api inputcss = "width: 0vw;"
    @api dropdownstyle = '';

    // records
    @api sObjectApiName = "Account"
    @api fields = 'Id, Name'
    @api filter = ''
    @api addonsearchfield = ''
@api preselectFilter = ''; // To be used in case of default preselection


    /* On account clear , Clear RSC Instance used in LGT_NewCase*/
    @api clear() {
        this.handleRemove();
        this.lstResult = [];
        this.hasRecords = true;
        this.isInitialLoad = true;
    }

    /* Check if lookup is related to RSC Instance CS21-3825*/
    get isRscObject() {
        return this.sObjectApiName === 'RSCInstance__c';
    }

    // Reactive flag - returns the filter only if it's valid
    // fetchLookupData method should be invoked only when filter is being updated by the parent CMP
    get filterCondition() {
        if (this.filter && this.filter.trim() !== '') {
            return this.filter;
        }
        // Returning undefined stops the wire from firing
        return undefined;
    }

    // This getter calculates the fields string dynamically
    get calculatedFields() {
        let fieldList = this.fields ? this.fields : 'Id,Name';
        
        // Remove whitespace to avoid parsing errors
        fieldList = fieldList.replace(/\s/g, ''); 

        // SAFETY CHECK: If this is an RSC object, FORCE 'RSCDeployment__c' into the list
        if (this.isRscObject) {
            if (!fieldList.includes('RSCDeployment__c')) {
                fieldList += ',RSCDeployment__c';
            }
            // Force add the 4th meta label if you are using it
            if (this.meta_entity_api4 && !fieldList.includes(this.meta_entity_api4)) {
                fieldList += ',' + this.meta_entity_api4;
            }
        }        
        return fieldList;
    }

    get computedLabel4() {
        if (this.meta_entity_label4) {
            return this.meta_entity_label4;
        }
        return this.isRscObject ? 'Site' : '';
    }

    // private properties
    lstResult = []; // to store list of returned records
    hasRecords = true;
    searchKey = ""; // to store input field value
    isSearchLoading = false; // to control loading spinner
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object formate
    isInitialLoad = true; // to select the primary url by default on initial load

    // initial function to populate default selected lookup record if defaultRecordId provided
    connectedCallback() {

        // Make the API property available to CSS as an attribute
        this.setAttribute('sobjectapiname', this.sObjectApiName);

        if (this.defaultRecordId != "") {
        fetchRecordById({
            recordId: this.defaultRecordId,
            sObjectApiName: this.sObjectApiName,
        })
            .then((result) => {
            if (result != null) {
                this.selectedRecord = result;
                this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
            }
            })
            .catch((error) => {
            this.error = error;
            this.selectedRecord = {};
            });
        }
    }

    // wire function property to fetch search record based on user input
    @wire(fetchLookupData, { fields: '$calculatedFields', 
                                searchKey: "$searchKey", 
                                sObjectApiName: "$sObjectApiName", 
                                filter: '$filterCondition', 
                                addonsearchfield: "$addonsearchfield"})
    searchResult(value) {
        const { data, error } = value; // destructure the provisioned value
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length > 0;

            // Check if we need to process results (RSC or Meta fields present)
            if (this.meta_entity_api || this.meta_entity_api2 || this.isRscObject) {
                
                this.lstResult = data.map(ele => {
                    const displayName = this.isRscObject 
                            ? (ele.RSCUrl__c || ele.Name)
                            : ele.Name;
                            
                    let meta3Value = 'NA';
                    
                    if (this.meta_entity_api4 && ele[this.meta_entity_api4]) {
                        meta3Value = ele[this.meta_entity_api4];
                    } 
                    else if (this.isRscObject && ele.RSCDeployment__c) {
                        meta3Value = ele.RSCDeployment__c;
                    }

                    return {
                        Id: ele.Id,
                        Name: displayName,
                        AccName: ele[this.meta_entity_api3] || 'NA',
                        MetaVal: ele[this.meta_entity_api] || 'NA',
                        MetaVal2: ele[this.meta_entity_api2] || 'NA',
                        MetaVal3: meta3Value, 
                        
                        // Raw fields for sorting
                        RawRelationship: ele.RSCAccountRelationship__c,
                        SortName: ele.RSCAccountName__c 
                    };
                });

                // Apply Sort ONLY for RSC Instances
                if (this.isRscObject) {
                    this.lstResult.sort((a, b) => {
                        // 1. Primary first (Rank 0 vs Rank 1)
                        const rankA = a.RawRelationship === 'Primary' ? 0 : 1;
                        const rankB = b.RawRelationship === 'Primary' ? 0 : 1;
                        
                        if (rankA !== rankB) return rankA - rankB;

                        // 2. Alphabetical by Account Name
                        return (a.SortName || '').localeCompare(b.SortName || '');
                    });
                }
            }else{
                this.lstResult = JSON.parse(JSON.stringify(data));
            }

            // Call reusable preselect helper
            //this.autoSelectDefaultRecord(data);

            // to select the primary url by default on initial load
            if (this.isInitialLoad && data.length > 0) {
                this.autoSelectDefaultRecord(data);
                this.isInitialLoad = false; // Stop it from running again when search is cleared
            }

        } else if (error) {
        console.error("(error---> " + JSON.stringify(error));
        }
    }

    //Method to Pre-Select the record if any default filter is present
    autoSelectDefaultRecord(data) {
        if (!this.preselectFilter || !data || data.length === 0) {
            return;
        }

        try {
            let fieldName, expectedValue;

            // Handle patterns like: Field__c = 'Value' OR Field = true
            const eqIndex = this.preselectFilter.indexOf('=');
            if (eqIndex > -1) {
                fieldName = this.preselectFilter.substring(0, eqIndex).trim();
                expectedValue = this.preselectFilter.substring(eqIndex + 1).trim();

                // Remove quotes if present
                if (expectedValue.startsWith("'") && expectedValue.endsWith("'")) {
                    expectedValue = expectedValue.substring(1, expectedValue.length - 1);
                }

                // Convert booleans safely
                if (expectedValue.toLowerCase() === 'true') expectedValue = true;
                if (expectedValue.toLowerCase() === 'false') expectedValue = false;

                // Find matching record
                const matchingRecord = data.find(rec => {
                    const fieldVal = rec[fieldName];
                    return (
                        fieldVal === expectedValue ||
                        String(fieldVal) === String(expectedValue)
                    );
                });

                if (matchingRecord) {
                    // For RSCInstance__c, display RSC URL as the label; otherwise, use Name
                    const displayName =
                        this.sObjectApiName === 'RSCInstance__c'
                            ? (matchingRecord.RSCUrl__c || matchingRecord.Name)
                            : matchingRecord.Name;

                    // Preserve the whole record but show correct label in the pill
                    this.selectedRecord = {
                        ...matchingRecord,
                        Name: displayName
                    };
                    this.handleSelect(this.selectedRecord); // update value on parent component as well from helper function
                    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                } else {
                    console.warn(` [autoSelectDefaultRecord] No match for ${fieldName} = ${expectedValue}`);
                }
            } else {
                console.warn(' [autoSelectDefaultRecord] Invalid preselectFilter format:', this.preselectFilter);
            }
        } catch (error) {
            console.error(' [autoSelectDefaultRecord] Error:', error);
        }
    }

    // update searchKey property on input field change
    handleKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
        this.searchKey = searchKey;
        }, DELAY);
    }
    // method to toggle lookup result section on UI
    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector(
        ".lookupInputContainer"
        );
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute("data-source");
        switch (whichEvent) {
        case "searchInputField":
            clsList.add("slds-is-open");
            break;
        case "lookupContainer":
            clsList.remove("slds-is-open");
            break;
        }
    }
    // method to clear selected lookup record
    handleRemove() {
        this.searchKey = "";
        this.selectedRecord = {};
        this.handleSelect(''); // update value on parent component as well from helper function

        // remove selected pill and display input field again
        const searchBoxWrapper = this.template.querySelector(".searchBoxWrapper");
        searchBoxWrapper.classList.remove("slds-hide");
        searchBoxWrapper.classList.add("slds-show");
        const pillDiv = this.template.querySelector(".pillDiv");
        pillDiv.classList.remove("slds-show");
        pillDiv.classList.add("slds-hide");

        const oEvent = new CustomEvent("removeSelected");
        this.dispatchEvent(oEvent);
    }
    // method to update selected record from search result
    handelSelectedRecord(event) {
        var objId = event.target.getAttribute("data-recid"); // get selected record Id
        this.selectedRecord = this.lstResult.find((data) => data.Id === objId); // find selected record from list
        this.handleSelect(this.selectedRecord); // update value on parent component as well from helper function
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }
    /*COMMON HELPER METHOD STARTED*/
    handelSelectRecordHelper() {
        this.template
        .querySelector(".lookupInputContainer")
        .classList.remove("slds-is-open");
        const searchBoxWrapper = this.template.querySelector(".searchBoxWrapper");
        searchBoxWrapper.classList.remove("slds-show");
        searchBoxWrapper.classList.add("slds-hide");
        const pillDiv = this.template.querySelector(".pillDiv");
        pillDiv.classList.remove("slds-hide");
        pillDiv.classList.add("slds-show");
    }
    // send selected lookup record to parent component using custom event
    handleSelect(value) {
        const oEvent = new CustomEvent("handleSelect", {
        detail: { selectedRecord: value },
        });
        this.dispatchEvent(oEvent);
    }
}