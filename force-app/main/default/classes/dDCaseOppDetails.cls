/**
* Date : September-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
* Test class : dDCaseOppDetails_Test
**/
public class dDCaseOppDetails {
    /**
    * @description
    * @param String oppId
    * @return WrapperClass
    * **/
     @AuraEnabled(cacheable=true)
    public static WrapperClass getOppDetails(String oppId){

        WrapperClass objWrap = new WrapperClass();

        if(string.isNotBlank(oppId)){
            objWrap.oppRecord = [Select Id,RecordType.name, StageName, CloseDate,AccountId, OwnerId, ACV_Amount__c,Amount, ETM_Theatre__c, ETM_Area__c,ETM_Region__c,
            Deal_Structuring_Oppty_Notes__c, In_Forecast_Theatre__c,Primary_Quote_Approval_Status__c,SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.SBQQ__Status__c,
            (Select id from Deal_Desk_Cases__r) from Opportunity where Id =: oppId LIMIT 1]; //DD25-7

            objWrap.oppRecordType = objWrap.oppRecord.RecordType.name; //DD25-7
            // DD25-88 starts
            if(objWrap.oppRecord.SBQQ__PrimaryQuote__c != null){
            	SBQQ__Quote__c prmQt  = [Select id,(Select id,Name from Deal_Desk_Cases__r) from SBQQ__Quote__c where id =: objWrap.oppRecord.SBQQ__PrimaryQuote__c LIMIT 1];
                if(prmQt.Deal_Desk_Cases__r != null && !prmQt.Deal_Desk_Cases__r.isEmpty()){
                 objWrap.ddcAlreadyExist = FALSE;
                 objWrap.ddcName = prmQt.Deal_Desk_Cases__r[0].Name;
                }
            }  
             // DD25-88 Ends   
            list<Opportunity> liOpp = new List<Opportunity>{objWrap.oppRecord};
            for(Opportunity opp : liOpp){
                objWrap.caseCount = opp.Deal_Desk_Cases__r.size();
            }
        }
        
        objWrap.ddReqId = UserInfo.getUserId();

        return objWrap;
    }
    /**
    * @description
    * @return map<string,string>
    * **/
    @AuraEnabled(cacheable=true)
    public static map<string,string> getQuesMetadata(){
        List<Deal_Desk_Template_Questions__mdt> quesMdt = [select Request_Type__c, Template_Question__c from Deal_Desk_Template_Questions__mdt];
        Map<String,String> valToQuesMap = new Map<String,String>();
        for(Deal_Desk_Template_Questions__mdt mdt : quesMdt){
            valToQuesMap.put(mdt.Request_Type__c,mdt.Template_Question__c);
        }
        return valToQuesMap;
    }
    /**
    * @description
    * @param string ddcId
    * @return WrapperClass2
    * **/
    @AuraEnabled(cacheable=true)
    public static WrapperClass2 getDDCPermission(string ddcId){
        //Boolean isDDCUser = false;
        WrapperClass2 objWrap2 = new WrapperClass2();
       /*List<PermissionSetAssignment> liPSA = [Select Id,PermissionSet.name from PermissionSetAssignment where AssigneeId =: UserInfo.getUserId()];
        for(PermissionSetAssignment li : liPSA){
            if(li.PermissionSet.name == 'DDC_Ticketing_User'){
                objWrap2.isDDCUser = true;
            }
        }*/
        Boolean isEnabled = FeatureManagement.checkPermission('Deal_Desk_Ticketing_User_Permission');
        if(isEnabled){
            objWrap2.isDDCUser = true;
        }
        if(ddcId!=null && ddcId!=''){
            objWrap2.ddCaseRecord = [select id, Request_Status__c, Case_Status__c from Deal_Desk_Case__c where Id =: ddcId LIMIT 1 ];
        }
        return objWrap2;
    }    
    /**
    * @description SAL26-1147
    * @param recordId
    * @param elapsedTime
    **/
    @AuraEnabled
    public static void saveElapsedTime(Id recordId, string elapsedTime) {
        if(recordId != null){
            List<Deal_Desk_Case__c> deal = [SELECT Id, Time_To_First_Response__c FROM Deal_Desk_Case__c  WHERE Id = :recordId LIMIT 1];
            if (!deal.isEmpty() && (String.isBlank(deal[0].Time_To_First_Response__c) || deal[0].Time_To_First_Response__c == '00:00:00')) {
                deal[0].Time_To_First_Response__c = elapsedTime;
                update deal;
            }
        }
    }
    /**
    * @description
    *
    *
    * **/
    public class WrapperClass {
        @AuraEnabled
        public Opportunity oppRecord;
        @AuraEnabled
        public integer caseCount=0;
        @AuraEnabled
        public String ddReqId;
        @AuraEnabled
        public String oppRecordType; //DD25-7
        @AuraEnabled
        public Boolean ddcAlreadyExist; //DD25-88
        @AuraEnabled
        public String ddcName; //DD25-88
    }
    /**
    * @description
    *
    *
    * **/
     public class WrapperClass2 {
        @AuraEnabled
        public boolean isDDCUser = false;
        @AuraEnabled
        public Deal_Desk_Case__c ddCaseRecord;
       
    }
}