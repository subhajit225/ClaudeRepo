public class RelatedListRecentCasesController {
    public Id caseId;
    public transient List<Case> recentCaseList{get;set;}
    public RelatedListRecentCasesController(ApexPages.StandardController controller){
        caseId = (id) controller.getId();
        recentCaseList = new List<Case>();
        recentCaseListAction();
    }
    
    public List<Case> recentCaseListAction(){
        Case cs = [SELECT Id, AccountId,RecordType__c from case where Id =: caseId];
        If(cs.AccountId != Null)
        {
           recentCaseList = [SELECT CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' AND RecordType__c =:cs.RecordType__c  Limit 900];
           return recentCaseList;
        }
        return Null;
    }
    
    Public List<Case> closedCasesListAction(){
        Case cs = [SELECT Id, AccountId,RecordType__c from case where Id =: caseId];
        If(cs.AccountId != Null)
        {
           recentCaseList = [SELECT CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' and Status =: 'Closed' AND RecordType__c =:cs.RecordType__c Limit 900];
           return recentCaseList;
        }
        return null;
    }
    
    Public List<Case> openCasesListAction(){
        Case cs = [SELECT Id, AccountId,RecordType__c from case where Id =: caseId];
        If(cs.AccountId != Null)
        {
           recentCaseList = [SELECT CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' and Status != 'Closed' AND RecordType__c =:cs.RecordType__c Limit 900];
           return recentCaseList;
        }
        return null;
    }
    
    Public List<Case> searchCasesListAction(){
        Case cs = [SELECT Id, AccountId, Subject,RecordType__c from case where Id =: caseId];
        If(cs.AccountId != Null)
        {
           recentCaseList = [SELECT CreatedDate,ClosedDate,Account.Name,Jira_Reference_urls__c,CaseNumber,Owner.Name,Subject,Status,Priority,Type,AccountId FROM Case where AccountId =: cs.AccountId and Account.Name != 'Rubrik' and Subject like :'%'+cs.Subject+'%' AND RecordType__c =:cs.RecordType__c Limit 900];
           return recentCaseList;
        }
        return null;
    }
    
    public pageReference getClosedCases()
    {
        closedCasesListAction();
        return null;
    }
    public pageReference getOpenCases()
    {
        openCasesListAction();
        return null;
    }
    public pageReference getRelatedCases()
    {
        searchCasesListAction();
        return null;
    }
}