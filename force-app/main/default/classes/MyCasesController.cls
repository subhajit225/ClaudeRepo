/**
 * @Author : 
 * @Description : 
 * @TestClass   : MyCasesControllerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1071        Vijay Kumar K R        July 18, 2022    Support Portal: Read only user profile for Cases
 * -------------------------------------------------------------------------
 */
public with sharing class MyCasesController {
    @auraEnabled
    public static CaseWrapper getCasesrecords(){
        
        CaseWrapper csWrapper=new CaseWrapper();
        // CS21-1071: Support Portal: Read only user profile
        csWrapper.hasAccess = Schema.sObjectType.Case.isAccessible();
        AccountDetails acDt=new AccountDetails();
        csWrapper.accDetail = acDt.getAccDetails();
        User usrinfo =[select Id, ContactId,Contact.accountId from user where Id =: Userinfo.getUserID()];
        List<Case> caselist= [SELECT CaseNumber, Contact.Name, Status, Priority, Subject, Type, ClosedDate, CreatedDate
                                FROM Case 
                                WHERE accountid =: usrinfo.Contact.accountId 
                                AND (NOT Priority LIKE '%P4%') 
                                AND isClosed = false AND (RecordType__c = 'Support Case' OR RecordType.Name = 'Customer Success')]; 

        if(!caselist.isEmpty()){
            csWrapper.caseList=caselist;
        }
        return csWrapper; 
    }
    public with sharing class OpportunityController_AC
    {
        
        public  List<Case> getCases()
        {
            return [SELECT CaseNumber,Contact.Name, Status, Priority, Subject, Type,ClosedDate,CreatedDate  FROM case ];
        }
        
        
        public  List<Case> getByName(String searchKey) {
            String name = '%' + searchKey + '%';
            return [SELECT CaseNumber, Status, Priority, Subject, Type,ClosedDate,CreatedDate  FROM case ];
        }
    }
      public without sharing class AccountDetails{
        public Account getAccDetails(){
            return [Select Technical_support_provided_by_Partner__c,Technical_support_provided_by_Partner__r.RASP_Customer_Portal__c,Technical_support_provided_by_Partner__r.RASP_Customer_Phone__c,Technical_support_provided_by_Partner__r.RASP_Customer_Email__c, Technical_support_provided_by_Partner__r.RASP_Escalation_Detail__c,Technical_support_provided_by_Partner__r.RASP_Business_Contact__c,Technical_support_provided_by_Partner__r.RASP_Business_Contact__r.Name from Account where ID = :Util.CurrentUser.Contact.AccountId LIMIT 1];
        }
    }
    public static list<Case> getCasefilter(){
        User usrinfo =[select Id, ContactId,Contact.accountId,Contact.Name from user where Id =: Userinfo.getUserID()];
        List<Case> viewlist= [ SELECT CaseNumber, Status, Priority, Subject, Type,ClosedDate,CreatedDate  FROM Case WHERE accountid=:usrinfo.Contact.accountId  ];
        system.debug('viewlist__'+viewlist);
        return viewlist; 
    }
    
    @auraEnabled
    Public static List<Case> getCasesByViews(string viewName){
         system.debug('viewName....'+viewName);
        List<Case> caseList;
        string ContactId = Userinfo.getUserID();
        User usrinfo =[select Id, Contact.accountId from user where Id =: Userinfo.getUserID()];
        List<string> CaseIds = new List<string>();
        for(CaseTeamMember ctm : [SELECT Id,ParentId,MemberId from CaseTeamMember WHERE MemberId =:Userinfo.getUserID()]){
            CaseIds.add(ctm.ParentId);
        }
        if(viewName != null && viewName == 'My Open Cases (P1/P2/P3)' ){
            caseList = [ SELECT CaseNumber, Status,Contact.Name, Priority, Subject, Type,ClosedDate,CreatedDate  FROM Case WHERE accountid=:usrinfo.Contact.accountId and (NOT Priority LIKE '%P4%') AND isClosed = false AND (RecordType__c = 'Support Case' OR RecordType.Name = 'Customer Success') ORDER BY CreatedDate DESC];
         
        }
        if(viewName != null && viewName == 'My Open Cases (P4)' ){
            caseList = [SELECT Id, CaseNumber, Status,Contact.Name, Priority, Subject, Type, ClosedDate,CreatedDate FROM Case WHERE accountid=:usrinfo.Contact.accountId AND IsClosed = false AND Priority  LIKE '%P4%' AND (RecordType__c = 'Support Case' OR RecordType.Name = 'Customer Success') ORDER BY CreatedDate DESC];
      
        }
        if(viewName != null && viewName == 'My Open Cases' ){
            caseList = [SELECT Id, CaseNumber, Status,Contact.Name, Priority, Subject, Type, ClosedDate,CreatedDate FROM Case WHERE accountid=:usrinfo.Contact.accountId AND IsClosed = false AND (RecordType__c = 'Support Case' OR RecordType.Name = 'Customer Success')  ORDER BY CreatedDate DESC];
         system.debug('caseList__444444444444444'+caseList);
        }
        if(viewName != null && viewName == 'Recently Viewed Cases' ){
            caseList = [SELECT Id, CaseNumber, Status,Contact.Name, Priority, Subject, Type, ClosedDate,CreatedDate FROM Case WHERE accountid=:usrinfo.Contact.accountId AND (RecordType__c = 'Support Case' OR RecordType.Name = 'Customer Success') ORDER BY   LastViewedDate DESC NULLS LAST ];
         system.debug('caseList__444444444444444'+caseList);
        }
        if(viewName != null && viewName == 'My Closed Cases' ){
            caseList = [SELECT Id, CaseNumber, Status,Contact.Name, Priority, Subject, Type, ClosedDate,CreatedDate FROM Case WHERE accountid=:usrinfo.Contact.accountId AND IsClosed = true AND (RecordType__c = 'Support Case' OR RecordType.Name = 'Customer Success')  ORDER BY ClosedDate DESC];
        }
        return caseList;
    }
     public class CaseWrapper{
        @AuraEnabled
        public Boolean hasAccess{get;set;}
        @AuraEnabled
        public list<Case> caseList{get;set;}
        @AuraEnabled
        public Account accDetail{get;set;}
        public CaseWrapper(){
            caseList=new List<Case>();
        }
    }
}