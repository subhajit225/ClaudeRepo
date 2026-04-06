public without sharing class PC_PartnerFundClaimController {
    public static String Description{get;set;}
    public static String recId{get;set;}
    public static String contentVersionIds{get;set;}
    public static String status{get;set;}
    public static String claimname{get;set;}
    public static String amount{get;set;}
    //prit26-12
    public static String fiscalQuarter{get;set;}
    public static String measurementOfSuccess1{get;set;}
    public static String measurementOfSuccess2{get;set;}
    public static String measurementOfSuccess3{get;set;}
    public static String measurementOfSuccess4{get;set;}
    private static List<string> pickListValues;
    //prit26-12
   /*
@purpose: To get Base URL of File
@param: 
@return: string -baseURL
*/
   @AuraEnabled
   public static string getfileBaseURL(){
       
       Organization org = new Organization();
       org = [SELECT Id,InstanceName FROM Organization];
       string instName = org.InstanceName.toLowerCase();
       string  baseurl = System.URL.getSalesforceBaseURL().toExternalForm();
       if(baseurl.contains('.force.com') && !baseurl.contains('lightning')){
           baseurl = baseurl+'/'+'partnersnew';
       }
       /*if(baseurl.contains(instName)){
           baseurl = baseurl.replace('.'+instName+'.my.salesforce.com','--c.'+instName+'.content.force.com');
       }else{
           baseurl = baseurl.replace('.my.salesforce.com','--c.'+instName+'.content.force.com');
       }*/
 	baseurl = baseurl.replace('.my.salesforce.com','--c.vf.force.com');
      return baseurl;
   }
   /*
@purpose: To get Base URL of VF
@param: 
@return: string -baseURL of VF
*/
   @AuraEnabled
   public static string getBaseURL(){
       
       Organization org = new Organization();
       org = [SELECT Id,InstanceName FROM Organization];
       string instName = org.InstanceName.toLowerCase();
       string  baseurl = System.URL.getSalesforceBaseURL().toExternalForm();
       if(baseurl.contains('.force.com') && !baseurl.contains('lightning')){
           baseurl = baseurl+'/'+'partnersnew';
       }
       /*if(baseurl.contains(instName)){
           baseurl = baseurl.replace('.'+instName+'.my.salesforce.com','--c.'+instName+'.visual.force.com');
       }else{
           baseurl = baseurl.replace('.my.salesforce.com','--c.'+instName+'.visual.force.com');
       }*/
        baseurl = baseurl.replace('.my.salesforce.com','--c.vf.force.com');
       return baseurl;
   }
   @AuraEnabled
   public static Decimal getTotalAmount(string mdfId){
       Decimal totalAmount = 0;
       List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
       pfrList = [select Id,Amount,TotalApprovedFcs from PartnerFundRequest where Id =: mdfId];
       if(!pfrList.isEmpty() && pfrList[0].TotalApprovedFcs != null){
           totalAmount = pfrList[0].Amount - pfrList[0].TotalApprovedFcs;
       }else if(!pfrList.isEmpty()){
           totalAmount = pfrList[0].Amount;
       }
       return totalAmount;
   }
   
   //prit26-12
   @AuraEnabled
   public static PartnerFundRequest getRequestDetails(string mdfId){
       String reqName = '';
       List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
       pfrList = [select Id,Title,Request_Number__c,Activity,Measurements_of_Success_Q1__c,Measurements_of_Success_Q2__c,Measurements_of_Success_Q3__c,Measurements_of_Success_Q4__c from PartnerFundRequest where Id =: mdfId];
       reqName = pfrList[0].Request_Number__c+' - '+pfrList[0].Title;
       return pfrList[0];
   }
   
   @AuraEnabled
    public static List<string> getPicklistValues(string fieldName){
        try{
            system.debug(fieldName);
            Schema.sObjectType objType = PartnerFundClaim.getSObjectType();
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
    //prit26-12
   
   public  void saveFilesAction(){ 
       List<ProcessInstanceStep> pInsStepList = new List<ProcessInstanceStep>();
       List<PartnerFundClaim> pfcList = new List<PartnerFundClaim>();
       system.debug('@@ recId '+recId);
       system.debug('@@ Amount '+Amount);
       if(!string.isBlank(recId)){
           pInsStepList = [SELECT Id, OriginalActorId FROM ProcessInstanceStep where ProcessInstance.TargetObjectId =: recId AND StepStatus='Approved' order by createddate desc limit 1];
           PartnerFundClaim pfc = new PartnerFundClaim();
           pfc.RequestId = recId;
           pfc.Title = 'test';
           if(!string.isBlank(Amount)){
               pfc.Amount = Double.valueOf(amount);
           }else{
               pfc.Amount = 0;
           }
           pfc.Description = Description;
           pfc.Fiscal_Quarter__c = fiscalQuarter;
           pfc.Measurements_of_Success_Q1__c = measurementOfSuccess1;
           pfc.Measurements_of_Success_Q2__c = measurementOfSuccess2;
           pfc.Measurements_of_Success_Q3__c = measurementOfSuccess3;
           pfc.Measurements_of_Success_Q4__c = measurementOfSuccess4;
           pfc.Status = 'Draft';
           if(!pInsStepList.isEmpty() && String.valueOf(pInsStepList[0].OriginalActorId).startsWith('005')){
               pfc.Approver__c = pInsStepList[0].OriginalActorId;
           }
           pfcList.add(pfc);
           system.debug('pfc->'+pfc);
       }
       
       if(!pfcList.isEmpty()){
           system.debug('pfcList->'+pfcList);
           insert pfcList;
       }
       system.debug('@@ pfcList '+pfcList);
       // insert file attachment 
       List<string> contVersionIdList = new List<string>();
       List<ContentVersion> cvList = new List<ContentVersion>();
       List<ContentDocumentLink> cdlList =new List<ContentDocumentLink>();
       List<String> contDocIdList = new List<String>();
       if(!pfcList.isEmpty()){
       /* ContentVersion and Documents */
           if(contentVersionIds != '' && contentVersionIds != null &&contentVersionIds.contains(';')){
               contVersionIdList = contentVersionIds.split(';');
           }else if(contentVersionIds != '' && contentVersionIds != null){
               contVersionIdList.add(contentVersionIds);
           }
           
           cvList = [SELECT id,contentDocumentId from ContentVersion where id IN :contVersionIdList];
           if(!cvList.isEmpty()){
               for(ContentVersion cv : cvList){
                   contDocIdList.add(cv.contentDocumentId);
               }
           }
           system.debug('@@ contDocIdList '+contDocIdList);
           if(!contDocIdList.isEmpty()){ //Inserting ContentDocumentLink only for New Message templates
               for(string cdId : contDocIdList){
                   ContentDocumentLink cdl = new ContentDocumentLink();
                   cdl.ContentDocumentId = cdId;
                   cdl.LinkedEntityId = pfcList[0].Id;
                   cdl.ShareType = 'I'; //Share of ContentDocument based on its parent Message record
                   cdl.Visibility = 'AllUsers'; //Visible to Community & Internal users based on access to the ContentDocument
                   cdlList.add(cdl);
               }
           }
           
           if(cdlList != null && !cdlList.isEmpty()){
               insert cdlList;
           }
           system.debug('@@ cdlList '+cdlList);
       }
   } 
   @AuraEnabled
   public static boolean getStatus(String mdfId) {
       Boolean flag = false;
       List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
       pfrList = [select Id,status,Activity_Start_Date__c, Activity_End_Date__c,RequestedAmount,TotalApprovedFcs,MDF_Request_Closed__c from PartnerFundRequest where Id =: mdfId];
       if(!pfrList.IsEmpty() && pfrList[0].status == 'Approved' && pfrList[0].Activity_End_Date__c < system.today() && pfrList[0].MDF_Request_Closed__c == false){
           flag = true;
       }
       if(pfrList[0].MDF_Request_Closed__c){
           flag = false;
       }
       return flag;
   }
}