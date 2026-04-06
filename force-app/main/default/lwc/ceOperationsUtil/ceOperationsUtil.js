export const GENERIC = [{
    label: 'Name',
    fieldName: 'Record__Url',
    type: 'url',
    typeAttributes: {
        label: {
            fieldName: 'Record__Name'
        },
        target: '_self'
    },
    cellAttributes: {
        class: 'slds-size_full'
    },
    sortable: true
}]
export const COLUMNS = {
    JIRA: [
        ...GENERIC,
        {
            label: "Summary",
            fieldName: "zsfjira__Summary__c",
            type: "text"
        },
        {
            label: "Priority",
            fieldName: "zsfjira__Prioriy__c",
            type: "text"
        },
        {
            label: "Fixed In Versions",
            fieldName: "Fixed_in_Version__c",
            type: "text"
        },
        {
            label: "Resolution",
            fieldName: "zsfjira__Resolution__c",
            type: "text"
        },
        {
            label: "Status",
            fieldName: "zsfjira__Status__c",
            type: "text"
        },
        {
            label: "Release Notes Candidate",
            fieldName: "Release_Notes_Candidate__c",
            type: "text"
        },
        {
            label: "Resolution Details",
            fieldName: "Resolution_Details__c",
            type: "richText",
            wrapText: true
        }
    ],
    RFE: [
        ...GENERIC,
        {
            label: "Aha Idea Number",
            fieldName: "Aha_Idea_Number__c",
            type: "text"
        },
        {
            label: "Aha Unique ID",
            fieldName: "Aha_Unique_ID__c",
            type: "text"
        },
        {
            label: "External Unique Id",
            fieldName: "External_Unique_Id__c",
            type: "text"
        },
        {
            label: "Idea Category",
            fieldName: "Idea_Category__c",
            type: "text"
        },
        {
            label: "Idea Description",
            fieldName: "Idea_Description__c",
            type: "text"
        },
        {
            label: "Impacted Customers",
            fieldName: "Impacted_Customers__c",
            type: "text"
        },
        {
            label: "Problem Statement",
            fieldName: "Problem_Statement__c",
            type: "text"
        },
        {
            label: "Product Area",
            fieldName: "Product_Area__c",
            type: "text"
        },
        {
            label: "Product Component",
            fieldName: "Product_Component__c",
            type: "text"
        },
        {
            label: "Status",
            fieldName: "Status__c",
            type: "text"
        }
    ],
    CASE: [{
        label: 'Case Number',
        fieldName: 'Record__Url',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Record__Name'
            },
            target: '_self'
        }
    },
    {
        label: 'Account Name',
        fieldName: 'Account__Url',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Account__Name'
            },
            target: '_self'
        }
    },
    {
        label: 'Contact Name',
        fieldName: 'Contact__Url',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Contact__Name'
            },
            target: '_self'
        }
    },
    {
        label: "Priority",
        fieldName: "Priority",
        type: "text",
        wrapText: true
    },
    {
        label: "Status",
        fieldName: "Status",
        type: "text",
        wrapText: true
    },
    {
        label: "Subject",
        fieldName: "Subject",
        type: "text",
        wrapText: true
    },
    {
        label: "Current Status",
        fieldName: "Current_Status__c",
        type: "text",
        wrapText: true
    },
    {
        label: "Next Step",
        fieldName: "Next_Step__c",
        type: "richText",
        wrapText: true
    },
    {
        label: 'Owner Name',
        fieldName: 'Owner__Url',
        type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Owner__Name'
            },
            target: '_self'
        }
    },
    {
        label: "JIRA Reference",
        fieldName: "Jira_Reference_urls__c",
        type: "richText",
        wrapText: true
    }
    ],

    PLAYBOOK: [
        ...GENERIC,
        {
            label: 'Account Name',
            fieldName: 'Account__Url',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Account__Name'
                },
                target: '_self'
            }
        },
        {
            label: 'Completion Percentage',
            fieldName: 'completion_percentage__c',
            type: 'number'
        },
        {
            label: 'Total Sub Tasks',
            fieldName: 'Total_Sub_Tasks__c',
            type: 'number'
        },
        {
            label: 'Total Sub Tasks Completed',
            fieldName: 'Total_Sub_Tasks_Completed__c',
            type: 'number'
        }
    ],
    SUCCESS_PLAN: [
        ...GENERIC,
        {
            label: 'Account Name',
            fieldName: 'Account__Url',
            type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'Account__Name'
                },
                target: '_self'
            }
        },
        {
            label: 'At Risk',
            fieldName: 'At_Risk__c',
            type: 'text'
        },
        {
            label: 'Customer Contact 1',
            fieldName: 'Customer_Contact_1__c',
            type: 'text'
        },
        {
            label: 'Customer Contact 2',
            fieldName: 'Customer_Contact_2__c',
            type: 'text'
        },
        {
            label: 'Description',
            fieldName: 'Description__c',
            type: 'text'
        },
        {
            label: 'Expected Outcome',
            fieldName: 'Expected_Outcome__c',
            type: 'text'
        },
        {
            label: 'Latest Update',
            fieldName: 'Latest_Update__c',
            type: 'date'
        },
        {
            label: 'Planned End Date',
            fieldName: 'Planned_End_Date__c',
            type: 'date'
        },
        {
            label: 'Priority',
            fieldName: 'Priority__c',
            type: 'text'
        },
        {
            label: 'Start Date',
            fieldName: 'Start_Date__c',
            type: 'date'
        },
        {
            label: 'Status',
            fieldName: 'Status__c',
            type: 'text'
        },
        {
            label: 'Type',
            fieldName: 'Type__c',
            type: 'text'
        },
        {
            label: 'Next Steps',
            fieldName: 'Next_Steps__c',
            type: 'text'
        },
        {
            label: 'Priority Sort Order',
            fieldName: 'Priority_Sort_Order__c',
            type: 'number'
        },
        {
            label: 'Internal Contact',
            fieldName: 'Internal_Contact__c',
            type: 'text'
        },
    ],
    ACCOUNT: [
        {
            "label": "CEM",
            "fieldName": "CEM__Url",
            "type": "url",
            typeAttributes: { label: { fieldName: 'CEM__Name' }, target: '_self' }
        },
        {
            "label": "Account Name",
            "fieldName": "Record__Url",
            "type": "url",
            typeAttributes: { label: { fieldName: 'Record__Name' }, target: '_self' }
        },
        {
            "label": "Account Preference",
            "fieldName": "Account_Preference__c",
            "type": "text"
        },
        {
            "label": "CX Summary Status",
            "fieldName": "CX_Summary_Status__c",
            "type": "text"
        },
        {
            "label": "CX Challenges",
            "fieldName": "CX_Challenges__c",
            "type": "text"
        },
        {
            "label": "CX Score",
            "fieldName": "CX_Customer_Health__c",
            "type": "text",
            cellAttributes: {
                alignment: 'left'
            },
        }
    ]
}

