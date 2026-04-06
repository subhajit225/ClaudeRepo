import { LightningElement,api,wire,track } from 'lwc';
import { getRecord,updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import CURRENT_USER_ID from '@salesforce/user/Id';

/*Schema Imports*/
import ID_FIELD from '@salesforce/schema/Deal_Registration__c.Id';
import DR_NAME_FIELD from '@salesforce/schema/Deal_Registration__c.Name';
import DR_COMMENTS_FIELD from '@salesforce/schema/Deal_Registration__c.DR_Comments__c';
import DR_STATUS_FIELD from '@salesforce/schema/Deal_Registration__c.Deal_Registration_Status__c';
import DR_OPPORTUNITY_FIELD from '@salesforce/schema/Deal_Registration__c.Opportunity__c';
import DR_LEAD_FIELD from '@salesforce/schema/Deal_Registration__c.Lead__c';
import DR_ACCOUNT_FIELD from '@salesforce/schema/Deal_Registration__c.Company_Name__c';
import DR_COMPANY_FIELD from '@salesforce/schema/Deal_Registration__c.Company__c';
import DR_PRIMARY_FIELD from '@salesforce/schema/Deal_Registration__c.Primary__c';
import DR_STATUS_CHANGE_TIMESTAMP_FIELD from '@salesforce/schema/Deal_Registration__c.Approval_Timestamp__c';
import DR_OWNERID_FIELD from '@salesforce/schema/Deal_Registration__c.OwnerId';
import DR_EXPIRY_DATE_FIELD from '@salesforce/schema/Deal_Registration__c.Deal_Reg_Exp_Date__c';
import DR_SUB_STATUS_FIELD from '@salesforce/schema/Deal_Registration__c.Deal_Registration_Sub_Status__c';
import DR_EXTENSION_REQUEST_FIELD from '@salesforce/schema/Deal_Registration__c.Deal_Registration_Extension_Request__c';
import DR_DEAL_INITIATED_TYPE_FIELD from '@salesforce/schema/Deal_Registration__c.Deal_Registration_Type__c';
import DR_PRIMARY_ON_OPPTY_FIELD from '@salesforce/schema/Deal_Registration__c.Primary_Deal_Registration__c';
import DR_REGISTRATION_TYPE_FIELD from '@salesforce/schema/Deal_Registration__c.Registration_Type__c';
import DR_APPROVAL_TIMESTAMP_FIELD from '@salesforce/schema/Deal_Registration__c.DR_Approved_Date__c';
import DR_PS_ESCALATED_FIELD from '@salesforce/schema/Deal_Registration__c.PS_Escalated__c';//prit25-17
import DR_ACV_ESCALATION from '@salesforce/schema/Deal_Registration__c.ACV_at_Escalation__c';//prit25-17
import DR_EXP_DATE_FIELD from '@salesforce/schema/Deal_Registration__c.Deal_Reg_Exp_Date__c';//prit25-402
import DR_REJECTION_REASON_FIELD from '@salesforce/schema/Deal_Registration__c.Rejection_Reason__c';//PRIT26-10
import DR_REJECTION_OTHER_REASON_FIELD from '@salesforce/schema/Deal_Registration__c.Rejection_Other_Reason__c';//PRIT26-10

/*Custom Label Imports*/
import DR_APPROVAL1 from '@salesforce/label/c.DR_Approval_1';
import DR_APPROVAL2 from '@salesforce/label/c.DR_Approval_2';
import DR_Proceed from '@salesforce/label/c.DR_Proceed';
import DR_PENDING_MEET from '@salesforce/label/c.DR_Pending_Meeting';
import DR_SELECT_CREATE_CONTACT from '@salesforce/label/c.DR_Select_Create_Contact';
import DR_OPPTY_HEADER from '@salesforce/label/c.DR_Opportunity_Header';
import DR_SDR_CONV_HEADER from '@salesforce/label/c.DR_SDR_Conv_Header';
import DR_SDR_WARNING from '@salesforce/label/c.DR_Sdr_Warning';
import DR_CONVERT_LEAD_BUTTON from '@salesforce/label/c.DR_Convert_Lead_Button';
import DR_PENDING_MEETING_LABEL from '@salesforce/label/c.DR_Pending_Meeting_Label';
import DR_REJECTED_LABEL from '@salesforce/label/c.DR_Rejected_Label';
import DR_ATTACH_OPPTY from '@salesforce/label/c.DR_Attach_Oppty';
import DR_CREATE_NEW_OPPTY from '@salesforce/label/c.DR_Create_New_Oppty';
import DR_PM_ACCOUNT_ADD_MSG from '@salesforce/label/c.DR_Account_Add_Msg';
import DR_CLOSED_OPP from '@salesforce/label/c.DR_Closed_Opp';
import DR_STAGE6_OPP from '@salesforce/label/c.DR_Stage_6_Opp';
import DR_RESELLER_DR_ATTACHED from '@salesforce/label/c.DR_Reseller_Deal_Attached';
import DR_ACC_MISMATCH_OPP from '@salesforce/label/c.DR_Account_Mismatch';
import DR_OEM_L1_APPROVAL from '@salesforce/label/c.DR_OEM_L1_Approval';
import DR_OEM_TVP_APPROVAL from '@salesforce/label/c.DR_OEM_TVP_Approval';
import DR_IS_MSP from '@salesforce/label/c.DR_IS_MSP'; //prit-24-741
import DR_PARTNER_LOOKUP_MISMATCH from '@salesforce/label/c.DR_PARTNER_LOOKUP_MISMATCH';//prit24-856
import PS_ESCALATION from '@salesforce/label/c.PS_Escalation';//prit25-17
import PS_ESCALATION_RSM_RVP from '@salesforce/label/c.PS_Escalation_RSM_RVP';//prit25-18
import PS_REJECTION from '@salesforce/label/c.PS_Rejection';//prit25-35
import DR_OPP_DISTI_ERROR from '@salesforce/label/c.DR_OPP_Disti_Error';//prit25-567
import DR_DISTRIBUTOR_MISMATCH from '@salesforce/label/c.DR_DISTRIBUTOR_MISMATCH';//prit26-145
import DR_OPP_RECORD_TYPE_ERROR from '@salesforce/label/c.DR_Opp_Record_Type_Error';//prit26-329
import DR_CONTRACT_INACTIVE from '@salesforce/label/c.DR_Contract_InActive';//prit26-307
import DR_ACTIVE_CONTRACT from '@salesforce/label/c.DR_Partner_Active_Contract';//prit26-307
import SALES_DATA_OPS_QUEUE_ID from '@salesforce/label/c.Sales_Data_Ops_Queue_Id';//prit26-465
import DEAL_INITIATED_TYPE from '@salesforce/label/c.Deal_Initiated_type';//prit26-519

/*Apex Method Imports*/
import getRelatedContactRecords from '@salesforce/apex/PC_DealRegistrationApexController.getRelatedRecords';
import getUserInOwnerTerritory from '@salesforce/apex/PC_DealRegistrationApexController.getUserInOwnerTerritory';
import allowDRAssociationToOpportunity from '@salesforce/apex/PC_DealRegistrationApexController.allowDRAssociationToOpportunity';

/*Const Declrations*/
const DR_FIELDS = [
    'Deal_Registration__c.Id',
    'Deal_Registration__c.Name',
    'Deal_Registration__c.Deal_Registration_Status__c',
    'Deal_Registration__c.Email__c',
    'Deal_Registration__c.DR_Comments__c',
    'Deal_Registration__c.Opportunity__c',
    'Deal_Registration__c.Lead__c',
    'Deal_Registration__c.Company_Name__c',
    'Deal_Registration__c.Company__c',
    'Deal_Registration__c.OwnerId',
    'Deal_Registration__c.FirstName__c',
    'Deal_Registration__c.LastName__c',
    'Deal_Registration__c.Phone__c',
    'Deal_Registration__c.Title__c',
    'Deal_Registration__c.Company_Name__r.Type',
    'Deal_Registration__c.Deal_Registration_Type__c',
    'Deal_Registration__c.Deal_Registration_Sub_Status__c',
    'Deal_Registration__c.Partner_Lookup__c',
    'Deal_Registration__c.Alliance_Type__c',
    'Deal_Registration__c.OEM_SubType__c',
    'Deal_Registration__c.Registration_Type__c',
    'Deal_Registration__c.Dedicated_Managed_Service__c',//prit24-741
    'Deal_Registration__c.PS_Escalated__c',//prit25-17
    'Deal_Registration__c.ACV_at_Escalation__c',//prit25-17
    'Deal_Registration__c.DR_Approved_Date__c',
    'Deal_Registration__c.CDM__c',//prit25-289
    'Deal_Registration__c.BDM__c',//prit25-289
    'Deal_Registration__c.Global_Account_Manager__c',//prit25-289
    'Deal_Registration__c.Deal_Registration_Expiration__c',//prit25-402
    'Deal_Registration__c.Sales_Manager__c',//prit25-402
    'Deal_Registration__c.Theatre_VP__c',//prit25-402
	'Deal_Registration__c.GSI_NDA__c',//prit25-479
    'Deal_Registration__c.Distributor__c',//prit26-145
    'Deal_Registration__c.Rejection_Reason__c',//prit26-334
    'Deal_Registration__c.Partner_Contract_Status__c',//prit26-307
    'Deal_Registration__c.CDM_Manager__c',//prit26-285
    'Deal_Registration__c.Opportunity_Stage__c'//prit26-545
    
];

const OPP_FIELD = [
    'Opportunity.Deal_Registration__c',
    'Opportunity.Deal_Registration_Number__c',
    'Opportunity.Deal_Reg_Approval_Status__c',
    'Opportunity.StageName'
];

export default class PC_DealRegButtonsConsole extends NavigationMixin(LightningElement) {
    isModalOpen = false;
    isCreateOppty = false;
    isCreateOpportunity = false;
    isCreateContact = false;
    showCreateOppty = false;
    isAccountAvailable = false;
    modalHeader = '';
    modalLabel = '';
    modalButtonLabel = '';
    showApprovalSection = '';
    modalButtonVariant = '';
    showAddOpptySection = '';
    showDRCommentSection = '';
    toastMessage = '';
    showSearchOpptySection = '';
    disableApprove = false;
    disablePending = false;
    disableReject = false;
    disableModalSubmit = false;
    selectedOpportunityId = '';
    dealRegistration;
    nameField = DR_NAME_FIELD;
    commentField = DR_COMMENTS_FIELD;
    opportunitylookupField = DR_OPPORTUNITY_FIELD;
    leadLookupField = DR_LEAD_FIELD;
    showLeadConversionCB = '';
    isLeadCreateUpdate = false;
    loadSpinner = false;
    leadRecordId = '';
    contactId = '';
    opptyId = '';
    isAccountUpdate = false;
    accountName = DR_COMPANY_FIELD;
    accountId;
    accountIdVar = DR_ACCOUNT_FIELD;
    dealRegStatus = DR_STATUS_FIELD;
    isAlreadyPending = false;
    dealStatus = '';
    opptyRecord;
    dealRegExists = false;
    //opptyDealReg = '';
    showDateError = false;
    setButtonPanelVisibilty = false;
    ownerId = DR_OWNERID_FIELD;
    loggedUserId = CURRENT_USER_ID;
    leadConvButton = true;
    showCreateContactButton = true;
    showPreviousButton = false;
    DR_CONV_HEADER = '';
    dealRegType = DR_DEAL_INITIATED_TYPE_FIELD;
    showDealInitiatedTypeSection = false;
    dealTypeSelectedValue = '';
    disableSDRButton = false;
    accountPendingMeetingUpdate = false;
    showPendingMeetingCB = false;
    isAttachmentUploaded = false;
    dealSubStatus = '';
    pendingMeetingNoMessage = '';
    oppSelectionErrorMessage = '';
    drPrimaryOnOppty = false;
    isOppCreateUpdate = false;
    showRegistrationTypeSection = false;
    isDealAutoSet = false;
    drAssociationRID = false;
    selectionResult = '';
    showL1ApprovalSection = false;
    showTVPApprovalSection = false;
    dealInitiatedTypeValue = '';
    registrationType = '';
    isCreateOpptyButton = false;
    dealTypeSelectedPicklistValue = '';
    accountIdforOpty = '';//prit24-741
    oppPSEscalated = false;
    isPSEscalated = false;//prit25-17
    selectedOppty;//prit25-17
    showPSEscalationApprovalSection = false;//prit25-18
    psEscalateApproveLabel = '';//prit25-18
    disableExtensionExpiration = true; //prit25-402
    outerSpinner = false;//prit25-402
    showCreateOppSec = true;
    isEngagementDR = false;//PRIT26-10
    rejectionField = DR_REJECTION_REASON_FIELD;//PRIT26-10
    isReject = false; //prit26-285 - fix rejection reason showing only on reject
    isAccountValueRequired = false;

    label = {
        DR_APPROVAL1,
        DR_APPROVAL2,
        DR_Proceed,
        DR_PENDING_MEET,
        DR_SELECT_CREATE_CONTACT,
        DR_OPPTY_HEADER,
        DR_SDR_CONV_HEADER,
        DR_SDR_WARNING,
        DR_CONVERT_LEAD_BUTTON,
        DR_PENDING_MEETING_LABEL,
        DR_REJECTED_LABEL,
        DR_ATTACH_OPPTY,
        DR_CREATE_NEW_OPPTY,
        /*DR_ARTFACT_REVIEW,
        DR_BDM_UPLOAD_MSG,*/
        DR_PM_ACCOUNT_ADD_MSG,
        DR_CLOSED_OPP,
        DR_STAGE6_OPP,
        DR_RESELLER_DR_ATTACHED,
        /*DR_SDRLED_OPP,*/
        DR_ACC_MISMATCH_OPP,
        DR_OEM_L1_APPROVAL,
        DR_OEM_TVP_APPROVAL,
        DR_IS_MSP, //prit24-741
        DR_PARTNER_LOOKUP_MISMATCH, //prit24-856 
        PS_ESCALATION, //prit25-17
        PS_ESCALATION_RSM_RVP, //prit25-18
        PS_REJECTION,//prit25-35
        DR_OPP_DISTI_ERROR,//prit25-567
        DR_DISTRIBUTOR_MISMATCH,//prit26-145
        DR_OPP_RECORD_TYPE_ERROR,//PRIT26-329
        DR_CONTRACT_INACTIVE,//prit26-307
        DR_ACTIVE_CONTRACT,//prit26-307
        SALES_DATA_OPS_QUEUE_ID,
        DEAL_INITIATED_TYPE //prit26-519
    };

    @track
    RECORD_FORM_ATTRIBUTES = {
        objectApiName : 'Deal_Registration__c',
        columns : '2',
        density : 'auto',
        fieldNames : '',
        mode : 'edit',
        layoutType : ''
    };
    @track
    contactDetailsOnDR = {};

    @api recordId;
    @api oppRecordId;
    @track contactList;

    @track columns = [{label: 'Contact Name', fieldName: 'Name', type: 'text', hideDefaultActions: true},
    {label: 'Email', fieldName: 'Email', type: 'Email', hideDefaultActions: true},
    {label: 'Title', fieldName: 'Title', type: 'text', hideDefaultActions: true},
    {label: 'Phone', fieldName: 'Phone', type: 'Phone', hideDefaultActions: true}];


    /******************** All Lifecycle Hooks *********************************************/
    connectedCallback(){
    }

    /******************** All Wired Methods ***********************************************/
    @wire(getRecord, { recordId: '$recordId', fields: DR_FIELDS })
    wiredRecord({error, data}){
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading Deal Registration',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            this.dealRegistration = data;
            this.enableDisableButtons();
            this.showLeadConSection();
            this.setButtonVisibilty();
            if(this.dealRegistration){
                this.contactDetailsOnDR = {
                    First_Name : this.dealRegistration.fields.FirstName__c.value,
                    Last_Name : this.dealRegistration.fields.LastName__c.value,
                    Phone : this.dealRegistration.fields.Phone__c.value,
                    Email : this.dealRegistration.fields.Email__c.value,
                    Title : this.dealRegistration.fields.Title__c.value
                };
            }
            if(this.dealRegistration.fields.Deal_Registration_Status__c.value != null){
                this.dealStatus = this.dealRegistration.fields.Deal_Registration_Status__c.value;
            }
            if(this.dealRegistration.fields.Deal_Registration_Type__c.value != null){
                this.dealTypeSelectedValue = this.dealRegistration.fields.Deal_Registration_Type__c.value;
                this.setDealInitiatedType(this.dealTypeSelectedValue);
            }
            if(this.dealRegistration.fields.Deal_Registration_Sub_Status__c.value != null){
                this.dealSubStatus = this.dealRegistration.fields.Deal_Registration_Sub_Status__c.value;
            }
            if(this.dealRegistration.fields.Registration_Type__c.value != null){
                this.registrationType = this.dealRegistration.fields.Registration_Type__c.value;
            }            
            if(this.dealRegistration.fields.Company_Name__c.value != '' && this.dealRegistration.fields.Company_Name__c.value != null){
                //this.getContactList();
                this.isAccountAvailable = true;
                this.showLeadConversionCB = false;
                this.showLeadConversion = false;
                if(this.isAccountUpdate && this.accountPendingMeetingUpdate){
                    this.showPendingMeetingSection();
                }/*else if(this.isAccountUpdate && this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value != 'Prospect'){
                    this.showDealInitiatedTypeSection = true;
                }*/else if(this.isAccountUpdate && this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value == 'Prospect'){
                    this.showAddOpptySection = true;
                    this.setDealInitiatedType(this.dealTypeSelectedValue);
                }
            }
            //prit24-741-start
            if(this.dealRegistration.fields.Dedicated_Managed_Service__c.value){
                this.showCreateOppSec = false;
                //this.accountIdforOpty = this.dealRegistration.fields.Partner_Lookup__c.value;
            }else{
                this.accountIdforOpty = this.dealRegistration.fields.Company_Name__c.value;
            }
            //prit24-741-end

            //PRIT26-10
            if(this.dealRegistration.recordTypeInfo.name == 'Engagement'){
                this.isEngagementDR = true;
            }
            //PRIT26-334
            if(this.dealRegistration.fields.Rejection_Reason__c.value != null){
                this.rejectRsn = this.dealRegistration.fields.Rejection_Reason__c.value;
            }
        }
    }
    deal_reg;

    /******************** All Imperative Apex Calls *********************************************/
    getContactList(){
        getRelatedContactRecords({parentRecordId : this.dealRegistration.fields.Company_Name__c.value})
        .then(result => {
            this.contactList = result;
            //console.log('contactlist '+JSON.stringify(this.contactList));
        })
        .catch(error => {
             //exception handling
            this.error = error;
            this.contactList = undefined;
        })
    }

    setButtonVisibilty(){
        getUserInOwnerTerritory({drRecordId : this.dealRegistration.fields.Id.value})
        .then(result => {
            this.setButtonPanelVisibilty = result.enableMainButtonPanel;
            this.leadConvButton = result.disableConvertLeadButton;
            if(this.leadConvButton == false && this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Conversion"){
                this.disableReject = true;
            }
            if(this.setButtonPanelVisibilty == false){
                this.disableApprove = true;
                this.disablePending = true;
                this.disableReject = true;
            }

            //prit26-285 - start
            console.log('---enableExpireButton->'+result.enableExpireButton);
            
            let usersAccessSet = new Set([this.dealRegistration.fields.OwnerId.value, this.dealRegistration.fields.CDM__c.value, this.dealRegistration.fields.CDM_Manager__c.value, this.dealRegistration.fields.BDM__c.value, this.dealRegistration.fields.Global_Account_Manager__c.value, this.dealRegistration.fields.Sales_Manager__c.value, this.dealRegistration.fields.Theatre_VP__c.value]);
            let usersAccessList = [...usersAccessSet];
            var today = new Date();
            let date1 = new Date(today.toISOString().split('T')[0]);
            let expireDate = new Date(this.dealRegistration.fields.Deal_Registration_Expiration__c.value);
            let diffInTime = date1.getTime() - expireDate.getTime();
            let diffInDays = Math.round(diffInTime / (1000 * 3600 * 24));

            if(this.dealRegistration.fields.Deal_Registration_Status__c.value == "Submitted" || this.dealRegistration.fields.Deal_Registration_Status__c.value == "Escalated" || this.dealRegistration.recordTypeInfo.name == 'Engagement')
            {
                this.disableExtensionExpiration = true;
            }else if( this.dealRegistration.fields.Deal_Registration_Status__c.value == "Expired" &&
                        ((diffInDays >= 30 && this.dealRegistration.fields.DR_Approved_Date__c.value == null) //deal was never approved
                        ||
                        (diffInDays >= 45 && this.dealRegistration.fields.DR_Approved_Date__c.value != null)) //deal was approved
            )
            {
                this.disableExtensionExpiration = true;
            }else if(usersAccessList.includes(this.loggedUserId) || result.enableExpireButton == true)
            {
                this.disableExtensionExpiration = false;
            }
            
            //prit26-285 - end

            if( //prit26-455
                this.loggedUserId == this.dealRegistration.fields.BDM__c.value ||
                this.loggedUserId == this.dealRegistration.fields.Global_Account_Manager__c.value ||
                this.loggedUserId == this.dealRegistration.fields.CDM__c.value )
            {
                this.disableApprove = true;
            }
            
            this.error = undefined;
        })
        .catch(error => {
             //exception handling
            this.error = error;
            this.setButtonPanelVisibilty = undefined;
        })
    }

    checkDRandOpptyAssociation() {
        allowDRAssociationToOpportunity({ currentDealRegID: this.dealRegistration.fields.Id.value, selectedOpptyId: this.oppRecordId })
            .then(result => {
                this.selectionResult = result.message;
                this.selectedOppty = result.opp;
                console.log('selectionResult ==== ',this.selectionResult);
                console.log('selectedOppty ==== ',this.selectedOppty);
                this.loadSpinner = false;
                if (result.message.includes('7 Closed')) {
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_CLOSED_OPP;
                }//PRIT26-329
                else if (result.message.includes('Renewal Opportunity')) {
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_OPP_RECORD_TYPE_ERROR;
                } 
                else if (result.message.includes('6 PO With')) {
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_STAGE6_OPP;
                } else if (result.message.includes('Account Mismatch')) {
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_ACC_MISMATCH_OPP;
                } else if (result.message.includes('Deal Type Auto-Set')) {
                    let dealValue = '';
                    if(this.selectedOppty.Account.Type == 'Prospect') {
                        dealValue = 'Partner Sourced New Logo (PSNL)';

                    } else {
                        dealValue = 'Partner Sourced Expand';

                    }
                    this.isDealAutoSet = true;
                    this.drPrimaryOnOppty = true;
                    
                    this.dealTypeDisabled = true;
                    this.dealTypeSelectedValue = dealValue;
                    this.dealTypeSelectedPicklistValue = dealValue;
                    this.disableModalSubmit = false;
                    this.setDealInitiatedType(dealValue);
                    
                } else if (result.message.includes('Opp 30 Day Selection')) {
                    this.showSearchOpptySection = false;
                    this.showRegistrationTypeSection = true;
                } else if (result.message.includes('Opp PS Expand')) {
                    this.showSearchOpptySection = false;
                    this.showDealInitiatedTypeSection = true;
                } else if (result.message.includes('Opp Stage Time Violation')) {
                    this.drPrimaryOnOppty = true;
                    this.dealRegExists = false;
                    this.disableModalSubmit = false;
                    this.oppSelectionErrorMessage = '';
                    this.drAssociationRID = true;
                } else if (result.message.includes('Reseller Deal Exists')) {
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_RESELLER_DR_ATTACHED;
                } else if (result.message.includes('No Deal Exists')) {
                    this.drPrimaryOnOppty = true;
                    this.dealRegExists = false;
                    this.disableModalSubmit = false;
                    this.oppSelectionErrorMessage = '';
                } else if (result.message.includes('Allow DR Association')) {
                    this.dealRegExists = false;
                    this.disableModalSubmit = false;
                    this.oppSelectionErrorMessage = '';
                }
                //prit24-741-start
                else if (result.message.includes('DR is MSP')) {
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_IS_MSP;
                }
                //prit24-741-end
                //prit24-856-start
                /*else if (result.message.includes('Opp DR MSP Account Mis-match')) {
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_PARTNER_LOOKUP_MISMATCH;
                }*/
                //prit24-856-end
                //prit25-17-start
                else if (result.message.includes('DR PS Escalation')) {
                    console.log('PS Escalated 1');
                    //prit25-182-start
                    if ((this.selectedOppty.Opportunity_Type__c == 'New Customer') || (this.selectedOppty.Opportunity_Type__c == 'Existing Customer' && this.dealRegistration.fields.Dedicated_Managed_Service__c.value) && this.dealRegistration.fields.Registration_Type__c.value == 'Partner Sourced'){
                        this.showRegistrationTypeSection = true;
                    }else {
                        this.showDealInitiatedTypeSection = true;
                    }
                    //prit25-182-end
                    this.oppPSEscalated = true;
                    this.drPrimaryOnOppty = true;
                }
                //prit25-17-end
                //prit25-567-start
                else if(result.message.includes('Opp Distributor Error')){
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_OPP_DISTI_ERROR;
                }
                //prit25-567-end

                //prit26-145-start
                if(result.message.includes('DR Dist is Mismatch')){
                    this.dealRegExists = true;
                    this.disableModalSubmit = true;
                    this.oppSelectionErrorMessage = this.label.DR_DISTRIBUTOR_MISMATCH;
                }
                //prit26-145-end
                
                this.error = undefined;
                console.log('DR association' + JSON.stringify(result));
                console.log('DR association' + JSON.stringify(this.dealRegistration.fields));

            })
            .catch(error => {
                //exception handling
                this.error = error;
                //this.contactList = undefined;
            })
    }

    /******************** Record Updates *********************************************/
    onClickDRConfirmAction(event) {
        const fields = {};
        let isReadyForUpdate = false;
        fields[ID_FIELD.fieldApiName] = this.recordId;
        let isValid = true;
        this.template.querySelectorAll('lightning-input-field').forEach(field => {
            if (!field.reportValidity()) {
                isValid = false;
            }
        });
        if(!isValid) return;
        
        if ((this.modalButtonLabel == "Pending Meeting" || this.modalButtonLabel == "Reject") && (this.dealRegistration.fields.Deal_Registration_Status__c.value != 'Escalated'))//prit25-35 - added condition to run for non-escalated deals
        {
            let drCommentsEle = this.template.querySelector('[data-id="drCommentId"]');
            if (this.modalButtonLabel == "Pending Meeting" && drCommentsEle) {
                    this.isAccountUpdate = false;
                    fields[DR_STATUS_FIELD.fieldApiName] = "Pending Meeting";
                    fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
                    this.toastMessage = "Deal Registration Pending Meeting";
                    fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
                    //prit26-285-start
                    let expDate = new Date(this.dealRegistration.fields.Deal_Registration_Expiration__c.value);
                    expDate.setDate(expDate.getDate() + 15);
                    fields[DR_EXPIRY_DATE_FIELD.fieldApiName] = expDate.toISOString().split('T')[0];
                    //prit26-285-start

                fields[DR_COMMENTS_FIELD.fieldApiName] = drCommentsEle.value;
                isReadyForUpdate = true;
            } else if (this.modalButtonLabel == "Reject" && drCommentsEle || this.modalButtonLabel == "Reject" && this.isEngagementDR) {
                    this.isAccountUpdate = false;
                    fields[DR_STATUS_FIELD.fieldApiName] = "Rejected";
                    fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
                    fields[DR_OPPORTUNITY_FIELD.fieldApiName] = '';
                    this.toastMessage = "Deal Registration Rejected";
                //PRIT26-334
                fields[DR_REJECTION_REASON_FIELD.fieldApiName] = this.rejectRsn;
                if(this.rejectRsn == 'Other' && (drCommentsEle.value == '' || drCommentsEle.value == null)){
                    this.handleErrorToast('Error','Rejection comment is required when Other is selected as a rejection reason');
                    return;
                }
                fields[DR_REJECTION_OTHER_REASON_FIELD.fieldApiName] = drCommentsEle.value;
                if(this.isEngagementDR){
                    this.toastMessage = "Managed Service Engagement Registration Rejected";
                }
                isReadyForUpdate = true;
            }
        }
        //prit25-35-start
        else if (this.modalButtonLabel == "Reject" && this.dealRegistration.fields.Deal_Registration_Status__c.value == 'Escalated' && this.dealRegistration.fields.PS_Escalated__c) {
            if (this.dealRegistration.fields.Deal_Registration_Sub_Status__c.value == 'Pending RSM Approval') {
                fields[DR_SUB_STATUS_FIELD.fieldApiName] = "RSM Rejected";
            } else if (this.dealRegistration.fields.Deal_Registration_Sub_Status__c.value == 'Pending RVP Approval') {
                fields[DR_SUB_STATUS_FIELD.fieldApiName] = "RVP Rejected";
            }
            fields[DR_STATUS_FIELD.fieldApiName] = "Approved";
            fields[DR_APPROVAL_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_PRIMARY_FIELD.fieldApiName] = true;
            fields[DR_EXPIRY_DATE_FIELD.fieldApiName] = '';
            fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
            fields[DR_REGISTRATION_TYPE_FIELD.fieldApiName] = 'Value Add';
            fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = 'Rubrik Sourced';

            isReadyForUpdate = true;
            this.isAccountUpdate = false;
            this.toastMessage = "Deal Registration Approved";
            console.log('PS Escalation Rejection');
        }
        //prit25-35-end
        //PRIT26-10-start
        else if(this.modalButtonLabel == "Approve" && this.dealRegistration.recordTypeInfo.name == 'Engagement' && this.dealStatus == 'Submitted'){
            fields[DR_STATUS_FIELD.fieldApiName] = "Approved";
            fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_APPROVAL_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            this.toastMessage = "Managed Service Engagement Registration Approved";
            isReadyForUpdate = true;
        }
        //PRIT26-10-end
        else if (this.modalButtonLabel == "Approve" && !this.disableModalSubmit && this.dealRegistration.recordTypeInfo.name == 'OEM' && this.dealSubStatus == "Pending L1 Approval" && !this.isPSEscalated) { //prit25-17 added check for this.isPSEscalated
            fields[DR_SUB_STATUS_FIELD.fieldApiName] = "Pending TVP Approval";
            if (this.dealTypeSelectedValue != null && this.dealTypeSelectedValue != '') {
                fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealTypeSelectedValue;
            } else {
                fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealRegistration.fields.Deal_Registration_Type__c.value;
            }
            this.toastMessage = "Deal Registration L1 approved and Pending TVP approval";
            isReadyForUpdate = true;
            this.isAccountUpdate = false;
        } else if (this.modalButtonLabel == "Approve" && !this.disableModalSubmit && this.dealRegistration.recordTypeInfo.name == 'OEM' && this.dealSubStatus == "Pending TVP Approval" && !this.isPSEscalated) { //prit25-17 added check for this.isPSEscalated
            fields[DR_STATUS_FIELD.fieldApiName] = "Submitted";
            fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
            if (this.dealTypeSelectedValue != null && this.dealTypeSelectedValue != '') {
                fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealTypeSelectedValue;
            } else {
                fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealRegistration.fields.Deal_Registration_Type__c.value;
            }
            this.toastMessage = "Deal Registration TVP approved and Pending AE approval";
            isReadyForUpdate = true;
            this.isAccountUpdate = false;
        } else if (this.modalButtonLabel == "Approve" && !this.disableModalSubmit && (this.drAssociationRID || this.selectionResult == 'Allow DR Association') && !this.isPSEscalated) { //prit25-17 added check for this.isPSEscalated
            fields[DR_STATUS_FIELD.fieldApiName] = "Approved";
            fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
            fields[DR_OPPORTUNITY_FIELD.fieldApiName] = this.selectedOpportunityId;
            fields[DR_PRIMARY_FIELD.fieldApiName] = true;
            fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_APPROVAL_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_EXPIRY_DATE_FIELD.fieldApiName] = '';
            fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
            fields[DR_REGISTRATION_TYPE_FIELD.fieldApiName] = 'Value Add';
            fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = 'Rubrik Sourced';
            if (this.drPrimaryOnOppty && (this.dealRegistration.recordTypeInfo.name == 'Reseller' || (this.dealRegistration.recordTypeInfo.name == 'Alliance' && this.dealRegistration.fields.Alliance_Type__c.value != 'Security') || this.dealRegistration.recordTypeInfo.name == 'Internal')) {
                fields[DR_PRIMARY_ON_OPPTY_FIELD.fieldApiName] = true;
            }
			//PRIT25-479
			if(this.dealRegistration.recordTypeInfo.name == 'Internal' && this.dealStatus == 'Escalated' && this.dealSubStatus == 'GSI-NDA Pending Approval' && this.dealRegistration.fields.GSI_NDA__c.value){
                fields[DR_PS_ESCALATED_FIELD.fieldApiName] = true;
            }
            this.toastMessage = "Deal Registration Approved";
            isReadyForUpdate = true;
            this.isAccountUpdate = false;
        } else if (this.modalButtonLabel == "Approve" && !this.disableModalSubmit && (this.showRegistrationTypeSection || this.showDealInitiatedTypeSection || this.isDealAutoSet) && !this.isPSEscalated) { //prit25-17 added check for this.isPSEscalated
            fields[DR_STATUS_FIELD.fieldApiName] = "Approved";
            fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
            fields[DR_OPPORTUNITY_FIELD.fieldApiName] = this.selectedOpportunityId;
            fields[DR_PRIMARY_FIELD.fieldApiName] = true;
            fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_APPROVAL_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_EXPIRY_DATE_FIELD.fieldApiName] = '';
            fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
            fields[DR_REGISTRATION_TYPE_FIELD.fieldApiName] = this.registrationType;
            if (this.dealTypeSelectedValue != null) {
                fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealTypeSelectedValue;
            } else {
                fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealRegistration.fields.Deal_Registration_Type__c.value;
            }
            if (this.drPrimaryOnOppty && (this.dealRegistration.recordTypeInfo.name == 'Reseller' || (this.dealRegistration.recordTypeInfo.name == 'Alliance' && this.dealRegistration.fields.Alliance_Type__c.value != 'Security') || this.dealRegistration.recordTypeInfo.name == 'Internal')) {
                fields[DR_PRIMARY_ON_OPPTY_FIELD.fieldApiName] = true;
            }
			//PRIT25-479
			if(this.dealRegistration.recordTypeInfo.name == 'Internal' && this.dealStatus == 'Escalated' && this.dealSubStatus == 'GSI-NDA Pending Approval' && this.dealRegistration.fields.GSI_NDA__c.value){
                fields[DR_PS_ESCALATED_FIELD.fieldApiName] = true;
            }
            this.toastMessage = "Deal Registration Approved";
            isReadyForUpdate = true;
            this.isAccountUpdate = false;
        }
        //prit25-17-start - PS Escalation Logic
        else if (this.modalButtonLabel == "Approve" && !this.disableModalSubmit && this.isPSEscalated && this.dealRegistration.fields.Deal_Registration_Status__c.value != 'Escalated' && this.dealRegistration.fields.Deal_Registration_Sub_Status__c.value != 'Pending RSM Approval') {
            fields[DR_STATUS_FIELD.fieldApiName] = "Escalated";
            //prit26-285-start
            var date = new Date();
            date.setDate(date.getDate() + 20);
            fields[DR_EXP_DATE_FIELD.fieldApiName] = date.toISOString().split('T')[0];
            //prit26-285-end
            fields[DR_PS_ESCALATED_FIELD.fieldApiName] = true;
                fields[DR_SUB_STATUS_FIELD.fieldApiName] = "Pending RSM Approval";
                this.toastMessage = "Deal Registration escalated for RSM/RVP approval";
            fields[DR_OPPORTUNITY_FIELD.fieldApiName] = this.selectedOpportunityId;
            fields[DR_PRIMARY_FIELD.fieldApiName] = true;
            fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
            fields[DR_ACV_ESCALATION.fieldApiName] = this.selectedOppty.ACV_Amount__c;
            if (this.drPrimaryOnOppty && (this.dealRegistration.recordTypeInfo.name == 'Reseller' || (this.dealRegistration.recordTypeInfo.name == 'Alliance' && this.dealRegistration.fields.Alliance_Type__c.value != 'Security') || this.dealRegistration.recordTypeInfo.name == 'Internal')) {
                fields[DR_PRIMARY_ON_OPPTY_FIELD.fieldApiName] = true;
            }
            isReadyForUpdate = true;
            this.isAccountUpdate = false;
            console.log('PS Escalation 1');
        }
        //prit25-17-end
        //prit25-18-start
        else if (this.modalButtonLabel == "Approve" && !this.disableModalSubmit && this.dealRegistration.fields.PS_Escalated__c && this.dealRegistration.fields.Deal_Registration_Status__c.value == 'Escalated' && this.dealRegistration.fields.Deal_Registration_Sub_Status__c.value == 'Pending RSM Approval') {
            if (this.dealRegistration.fields.ACV_at_Escalation__c.value > 300000) {
                fields[DR_SUB_STATUS_FIELD.fieldApiName] = "Pending RVP Approval";
                this.toastMessage = "Deal Registration RSM approved and Pending RVP approval";
            } else {
                fields[DR_STATUS_FIELD.fieldApiName] = "Approved";
                fields[DR_SUB_STATUS_FIELD.fieldApiName] = "RSM Approved";
                fields[DR_APPROVAL_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
                fields[DR_PRIMARY_FIELD.fieldApiName] = true;
                fields[DR_EXPIRY_DATE_FIELD.fieldApiName] = '';
                fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
                //prit25-182 - start
                if(this.dealRegistration.fields.Deal_Registration_Type__c.value == "Rubrik Sourced" && this.dealRegistration.fields.Registration_Type__c.value == "Value Add"){
                    fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = "Partner Sourced Expand";
                    fields[DR_REGISTRATION_TYPE_FIELD.fieldApiName] = "Partner Sourced";
                }else{
                    fields[DR_REGISTRATION_TYPE_FIELD.fieldApiName] = this.registrationType;
                    if (this.dealTypeSelectedValue != null) {
                        fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealTypeSelectedValue;
                    } else {
                        fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealRegistration.fields.Deal_Registration_Type__c.value;
                    }
                }
                //prit25-182 - end
                if (this.drPrimaryOnOppty && (this.dealRegistration.recordTypeInfo.name == 'Reseller' || (this.dealRegistration.recordTypeInfo.name == 'Alliance' && this.dealRegistration.fields.Alliance_Type__c.value != 'Security') || this.dealRegistration.recordTypeInfo.name == 'Internal')) {
                    fields[DR_PRIMARY_ON_OPPTY_FIELD.fieldApiName] = true;
                }
                this.toastMessage = "Deal Registration Approved";
            }
            fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            isReadyForUpdate = true;
            this.isAccountUpdate = false;
            console.log('PS Escalation 2');
        }
        else if (this.modalButtonLabel == "Approve" && !this.disableModalSubmit && this.dealRegistration.fields.PS_Escalated__c && this.dealRegistration.fields.Deal_Registration_Status__c.value == 'Escalated' && this.dealRegistration.fields.Deal_Registration_Sub_Status__c.value == 'Pending RVP Approval') {
            fields[DR_STATUS_FIELD.fieldApiName] = "Approved";
            fields[DR_SUB_STATUS_FIELD.fieldApiName] = "RVP Approved";
            fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_APPROVAL_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
            fields[DR_PRIMARY_FIELD.fieldApiName] = true;
            fields[DR_EXPIRY_DATE_FIELD.fieldApiName] = '';
            fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
            //prit25-182 - start
            if(this.dealRegistration.fields.Deal_Registration_Type__c.value == "Rubrik Sourced" && this.dealRegistration.fields.Registration_Type__c.value == "Value Add"){
                fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = "Partner Sourced Expand";
                fields[DR_REGISTRATION_TYPE_FIELD.fieldApiName] = "Partner Sourced";
            }
            //prit25-182 - end
            isReadyForUpdate = true;
            this.isAccountUpdate = false;
            this.toastMessage = "Deal Registration Approved";
            console.log('PS Escalation 3');
        }
        //prit25-18-end
        else if (this.isLeadCreateUpdate) {
            isReadyForUpdate = true;
            this.toastMessage = "Deal Registration Pending Conversion";
            fields[DR_STATUS_FIELD.fieldApiName] = "Pending Conversion";
            //prit26-285-start
            let expDate = new Date(this.dealRegistration.fields.Deal_Registration_Expiration__c.value);
            expDate.setDate(expDate.getDate() + 15);
            fields[DR_EXP_DATE_FIELD.fieldApiName] = expDate.toISOString().split('T')[0];
            //prit26-285-end
            fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
            fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
        } else if (this.isAccountUpdate) {
            isReadyForUpdate = true;
            this.toastMessage = "Account added to Deal Registration"
            fields[DR_ACCOUNT_FIELD.fieldApiName] = this.accountId;
        } else if (this.isOppCreateUpdate) {
            if (this.dealRegistration.recordTypeInfo.name == 'OEM' || (this.dealRegistration.recordTypeInfo.name == 'Alliance' && this.dealRegistration.fields.Alliance_Type__c.value == 'Security')) {
                fields[DR_STATUS_FIELD.fieldApiName] = "Approved";
                fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
                fields[DR_OPPORTUNITY_FIELD.fieldApiName] = this.selectedOpportunityId;
                fields[DR_STATUS_CHANGE_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
                fields[DR_APPROVAL_TIMESTAMP_FIELD.fieldApiName] = new Date().toISOString();
                fields[DR_EXPIRY_DATE_FIELD.fieldApiName] = '';
                fields[DR_EXTENSION_REQUEST_FIELD.fieldApiName] = '';
                fields[DR_REGISTRATION_TYPE_FIELD.fieldApiName] = this.registrationType;
                if (this.dealTypeSelectedValue != null) {
                    fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealTypeSelectedValue;
                } else {
                    fields[DR_DEAL_INITIATED_TYPE_FIELD.fieldApiName] = this.dealRegistration.fields.Deal_Registration_Type__c.value;
                }
            }
            this.toastMessage = "Deal Registration Approved";
            isReadyForUpdate = true;

        }//prit26-285-start
        else if(event.currentTarget.name = 'Extend Expiration Date' && !this.disableExtensionExpiration) {
            isReadyForUpdate = true;
            this.outerSpinner = true;
            if(this.dealRegistration.fields.Deal_Registration_Status__c.value == 'Expired'){
                let date = new Date();
                if(this.dealRegistration.fields.DR_Approved_Date__c.value == null)
                {//Deal was never approved
                    fields[DR_STATUS_FIELD.fieldApiName] = 'Submitted';
                    date.setDate(date.getDate() + 20);
                }else{//Deal was approved
                    date.setDate(date.getDate() + 45);
                    fields[DR_STATUS_FIELD.fieldApiName] = 'Approved';
                }
                if(this.dealRegistration.fields.OwnerId.value === this.label.SALES_DATA_OPS_QUEUE_ID){//deal was Expired from Pending Conversion status
                    fields[DR_OWNERID_FIELD.fieldApiName] = this.dealRegistration.fields.CDM__c.value;//reset owner to CDM
                }
                fields[DR_EXP_DATE_FIELD.fieldApiName] = date.toISOString().split('T')[0];
                fields[DR_SUB_STATUS_FIELD.fieldApiName] = null;
            }else if(this.dealRegistration.fields.Deal_Registration_Status__c.value != 'Expired'){
                let date = new Date(this.dealRegistration.fields.Deal_Registration_Expiration__c.value);
                if(this.dealRegistration.fields.Deal_Registration_Status__c.value == 'Pending Conversion' || this.dealRegistration.fields.Deal_Registration_Status__c.value == 'Pending Meeting'){
                    date.setDate(date.getDate() + 10);
                }else if(this.dealRegistration.fields.Deal_Registration_Status__c.value == 'Approved'){
                    date.setDate(date.getDate() + 45);
                }
                fields[DR_EXP_DATE_FIELD.fieldApiName] = date.toISOString().split('T')[0];
            }
            this.toastMessage = 'Deal Registration Expiration Extended';
        }
        //prit26-285-end*/
        if (isReadyForUpdate) {
            this.loadSpinner = true;
            const recordInput = { fields };
            console.log('recordInput' + JSON.stringify(recordInput));
            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: this.toastMessage,
                            variant: 'success'
                        })
                    );
                    // Display fresh data in the form
                    this.closeModal();
                    /*if(!this.isAccountUpdate){
                        this.closeModal();
                    }*/
                    this.loadSpinner = false;
                    this.outerSpinner = false;
                    return refreshApex(this.dealRegistration);
                })
                .catch(error => {
                    console.log('DR Update Error==' ,error);
                    console.log('DR Update Error' + JSON.stringify(Object.values(error.body.output.errors[0])[5]));
                    this.closeModal();
                    this.loadSpinner = false;
                    this.outerSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Updating Deal Registration',
                            message: JSON.stringify(Object.values(error.body.output.errors[0])[5]),
                            variant: 'error'
                        })
                    );
                });
        }
    }


    /************************************* Handler Methods **************************/
    enableDisableButtons(){
        if(this.dealRegistration.fields.Deal_Registration_Status__c.value == "Rejected" || this.dealRegistration.fields.Deal_Registration_Status__c.value == "Approved" || this.dealRegistration.fields.Deal_Registration_Status__c.value == "Expired"){
            this.disableApprove = true;
            this.disablePending = true;
            this.disableReject = true;
        }
        if(this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Meeting" || this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Conversion"){
            this.disablePending = true;
        }
        if(this.dealRegistration.recordTypeInfo.name == "Alliance" || this.dealRegistration.recordTypeInfo.name == "Engagement"){//PRIT26-10
            this.disablePending = true;
        }
        //prit26-545
        if (this.dealRegistration?.fields?.Deal_Registration_Status__c?.value === 'Escalated' && this.dealRegistration?.fields?.Opportunity_Stage__c?.value?.toLowerCase()?.includes('closed')){
            this.disableApprove = true;
            this.disablePending = true;
        }
    }

    showLeadConSection(){
        if(this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Conversion" && this.dealRegistration.fields.Deal_Registration_Status__c.value != null && this.showLeadConversion){
            this.showLeadConversion = true;
            this.showLeadConversionCB = false;
        }
    }

    openModal(event) {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
        let buttonName = event.target.id;
        if (buttonName.includes("pendingMeeting")) {
            this.isReject = false; //prit26-285- rejection reason should only show on reject
            this.showPendingMeetingCB = true;
            if (!this.isAccountAvailable) {
                this.modalHeader = 'Add Account to Deal Registration';
                this.label.DR_SDR_WARNING = 'Please search for an account in the database and add it to the deal registration.';
                this.DR_CONV_HEADER = '';
                this.showLeadConversionCB = true;
                this.disableSDRButton = true;
                this.modalButtonLabel = '';
                this.modalButtonVariant = 'brand';
                this.disableModalSubmit = true;
                this.accountPendingMeetingUpdate = true;
                this.showApprovalSection = false;
            } else {
                this.showPendingMeetingSection();
                this.showAddOpptySection = false;
            }
        }
        if (buttonName.includes("reject")) {
            this.isReject = true; //prit26-285- rejection reason should only show on reject
            this.showPendingMeetingCB = false;
            if (this.dealRegistration.fields.PS_Escalated__c.value) {
                this.modalHeader = 'Reject Deal Registration';
                this.modalLabel = this.label.PS_REJECTION;
                this.isPSEscalated = true;
                this.showDRCommentSection = true;
                this.modalButtonLabel = 'Reject';
                this.modalButtonVariant = 'destructive';
                this.disableModalSubmit = false;
            } else {
                this.showDRCommentSection = true;
                this.modalHeader = 'Reject Deal Registration';
                this.modalLabel = this.label.DR_REJECTED_LABEL;
                this.modalButtonLabel = 'Reject';
                this.modalButtonVariant = 'destructive';
                this.showApprovalSection = false;
                this.disableModalSubmit = false;
            }

        }
        if (buttonName.includes("approve")) {
            this.isReject = false;//prit26-285- rejection reason should only show on reject
            this.showPendingMeetingCB = false;
            this.dealTypeSelectedValue = this.dealRegistration.fields.Deal_Registration_Type__c.value;
            if (this.dealRegistration.fields.PS_Escalated__c.value) {
                this.disableModalSubmit = false;
                this.modalButtonLabel = 'Approve';
                this.modalButtonVariant = 'brand';
                this.modalHeader = 'Approve Deal Registration';
                this.showPSEscalationApprovalSection = true;
                this.psEscalateApproveLabel = this.label.PS_ESCALATION_RSM_RVP;
            }
            else {
                //PRIT26-10-start
                if(this.dealRegistration.recordTypeInfo.name == "Engagement"){
                    this.loadSpinner = true;
                    this.isModalOpen = false;
                    this.modalButtonLabel = 'Approve';
                    this.onClickDRConfirmAction();
                //PRIT26-10-end
                }else if (this.dealRegistration.recordTypeInfo.name == "OEM" && this.dealRegistration.fields.OEM_SubType__c.value == "Revshare" && (this.dealSubStatus == "Pending L1 Approval" || this.dealSubStatus == "Pending TVP Approval")) {
                    if (this.dealSubStatus == "Pending L1 Approval") {
                        this.showL1ApprovalSection = true;
                        this.modalHeader = 'OEM Deal Registration L1 Approval';
                    } else if (this.dealSubStatus == "Pending TVP Approval") {
                        this.showTVPApprovalSection = true;
                        this.modalHeader = 'OEM Deal Registration TVP Approval';
                    }
                    this.disableModalSubmit = false;
                    this.modalButtonLabel = 'Approve';
                    this.modalButtonVariant = 'brand';
                    this.showPreviousButton = false;
                    this.showApprovalSection = false;
                } else {
                    if (this.leadConvButton == false && this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Conversion") {
                        this.showApprovalSection = false;
                        this.DR_CONV_HEADER = 'Account and Opportunity Creation';
                        this.modalHeader = this.DR_CONV_HEADER;
                        this.onClickConvertOpty();
                    } else {
                        this.DR_CONV_HEADER = this.label.DR_SDR_CONV_HEADER;
                        this.showApprovalSection = true;
                        this.modalHeader = 'Approve Deal Registration';
                    }
                    this.showDRCommentSection = false;
                    this.modalButtonLabel = 'Approve';
                    this.modalButtonVariant = 'brand';
                    this.disableModalSubmit = true;
                    this.showPreviousButton = false;
                }
            }
        }
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.showDRCommentSection = false;
        this.isModalOpen = false;
        this.modalHeader = '';
        this.modalLabel = '';
        this.modalButtonLabel = '';
        this.showApprovalSection = false;
        this.modalButtonVariant = '';
        this.showAddOpptySection = false;
        this.toastMessage = '';
        this.disableModalSubmit = false;
        this.showLeadConversionCB = false;
        this.showSearchOpptySection = false;
        this.showLeadConversion = false;
        this.isCreateContact = false;
        this.isCreateOpportunity = false;
        this.isCreateOppty = false;
        this.isAlreadyPending = false;
        this.opptyRecord = undefined;
        this.dealRegExists = false;
        //this.opptyDealReg = '';
        this.showDateError = false;
        this.showPreviousButton = false;
        this.showCreateOppty = false;
        this.showDealInitiatedTypeSection = false;
        this.dealTypeSelectedValue = '';
        this.disableSDRButton = false;
        this.label.DR_SDR_WARNING = DR_SDR_WARNING;
        this.label.DR_CONV_HEADER = DR_SDR_CONV_HEADER;
        this.accountPendingMeetingUpdate = false;
        this.showPendingMeetingCB = false;
        //this.isAllianceDRSection = false;
        this.oppSelectionErrorMessage = '';
        this.drPrimaryOnOppty = false;
        //this.showRSMApprovalSection = false;
        this.showRegistrationTypeSection = false;
        this.isDealAutoSet = false;
        //this.registrationTypeSelectedValue = '';
        this.dealTypeSelectedValue = '';
        this.showL1ApprovalSection = false;
        this.showTVPApprovalSection = false;
        this.dealTypeSelectedPicklistValue = '';
        this.isCreateOpptyButton = false;
        this.accountIdforOpty = '';//prit24-741
        this.showPSEscalationApprovalSection = false; //prit25-18
        this.isLeadCreateUpdate = false;
        this.isOppCreateUpdate = false; //prit26-518
    }

    onDRApprovalYes(event){
        this.showApprovalSection = false;
        this.showDRCommentSection = false;
        this.showPreviousButton = true;
        /*if(this.isAccountAvailable && this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value == 'Prospect'){
            this.showDealInitiatedTypeSection = false;
            this.showAddOpptySection = true;
        }else if(this.isAccountAvailable && this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value != 'Prospect'){
            this.showDealInitiatedTypeSection = true;
        }else */if(!this.isAccountAvailable){
            this.onClickConvertOpty();
            this.showDealInitiatedTypeSection = false;
        }else if(this.isAccountAvailable && this.dealRegistration.fields.Company_Name__r.value != null){
            this.showDealInitiatedTypeSection = false;
            this.showAddOpptySection = true;
        }
    }

    onDRApprovalNo(event){
        if(this.dealRegistration.recordTypeInfo.name == "Alliance" || this.dealRegistration.recordTypeInfo.name == "Internal"){
            this.isAlreadyPending = true;
            this.pendingMeetingNoMessage = "Deal Registration cannot be set pending meeting";
        }else if(this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Meeting" || this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Conversion"){
            this.isAlreadyPending = true;
            this.pendingMeetingNoMessage = "Deal Registration already" + this.dealStatus;
        }else{
            this.openModal(event);
        }
    }

    onClickAttachOpty(event){
        let buttonName = event.target.id;
        if(this.dealRegistration.recordTypeInfo.name == 'Reseller' && (this.dealRegistration.fields.Distributor__c.value == '' || this.dealRegistration.fields.Distributor__c.value == null)){
            this.handleErrorToast('Distributor cannot be blank','Distributor is mandatory before DR Approval/Opp creation');
            return;
        }
        if(buttonName.includes("attachOpty")){
            this.template.querySelector('[data-id="attach-oppty"]').classList.remove('custom-box');
            this.template.querySelector('[data-id="attach-oppty"]').classList.add('disable-div');
            if(this.showCreateOppSec){
                this.template.querySelector('[data-id="create-oppty"]').classList.remove('custom-box');
                this.template.querySelector('[data-id="create-oppty"]').classList.add('disable-div');
            }
            this.showSearchOpptySection = true;
            this.showLeadConversionCB = false;
            this.showLeadConversion = false;
            this.isCreateOppty = false;
            this.isCreateOpportunity = false;
            this.isCreateContact = false;
            this.showCreateOppty = false;
            this.showDateError = false;
            this.showCreateContactButton = true;
            this.showPreviousButton = true;
        }
    }

    onClickConvertOpty(){
        this.selectedOpportunityId = '';
        this.disableModalSubmit = true;
        this.showSearchOpptySection = false;
        this.showLeadConversionCB = true;
        this.isCreateOppty = false;
        this.isCreateOpportunity = false;
        this.isCreateContact = false;
        this.showCreateOppty = false;
        this.isCreateOpportunity = false;
        this.showDateError = false;

        if(this.dealRegistration.fields.Lead__c.value != null && this.dealRegistration.fields.Deal_Registration_Status__c.value == "Pending Conversion"){
            this.showLeadConversion = true;
            this.showLeadConversionCB = false;
        }
    }

    onClickCreateOpty(event){
        this.oppRecordId = null; //PRIT24-851 
        let buttonName = event.target.id;
        if(buttonName.includes("createOpty")){
            this.isCreateOpptyButton = true;
            this.template.querySelector('[data-id="attach-oppty"]').classList.remove('custom-box');
            this.template.querySelector('[data-id="attach-oppty"]').classList.add('disable-div');
            if(this.showCreateOppSec){
                this.template.querySelector('[data-id="create-oppty"]').classList.remove('custom-box');
                this.template.querySelector('[data-id="create-oppty"]').classList.add('disable-div');
            }
            this.selectedOpportunityId = '';
            this.disableModalSubmit = true;
            this.showSearchOpptySection = false;
            this.showLeadConversionCB = false;
            this.showAddOpptySection = true;
            this.opptyRecord = undefined;
            this.dealRegExists = false;
            //this.opptyDealReg = '';
            this.isCreateContact = false;
            this.isCreateOpportunity = false;
            this.showDateError = false;
            this.showCreateContactButton = true;
            this.showPreviousButton = true;
            this.showApprovalSection = false;
            this.showCreateOppty = false;
            this.oppSelectionErrorMessage = '';
            this.getContactList();
            if(this.isAccountAvailable && this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value != 'Prospect'){
                this.showDealInitiatedTypeSection = true;
                this.dealTypeSelectedPicklistValue = '';//PRIT24-851 
            }else{
                this.isCreateOppty = true;
            }
        }
    }

    handleOpptySelection(event){
        let selectedOppty = event.detail.value[0];
        this.dealRegExists = false;
        this.oppSelectionErrorMessage = '';
        this.drPrimaryOnOppty = false;
        this.drAssociationRID = false;
        this.showRegistrationTypeSection = false;
        if(selectedOppty!='' && selectedOppty!=undefined){
            this.selectedOpportunityId = selectedOppty;
            this.oppRecordId = selectedOppty;
            this.checkDRandOpptyAssociation();
            this.loadSpinner = true;
            this.dealTypeSelectedPicklistValue = '';//PRIT24-851 
        }else{
            this.disableModalSubmit = true;
        }
    }

    handleSendToSDR(event){
        let isSendtoSDR = event.target.id;
        this.isAccountValueRequired = false;
        Promise.resolve().then(() => {
        if(isSendtoSDR.includes("sendToSDR")){
            if(this.dealRegistration.fields.Partner_Lookup__c.value == '' || this.dealRegistration.fields.Partner_Lookup__c.value == null){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Partner Lookup Missing',
                        message: 'Partner Lookup is mandatory before Deal Registration is sent for Account Creation',
                        variant: 'error',
                    }),
                );
            }else{
                this.isLeadCreateUpdate = true;
                this.onClickDRConfirmAction(event);
            }
        }
        });
    }

    handleConvertLead(event){
        let drLeadId = this.template.querySelector('[data-id="leadid"]');
        if(drLeadId.value){
            this.leadRecordId = drLeadId.value;
            this.navigateToUrl();
        }
    }

    handleRejectionReason(){
        this.rejectRsn = this.template.querySelector('[data-id="rejectionReasonId"]').value;
    }

    createContact(){
        this.isCreateContact = true;
        this.isCreateOppty = false;
        this.isCreateOpportunity = false;
        this.showCreateOppty = false;
        this.showPreviousButton = true;
        this.showApprovalSection = false;
    }

    createOpportunity(){
        this.isCreateContact = false;
        this.isCreateOppty = false;
        this.isCreateOpportunity = true;
        this.showCreateOppty = false;
        this.showPreviousButton = true;
        this.showApprovalSection = false;
    }

    createContactSuccess(event){
        this.contactId = event.detail.id;
        this.isCreateOppty = true;
        this.isCreateContact = false;
        this.showCreateOppty = false;
        this.loadSpinner = false;
        this.showCreateContactButton = true;
        this.showPreviousButton = true;
        this.getContactList();
    }

    getSelectedRecord(event){
        const selectedRows = event.detail.selectedRows;
        if(selectedRows.length>0){
            this.contactId = selectedRows[0].Id;
            this.showCreateContactButton = false;
            this.showCreateOppty = true;
        }
    }

    createOpportunitySuccess(event){
        this.selectedOpportunityId = event.detail.id;
        this.isAccountUpdate = false;
        this.isOppCreateUpdate = true;
        this.onClickDRConfirmAction(event);
    }

    handleAddAccount(event){
        this.outerSpinner = true;
        this.isLeadCreateUpdate = false;
        this.isAccountValueRequired = true;
        this.showAddOpptySection = false;
        Promise.resolve().then(() => {
            let accountId = this.template.querySelector('[data-id="accId"]');
            if(!accountId.value){
                accountId.reportValidity();
                accountId.focus();
                this.outerSpinner = false;
            }else{
                this.isModalOpen = false; //////
                this.isAccountUpdate = true;
                this.accountId = accountId.value;
                this.onClickDRConfirmAction(event);
            }
        });
    }

    handleCloseDateSelection(event){
        let selectedDate = event.detail.value;
        if(new Date(selectedDate) < new Date()){
            let dateField = this.template.querySelector("lightning-input-field[data-id=close-date]");
            dateField.value = '';
            dateField.focus();
            this.showDateError = true;
        }else{
            this.showDateError = false;
        }
    }

    createRecordSubmit(){
        this.loadSpinner = true;
    }

    createRecordSubmitOppty(event){
        this.loadSpinner = true;
        event.preventDefault();
        let activeContractStatus = this.label.DR_ACTIVE_CONTRACT.split(';');  //prit26-307
        const fields = event.detail.fields;
        //PRIT24-538 : Avoid attaching opportunity to DR without Partner lookup
        if(this.dealRegistration.fields.Partner_Lookup__c.value == null || this.dealRegistration.fields.Partner_Lookup__c.value == '') {
            this.handleErrorToast('Partner cannot be blank','Unable to create opportunity without Partner Lookup on Deal Registration');
        } //prit26-145-start 
        else if(this.dealRegistration.recordTypeInfo.name == 'Reseller' && (this.dealRegistration.fields.Distributor__c.value == '' || this.dealRegistration.fields.Distributor__c.value == null)) {
            this.handleErrorToast('Distributor cannot be blank','Distributor is mandatory before DR Approval/Opp creation');   
        } //prit26-145-end
        //prit26-307-start
        else if(this.dealRegistration.fields.Partner_Contract_Status__c.value == null || this.dealRegistration.fields.Partner_Contract_Status__c.value == '' || !activeContractStatus.includes(this.dealRegistration.fields.Partner_Contract_Status__c.value)) {
            this.handleErrorToast('Agreement cannot be inactive',this.label.DR_CONTRACT_INACTIVE);   
        } //prit26-307-end
        else{
            if(fields != null && 'StageName' in fields && (this.dealRegistration.recordTypeInfo.name == 'Reseller' || this.dealRegistration.recordTypeInfo.name == 'Internal' || (this.dealRegistration.recordTypeInfo.name == 'Alliance' && this.dealRegistration.fields.Alliance_Type__c.value == 'Cloud'))){
                fields.Deal_Registration__c = true;
                fields.Deal_Registration_Number__c = this.dealRegistration.fields.Name.value;
                fields.Deal_Reg_Approval_Status__c = 'Approved';
                fields.Projected_Product_Mix__c = 'Fresh';
                if(this.dealTypeSelectedValue != null && this.dealTypeSelectedValue != ''){
                    this.setDealInitiatedType(this.dealTypeSelectedValue);
                    fields.Deal_Registration_Type__c = this.dealInitiatedTypeValue;
                }else{
                    this.setDealInitiatedType(this.dealRegistration.fields.Deal_Registration_Type__c.value);
                    fields.Deal_Registration_Type__c = this.dealInitiatedTypeValue;
                }
            }else if (fields != null && 'StageName' in fields){
                if(this.dealTypeSelectedValue != null && this.dealTypeSelectedValue != ''){
                    this.setDealInitiatedType(this.dealTypeSelectedValue);
                    fields.Deal_Registration_Type__c = this.dealInitiatedTypeValue;
                }else{
                    fields.Deal_Registration_Type__c = 'Rubrik Initiated Deal';
                }
                fields.Deal_Reg_Expiration_Date__c = '';
                fields.Projected_Product_Mix__c = 'Fresh';
            }
            fields.AccountId = this.dealRegistration.fields.Company_Name__c.value;
            this.template.querySelector('[data-id="opptyRecForm"]').submit(fields);
            }
    }

    handleErrorToast(title, msg) {
            this.loadSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                title: title,
                message : msg,
                    variant: 'error',
                }),
            );
        }

    handlePreviousClick() {
        let contactScreen = false;
        if (this.isCreateOppty == true && contactScreen == false) {
            this.showSearchOpptySection = true;
            this.isCreateOppty = false;
            this.isCreateContact = false;
        }
        if (this.showRegistrationTypeSection == true) {
            this.showSearchOpptySection = true;
            this.showRegistrationTypeSection = false;
            //this.registrationTypeSelectedValue = '';
            this.dealTypeSelectedValue = '';
            this.dealTypeSelectedPicklistValue = '';
            this.oppPSEscalated = false;//prit25-17
            this.isPSEscalated = false;//prit25-17
        }
        if (this.showDealInitiatedTypeSection == true) {
            //this.showApprovalSection = true;
            this.showDealInitiatedTypeSection = false;
            this.showSearchOpptySection = true;
            //this.registrationTypeSelectedValue = '';
            this.dealTypeSelectedValue = '';
            this.dealTypeSelectedPicklistValue = '';
            this.showPreviousButton = true;
            this.oppPSEscalated = false;//prit25-182
            this.isPSEscalated = false;//prit25-182
        }
        /*if(this.showAddOpptySection == true && this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value != 'Prospect'){
            this.showDealInitiatedTypeSection = true;
            this.showApprovalSection = false;
            this.showAddOpptySection = false;
            this.showPreviousButton = true;
        }*/
        if (this.showAddOpptySection == true && this.dealRegistration.fields.Company_Name__r.value != null/* && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value == 'Prospect'*/) {
            this.showApprovalSection = true;
            this.showPreviousButton = false;
            this.showAddOpptySection = false;
            this.showDealInitiatedTypeSection = false;
            this.isCreateOpptyButton = false;
        }
        if (this.showSearchOpptySection == true) {
            this.disableModalSubmit = true;
            this.showAddOpptySection = true;
            this.showPreviousButton = true;
            this.showSearchOpptySection = false;
            this.showApprovalSection = false;
            this.showDealInitiatedTypeSection = false;
            this.dealRegExists = false;
            this.drPrimaryOnOppty = false;
            this.isCreateOpptyButton = false;
            this.template.querySelector('[data-id="attach-oppty"]').classList.add('custom-box');
            this.template.querySelector('[data-id="attach-oppty"]').classList.remove('disable-div');
            if(this.showCreateOppSec){
                this.template.querySelector('[data-id="create-oppty"]').classList.add('custom-box');
                this.template.querySelector('[data-id="create-oppty"]').classList.remove('disable-div');
            }
        }
        if (this.showLeadConversionCB == true) {
            this.showApprovalSection = true;
            this.showPreviousButton = false;
            this.showLeadConversionCB = false;
        }
        if (this.isCreateContact) {
            this.showAddOpptySection = true;
            this.showPreviousButton = true;
            this.showApprovalSection = false;
            this.isCreateContact = false;
            this.showCreateContactButton = true;
            this.isCreateOppty = true;
            this.showDealInitiatedTypeSection = false;
            contactScreen = true;
        }
        if (this.isCreateOpportunity) {
            this.showAddOpptySection = true;
            this.isCreateOpportunity = false;
            this.showPreviousButton = true;
            this.showApprovalSection = false;
            this.showCreateContactButton = true;
            this.isCreateOppty = true;
            this.showDealInitiatedTypeSection = false;
            contactScreen = true;
        }
        if (this.showLeadConversion == true) {
            this.showPreviousButton = false;
            this.showLeadConversion = false;
            this.showAddOpptySection = false;
            this.showApprovalSection = true;
        }
    }

    navigateToUrl(){
        this[NavigationMixin.Navigate]({
            type : 'standard__webPage',
            attributes : {
                url : '/apex/CustomLeadConversion?id=' + this.leadRecordId
           }
        })
    }

    formatDate(dateTimeValue){
        let year = dateTimeValue.getFullYear();
        let month = dateTimeValue.getMonth()+1;
        let day = dateTimeValue.getDate();

        if (day < 10) {
            day = '0' + day;
        }

        if (month < 10) {
            month = '0' + month;
        }

        let formattedDate = year + '-' + month + '-' + day;
        return formattedDate;
    }

    handleErrors(event) {
        let message = event.detail.detail;
        console.log('field error'+JSON.stringify(event.detail.output.fieldErrors));
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error Updating the record',
                message,
                variant: 'error',
            }),
        );
    }

    /*handleDealTypeSelection(event){
        let dealType = event.detail.value;
        if(dealType){
            this.dealTypeSelectedValue = dealType;
            //this.showAddOpptySection = true;
            //this.showDealInitiatedTypeSection = false;
            this.disableModalSubmit = false;
            this.oppSelectionErrorMessage = '';
        }else if(dealType == ""){
            this.dealTypeSelectedValue = '';
            this.disableModalSubmit = true;
        }
    }*/

    handleRegistrationTypeSelection(event) {
        let regType = event.detail.value;
        console.log('regType' + regType);
        if (regType) {
            if (this.isCreateOpptyButton) {
                this.isCreateOppty = true;
                this.showDealInitiatedTypeSection = false;
                this.disableModalSubmit = true;
                this.dealTypeSelectedValue = regType;
                this.dealTypeSelectedPicklistValue = regType;
                this.drPrimaryOnOppty = true;
                this.dealRegExists = false;
                this.oppSelectionErrorMessage = '';
            } else {
                //prit25-17 - start
                if (this.oppPSEscalated && (regType == 'Partner Sourced New Logo (PSNL)' || regType == 'Partner Sourced Expand')) {//prit25-182
                    this.oppSelectionErrorMessage = this.label.PS_ESCALATION;
                    this.dealRegExists = true;
                    this.isPSEscalated = true;
                    this.disableModalSubmit = false;
                    }else {
                        this.oppSelectionErrorMessage = '';
                        this.dealRegExists = false;
                        this.isPSEscalated = false;
                    this.disableModalSubmit = false;
                    }
                this.dealTypeSelectedValue = regType;
                this.dealTypeSelectedPicklistValue = regType;
                this.drPrimaryOnOppty = true;
                //prit25-17 - end
            }
            this.setDealInitiatedType(regType);
            /*this.dealTypeSelectedValue = regType;
            this.dealTypeSelectedPicklistValue = regType;
            this.drPrimaryOnOppty = true;
            this.dealRegExists = false;
            this.oppSelectionErrorMessage = '';*/
        } else if (regType == "") {
            this.dealTypeSelectedValue = '';
            this.dealTypeSelectedPicklistValue = '';
            this.dealInitiatedTypeValue = '';
            this.disableModalSubmit = true;
        }
    }

    showPendingMeetingSection(){
        this.showDRCommentSection = true;
        this.modalHeader = 'Move Deal Registration to Pending Meeting';
        this.modalLabel = this.label.DR_PENDING_MEETING_LABEL;
        this.modalButtonLabel = 'Pending Meeting';
        this.modalButtonVariant = 'brand';
        this.showApprovalSection = false;
        this.disableModalSubmit = false;
    }

    handlePendingMeetCB(event){
        let isCBChecked = event.target.checked;
        if(isCBChecked){
            this.showPendingMeetingSection();
            this.showLeadConversionCB = false;
        }
    }

    get dealTypeOptions() {
        //PRIT24-851-Added oppRecordId != null & "else condition" 
        if (this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value != 'Prospect' && this.oppRecordId != null){
            return [
                {label: '--None--', value: ''},
                { label: 'Partner Sourced Expand', value: 'Partner Sourced Expand' },
                { label: 'Rubrik Sourced', value: 'Rubrik Sourced' }
            ];
        }else if(this.dealRegistration.fields.Company_Name__r.value != null && this.dealRegistration.fields.Company_Name__r.value.fields.Type.value != 'Prospect'){
            return [
                { label: 'Partner Sourced Expand', value: 'Partner Sourced Expand' }
            ];
        }
    }

    get dealInitiatedTypeOptions() {
        return [
            { label: '--None--', value: ''},
            { label: 'Partner Sourced New Logo (PSNL)', value: 'Partner Sourced New Logo (PSNL)' },
            { label: 'Rubrik Sourced', value: 'Rubrik Sourced' },
        ];
    }

    setDealInitiatedType(regisType){
        if(regisType == 'Partner Sourced New Logo (PSNL)'){
            this.dealInitiatedTypeValue = 'Partner Sourced New Logo (PSNL)';
            this.registrationType = 'Partner Sourced';
        }else if(regisType == 'Partner Sourced Expand'){
            this.dealInitiatedTypeValue = 'Partner Sourced Expand';
            this.registrationType = 'Partner Sourced';
        }else if(regisType == 'Rubrik Sourced'){
            this.dealInitiatedTypeValue = 'Rubrik Sourced';
            this.registrationType = 'Value Add';
        }
    }
}