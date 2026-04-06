/*
* @Author       :   Ankit Gupta
* @CreatedDate  :   11-11-2024
* @Jira Ticket  :   PRIT25-243
* @Description  :   Controller for case management, queue ID retrieval, and user details.
* @LWC          :   pc_PartnerCaseForm, pc_PartnerCaseListView, pc_PartnerCaseView
* @TestClass    :   PC_PartnerCaseControllerTest.cls
*/
public with sharing class PC_PartnerCaseController {
    @AuraEnabled(cacheable=true)
    public static CaseWrapper getCurrentUserInfo() {
        try {
            User currentUser = getCurrentUser();
            return new CaseWrapper(currentUser);
        } catch (Exception e) {
            logError('User', e.getMessage(), 'getCurrentUserInfo');
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static CaseWrapper createCase(Case caseRecord) {
        try {
            insert caseRecord;
            return new CaseWrapper(caseRecord.Id);
        } catch (DmlException dmlEx) {
            logError('Case', dmlEx.getMessage(), 'createCase');
            throw new AuraHandledException(dmlEx.getMessage());
        }
    }
    
    @AuraEnabled
    public static void uploadFilesToCase(List<Id> contentDocumentIds, Id caseId) {
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        try {
            for (Id documentId : contentDocumentIds) {
                documentLinks.add(new ContentDocumentLink(
                    ContentDocumentId = documentId,
                    LinkedEntityId = caseId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
            insert documentLinks;
        } catch (DmlException dmlEx) {
            logError('Case', dmlEx.getMessage(), 'uploadFilesToCase');
            throw new AuraHandledException(dmlEx.getMessage());
        }
    }
    
    @AuraEnabled
    public static void deleteFile(String documentId) {
        try {
            delete [SELECT Id FROM ContentDocument WHERE Id = :documentId LIMIT 1];
        } catch (Exception e) {
            logError('Case', e.getMessage(), 'deleteFile');
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static CaseWrapper getFilteredCases(String filter) {
        try {
            Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
            User currentUser = getCurrentUser();
            Boolean isAdminOrExecutive = isAdminOrExecutiveUser(currentUser);
            String condition = buildCondition(filter, currentUser, isAdminOrExecutive);
            String query = String.format(
                'SELECT CaseNumber, Owner.Name, Status, Type__c, SubType__c, Contact.Name, CreatedDate, LastModifiedDate ' +
                'FROM Case {0} AND RecordTypeId =:partnerCaseId ORDER BY CreatedDate DESC', 
                new String[]{condition}
            );
            List<Case> caseList = Database.query(query);
            return new CaseWrapper(caseList, isAdminOrExecutive);
        } catch (Exception e) {
            logError('Case', e.getMessage(), 'deleteFile');
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static User getCurrentUser() {
        return [
            SELECT Id, ContactId, Contact.Email, Contact.Primary_Role__c, AccountId 
            FROM User 
            WHERE Id = :UserInfo.getUserId() 
            LIMIT 1
        ];
    }
    
    private static Boolean isAdminOrExecutiveUser(User currentUser) {
        Set<String> adminRoles = new Set<String>{'Admin', 'Executive'};
            return currentUser.Contact != null && adminRoles.contains(currentUser.Contact.Primary_Role__c);
    }
    
    private static String buildCondition(String filter, User currentUser, Boolean isAdminOrExecutive) {
        String baseCondition = isAdminOrExecutive && !filter.contains('My')
            ? 'AccountId = \'' + currentUser.AccountId + '\'' 
            : 'createdById = \'' + currentUser.Id + '\'';
        
        String filterCondition = filter.contains('Open Cases') ? ' AND (NOT Status LIKE \'%Close%\')' : 
                                 filter.contains('Closed Cases') ? ' AND Status LIKE \'%Close%\'' :
                                 filter == 'Recently Viewed Cases' ? ' AND LastViewedDate != NULL' : '';
        
        return 'WHERE ' + baseCondition + filterCondition;
    }
    
    @TestVisible
    private static void logError(String objectName, String errorMsg, String methodName) {
        insert new Error_Logs__c(
            Object__c = objectName,
            Error_Message__c = errorMsg,
            Class__c = PC_PartnerCaseController.class.getName(),
            Method__c = methodName,
            Type__c = 'SFDC',
            Success__c = false
        );
    }
    
    @AuraEnabled
    public static CaseWrapper getCaseDetails(String recordId){
        try{
            List<Case> tempCase = [SELECT Id, Subject, Priority, Description, CaseNumber, OwnerId, Owner.Name, Origin, 
                                   ContactId, AccountId, RecordTypeId, Type__c, SuppliedEmail, Recipient_Email__c, 
                                   CreatedDate, RecordType__c, Status, Subtype__c, Date_Time_Closed__c, Contact_Name__c,
                                   Contact_Phone__c, Contact_Email__c, IsEscalated, isClosed,
                                   (SELECT Id, CommentBody, CreatedDate, CreatedBy.Name FROM CaseComments 
                                    WHERE IsPublished = TRUE ORDER BY CreatedDate DESC),
                                   (SELECT Id, contentType,createdDate,Name,Description FROM Attachments ORDER BY createddate),
                                   (SELECT Id,Title,FileType,CreatedDate,contentDocumentId  FROM AttachedContentDocuments ORDER BY createddate),
                                   (Select Id, Subject, TextBody, HtmlBody, ToAddress, CcAddress, FromAddress from EmailMessages)
                                   FROM Case WHERE Id =:recordId];
            
            return new CaseWrapper(tempCase, Schema.sObjectType.Case.isUpdateable());
        } catch (Exception e){
            logError('Case', e.getMessage(), 'getCaseDetails');
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static void addMyComment(String parentId, String body){
        insertCaseComment(parentId,body);
    }
    
    @AuraEnabled
    public static void reopen(String parentId, String body){
        Case caseRec = new Case(Id = parentId);
        caseRec.Status='Reopen';
        update caseRec;
        insertCaseComment(parentId,body);
    }
    
    @AuraEnabled
    public static CaseWrapper createCaseWithComment(Case caseRecord, String body) {
        try {
            insert caseRecord;
            insertCaseComment(caseRecord.Id,body);
            return new CaseWrapper(caseRecord.Id);
        } catch (DmlException dmlEx) {
            logError('Case', dmlEx.getMessage(), 'createCase');
            throw new AuraHandledException(dmlEx.getMessage());
        }
    }
    
    public static void insertCaseComment(String parentId, String body){
        CaseComment cc = new caseComment();
        cc.CommentBody = body.length() > 4000 ?  body.substring(0,3900)+'...': body;
        cc.ParentId = parentId;
        cc.IsPublished = true;
        try{
            insert cc;
        }catch (Exception e){
            logError('Case', e.getMessage(), 'createCase');
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class CaseWrapper {
        @AuraEnabled public List<Case> caseList { get; set; }
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public User currentUser { get; set; }
        @AuraEnabled public Boolean isAccess { get; set; }
        
        public CaseWrapper(User currentUser) {
            this.currentUser = currentUser;
        }
        
        public CaseWrapper(Id caseId) {
            this.caseId = caseId;
        }
        
        public CaseWrapper(List<Case> caseList, Boolean isAccess) {
            this.caseList = caseList;
            this.isAccess = isAccess;
        }
    }
}