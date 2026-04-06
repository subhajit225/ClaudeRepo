public class CaseDetailControllerLWC {
    //Recent Cases Class
    @AuraEnabled
    public static List<Case> getCaseRecLWC(Id caseId , string field , string order ){
        List<case> CaseRecordsRelatedToSameAccount = new List<case> ();
        List<Case> caseRecord = [SELECT Id,Accountid,recordTypeId FROM case WHERE ID =: caseId];
        
        if(caseRecord!=NULL && caseRecord.size()>0){
            Id AccountId = caseRecord[0].AccountId;
            Id recordTypeId = caseRecord[0].recordTypeId;
            
            string query = 'SELECT Id,Status,LastModifiedDate,CaseNumber,Subject,Priority,Cluster__r.Id,Resolution__c,Owner.Name,Cluster__r.Name,Cluster__c,CreatedDate FROM case WHERE Account.Id =: AccountId AND Id !=:caseId  AND recordTypeId =:recordTypeId Order By '+ field +' '+ order +' NULLS LAST LIMIT 50000' ;
            CaseRecordsRelatedToSameAccount = Database.query(query);
        }
        if(CaseRecordsRelatedToSameAccount != null && !CaseRecordsRelatedToSameAccount.isEmpty()){
            return CaseRecordsRelatedToSameAccount;
        }
        else{
            return new List<Case>();
        }
        
    }
    
    @AuraEnabled
    public static List<Case> getFiveCaseRecordsLWC(Id caseId , string field , string order ){
        List<case> CaseRecordsRelatedToSameAccount = new List<case> ();
        List<Case> caseRecord = [SELECT Id,Accountid,recordTypeId FROM case WHERE ID =: caseId];
        
        if(caseRecord!=NULL && caseRecord.size()>0){
            Id AccountId = caseRecord[0].AccountId;
            Id recordTypeId = caseRecord[0].recordTypeId;
            
            string query = 'SELECT Id,Status,LastModifiedDate,CaseNumber,Subject,Priority,Cluster__r.Id,Resolution__c,Owner.Name,Cluster__r.Name,Cluster__c,CreatedDate FROM case WHERE Account.Id =: AccountId AND Id !=:caseId  AND recordTypeId =:recordTypeId Order By '+ field +' '+ order +' NULLS LAST LIMIT 5' ;
            CaseRecordsRelatedToSameAccount = Database.query(query);
        }
        if(CaseRecordsRelatedToSameAccount != null && !CaseRecordsRelatedToSameAccount.isEmpty()){
            return CaseRecordsRelatedToSameAccount;
        }
        else{
            return new List<Case>();
        }
        
    }
}