function getColumns(name) {
    let columns = [];
    switch (name) {
        case 'jiras':
            columns = COLUMNS.JIRA;
            break;
        case 'rfes':
            columns = COLUMNS.RFE;
            break;
        case 'success-plans':
            columns = COLUMNS.SUCCESS_PLAN;
            break;
        case 'playbooks':
            columns = COLUMNS.PLAYBOOK;
            break;
        case 'accounts':
            columns = COLUMNS.ACCOUNT;
            break;
        case 'tcv_12_priority':
        case 'open_cases':
        case 'closed_cases':
        case 'tcv_12':
        case 'open_p1':
            columns = COLUMNS.CASE;
            break;
        default:
            columns = COLUMNS.GENERIC;
    }
    return columns.map(item => ({ ...item, sortable: true }));;
}

function getTitle(name) {
    switch (name) {
        case 'jiras':
            return 'JIRA Reference';
        case 'rfes':
            return 'AHA Reference';
        case 'success-plans':
            return 'Success Plans';
        case 'playbooks':
            return 'Playbooks';
        default:
            return '';
    }
}

function normalizeRecordData(data, name) {
    return data.map(record => {
        let r = JSON.parse(JSON.stringify(record));
        r.Record__Url = '/' + r.Id;
        if (name == 'playbooks' || name == 'success-plans') {
            r.Record__Name = r.Name;
            r.Account__Name = r.Account__c ? r.Account__r.Name : '';
            r.Account__Url = r.Account__c ? '/' + r.Account__c : '';
        }
        if (name == 'jiras') {
            r.Record__Name = r.Name;
        }
        if (name == 'rfes') {
            r.Record__Name = r.Name;
        }
        if (['open_cases', 'open_p1', 'tcv_12_priority'].includes(name)) {
            r.Record__Name = r.CaseNumber;
            r.Account__Name = r.AccountId ? r.Account.Name : '';
            r.Account__Url = r.AccountId ? '/' + r.AccountId : '';
            r.Contact__Name = r.ContactId ? r.Contact.Name : '';
            r.Contact__Url = r.ContactId ? '/' + r.ContactId : '';
            r.Owner__Name = r.OwnerId ? r.Owner.Name : '';
            r.Owner__Url = r.OwnerId ? '/' + r.OwnerId : '';
        }
        if (name == 'accounts') {
            r.Record__Url = '/' + r.Id;
            r.Record__Name = r.Name;
            r.CEM__Name = r.Account_SAM__c ? r.Account_SAM__r.Name : '';
            r.CEM__Url = r.Account_SAM__c ? '/' + r.Account_SAM__r.Id : '';
        }
        return r;
    });
}
function getLastUpdatedInterval(value, lastLoadTimestamp) {
    const difference = (value - lastLoadTimestamp) / 1000;
    let output = ``;
    if (difference < 60) {
        output = `a few seconds ago`;
    } else if (difference < 3600) {
        output = `${Math.floor(difference / 60)} minutes ago`;
    } else if (difference < 86400) {
        output = `${Math.floor(difference / 3600)} hours ago`;
    } else if (difference < 2620800) {
        output = `${Math.floor(difference / 86400)} days ago`;
    } else if (difference < 31449600) {
        output = `${Math.floor(difference / 2620800)} months ago`;
    } else {
        output = `${Math.floor(difference / 31449600)} years ago`;
    }
    return output;
}
function getColorScheme(criteria) {
    switch (criteria) {
        case 'N/A': return '#8032ed';
        case 'None': return 'rgb(184,128,140)';
        case 'P1': return 'rgba(218,99,100,255)';
        case 'P2': return 'rgba(237,128,50,255)';
        case 'P3': return 'rgba(70,111,155,255)';
        case 'P3 - Medium': return '#329fed';
        case 'P3 - Standard request': return '#3532ed';
        case 'P4': return 'rgba(70,141,131,255)';
        default: return '#cc99ff'
    }

}
function getPriorityGrouping(priority) {
    priority = priority || '';
    if (priority == '' || priority == '--- None ---' || priority == 'None') {
        return 'None'
    }
    else if (priority.toUpperCase().startsWith('P1')) {
        return 'P1'
    }
    else if (priority.toUpperCase().startsWith('P2')) {
        return 'P2'
    }
    else if (priority.toUpperCase().startsWith('P3')) {
        return 'P3'
    }
    else if (priority.toUpperCase().startsWith('P4')) {
        return 'P4'
    } else {
        return 'N/A'
    }
}
function sortArrayByKey(arr, key, ascending = true) {
    let array = JSON.parse(JSON.stringify(arr || []))
    return array.sort((a, b) => {
        let valueA = a[key];
        let valueB = b[key];

        if (valueA === null) return 1;
        if (valueB === null) return -1;

        if (ascending) {
            if (valueA < valueB) return -1;
            if (valueA > valueB) return 1;
        } else {
            if (valueA > valueB) return -1;
            if (valueA < valueB) return 1;
        }
        return 0;
    });
}
function reorderKeyToLast(objj, keyToMoveLast) {
    let obj = JSON.parse(JSON.stringify(objj || {}))
    if (obj.hasOwnProperty(keyToMoveLast)) {
        const { [keyToMoveLast]: value, ...rest } = obj;
        return { ...rest, [keyToMoveLast]: value };
    } else {
        return obj;
    }
}
function getSortedData(fieldName, direction, data) {
    let result = Object.assign([], data);
    fieldName = getNormalizedFieldName(fieldName);

    return result.sort((a, b) => {
        const aValue = a[fieldName] && typeof a[fieldName] === 'string' ? a[fieldName].toLowerCase() : a[fieldName];
        const bValue = b[fieldName] && typeof b[fieldName] === 'string' ? b[fieldName].toLowerCase() : b[fieldName];
        if (Boolean(aValue) === false && Boolean(bValue) !== false) {
            return direction === 'asc' ? -1 : 1;
        } else if (Boolean(aValue) !== false && Boolean(bValue) === false) {
            return direction === 'asc' ? 1 : -1;
        } else if (aValue < bValue) {
            return direction === 'asc' ? -1 : 1;
        } else if (aValue > bValue) {
            return direction === 'asc' ? 1 : -1;
        } else {
            return 0;
        }
    });
}
function getNormalizedFieldName(fieldName) {
    return fieldName.endsWith('__Url') ? fieldName.replace(/__Url$/, '__Name') : fieldName;
}

export {
    normalizeRecordData,
    getColumns,
    getTitle,
    getLastUpdatedInterval,
    getColorScheme,
    sortArrayByKey,
    getPriorityGrouping,
    reorderKeyToLast,
    getSortedData
}