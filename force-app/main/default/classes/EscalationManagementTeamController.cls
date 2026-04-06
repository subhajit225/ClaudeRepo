/*
* @Author           :   Vijay Kumar K R
* @CreatedDate      :   
* @lwc              :   escalationManagementTeam.lwc
* @TestClass        :   EscalationManagementTeamControllerTest.cls
* -------------------------- @History ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Story Number       Modified By              Date                          Description
* CS21-1378         Vijay Kumar K R        Nov 29 2022    Enable Escalation Management Team (EMT) Reporting within Salesforce Lightning
* ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class EscalationManagementTeamController {
    
    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}

    @TestVisible
    public static final Id RANSOMWARE_RTID = Schema.SObjectType.Escalation__c.getRecordTypeInfosByDeveloperName().get('Escalation_Ransomware').getRecordTypeId();
    public static final Id SUPPORT_RTID = Schema.SObjectType.Escalation__c.getRecordTypeInfosByDeveloperName().get('Escalation_Support').getRecordTypeId();

    public EscalationManagementTeamController(ApexPages.StandardController controller) {
        
    }

    /**
     * Method: getDraftEscalation 
     * Description: Fetch Draft Escalation record
     * params: 
     * return: Escalation Id
     **/
    @AuraEnabled
    public static draftEscalation getDraftEscalation() {
        try {
            List<String> recordIdList = new List<String>{RANSOMWARE_RTID, SUPPORT_RTID};
            List<Escalation__c> escList = [SELECT Id, Case__c, LastModifiedDate, RecordTypeId 
                                            FROM Escalation__c 
                                            WHERE RecordTypeId IN: recordIdList 
                                            AND isDraft__c = true
                                            AND CreatedById =: UserInfo.getUserId()];

            Escalation__c ranEsc = null;
            Escalation__c supEsc = null;
            if(!escList.isEmpty()){
                for(Escalation__c objEsc : escList){
                    if(objEsc.RecordTypeId == RANSOMWARE_RTID){
                        ranEsc = objEsc;
                    }else if(objEsc.RecordTypeId == SUPPORT_RTID){
                        supEsc = objEsc;
                    }
                }
            }
            return new draftEscalation(ranEsc, supEsc);
        } catch (Exception e) {
            System.debug('getDraftEscalation Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: getDraftLessonsLearned 
     * Description: Fetch Draft Lessons_Learned__c record
     * params: String escId
     * return: List<Lessons_Learned__c>
     **/
    @AuraEnabled
    public static List<Lessons_Learned__c> getDraftLessonsLearned(String escId) {
        try{
            System.debug('getDraftLessonsLearned escId: '+escId);

            List<Lessons_Learned__c> llList = new List<Lessons_Learned__c>();
            llList = [SELECT Id, Case__c, LastModifiedDate 
                        FROM Lessons_Learned__c 
                        WHERE isDraft__c = true 
                        AND Escalation__c =: escId 
                        AND CreatedById =: UserInfo.getUserId() Limit 1];
            return llList;
        } catch (Exception e) {
            System.debug('getDraftLessonsLearned Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: wrapper class
     **/
    public class draftEscalation{
        @AuraEnabled 
        public Escalation__c ransomwareEsc {get;set;}
        @AuraEnabled 
        public Escalation__c supportEsc {get;set;}
        public draftEscalation(Escalation__c ransomwareEsc, Escalation__c supportEsc){
            this.ransomwareEsc = ransomwareEsc;
            this.supportEsc = supportEsc;
        }
    }

    /**
     * Method: getCaseDetails 
     * Description: To display Case fields info on Escalation form
     * params: Id caseId, String sObjectName
     * return: caseDetails WrapperClass
     **/
    @AuraEnabled(cacheable=true)
    public static caseDetails getCaseDetails(Id caseId) {
        try {

            List<Escalation__c> escList = [SELECT Id, Case__c
                                            FROM Escalation__c 
                                            WHERE Case__c =: caseId 
                                            AND Status__c != 'Closed' Limit 1];
                                            
            if(escList.size() < 1
                || Test.isRunningTest()){
                    // fields
                    List<String> caseFields = new List<String> {'Id', 'AccountId', 'Account.Name', 'Priority', 'Software_Version__c', 'SentryAI_URL__c', 'Cluster__c', 'AHA_reference__c',
                                'Cluster__r.uuid__c', 'OwnerId', 'Case_Time_Zone__c', 'Grafana_Link__c', 'Slack_channel__c', 'JIRA_References_URL__c', 'Idea_Reference__c', 
                                'Account.GDPR_Terms_Agreed__c', 'Support_Tunnel__c', 'Jira_Reference_urls__c', 'EscalationManagerOwner__c', 'EscalationManagerOwner__r.Id'};
                    // filter 
                    String caseRecordIdFilter = 'Id = \'' + String.escapeSingleQuotes(caseId) + '\'';

                    String query = 'SELECT '+ String.escapeSingleQuotes(String.join(new List<String>(caseFields), ', ')) + ' FROM Case ';
                            query += ' WHERE '+caseRecordIdFilter+'';
                    System.debug('getCaseDetails query: '+query);
                    Case objCase = Database.query(query);

                    String headsUpString = '';
                    if(objCase.AccountId != null){
                        headsUpString = [SELECT Id, Account.Heads_up_to_support_team__c FROM Account WHERE Id =: objCase.AccountId Limit 1].Heads_up_to_support_team__c;
                    }

                    String existingArticles = '';
                    for(CaseArticle objCaseAr : [SELECT Id, KnowledgeArticle.ArticleNumber
                                                    FROM CaseArticle
                                                    WHERE CaseId =: caseId]){
                        existingArticles += objCaseAr.KnowledgeArticle.ArticleNumber+',';
                    }

                    return new caseDetails(objCase, headsUpString, existingArticles.removeEnd(','));
            }else{
                throw new OtherException('Open Escalation already existing under this Case.');
            }
        } catch (BaseException e) {
            System.debug('getCaseDetails Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: wrapper class
     **/
    public class caseDetails{
        @AuraEnabled 
        public Case caseRecord {get;set;}
        @AuraEnabled 
        public String headsUpString {get;set;}
        @AuraEnabled 
        public String existingArticles {get;set;}
        public caseDetails(Case caseRecord, String headsUpString, String existingArticles){
            this.caseRecord = caseRecord;
            this.headsUpString = headsUpString;
            this.existingArticles = existingArticles;
        }
    }

    /**
     * Method: attachCaseNotes 
     * Description: Attaching ContentDocumentLinks (Notes & Attachments) from Case to Escalation record
     * params: Id caseId, Id escId
     * return: void
     **/
    @AuraEnabled
    public static void attachCaseNotes(Id caseId, Id escId) {
        try {
            //Get all corresponding files of corresponsind Source Object
            list<ContentDocumentLink> allCdLinks = new list<ContentDocumentLink> ();
            allCdLinks = [select Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility 
                                            from ContentDocumentLink 
                                            where LinkedEntityId =: caseId];
            
            //Final List to insert file into new destination object
            list<ContentDocumentLink> allCdLinksToInsert = new list<ContentDocumentLink> ();
            
            for(ContentDocumentLink cdl : allCdLinks){
                cdl.Id = null;   
                cdl.LinkedEntityId = escId;
                allCdLinksToInsert.add(cdl);
            }
            
            if(!allCdLinksToInsert.isEmpty()){
                database.Insert(allCdLinksToInsert,false);
            }
        } catch (Exception e) {
            System.debug('attachCaseNotes Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: getEscalationDetails 
     * Description: fetching Escalation__c details to display on Lessons Learnt form from Quick Action.
     * params: Id esclId
     * return: Escalation__c
     **/
    @AuraEnabled(cacheable=true)
    public static Escalation__c getEscalationDetails(Id esclId) {
        try {
            // fields
            List<String> esclFields = new List<String> {'Id', 'Case__c', 'Account__c', 'Case__r.AccountId', 'Case_Priority__c', 'Slack_channel__c', 'JIRA_Reference__c', 'Case__r.Idea_Reference__c', 
                                                        'Business_impact_media_attention__c', 'Closed_Date__c',  'Customer_Geo__c', 'Escalation_Manager_Owner__c', 'AHA_reference__c'};
            // filter 
            String esclRecordIdFilter = 'Id = \'' + String.escapeSingleQuotes(esclId) + '\'';
            
            String query = 'SELECT '+ String.escapeSingleQuotes(String.join(new List<String>(esclFields), ', ')) + ' FROM Escalation__c ';
            query += ' WHERE '+esclRecordIdFilter+'';
            
            return Database.query(query);
        } catch (Exception e) {
            System.debug('getEscalationDetails Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: recentCaseListAction 
     * Description: return list of cases based on filter condition on Lessons Learnt Quick Action
     * params: Id esclId, String filterCondition
     * return: List<Case>
     **/
    @AuraEnabled(cacheable=true)
    public static List<Case> recentCaseListAction(Id esclId, String filterCondition){
        try {
            Escalation__c objEscl = [SELECT Id, Case__c, Case__r.Subject, Case__r.AccountId, Case__r.RecordType__c FROM Escalation__c WHERE Id =: esclId];
            
            if(objEscl.Case__r.AccountId != null){

                // fields
                List<String> fields = new List<String> {'Id', 'CreatedDate', 'ClosedDate', 'Account.Name', 'Jira_Reference_urls__c', 
                                                    'CaseNumber', 'Owner.Name', 'Subject', 'Status', 'Priority', 'Type', 'AccountId'};
            
                // filter for 'RecentCases' by default
                String filterString = 'AccountId = \''+objEscl.Case__r.AccountId+'\' AND Account.Name != \'Rubrik\' AND RecordType__c =\''+objEscl.Case__r.RecordType__c+'\' ';

                if(filterCondition == 'OpenCases'){
                    filterString += 'AND Status != \''+String.escapeSingleQuotes('Closed')+'\'';
                }
                else if(filterCondition == 'ClosedCases'){
                    filterString += 'AND Status = \''+String.escapeSingleQuotes('Closed')+'\'';
                }
                else if(filterCondition == 'RelatedCases'){
                    filterString += 'AND Subject like \'%'+String.escapeSingleQuotes(objEscl.Case__r.Subject)+'%\'';
                }
                
                String query = 'SELECT '+ String.escapeSingleQuotes(String.join(new List<String>(fields), ', ')) + ' FROM Case';
                query += ' WHERE '+filterString+'';

                System.debug('final query: '+query);
                return Database.query(query);
            }
            return null;
        } catch (Exception e) {
            System.debug('recentCaseListAction Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: createCaseTeamMember 
     * Description: return list of cases based on filter condition on Lessons Learnt Quick Action
     * params: Id caseId
     * return: void
     **/
    @AuraEnabled
    public static String createCaseTeamMember(Id caseId){
        try{
            CaseTeamMember objCm = new CaseTeamMember();
            objCm.ParentId = caseId;
            objCm.MemberId = Userinfo.getUserId();
            objCm.TeamRoleId = [SELECT Id FROM CaseTeamRole WHERE Name = 'Case Accelerator'].Id;
            database.insert (objCm, false);
            System.debug('createCaseTeamMember: '+objCm);
            return null;
        } catch (Exception e) {
            System.debug('createCaseTeamMember Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * Method: getRelatedNotes 
     * Description: return list of cases based on filter condition on Lessons Learnt Quick Action
     * params: Id recordId
     * return: Note__c
     **/
    @AuraEnabled
    public static void sendCaseComment(Id recordId, String nextSteps){
        try{
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            String parentId = null;
            if(sObjName == 'Escalation__c'){
                parentId = [SELECT Id, Case__c FROM Escalation__c WHERE Id =: recordId].Case__c;
            }else{
                parentId = [SELECT Id, Case__c FROM Lessons_Learned__c WHERE Id =: recordId].Case__c;
            }   
            
            INSERT new CaseComment(ParentId = parentId, CommentBody = nextSteps);
        } catch (Exception e) {
            System.debug('sendCaseComment Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: getDraftNote 
     * Description: return list of cases based on filter condition on Lessons Learnt Quick Action
     * params: Id recordId
     * return: Note__c
     **/
    @AuraEnabled
    public static Note__c getDraftNote(String SectionType, Id recordId){
        try {
            String sObjName = recordId.getSObjectType().getDescribe().getName();

            String query = 'SELECT Id, Action_Items_Notes__c, Area_Of_Improvement__c, Body__c, Due_Date__c, Escalation__c, Status__c, ';
                    query += ' isDraft__c, Object_Type__c, Lessons_Learned__c, Outcome__c, Owner_s__c, Section_Type__c, Title__c, lastModifiedDate ';
                    query += ' FROM Note__c ';
                    query += ' WHERE Section_Type__c = \''+String.escapeSingleQuotes(SectionType)+'\' ';
            if(sObjName == 'Escalation__c'){
                query += ' AND Escalation__c = \''+String.escapeSingleQuotes(recordId)+'\' ';
            }else if(sObjName == 'Lessons_Learned__c'){
                query += ' AND Lessons_Learned__c = \''+String.escapeSingleQuotes(recordId)+'\' ';
            }
            query += ' AND isDraft__c = true Limit 1';
            return Database.query(query);
        } catch (Exception e) {
            System.debug('getDraftNote Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method: getDraftNote 
     * Description: return list of Notes Status Picklist Values
     * params: 
     * return: List<Map<String, String>>
     **/
    @AuraEnabled
    public static List<Map<String, String>> getNotesStatusPickListValues(){
        try {
            List<Map<String, String>> pickListValuesMapList = new List<Map<String, String>>();
            Schema.DescribeFieldResult fieldResult = Note__c.Status__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry pickListVal : ple){
                Map<String, String> valueMap = new Map<String, String>();
                valueMap.put('label', pickListVal.getLabel());
                valueMap.put('value', pickListVal.getValue());
                pickListValuesMapList.add(valueMap);
            }     
            return pickListValuesMapList;
        }
        catch (Exception e) {
            System.debug('getNotesStatusPickListValues Exception: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}