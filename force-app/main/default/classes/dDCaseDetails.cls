/**
* Date : September-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
* Test class : dDCaseOppDetails_Test
**/
public class dDCaseDetails {

    @AuraEnabled(cacheable=true)
    public static WrapperClass getddCaseDetails(String ddCaseId){

        WrapperClass objWrap = new WrapperClass();

        if(string.isNotBlank(ddCaseId)){
            objWrap.ddRecord = [Select Id, Request_Status__c, Opportunity_Stage__c from Deal_Desk_Case__c where Id =: ddCaseId LIMIT 1];
        }
         return objWrap;
    }

    @AuraEnabled
    public static void updateCase(String ddCaseId){
         try{
            Deal_Desk_Case__c ddc = new Deal_Desk_Case__c();
            ddc.Id = ddCaseId;
            ddc.Request_Status__c = 'Draft';
            ddc.ApprovalStatus__c = null;
            ddc.Amount_Conditional__c = null;
            ddc.Close_Date_Conditional__c = null;
            ddc.Primary_Quote_Conditional__c = null;
            update ddc;
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }


    public class WrapperClass {

        @AuraEnabled
        public Deal_Desk_Case__c ddRecord;
    }

}