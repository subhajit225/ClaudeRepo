public without sharing class PC_PartnerFundReqController {
    public string precordId{get;set;}
    private final PartnerFundRequest pfr;
    public string msg{get;set;}
    private static List<string> pickListValues;
    public PC_PartnerFundReqController(ApexPages.StandardController stdController){
        this.pfr = (PartnerFundRequest)stdController.getRecord();
        precordId = pfr.Id;
    }
    @AuraEnabled
    public static List<string> getPicklistValues(string fieldName){
        try{
            system.debug(fieldName);
            Schema.sObjectType objType = PartnerFundRequest.getSObjectType();
            String pickFieldAPI = fieldName.toLowerCase();
            Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
            Schema.SObjectField pickField = objFieldMap.get(pickFieldAPI);
            List<Schema.PicklistEntry> fieldValues = pickField.getDescribe().getPicklistValues();
            pickListValues = new List<string>();              
            for (Schema.PicklistEntry a : fieldValues) {                  
                pickListValues.add(a.getLabel()+';'+a.getValue());
            }
        }catch (Exception e){             
            system.debug('Exception occured '+e.getMessage()+ ' at line number '+e.getLineNumber());           
        }
        system.debug('## Options'+ pickListValues); 
        return pickListValues;
    }

    @AuraEnabled
    public static string savePartnerFundReq(string title,string PO_Currency,string Activity,string Activity_Objective,string Alliances,Date Activity_Start_Date,Date Activity_End_Date,string RequestedAmount,string Description, List<Id> docIds, String dedicatedResourceName, String jobTitle, String mos1, String mos2, String mos3, String mos4){
        string flag = 'success';
        boolean doNotCreateCampaign = false;
        List<user> userList = new List<user>();
        userList = [select Id, accountId
                    from user
                    where Id = :userinfo.getUserId()];

        //PRIT24-428
        //Avoid Campaign Creation for 'Training and Readiness', 'Sales Incentive', 'Dedicated Resource' MDFs
        if(Activity == 'Training and Readiness' || Activity == 'Sales Incentives' || Activity == 'Dedicated Resource'){
            doNotCreateCampaign = true;
        }
        PartnerFundRequest pfrec= new PartnerFundRequest();
        ContentDocument conDoc = new ContentDocument();
        try {  
            pfrec.Status = 'Draft';
            pfrec.title = title;
            pfrec.Activity = Activity;
            pfrec.Activity_Objective__c = Activity_Objective;
            pfrec.PO_Currency__c = PO_Currency;
            pfrec.Alliances__c = Alliances;
            pfrec.Activity_Start_Date__c = Activity_Start_Date;
            pfrec.Activity_End_Date__c = Activity_End_Date;
            pfrec.RequestedAmount = Double.valueOf(RequestedAmount);
            pfrec.Description = Description;
            pfrec.ChannelPartnerId = userList[0].accountId;
            pfrec.Do_Not_Auto_Generate_Campaign__c = doNotCreateCampaign;
            pfRec.Dedicated_Resource_Name__c = dedicatedResourceName;
            pfRec.Job_Title__c = jobTitle;
            pfRec.Measurements_of_Success_Q1__c = mos1;
            pfRec.Measurements_of_Success_Q2__c = mos2;
            pfRec.Measurements_of_Success_Q3__c = mos3;
            pfRec.Measurements_of_Success_Q4__c = mos4;
            system.debug('@@in '+pfrec);
            Database.SaveResult sr = Database.insert(pfrec,false);
            
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted pfrec. pfrec ID: ' + sr.getId());
                if(docIds != null && docIds.size() > 0){
                	List<ContentDocumentLink> conLinkList = attachUploadedDocuments(docIds, sr.getId());
                    if(conLinkList.size() > 0){
                        Database.insert(conLinkList,false);
                    }
                }
                flag = 'success';
            }else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('pfrec fields that affected this error: ' + err.getFields());
                    flag = 'Error while saving'+ err.getFields();
                }
            }
    return flag;  
    }catch(Exception e) {
        flag = 'Error while saving'+e.getMessage()+ ' at line number '+e.getLineNumber()+' ' +e.getCause();
        system.debug('Exception occured '+e.getMessage()+ ' at line number '+e.getLineNumber()+' ' +e.getCause());
        return flag;
    }
}
    public static List<ContentDocumentLink> attachUploadedDocuments(List<Id> documentIds, Id recId){
        List<ContentDocumentLink> conDocLinks = new List<ContentDocumentLink>();
        for(Id docId : documentIds){
            ContentDocumentLink conL = new ContentDocumentLink();
            conL.LinkedEntityId = recId;
            conL.ContentDocumentId = docId;
            conL.ShareType = 'I';
            conL.Visibility = 'AllUsers';
            conDocLinks.add(conL);
        }
        return conDocLinks;
    }
    
    public class wrap{
        @AuraEnabled
        public string Activity_Type;
        @AuraEnabled
        public string Activity_Objective;
        @AuraEnabled
        public string PO_Currency;
        @AuraEnabled
        public string Campaign_Focus;
        @AuraEnabled
        public string Title;
        @AuraEnabled
        public Date Activity_Start_Date;
        @AuraEnabled
        public Date Activity_Etart_Date;
        @AuraEnabled
        public string RequestedAmount;
        @AuraEnabled
        public string Description;
        @AuraEnabled
        public List<Id> docIds;

    }

    public PageReference callcheckCancel(){
        msg = '';
        try{
            List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
            if (!string.isBlank(precordId)){
                pfrList = [select Id, Cancel_Partner_Fund_Request__c
                           from PartnerFundRequest
                           where Id = :precordId];
                if (!pfrList[0].Cancel_Partner_Fund_Request__c){
                    pfrList[0].Cancel_Partner_Fund_Request__c = true;
                    update pfrList;
                    msg = 'Request is cancelled successfully';
                }else{
                    msg = 'Request is already Cancelled';
                }
            }
        }catch(Exception e){
            msg = e.getMessage();
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                msg = msg.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
            }
        }
        return null;
    }
}