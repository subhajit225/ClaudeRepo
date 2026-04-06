/**
* @File Name : CaseDetailsControllerLWC.cls
* @Description : Created new LWC Component lgt_caseInfoSectionLWC to increase the performance of Case Header Section
* @Author : Grazitti
* @Last Modified By : Shailesh Kumar
* @Last Modified On : March 6, 2025
* @TestClass : CaseDetailsControllerLWC_Test
// ********************Change Logs ******************************************************************************************************************************************************

* Modified By          Date                     Description
* Shailesh Kumar       12 March, 2025           Created new LWC Component lgt_caseInfoSectionLWC to increase the performance of Case Header Section
* Shailesh Kumar       25 March, 2025           fixed issue of scrolling when updating hot critical issue field from hero header section and ACV Amount field label text

// ********************Change Logs Ends**************************************************************************************************************************************************/
/**
 * @description class used to get fields for hero header section based on recordtype of the case
*/ 
public with sharing class CaseDetailsControllerLWC {
    /**
     * @description
     * @param recId id of the case
     * @return recordType
    */
	@AuraEnabled
    public static string getRecType(String recId){
        return [Select RecordType.Name from Case where Id=:recId].RecordType.Name;
    }
    /**
     * @description
     * @param recId id of the case
     * @return case information to show hide the milestone component on Case Detail page below the hero header section
    */
    @AuraEnabled
    public static WrapperCaseDetails getCaseInfo(String recId){
        Boolean showMilestoneComp = false;
        Case csInfo = null;
        WrapperCaseDetails csDetails = new WrapperCaseDetails();
        csInfo = [SELECT Id,RecordType.Name,Initial_Milestone_Flag_Name__c,(SELECT Id FROM CaseMilestones WHERE IsViolated =true AND IsCompleted=false) FROM Case WHERE Id=:recId WITH USER_MODE];
        csDetails.recordTypeName = csInfo.RecordType.Name;
        csDetails.showMilestone = (csInfo.Initial_Milestone_Flag_Name__c == 'Yellow' || csInfo.Initial_Milestone_Flag_Name__c == 'Orange' || csInfo.CaseMilestones.size() >0) ? true : false;//LIG-3
        return csDetails;
    }
    /**
     * @description : Case Info Section - showing fields on hero header section for a case record.
     * @param  recordId : id of the case
     * @return Wrappercase
    */
    @AuraEnabled
    public static Wrappercase getFields(String recordId){
        List<String> nonRatingFields = new List<String>{'Status','Origin','Priority','Platform__c','Problem_Type__c',
            'Sub_Component__c','Software_Version__c','Case_Severity__c','Product_Name__c','If_Other__c','Product_Area__c',
            'Phase__c','Churn_Reason__c','CSM_Owner__c','Quoting_Specialist__c','CSM_Summary_Status__c',
            'CustomerFirstContact__c','CustomerOnboardingCompletion__c','CustomersFirstResponse__c','Entitlement__c',
            'Sub_Phase__c','Snooze_End_DateTime__c','Customer_Sentiments__c'};
        Wrappercase newRecord = new Wrappercase();
        List<wrapper> listWrapper = new List<wrapper>();
        Case caserecord = null;
        User u = null;
        String query = 'Select ';

        List<String> managerProfiles = Label.CaseInfoManagerProfiles.trim().split(',');
        if (Schema.sObjectType.User.isAccessible()) {
            u = [SELECT id, Profile.Name, is_Customer_Success_User__c FROM User WHERE id =: Userinfo.getUserId()];
        }
        List<Schema.FieldSetMember> fieldset;
        if (Schema.sObjectType.Case.isAccessible()) {
            caserecord = [SELECT id,RecordType.Name FROM Case WHERE Id =: recordId];
        }
        if(u!=null && u.is_Customer_Success_User__c){//change from division to is_Customer_Success_User__c
            fieldset = SObjectType.Case.FieldSets.Customer_Sucess_Fieldset.getFields();
        }else if(caseRecord!=null && caseRecord.RecordType.Name == 'Renewal Case'){
            fieldset = SObjectType.Case.FieldSets.Renewal_Fieldset.getFields();
        }else{
            fieldset = SObjectType.Case.FieldSets.ConsoleFields.getFields();
        }

        newRecord.isCustomerSuccessUser = u.is_Customer_Success_User__c;
        newRecord.sectionLabel = u.is_Customer_Success_User__c ? 'Customer Success' : 'Case Information';
        newRecord.isSupportManager = managerProfiles.contains(u.Profile.Name) ? true : false;
        for(Schema.FieldSetMember each : fieldset){
            wrapper eachRecord = new wrapper();
            eachRecord.label = each.getLabel();
            eachRecord.Name= each.getFieldPath();
            eachRecord.isUrlField = false;
            eachRecord.showCopyIcon = false;
            eachRecord.isEditMode = false;
            eachRecord.isCustomUrl = false;
            if(eachRecord.Name == 'AccountId'){
                eachRecord.label = 'Account Name';
                eachRecord.showCustomLabel = true;
            }
            if(eachRecord.Name == 'CreatedDate'){
                eachRecord.label = 'Date/Time Opened';
            }
            if(eachRecord.Name == 'Case_Owner_Name__c'){
                eachRecord.label = 'Case Owner';
                eachRecord.showCustomLabel = true;
            }
            if(eachRecord.Name == 'OwnerId'){
                eachRecord.label = 'Owner Name';
                eachRecord.showCustomLabel = true;
            }
            if(eachRecord.Name == 'Opportunity_lookup__r.ACV_Amount__c'){
                eachRecord.label = 'ACV Amount';
                eachRecord.showCustomLabel = true;
            }
            if(eachRecord.Name == 'Account.OwnerId' && newRecord.isCustomerSuccessUser){
                eachRecord.label = 'Account Executive';
            }
            if(eachRecord.Name == 'LastModifiedById'){
                eachRecord.label = 'LastModified By';
            }
            if(eachRecord.Name == 'Account.Id' && newRecord.isCustomerSuccessUser){
                eachRecord.label = 'Id';
            }
            if(eachRecord.Name == 'Feature__c' && newRecord.isCustomerSuccessUser){
                eachRecord.label = 'Feature Name';
            }
            if(eachRecord.Name == 'Cluster__c' || eachRecord.Name == 'Additional_Cluster__c'){
                eachRecord.isCustomUrl = true;
            }
            eachRecord.isLookupField = false;
            eachRecord.lookupFieldValue = '';
            eachRecord.Type= String.ValueOf(each.getType());    //CS21-1984
            eachRecord.isFieldTypeDateTime = eachRecord.Type == 'DATETIME' ? TRUE : FALSE;
            if(nonRatingFields.contains(each.getFieldPath()) 
              || (each.getFieldPath() == 'HotCriticalIssue__c' && newRecord.isSupportManager)
              || (each.getFieldPath() == 'Sales_Escalated__c' && newRecord.isSupportManager)
              || (each.getFieldPath() == 'OwnerId' && caserecord.RecordType.Name == 'Renewal Case')){
                eachRecord.isNotRatingField = true;
              }else{
                  eachRecord.isNotRatingField = false;
              }
            listWrapper.add(eachrecord);
            query +=each.getFieldPath() + ',';
        }
        newRecord.wrapperList = listWrapper;
        if(u.is_Customer_Success_User__c && !query.containsIgnoreCase('Account.Rubrik_Sales_Engineer__r.Name')){ 
            query += ' Account.Rubrik_Sales_Engineer__r.Name, ';
        }
        if(query.containsIgnoreCase('Cluster__c')){
            query += ' Cluster__r.Name, ';
        }
        if(query.containsIgnoreCase('Additional_Cluster__c')){
            query += ' Additional_Cluster__r.Name, ';
        }
        if(query.containsIgnoreCase('Feature__c')){
            query += ' Feature__r.Feature__c, ';
            query += ' Feature__r.Id, ';
        }
        //Added EscalationManagerOwner__r.Name field - CS21-504 - Veera
        query += ' EscalationManagerOwner__r.Name, Id, Account.Owner.Name, RecordType.Name FROM Case where Id = :recordId';
        case cs = null;
        if (Schema.sObjectType.Case.isAccessible()) {
            cs = Database.query(String.escapeSingleQuotes(query));
        }
        newRecord.recordDetail = cs;
        return newRecord; 
    }
    /**
     * @description used in WrapperCase
    */
	public class Wrapper{
        /**
        * @description label of the field
        */
        @AuraEnabled
        public String label{get;set;}
        /**
        * @description to store API name of the field
        */
        @AuraEnabled
        public String Name{get;set;}
        /**
        * @description type of the field
        */
        @AuraEnabled
        public String Type{get;set;}
        /**
        * @description for non rating fields
        */
        @AuraEnabled
        public Boolean isNotRatingField {get;set;}
        /**
        * @description to show dateTime type fields
        */
        @AuraEnabled
        public Boolean isFieldTypeDateTime {get;set;}
        /**
        * @description if it is true then field will go in edit mode
        */
        @AuraEnabled
        public Boolean isEditMode {get;set;}
        /**
        * @description to show field as lookup
        */
        @AuraEnabled
        public Boolean isLookupField {get;set;}
        /**
        * @description to store lookup field value
        */
        @AuraEnabled 
        public String lookupFieldValue {get;set;}
        /**
        * @description to show copy icon
        */
        @AuraEnabled
        public Boolean showCopyIcon {get;set;}
        /**
        * @description if this is true then field will be rendered as formatted url
        */
        @AuraEnabled
        public Boolean isUrlField {get;set;}
        /**
        * @description if true then outfield's label will be shown in label tag and variant for outputfield will be "label-hidden"
        */
        @AuraEnabled
        public Boolean showCustomLabel {get;set;}
        /**
        * @description to show the cluster field as custom url to open in new tab
        */
        @AuraEnabled
        public Boolean isCustomUrl {get;set;}
        /**
        * @description to hold the custom url link
        */
        @AuraEnabled
        public String customUrlLink {get;set;}

    }
    /**
     * @description used as a wrapper
    */
    public class WrapperCase{
        /**
        * @description to store case record details
        */
        @AuraEnabled
        public Sobject recordDetail{get;set;}
        /**
        * @description List of wrapper class data
        */
        @AuraEnabled
        public List<Wrapper> wrapperList{get;set;}
        /**
        * @description to store sectionLabel
        */
        @AuraEnabled
        public String sectionLabel {get;set;}
        /**
        * @description to store the user is Customer Success user or not
        */
        @AuraEnabled
        public Boolean isCustomerSuccessUser {get;set;}
        /**
        * @description to store the user is Support manager or not
        */
        @AuraEnabled
        public Boolean isSupportManager {get;set;}
    }
    /**
     * @description used as a wrapper
    */
    public class WrapperCaseDetails{
        /**
        * @description to store record type name
        */
        @AuraEnabled
        public String recordTypeName {get;set;}
        /**
        * @description to show hide the milestone component on UI
        */
        @AuraEnabled
        public Boolean showMilestone {get;set;}
    }
    /**
     * @description used as a wrapper for getRecentOwnerChange method
    */
    public class WrapperOwnerChange {
        /**
        * @description to store owner changed flag
        */
        @AuraEnabled
        public Boolean isOwnerChanged {get;set;}
        /**
        * @description stores the error message
        */
        @AuraEnabled
        public String errorMessage {get;set;}
    }
}