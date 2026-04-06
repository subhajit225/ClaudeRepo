/**
* @Author :
* @description :
* @TestClass   : CaseApexControllerTest 
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1071        Vijay Kumar K R       July 18, 2022    Support Portal: Read only user profile for Cases
* CS21-1324        Vijay Kumar K R       Dec 09, 2022     [FedRAMP] Disable case creation from Support Portal
* CS21-1407        Raveesh Layal         May 24, 2023     Process PTO auto-routing after escalation processing
* CS21-1562        Raveesh Layal         June 21, 2023    Disallow support case reopening after 30 days from Status change to Closed
* CS21-1884        Raveesh Layal         August 29, 2023  Case routing fix if case owner is inactive
* CS21-1839        Raveesh Layal         September 28, 2023 Admin Panel: Modify "Contacts without user" section
* CS21-1923        Vijay Kumar K R        Oct 10 2023      Escalation Task assignment - Not in CSE queue or OPEN
* CS21-2005        Vijay Kumar K R        Nov 20 2023      [FedRAMP 1.5] Enable case creation on the Rubrik Support Portal for hybrid RSC-G/RSC/CDM customers
* CS21-2108        Abhishek Mahajan      Jan 10 2024      Remove visibility of which queue a case is sitting in on the Support Portal
* CS21-3033        Vijay Kumar K R          Feb 06, 2024   US ASE / FED queue and routing changes FY25
* CS21-2619        Vijay Kumar K R          Spe 3, 2024    End of Support (EOS) Notifications for Clusters Running CDM 8.1 (or earlier)
* -------------------------------------------------------------------------

*/
public without sharing class CaseApexController {
    public static String commentBody;

    /**
     * @description get Realted Picklist values.
     * @return wrapper
     */
    @AuraEnabled
    public static wrapper getPickListValuesIntoList(){
        wrapper wrToReturn = new wrapper();
        wrToReturn.rscSupport = [SELECT Id, Contact.Account.RSC_G_Support__c
                                        FROM User
                                        WHERE Id =: UserInfo.getUserId()].Contact.Account.RSC_G_Support__c;
        wrToReturn.hasAccess = Schema.sObjectType.Case.isCreateable();
        wrToReturn.clusterHelptext = Case.Cluster__c.getDescribe().getInlineHelpText();
        wrToReturn.accDetail = [Select Id,Technical_support_provided_by_Partner__c,Technical_support_provided_by_Partner__r.RASP_Customer_Portal__c,
                                Technical_support_provided_by_Partner__r.RASP_Customer_Phone__c,Technical_support_provided_by_Partner__r.RASP_Customer_Email__c, 
                                Technical_support_provided_by_Partner__r.RASP_Escalation_Detail__c,Technical_support_provided_by_Partner__r.RASP_Business_Contact__c,
                                Technical_support_provided_by_Partner__r.RASP_Business_Contact__r.Name, Tabs_Visibility__c from Account where ID = :Util.CurrentUser.Contact.AccountId LIMIT 1];
        Map<string, String> PrefferMethod = getPicklistValues('Case', 'Contact_method__c');
        Map<string, String> Priorty = getPicklistValues('Case', 'Priority');
        Map<string, String> Casetype = getPicklistValues('Case', 'Type');

        wrapper WrapPrefferMethod = new wrapper();
        WrapPrefferMethod.label='--- None ---';
        WrapPrefferMethod.Value='None';
        WrapPrefferMethod.selected=false;
        wrToReturn.ContactMethodOptions.add(WrapPrefferMethod);

        for(string pm : PrefferMethod.keySet()){
            wrapper wr1 = new wrapper();
            wr1.label= pm;
            wr1.Value= PrefferMethod.get(pm);
            wr1.selected=false;
            wrToReturn.ContactMethodOptions.add(wr1);
        }

        wrapper WrapPriorty = new wrapper();
        WrapPriorty.label='--- None ---';
        WrapPriorty.Value='--- None ---';
        wrToReturn.priorityOptions.add(WrapPriorty);

        for(string p : Priorty.keySet()){
            wrapper wr1 = new wrapper();
            wr1.label= p;
            wr1.Value= Priorty.get(p);
            wr1.selected=false;
            wrToReturn.priorityOptions.add(wr1);
        }

        wrapper WrapCasetype = new wrapper();
        WrapCasetype.label='--- None ---';
        WrapCasetype.Value='--- None ---';
        wrToReturn.TypeOptions.add(WrapCasetype);

        for(string p : Casetype.keySet()){
            wrapper wr1 = new wrapper();
            wr1.label= p;
            wr1.Value= Casetype.get(p);
            wr1.selected=false;
            wrToReturn.typeOptions.add(wr1);
        }
        return wrToReturn;
    }

    /**
     * @description get Case details.
     * @param recordId of case
     * @return wrapper
     */
    @AuraEnabled
    public static Casewrapper getCaseDetails(String recordId){

        UserRecordAccess ur = [SELECT HasAllAccess, HasDeleteAccess, HasEditAccess, HasReadAccess, HasTransferAccess, RecordId
                                FROM UserRecordAccess
                                WHERE UserId =: Userinfo.getUserId()
                                AND RecordId =: RecordId];
        if(!ur.HasReadAccess){
            return new Casewrapper();
        }

        Case tempCase = [SELECT id,subject,type,priority,description,casenumber,Product__c,Owner.Name,Owner.Type,origin,createddate,LastModifiedDate,status,isclosed,RecordType__c,Account.RSC_G_Support__c,
                         Contact_Name__c,Contact_Phone__c, Cluster_Tag__c, Cluster__c, Cluster__r.Name, ContactPhone, ContactMobile, ContactEmail,Contact.Name, Cluster__r.CDM_End_of_Support_Status__c,
                         Contact_method__c,Assigned_To_static__c,Support_Tunnel__c,Resolution_Details__c,ClosedDate,isEscalated,Case_Thread_ID__c,RSCInstance__r.RSCUrl__c,RSCInstance__r.Name,
                         (SELECT Id, CommentBody, CreatedDate, CreatedBy.Name FROM CaseComments WHERE IsPublished = TRUE ORDER BY CreatedDate DESC)
                         FROM Case WHERE Id = :recordId ];
        if(tempCase.RecordType__c != 'Support Case' && tempCase.RecordType__c != 'Customer Success'){
            return new Casewrapper();
        }

        Set<Id> caseCommentIdSet = new Set<Id>();
        for(CaseComment eachCaseComment : tempCase.CaseComments){
            caseCommentIdSet.add(eachCaseComment.Id);
        }

        //e2ca - 23 Jan 2023 - code added
        Map<Id,E2CAdv__CommentSourceControllers__c> CaseCommentIdtoCSC= new Map<id,E2CAdv__CommentSourceControllers__c>();
        for(E2CAdv__CommentSourceControllers__c CSC :[SELECT Id, E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Body__c ,
                                                      E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Body_Text__c,
                                                            E2CAdv__Long_Comments_Id__r.E2CAdv__IsCommentTrimmed__c , E2CAdv__CaseCommentId__c
                                                      FROM E2CAdv__CommentSourceControllers__c
                                                      WHERE  E2CAdv__CaseCommentId__c in :caseCommentIdSet
                                                      ORDER BY CreatedDate DESC]){
                                                          CaseCommentIdtoCSC.put(csc.E2CAdv__CaseCommentId__c,CSC);
        }
        //--end

        for(CaseComment eachCaseComment : tempCase.CaseComments){
            if(CaseCommentIdtoCSC.containsKey(eachCaseComment.Id) && CaseCommentIdtoCSC.get(eachCaseComment.Id).E2CAdv__Long_Comments_Id__r.E2CAdv__IsCommentTrimmed__c){
                eachCaseComment.CommentBody = CaseCommentIdtoCSC.get(eachCaseComment.Id).E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Body_Text__c;
            }
        }

        CaseArticle[] caseArticles = [SELECT KnowledgeArticleId FROM CaseArticle WHERE CaseId = :RecordId];

        Set<Id> kaIdSet = new Set<Id>();
        if(caseArticles != null && !caseArticles.isEmpty()){
            for (CaseArticle art: caseArticles) {
                kaIdSet.add(art.KnowledgeArticleId);
            }
        }

        List<KnowledgeArticleVersion> articlesList = new List<KnowledgeArticleVersion>();
        if(!kaIdSet.isEmpty()){
            articlesList = [SELECT Id, KnowledgeArticleId, UrlName, Title, Summary, LastPublishedDate
                                              FROM KnowledgeArticleVersion
                                              WHERE PublishStatus= 'Online'
                                              AND Language = 'en_US'
                            AND KnowledgeArticleId IN :kaIdSet];
        }

        List<Case> tempAttachment=[SELECT Id,
                                    (SELECT Id, contentType,createdDate,Name,Description FROM Attachments ORDER BY createddate),
                                    (SELECT Id,Title,FileType,CreatedDate,contentDocumentId  FROM AttachedContentDocuments ORDER BY createddate)
                                    FROM Case
                                    WHERE id=:recordId];

        Casewrapper WC = new Casewrapper();
        WC.caseDetail=tempCase;
        WC.caseArticle=articlesList;
        WC.caseAttachmnt=tempAttachment;
        // CS21-1071: Support Portal: Read only user profile
        WC.isEditAccess = Schema.sObjectType.Case.isUpdateable();
        // CS21-1071: Ends
        // CS21-1562: Disallow support case reopening after 30 days from Status change to Closed
        WC.isReopenAccess=true;
        if(tempCase.IsClosed){
          WC.isReopenAccess=(Date.valueOf(tempCase.ClosedDate).daysBetween(system.today())>30)? false:true;
        }
        // CS21-1562: Ends
        return WC;
    }

    /**
     * @description insert case comment
     * @param parentId of case
     * @param body of comment
     * @return wrapper
     */
    @AuraEnabled
    public static caseComment addMyComment(String parentId, String body){
        commentBody = body;
        CaseComment cc = new caseComment();
        //cc.CommentBody = body;
        cc.CommentBody = body.length() > 4000 ?  body.substring(0,3900)+'...': body;

        cc.ParentId = parentId;
        cc.IsPublished = true;
        insert cc;
        if(body.length() > 4000)
            setComment(cc.Id,body );
        return cc;
    }

     /**
     * @description insert case comment
     * @param ccId of case
     * @param body of comment
     */
    public static void setComment(String ccId, String body){
        // long comment
        E2CAdv__CommentSourceControllers__c scr = [SELECT Id,E2CAdv__Long_Comments_Id__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Body__c ,
                                                   E2CAdv__Long_Comments_Id__r.E2CAdv__IsCommentTrimmed__c , E2CAdv__CaseCommentId__c
                                                   FROM E2CAdv__CommentSourceControllers__c
                                                   WHERE  E2CAdv__CaseCommentId__c =:ccId ];
        E2CAdv__Long_Comments__c longComment = new 	E2CAdv__Long_Comments__c(
            id = scr.E2CAdv__Long_Comments_Id__c,
            E2CAdv__Comment_Body__c = body,
            E2CAdv__Comment_Body_text__c = body,

            E2CAdv__IsCommentTrimmed__c = true
        );
        update longComment;
        // source controllerquery
    }

    /**
     * @description escalate the case.
     * @param parentId of case
     * @param body of comment
     * @return caseComment
     */
    @AuraEnabled
    public static caseComment escalate(String parentId, String body){
        //CS21-1407 starts
        Case originalCaseOwner = [SELECT OwnerId
                                  FROM Case
                                  WHERE Id =:parentId];
        //CS21-1407 ends
        String ARbody = 'The case related to AR has been escalated with the following comments:'+ ' \n'+body; 
        CaseComment cc1 = new caseComment();
        body = 'This case has been escalated with the following comments:'+' \n'+body;
        commentBody = body;
        cc1.CommentBody = body.length() > 4000 ?  body.substring(0,3900)+'...': body;
        cc1.ParentId = parentId;
        insert cc1;
        if(body.length() > 4000)
            setComment(cc1.Id,body );
        Case caseRec = [SELECT Id, AccountId, OwnerId, Subject, Owner_s_Manager__c, Recent_Case_Owner__c, 
                        IsEscalated, Escalation_Count__c
                        FROM Case
                        WHERE Id =:parentId];
        caseRec.isEscalated = true;
        caseRec.Last_Customer_Update__c = System.now();
        caseRec.Escalation_Count__c = caseRec.Escalation_Count__c == null ? 1 : ++caseRec.Escalation_Count__c;
        update caseRec;

        Tasks__c t = new Tasks__c();
        t.Case__c = parentId;
        t.Account__c = caseRec.AccountId;
        t.Customer_Comments__c = body;
        t.Owner_ID__c = caseRec.Recent_Case_Owner__c;
        t.Priority__c = 'High';
        t.Problem_Statement__c = body;
        t.Status__c = 'Pending';
        t.Subject__c = caseRec.Subject;
        t.Support_Manager__c = caseRec.Owner_s_Manager__c;
        t.Task_Sub_Type__c = 'Portal Triggered Escalation';
        t.Task_Type__c = 'Customer Escalation';
        insert t;

        //------- CS21-2742: Update AR that case was escalated with escalation comments and send email to owner 
        List<Note> insertNotes = new List<Note>();
        Map<String,List<Note>> sendNotifications = new Map<String,List<Note>>();
        for(Assist_Request__c AR: [Select Id, Name, Case__c, ownerId, Type__c, Account__c, Priority__c, owner.email from Assist_Request__c where Case__c =: parentId]){
            String title = 'CASE is ESCALATED - Assist Request '+AR.Name;
            insertNotes.add(new Note(ParentId = AR.Id,Body  = ARbody,title=title));
            
        }
        if(!insertNotes.isEmpty()){
            insert insertNotes;
        }
        sendNotifications.put('notesRecordList',insertNotes);
        Flow.Interview.sendNotificationToARowner flow1 = new Flow.Interview.sendNotificationToARowner(sendNotifications);
        flow1.start();
        //------- CS21-2742: Update AR that case was escalated with escalation comments and send email to owner 
        

        return cc1;
    }

    
    /**
     * @description reopen the case.
     * @param parentId of case
     * @param body of comment
     * @return Case
     */
    @AuraEnabled
    public static Case reopen(String parentId, String body){
        Case caseRec = new Case(Id = parentId);
        caseRec.Status='Reopen';
        //CS21-1884 Case routing fix if case owner is inactive
        update caseRec;

        CaseComment cc1 = new caseComment();
        cc1.CommentBody =  body.length() > 4000 ?  body.substring(0,3900)+'...': body;
        cc1.ParentId = parentId;

        insert cc1;
        if(body.length() > 4000)
            setComment(cc1.Id,body );

        return caseRec;
    }

    /**
     * @description update case as closed.
     * @param recId of case
     * @return Case
     */
    @AuraEnabled
    public static Case statusclosed(String recId){
        Case cs = new Case();
        cs.status = 'Customer requested close';
        cs.id = recId;
        update cs;
        return cs;
    }

    /**
     * @description get Related Attachments of Case.
     * @param recordId of case
     * @return List<Attachment>
     */
    @AuraEnabled
    public static List<Attachment> getAttachmentDetails(String recordId){
        List<Attachment> tempAttachment = [SELECT Id, Name, Body, CreatedDate, Description, ParentId FROM Attachment  where ParentId  =: recordId];
        return tempAttachment;
    }

    /**
	* @description picklist wrapper class
	*/
    public class CasePicklistCls {
        /**
		* @description label
		*/
        @AuraEnabled
        public string label{get;set;}
        /**
		* @description value
		*/
        @AuraEnabled
        public string value{get;set;}
        /**
		* @description selected
		*/
        @AuraEnabled
        public boolean selected{get;set;}
        
        /**
        * @description Case picklist value
		* @param label
		* @param value
        */
        public casepicklistcls(String label, String value) {
            this.label=label;
            this.value=value;
            this.selected=false;
        }
    }
    Map<string, String> PrefferMethod = getPicklistValues('Case', 'Preferred_Method_of_Contact__c');
    Map<string, String> Priorty = getPicklistValues('Case', 'Priority');
    Map<string, String> Casetype = getPicklistValues('Case', 'Type');

    /**
	* @description method to return picklist
	* @param ObjectApi_name
	* @param Field_name
    * @return Map
	*/
    public static Map<String, String> getPicklistValues(String ObjectApi_name,String Field_name){
        List<String> lstPickvals=new List<String>();
        Map<String, string>MapPickVals = new Map<String, String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            lstPickvals.add(a.getValue());//add the value  to our final list
            MapPickVals.put(a.getLabel(),a.getValue());
        }
        return MapPickVals;
    }

     /**
	* @description wrapper class
	*/
    public  class Wrapper{
        /**
		* @description rscSupport
		*/
        @AuraEnabled
        public String rscSupport{get; set;}
        /**
		* @description checked
		*/
        @AuraEnabled
        public Boolean checked{get; set;}
        /**
		* @description contact
		*/
        @AuraEnabled
        public Contact contact{get; set;}
        /**
		* @description teamMember
		*/
        @AuraEnabled
        public CaseTeamMember teamMember{get; set;}
        /**
		* @description label
		*/
        @AuraEnabled
        public string label{get;set;}
        /**
		* @description Value
		*/
        @AuraEnabled
        public string Value{get;set;}
        /**
		* @description selected
		*/
        @AuraEnabled
        public boolean selected{get;set;}
        /**
		* @description selected
		*/
        @AuraEnabled
        public list<wrapper>priorityOptions{get;set;}
        /**
		* @description typeOptions
		*/
        @AuraEnabled
        public list<wrapper>typeOptions{get;set;}
        /**
		* @description ContactMethodOptions
		*/
        @AuraEnabled
        public list<wrapper>ContactMethodOptions{get;set;}
        /**
		* @description hasAccess
		*/
        @AuraEnabled
        public Boolean hasAccess{get;set;}
        /**
		* @description accDetail
		*/
        @AuraEnabled
        public account accDetail{get;set;}
        /**
		* @description clusterHelptext
		*/
        @AuraEnabled
        public String clusterHelptext{get;set;}
        /**
		* @description wrapper
		*/
        public wrapper(){
            priorityOptions = new List<wrapper>();
            typeOptions = new List<wrapper>();
            ContactMethodOptions = new List<wrapper>();
        }
        /**
        * @description CS21-496 starts
        * @param con
        * @param ctm
        * @param selected
        */
        public wrapper(Contact con, CaseTeamMember ctm, boolean selected) {
            contact = con;
            TeamMember = ctm;
            checked = selected;
        }
    }

     /**
	* @description wrapper class
	*/
    public  class Casewrapper{
        /**
        * @description caseDetail
        */
        @AuraEnabled
        public Case caseDetail{get; set;}
        /**
        * @description caseArticle
        */
        @AuraEnabled
        public List<KnowledgeArticleVersion> caseArticle{get; set;}
        /**
        * @description caseAttachmnt
        */
        @AuraEnabled
        public List<case> caseAttachmnt{get; set;}
        /**
        * @description isEditAccess
        */
        @AuraEnabled
        public Boolean isEditAccess{get; set;}
        /**
        * @description isReopenAccess
        */
        @AuraEnabled
        public Boolean isReopenAccess{get; set;}
    }
    /**
	* @description GET related Cases
	* @return Cases
	*/
    public static List<Case> getCases(){
        Id myId =[SELECT id,ContactId FROM user WHERE Id =: Userinfo.getUserId()].ContactId;
        List<Case> clist = [SELECT Subject,Type,Priority,Contact_method__c,Support_Tunnel__c,Description FROM Case WHERE ContactId =: myId];
        return cList;
    }
    /**
	* @description CS21-496 starts
	* @param ca
    * @return Case
	*/
    @AuraEnabled
    public static Case saveCase(Case ca) {
        AssignmentRule AR = new AssignmentRule(); AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.assignmentRuleId= AR.id;
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
        ca.RecordTypeId = recordTypeId;
        ca.setOptions(dmo);
            insert ca;
        // 3033: US ASE / FED queue and routing changes FY25
        updateCaseOwner(ca);
        return  [SELECT Id ,CaseNumber  FROM CASE WHERE ID =: ca.Id ];
    }

    /**
	* @description 3033: US ASE / FED queue and routing changes FY25
	* @param ca
	*/
    public static void updateCaseOwner(Case ca){
        
        Case objCase = [SELECT Id, AccountId, OwnerId, Origin, RecordTypeId, Account.US_Federal_Account__c FROM Case WHERE Id =: ca.Id];

        Map<Id, Assigned_Support_Engineer__c> aseByAccIdMap = new Map<Id, Assigned_Support_Engineer__c>();
        aseByAccIdMap = CaseTriggerHandler.getAccAssignedSupEngRecords(new Set<Id>{objCase.AccountId}, aseByAccIdMap);

        Map<String, Id> queueNameIdMap = new Map<String, Id>();
        queueNameIdMap = CaseTriggerHandler.getCaseQueueMap();

        if(objCase.AccountId != null
            && objCase.RecordTypeId == CaseTriggerHandler.SUPPORT_CASE_RT_ID
          // Skip logic when case details are updated and the case owner is in 'Predibase' queue
                && objCase.ownerId != queueNameIdMap.get('Predibase_Queue')){
                // Where an account is both "Federal" and "ASE", default to the ASE queue
                if(objCase.Account.US_Federal_Account__c 
                    && aseByAccIdMap.containskey(objCase.AccountId)){
                        objCase.OwnerId = queueNameIdMap.get('ASE_Queue');
                }
                // For FedRel Case
                else if(objCase.Account.US_Federal_Account__c){
                        objCase.OwnerId = queueNameIdMap.get('FED_Queue');
                }
                    // Account with ASE record
                else if(aseByAccIdMap.containskey(objCase.AccountId)){
                    // Non Proctive Case (Alert, Alert(jira) and SenttyAI)
                    if(!CaseTriggerHandler.PROACTIVE_CASE_ORIGIN_LIST.contains(objCase.Origin)){
                        objCase.OwnerId = queueNameIdMap.get('ASE_Queue');
                }
                // Proctive Case (Alert, Alert(jira) and SenttyAI)
                else if(CaseTriggerHandler.PROACTIVE_CASE_ORIGIN_LIST.contains(objCase.Origin)){
                    objCase.OwnerId = queueNameIdMap.get('Proactive_Alerts');
                    }
                } 
            }
        UPDATE objCase;
    }

    /**
	* @description caseTeamMembers
	* @param CaseId
	* @param CaseNumber
    * @return manageCaseTeam
	*/
    @AuraEnabled
    Public static List<manageCaseTeam> caseTeamMembers(string CaseId , string CaseNumber){
        List<Contact> ConList = retrieveContacts('', false, CaseId);
        return generateCaseMembersList(CaseId, ConList);
    }

    /**
	* @description CaseTeams
    */
    public class ManageCaseTeam{
        /**
        * @description con
        */
        @AuraEnabled public Contact con{get;set;}
        /**
        * @description isAdded
        */
        @AuraEnabled public Boolean isAdded{get;set;}
        /**
        * @description Construtor
        * @param con
        * @param isAdded
        */
        public manageCaseTeam(Contact con , Boolean isAdded){
            this.con = con;
            this.isAdded = isAdded;
        }
    }

    /**
	* @description add Collegue to Case
	* @param caseId
	* @param memberIdList
	*/
    @AuraEnabled
    Public static void addColleaguesToCase(string caseId, List<string> memberIdList){
        try{
            List<CaseTeamMember> ctm_To_Delete = new List<CaseTeamMember>();
            for(CaseTeamMember ctm :[SELECT Id, memberid from caseteammember where parentid = :caseId AND memberid NOT IN :memberIdList]){
                string mId = ctm.memberid;
                if(mId.startsWith('003')){
                    ctm_To_Delete.add(ctm);
                }
            }
            if(ctm_To_Delete.size()>0){
                delete ctm_To_Delete;
            }
            
            List<CaseTeamMember> ctm_To_Insert = new List<CaseTeamMember>();
            string roleId = [select Id from CaseTeamRole where Name = 'Email CC'].Id;
            
            for (Id cid : memberIdList) {
                ctm_To_Insert.add(new CaseTeamMember(ParentId=caseId, MemberId=cid, TeamRoleId=roleId));
            }
            if(ctm_To_Insert.size()>0){
                Database.SaveResult[] srList = database.insert(ctm_To_Insert,false);
                Error_Logs__c errorLog = new Error_Logs__c(
                    Class__c = 'CaseApexController', 
                    Method__c = 'addColleaguesToCase',
                    Object__c = 'CaseTeamMember',
                    Type__c = 'SFDC',
                    Success__c = false
                );
                List<String> errorMessages = new List<String>();
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            errorMessages.add('"'+sr.getId()+'--'+err.getStatusCode() + ': ' + err.getMessage()+'"');
                        }
                    }
                }
                if(!errorMessages.isEmpty()){
                    errorLog.Error_Message__c = String.join(errorMessages, ',');
                    insert errorLog;
                }
                
            }
        }catch(Exception e){
            UtilityClass.logException(e, 'CaseApexController', 'addColleaguesToCase', 'CaseTeamMember', null, 'SFDC', false);
             throw new AuraHandledException('ops something went wrong.');
        }
    }

    /**
	* @description Create Contact 
	* @param firstName
	* @param lastName
    * @param email
	* @param title
    * @param phone
    * @return string
	*/
    @AuraEnabled
    public static string createContact(String firstName, String lastName, String email, String title, String phone) {
     //CS21-1839
        list<String> partnerUserList=new list<String>();
        list<String> sameAccCustomerlist=new list<String>();
        list<String> sameAccPartnerlist=new list<String>();
        list<String> sameAccInactiveUserlist=new list<String>();
        list<String> diffAccUserList=new list<String>();
        list<String> Inactiveuserlist=new list<String>();
        
        Map<Id, UserLicense> licenseMap=new Map<id,UserLicense>([SELECT Id, Name FROM UserLicense  WHERE NAME LIKE '%Customer Community%' OR NAME LIKE '%Partner Community%']);
        list<user> userlist=[select id,isactive,contact.Accountid,contactid,Profile.UserLicenseId,IsPortalEnabled,accountid,email,
                             contact.Created_By_Customer__c,contact.email from user where Email=:email or contact.email=:email order by isactive desc];
        
        if(userlist.size()>0)
        {      
            for(user u:userlist){
                
                if(u.AccountId==Util.CurrentUser.Contact.AccountId){
                    if(u.IsActive && (licenseMap.get(u.Profile.UserLicenseId).Name).contains('Customer Community') && u.IsPortalEnabled){
                        sameAccCustomerlist.add(u.email);
                    }else if(u.IsActive && (licenseMap.get(u.Profile.UserLicenseId).Name).contains('Partner Community') && u.IsPortalEnabled){
                        sameAccPartnerlist.add(u.email);
                    }else if(!u.IsActive){
                        sameAccInactiveUserlist.add(u.email);
                    }
                }else if(u.AccountId!=Util.CurrentUser.Contact.AccountId && u.Accountid!=null){
                    diffAccUserList.add(u.email);
                }else if(!u.Isactive){
                    Inactiveuserlist.add(u.email);
                }
                
            }
              
             for(user u:userlist){
                 if(sameAccCustomerlist.contains(u.email)){
                       if(u.contact.email!=u.email && u.email==email )
                              {
                                  return 'This user already exist with "'+u.contact.email+'" email.';
                              }
                                return label.Manage_Colleague_Same_Acc_Error; 

                 }
                 else if(sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email)){
                       partnerUserList.add(u.contactid);

                 }else if(sameAccInactiveUserlist.contains(u.email) && !sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email)){
                      return label.User_is_Inactive_Error;
                 }
                 else if(diffAccUserList.contains(u.email) && !sameAccInactiveUserlist.contains(u.email) && !sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email)){
                      return label.Different_Account_Error;

                 }
                   else if(Inactiveuserlist.contains(u.email) && !diffAccUserList.contains(u.email) && !sameAccInactiveUserlist.contains(u.email) && !sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email)){
                      return label.User_is_Inactive_Error;

                 }
           
                }  
            }
      
      
        list<contact> conlist=[select email,accountid,Created_By_Customer__c,User_Profile__c from contact where Email=:email or id in:partnerUserList order by User_Profile__c desc];

        String retVal = '';
        Boolean duplicateContactAvailable=false;
        Boolean contactUnderSameAccount=false;
        list<String> sameEmaillist=new List<String>();
        list<contact> contactList=new list<contact>();
        try {
             if(conlist.size()>0)
            {
              for(contact conData:conlist)
                {
                    if(conData.accountid==Util.CurrentUser.Contact.AccountId )
                      { 
                           if(!conData.Created_By_Customer__c || ((partnerUserList.contains(conData.id)) && !conData.Created_By_Customer__c)){ 
                              Contact con = new Contact();
                              con.id=conData.id;
                              con.FirstName = firstName;
                              con.lastName = lastName;
                              con.Email = email;
                              con.Title = title;
                              if(phone!=null)
                              {
                                 con.Phone = phone; 
                              }
                              con.AccountId = Util.CurrentUser.Contact.AccountId;
                              con.Created_By_Customer__c=true; 
                              contactUnderSameAccount=true;
                               if(!sameEmaillist.contains(con.email)){
                                   contactList.add(con);
                               }
                              
                              sameEmaillist.add(con.email);
                             }
                          else {
                              return label.Manage_Colleague_Same_Acc_Error; 
                          }
                      }
                  else{
                    
                      duplicateContactAvailable=true;
                     }     
                }
                if(contactList!=null && contactList.size()>0)
                {
                    update contactList;
                    return '';
                }
                if(!contactUnderSameAccount && duplicateContactAvailable){
                         return label.Manage_Colleague_Diff_Acc_Error; 
                    }
          
            }else{
            Contact con = new Contact();
            con.FirstName = firstName;
            con.lastName = lastName;
            con.Email = email;
            con.Title = title;
            con.Phone = phone;
            con.AccountId = Util.CurrentUser.Contact.AccountId;
            con.Created_By_Customer__c=true;
           insert con;
                }
            if(Test.isRunningTest()){
                throw new DMLException();
            }   
            
         //   CS21-1839 Ends
        } catch (exception ex) {
            retVal = ex.getMessage();
        }
        return retVal;
    }

    /**
	* @description Contact
	*/
    @AuraEnabled
    public static Contact contact {
        get {
            if (contact == null)
                contact = new Contact(AccountId = Util.CurrentUser.Contact.AccountId);
            return contact;

        }
        set;
    }

     /**
    * @description dummyMethod
    * */
    @AuraEnabled
    public static void getBig() {
        System.debug(LoggingLevel.ERROR,'Dummy');
    }


    /**
    * @description fetchContact
    * @param sortField
	* @param isAsc
    * @param CaseId
    * @return manageCaseTeam
    */
     @AuraEnabled
    Public static List<manageCaseTeam> fetchContact(String sortField, Boolean isAsc, String CaseId){
        List<Contact> ConList = retrieveContacts(sortField, isAsc, CaseId);
        return generateCaseMembersList(CaseId, ConList);
    }


    /**
	* @description Retrive Contacts related to Case Account
	* @param sortField
    * @param isAsc
-   * @param CaseId
    * @return Contact
	*/
    private static List<Contact> retrieveContacts(String sortField, Boolean isAsc, String CaseId){
        
        Id AccountId = [SELECT AccountId FROM Case WHERE Id=:CaseId].AccountId;
        Map<Id, UserLicense> licenseMap=new Map<id,UserLicense>([SELECT Id, Name FROM UserLicense WHERE NAME LIKE '%Customer Community%'  OR NAME LIKE '%Partner Community%']);
        List<Contact> ConList = new List<Contact>();
        list<Id> activeUserConIds=new list<Id>();
        list<id> inActiveUserConIds=new list<Id>();
        
        for(user u:[select id,contactId,IsActive,Profile.UserLicenseId,contact.Created_By_Customer__c,email,contact.email from user where Accountid=:AccountId and IsportalEnabled=true]){
            if(u.IsActive && ((licenseMap.get(u.Profile.UserLicenseId).Name).contains('Customer Community') || (u.contact.Created_By_Customer__c && (licenseMap.get(u.Profile.UserLicenseId).Name).contains('Partner Community')))){
                 activeUserConIds.add(u.ContactId); 
            }else{
                 inActiveUserConIds.add(u.ContactId);
            }
              
        }
        String ConLists = 'Select Id, FirstName, LastName, Email, AccountId, Name,Created_By_Customer__c  ' +
                            'From Contact Where (Email !=null And AccountId =:AccountID AND Created_By_Customer__c=true And Id NOT in :inActiveUserConIds) OR (Id in :activeUserConIds )';

        if(!String.isBlank(sortField)){
            ConLists += ' Order By ' + String.escapeSingleQuotes(sortField);

            if(!isAsc){
                ConLists += ' desc';
            }
        }
        ConList=Database.query(String.escapeSingleQuotes(ConLists));
           
        
        return ConList;
    }

    /**
	* @description generateCaseMembersList
	* @param CaseId
	* @param ConList
    * @return manageCaseTeam
	*/
    private static List<manageCaseTeam> generateCaseMembersList(String CaseId, List<Contact> ConList){
        List<CaseTeamMember> caseMem= [select id, MemberId from CaseTeamMember where ParentId =: CaseId];
        Set<Id> alreadyAMember = new Set<Id>();
        for(CaseTeamMember csm :caseMem ){
            alreadyAMember.add(csm.MemberId);
        }
        List<manageCaseTeam> caseMembers = new  List<manageCaseTeam>();
        for(Contact csm :ConList ){
            caseMembers.add(new manageCaseTeam(csm,alreadyAMember.contains(csm.Id)));
        }
        return caseMembers;
    }

    /**
	* @description S21-2619-Vijay Kumar K R-Spe 3, 2024    End of Support (EOS) Notifications for Clusters Running CDM 8.1 (or earlier)eCaseMembersList
	* @param clusterId
    * @return manageCaseTeam
	*/
    @AuraEnabled
    Public static String checkClusterSoftwareVersion(String clusterId){
        return [SELECT Id, CDM_End_of_Support_Status__c FROM Cluster__c WHERE Id =: clusterId].CDM_End_of_Support_Status__c;
    }
}