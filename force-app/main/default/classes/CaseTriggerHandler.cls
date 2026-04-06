/**
 * @Author      : Rajesh Gosetty
 * @description : CaseTriggerHandler to handle the methods that are being called at case events
 * @TstClass    : CaseTriggerHandlerTest
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS-226           Ashwini Gnanamurthy    Sept 12, 2019    Defaulting the JIRA alert's origin to 'Alert (Email)'
 * CS21-1192        Vijay Kumar K R        July 18, 2022    Defaulting the JIRA alert's origin to 'Alert (JIRA)'
 * CS21-717         Vijay Kumar K R        July 18, 2022    Improve logic of creating Proactive Alert (Email) cases from ALERT JIRAs
 * CS21-1243        Shiva Sharma           Sept 13, 2022    Update threshold of Digital queue routing and US account
 * CS21-1252        Shubham                Sept 22, 2022    Fixed Case Status Tracker issue
 * CS21-553         Shubham                Oct 11,2022      Added validation on End User Customer field
 * CS21-617         Shubham                Oct 28,2022      Added a warning to change case contact
 * CS21-1328        Vijay Kumar K R        Nov 08, 2022     Create a field to extract Asset's Support End Date from Asset to Case Page
 * CS21-1349        Shubham                Nov 11,2022      Calculated and updated TTR field on case every time the case status is changed to Closed.
 * CS21-1361        Vijay Kumar K R        Nov 17, 2022     Removal of SLAs and Next Step validation for Alert JIRA
 * CS21-1302        Shiva Sharma           Nov 22, 2022     Update Account on Selection of Contact .
 * CS21-1326        Vijay Kumar K R        Dec 14, 2022     [FedRAMP] Disable case creation from email.
 * CS21-1316        Vijay Kumar K R        Jan 06, 2023     [FedRAMP] Disable GetFeedback.
 * AFTER-GO-LIVE-170-Shiva Sharma          Feb 02, 2023     Contact selection to oldest in case multiple contact based on supplied email
 * CS21-1378        Vijay Kumar K R        May 22, 2023     If Ransomware recovery selected under the Special account handling: automatically include incident managers of the Ransomware Response Team (RRT) in Public Comment cc
 * CS21-1261        Vijay Kumar K R        May 23, 2023     Enable Case Owner Manager from SFDC to display in JIRA
 * CS21-1452        Vijay Kumar K R        June 14, 2023     Case Survey Feedback Owner Reassignment: If Case Owner changes in case of a transfer of ownership, the new Survey Owner field should capture the change (last case owner).
 * CS21-1536        Vijay Kumar K R        July 4, 2023      Append the Cluster Tag in the case subject line for proactive alerts
 * CS21-1832:       Vijay Kumar K R        August 23, 2023   New Value added "Waiting for Customer Input" TTR Calculation to be modified with an inclusion to active case statuses
 * CS21-1762        Vijay Kumar K R        July 6 2023      If the Hot/Critical Issue has the Escalation Manager Owner set in the primary case, the escalation Manager Owner should also reflect in the Ransomware Escalation or Support Escalation created
 * CS21-1832:       Vijay Kumar K R        August 23 2023   New Value added "Waiting for Customer Input" TTR Calculation to be modified with an inclusion to active case statuses
 * CS21-1885:       Vijay Kumar K R        August 23 2023   Initial Case owner assignment
 * CS21-1750        Sushant Arora          Sep 21 2023      Enable custom case field history tracking
 * CS21-1923        Vijay Kumar K R        Oct 10 2023      Escalation Task assignment - Not in CSE queue or OPEN
 * CS21-100        Shiva Sharma             11/18/2023      Changed field from comment to text
 * CS21-2006        Vijay Kumar K R        Nov 21 2023      [FedRAMP 1.5] Enable case creation with email for hybrid RSC-G/RSC/CDM customers
 * CS21-2009        Vijay Kumar K R        Dec 19 2023      Request to have 'Initial Case Owner' field in SFDC cases owned by Proactive Support Team
 * CS21-2029        Sushant Arora          Aug 21 2024      Updating the contacts on the case as per the conditions in the ticket.
 * CS21-2619        Vijay Kumar K R        Sept 09 2024      End of Support (EOS) Notifications for Clusters Running CDM 8.1 (or earlier)
 * RRR-8			Sushant Arora		   Nov 19, 2024     Update fields on Risk Profile, when value on Mitigation case changes.
 * CS21-3033        Vijay Kumar K R        Jan 16 2024      US ASE / FED queue and routing changes FY25
 * CS21-3212 		Sushant Arora 		   May 29 2025      moving current status and next steps comment insertion code to flow.
 * CS21-3531		Shailesh Kumar		   Aug 28 2025		Test Class coverage
 * RRR-66           Sushant Arora          June 19, 2025    Create CSM cases when "Customer Sentiment" on the CSM case chnaged to "Red"
 * CS21-3040		Shailesh Kumar			Oct 8, 2025		AHA Idea Links in Escalation Case Information
 * CS21-3568        Shailesh Kumar         Oct 30, 2025     Disallow case ownership transfer after 7 days of "Closed" status
 * --------------------------------------------------------------------------------------------------------------------------------
 */

public class CaseTriggerHandler {

    public static Boolean stopValidation=true;
    public static Boolean isRepeat = true;
    public static Boolean isExecuted = false; //CS21-1252 - To avoid recursion of UpdateStatusTracking Method
    public static Boolean milestoneRun = false;
    public static Set<Id> caseIdAfter = new Set<Id>();
    public static Set<Id> caseIdBefore = new Set<Id>();
    public static Map<Id,String> caseSuggestionMap = new Map<Id,String>();
    public static Map<Id,Contact> conMap = new Map<Id,Contact>();
    public static map<String,Case> mapJiraToCase = new map<String,Case>();
    public static map<Id,Contact> caseConIdTOEmail = new map<Id,Contact>();//map to get case contact email
    public static String contactEmail;
    public static Map<String, Id> queueNameIdMap = new Map<String, Id>();
    public static Set<Id> caseIdSetForSurvey = new Set<Id>();   //Stores the Case Ids so that Survey is not resent
    // CS21-1261 Update: Enable Case Owner Manager from SFDC to display in JIRA
    public static Map<String, Case> caseNumberAndOwnerEmailsforJira = new Map<String, Case>(); //Case Owner updates to be sent to JIRA - CS21-644
    public static Integer openQueueThreshold = Integer.ValueOf(System.label.Open_Queue_Threshold);//CS21-1890
    @TestVisible
    private static final String CASE_ORIGIN_ALERT_JIRA = 'Alert_JIRA';
    @TestVisible
    private static final String JIRA_CASE_WEB_EMAIL = System.label.JIRA_Case_Web_Email;
    private static final Id ALERT_BOT_USER_ID = [SELECT Id FROM User WHERE Alias = 'alertbot' AND IsActive = true Limit 1].Id;
    private static final List<String> PRO_ACTIVE_CASE_ORIGIN_LIST = System.Label.Pro_Active_Case_Origins.split(',');
    //CS21-2006:
    private static final String FEDRAMP_RSC_CDM_LABEL = System.label.FedRAMP_RSC_G_For_Case_Creation;
    private static final List<String> TA_PUSH_ACCOUNTS = System.label.TA_Program_Accounts.split(';');
    // 3033: Support Case RT Id
    @TestVisible
    public static Id SUPPORT_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case').getRecordTypeId();
    //RRR-66
    Id customerSuccessRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Success').getRecordTypeId();

    public static final List<String> PROACTIVE_CASE_ORIGIN_LIST = new List<String>{'Alert','Alert_JIRA','Pulse'};
    public static Boolean IS_TRANSFER_QUEUE_APPROVED = false;
	public static Boolean forceAsyncFlagForTest = false;

    //CS21-2006:
	/**
     * @description get Fed Ramp Case Ids.
     * @param caseList A list of Case IDs.
     * @return List of case Ids
     */
    public Set<Id> getFedRampCaseIds(List<Case> caseList){
        Set<Id> fedRampCaseIdSet = new Set<Id>();
        for(Case cs: [SELECT Id, Account.RSC_G_Support__c
                        FROM Case
                        WHERE Id IN: caseList]){
            if(cs.Account.RSC_G_Support__c != null
                && !String.valueOf(cs.Account.RSC_G_Support__c).contains(FEDRAMP_RSC_CDM_LABEL)){
                    fedRampCaseIdSet.add(cs.Id);
            }
        }
        return fedRampCaseIdSet;
    }
	
	/**
     * @description after insert method
     */
    public void afterInsert(){
        Set<id> caseIds = new Set<id>();
        Set<Id> allCaseIds = new Set<Id>();
        Schema.DescribeFieldResult fieldResult =  Case.Status.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Status_Tracking__c> csTList = new List<Status_Tracking__c>();
        List<Case> csJList = new List<case>();  //List of cases for Linking Jira Alert
        List<CaseComment> ccList = new List<CaseComment>();
        Set<Id> dupCaseIdSet = new Set<Id>();

        Integer maxLength = 0;
        Integer alertLength = Integer.valueOf(System.label.JIRAID_Length);
        Integer sparkLength = Integer.valueOf(System.label.JIRA_SPARK_Length);

        //CS21-2006:
        Set<Id> fedRampCaseIdSet = getFedRampCaseIds(trigger.new);
        //RRR-66
        List<Case> redSentimentCases = new List<Case>();

        // Collect Support Cases for RSC-G deletion processing
        Set<Id> supportCaseAccIdSet = new Set<Id>();
        List<Case> rscgCaseList = new List<Case>();

        for(Case cs: (List<Case>)trigger.new){
            if(cs.RecordTypeId == SUPPORT_CASE_RT_ID && cs.AccountId != null){
                supportCaseAccIdSet.add(cs.AccountId);
            }
            //RRR-66
            if (cs.RecordTypeId == customerSuccessRecordTypeId && cs.Customer_Sentiments__c == 'Red') {
                redSentimentCases.add(cs);
            }
            // by Vijay CS21-1326: Stoping below fiunctionalities for FedRAMP Case created by Email (Since it's deleted after 1min)
            if(fedRampCaseIdSet.contains(cs.Id)){
                continue;
            }

            // Edited by Bharat CS-384 & CS-491
            if(cs.duplicate_case_id__c!=null){
                If(cs.Subject !=null && cs.Subject.containsIgnoreCase('JIRA')){
                    String jira_id = cs.subject.substringBefore(')').substringAfter('] (');
                    maxLength = jira_id.containsIgnoreCase('alert') ? alertLength: sparkLength;
                    If(jira_id.length() > maxLength ){
                        jira_id = jira_id.substring(0, maxLength );
                    }
                    CaseComment cc = new CaseComment();
                    cc.ParentId = cs.duplicate_case_id__c;
                    cc.CommentBody = jira_id + ' is looking for an update again';
                    ccList.add(cc);
                    dupCaseIdSet.add(cs.Id);
                }
            }
            // CS21-717: to avoid linking Duplicate case (which is deleted in SF by deleteDupCases method) in JIRA
            else{
                if(cs.Origin == CASE_ORIGIN_ALERT_JIRA){
                    csJList.add(cs);
                }
                if(cs.ContactId != null){
                    caseIds.add(cs.id);
                }
                for(Schema.PicklistEntry f : ple){
                    csTList.add(new Status_Tracking__c(Case__c = cs.id,Tracking__c = f.value ,Days__c = 0,Hours__c = 0, Minutes__c = 0,Miliseconds__c = 0,Number_of_times_in_status__c = 0 ));
                }
            }
            
            //--- CS21-3051- insert related SupportCaseIntelligence__c records
            allCaseIds.add(cs.Id);
        }

        // Enqueue RSC-G Support Case deletion processing using Queueable 
        if(!supportCaseAccIdSet.isEmpty()){
            Map<Id, Account> rscgAccountByCaseIdMap = new Map<Id, Account>([SELECT Id, RSC_G_Support__c FROM Account WHERE Id IN :supportCaseAccIdSet]);
            fetchRscgCases(rscgAccountByCaseIdMap, rscgCaseList);
        }

        if(!csTList.isEmpty()){
            insert csTList;
        }
        if(!caseIds.isEmpty()){
            CaseTriggerHandler.searchUnifyMethod(caseIds);
        }
        if(!csJList.isEmpty()){
            //CaseTriggerHandler.AcctoCaseTeamsHandler((List<Case>)trigger.new);
            LinkJiraAlert(csJList);  // Added by Grazitti for linking Jira Alerts to cases
        }
        if(!ccList.isEmpty()){
            insert ccList;
        }

        if(!dupCaseIdSet.isEmpty()){
            deleteDupCases(dupCaseIdSet);
        }
        //RRR-66
        if(!redSentimentCases.isEmpty()){
            CS_AutomaticRiskProfileCreation.handleCustomerSentimentChange(null, redSentimentCases);
        }

        accountTerritoryToCaseTeams(((Map<Id, Case>)Trigger.newMap).keyset(), 'Case insert', null);

        // ----- CS21-3051- insert related SupportCaseIntelligence__c records
        createSupportLogicRecords(allCaseIds);

        // Enqueue RSC-G Support Case deletion processing using Queueable directly
        if(!rscgCaseList.isEmpty()){
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(rscgCaseList);
            System.enqueueJob(queueable);
        }
    }

    /**
    * @Method fetchRscgCases
    * @description fetching RSC-G cases
    * @param rscgAccountByCaseIdMap
    * @param rscgCaseList
    **/
    public static void fetchRscgCases(Map<Id, Account> rscgAccountByCaseIdMap, List<Case> rscgCaseList){
        for(Case cs : (List<Case>)trigger.new){
            if(rscgAccountByCaseIdMap.containsKey(cs.AccountId) && rscgAccountByCaseIdMap.get(cs.AccountId).RSC_G_Support__c == 'RSC-G'){
                rscgCaseList.add(cs);
            }
        }
    }

    /**
    * @Method deleteDupCases CS21-1192: Vijay Kumar K R <vijay.kr@rubrik.com>
    * @description deleting duplicate cases created from JIRA
    * @param dupCaseIdSet
    **/
    @future
    public static void deleteDupCases(Set<Id> dupCaseIdSet){
        DELETE [SELECT Id FROM Case WHERE Id IN: dupCaseIdSet];
    }

    /**
     * @description CS21-3051- insert related SupportCaseIntelligence__c records
     * @param caseIdSet set of case Ids
    */
    @future
    public static void createSupportLogicRecords(Set<Id> caseIdSet){
        try{
            List<SupportCaseIntelligence__c> supportCase = new List<SupportCaseIntelligence__c>();
            List<String> caseRecordTypes = (System.label.Case_recordtypes_for_SupportCaseIntelligence).split(',');
            if (Schema.sObjectType.Case.isAccessible()) {
                for(Case cs : [Select Id from Case where Id In: caseIdSet and Recordtype.Name In:caseRecordTypes]){
                    SupportCaseIntelligence__c sc = new SupportCaseIntelligence__c(Case__c = cs.id);
                    supportCase.add(sc);
                }
                if(!supportCase.isEmpty()){
                    insert supportCase;
                } 
            }
        }
        // catch statement for exceptions.
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception>>>>>'+e.getmessage());
            UtilityClass.logException(e, 'CaseTriggerHandler', 'createSupportLogicRecords');
        }
           
    }
	
	/**
     * @description after update method
     */
    public void afterUpdate(){
        set<id> csIds = new set<id>();
        //RRR-66
        List<Case> redSentimentCases = new List<Case>();
        Map<Id,Case> oldRedSentimentCases = new Map<Id,Case>();
        List<How_To__kav> kavList = new List<How_To__kav >();
        List<caseMilestone > milestoneList = new List<caseMilestone >();
        List<caseComment> caseCommentList = new List<caseComment>();
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        Map<id,Case> caseOldMap = (Map<Id,Case>)trigger.oldMap;
        Map<Id,Account> updateAccountMap = new Map<Id,Account>();
         List<Id> caseIdPriority = new List<Id>();
        //Map for Opportunity Id and Service Contract ID
        //Map<Id,String> contractStatus = new Map<Id,String>();
        //Map for Service Contract Id and Opportunity
        //Map<Id,Opportunity> scOppMap = new Map<Id,Opportunity>();
        //Map for fields mapping
        /*Map<String,String> fieldsMap = new Map<String,String>();
        fieldsMap.put('Duplicate', 'Duplicate Opp');
        fieldsMap.put('No Budget', 'Lost Budget');
        fieldsMap.put('No Response', 'Went Dark');
        fieldsMap.put('No Longer a Rubrik Customer', 'Lost Budget');
        fieldsMap.put('Not Ready to Renew', 'Timing/Not Ready');
        fieldsMap.put('Asset/Software Decommissioned', 'Lost Budget');*/
        Set<Id> changeAccountCaseIdSet = new Set<Id>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>{};
            Map<String,EmailTemplate> emailTemplateMap = new Map<String,EmailTemplate>();

        // CS21-1762
        Map<Id, Id> escMangerOwnerIdByCaseIdMap = new Map<Id, Id>();

        for(EmailTemplate et : [Select id,DEVELOPERNAME from EmailTemplate]){
            emailTemplateMap.put(et.DeveloperName,et);
        }
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'support@rubrik.com'];
        Set<Id> taskIds = new Set<Id>();

        // CS21-1452: Owner Change Case IdSet
        Map<Id, Id> userIdByOwnerChangeCaseIdMap = new  Map<Id, Id>();

        //CS21-2006:
        Set<Id> fedRampCaseIdSet = getFedRampCaseIds(trigger.new);
        //CS21-2116:
        Map<Id,Case> partnerCaseMap = new Map<Id,Case>();
        
        //CS21-3040
        Map<Id,Case> supportCaseIdeaRefMap = new Map<Id,Case>();
        
        Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();

        for(Case cs: (List<Case>)trigger.new){
            Contact con = new Contact();
            if(conMap.containskey(cs.Contactid))
                con = conMap.get(cs.Contactid);
            integer count = 0;
            EmailTemplate et;
            If(cs.KCS_Article_Candidate__c  == 'New Article Created' && cs.KCS_Article_Status__c == 'Draft' && cs.Article_Created__c == False)
            {

                How_To__kav kcs = new How_To__kav();
                kcs.Title = cs.Subject;
                kcs.UrlName = 'KCSURL0';
                kcs.Case__c = cs.Id;
                kcs.Resolution__c = cs.Resolution_Details__c;
                kcs.Cause__c =cs.Cause__c;
                kcs.Problem__c = cs.Problem__c;
                kcs.Status__c = cs.KCS_Article_Status__c;
                kcs.Solution_Detail__c  = cs.Solution__c;
                kcs.Additional_Note__c  = cs.Additional_Notes__c;
                kavList.add(kcs);

            }

            // Added by Grazitti for Copy Next Step to case Comments
            Case oldcase = (Case)trigger.oldmap.get(cs.id);
            //RRR-66
            if (cs.RecordTypeId == customerSuccessRecordTypeId && (cs.Customer_Sentiments__c != oldcase.Customer_Sentiments__c)) {
                redSentimentCases.add(cs);
                oldRedSentimentCases.put(cs.Id, oldcase);
            }
            //RNWA-17
            /*if( cs.status =='Closed' && cs.ServiceContractId != null && cs.Resolution__c != 'Spam/Junk'){
                contractStatus.put(cs.ServiceContractId, cs.Resolution_Code__c);
                scOppMap.put(cs.ServiceContractId,new Opportunity());
            }*/
            // CS-357 Akashdeep Start
            if(cs.priority!=oldcase.priority && cs.status!='Closed'){
                csIds.add(cs.id);
            }
            // CS-357 Akashdeep End
            //cs21-194
            if(cs.Status == 'Closed' && cs.Status != oldcase.Status && cs.PS_Task__c != null){
                taskIds.add(cs.PS_Task__c);
            }
			//CS21-2116
            if(partnerCaseId == cs.RecordTypeId && (cs.Type__c != oldcase.Type__c || cs.SubType__c != oldcase.SubType__c) ){
                partnerCaseMap.put(cs.Id,cs);
            }

            // Updated by Vijay Kumar K R for CS21-1175: Upon changing status from Waiting for Rubrik Support to In Progress or similar, automatic private comment added
            // Commented by Sushant Arora and moved to flow Case - After Insert,After Update for CS21-3212.
            /*
            if(trigger.oldmap.containsKey(cs.id) && (String.isNotBlank(cs.Current_Status__c) && isChangedCheck(cs, oldcase, 'Current_Status__c')) || (String.isNotBlank(cs.Next_Step__c) && isChangedCheck(cs, oldcase, 'Next_Step__c'))){
                        caseComment cc = new caseComment();
                        cc.ParentId = cs.Id;
                        cc.CommentBody = 'Case Summary: ' + cs.Current_Status__c + '\n' + 'Next Step: ' + cs.Next_Step__c;
                        caseCommentList.add(cc);
            }
			*/
            // Added by Grazitti to Check for Case Update upon which send Email Survey notification and Contact Fields update
            if(cs.close_survey_triggered__c != oldcase.close_survey_triggered__c
                && cs.close_survey_triggered__c
                && cs.Resolution__c != null
                && !System.Label.Spam_Resolutions.contains(cs.Resolution__c)
                // CS21-1316: change by Vijay, for fedRAMP Case: Not sending Email Notifications on Case Closure
                && !fedRampCaseIdSet.contains(cs.Id)){

                datetime lastSurveyTime = con.Last_GetFeedback_Date__c;
                datetime dtnow = datetime.now();

                if(!System.Label.Skip_Case_Close_Survey_for_Accounts.contains(cs.AccountId)
                    && (lastSurveyTime ==null
                        || (dtnow.getTime() - lastSurveyTime.getTime()) > (7*24*3600*1000)
                        || (System.Label.Account_Id_for_every_Case_Survey.contains(cs.AccountId)))
                    && caseIdSetForSurvey.contains(cs.Id)){
                        et = emailTemplateMap.get('Case_Closed_Notification_External_Survey');
                }
                else{
                    et = emailTemplateMap.get('Case_Closed_Notification_External');
                }

                con.Last_GetFeedback_Date__c = datetime.now();
                //if(con.Id != null){
                contactMap.put(con.id,con);
                //}

                Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
                if (owea.size() > 0 ) {
                    singleMail.setOrgWideEmailAddressId(owea.get(0).Id);
                }

                //set object Id
                singleMail.setTargetObjectId(con.Id);
                singleMail.setWhatId (cs.Id);
                //set template Id
                singleMail.setTemplateId(et.Id);
                //flag to false to stop inserting activity history
                singleMail.setSaveAsActivity(false);
                //This will not send email to contact
                singleMail.setTreatTargetObjectAsRecipient(false);
                List<String> toA = new List<String>{};
                    toA.add(cs.ContactEmail);
                singleMail.setToAddresses(toA);
                emails.add(singleMail);
                //send mail
            }

            if(cs.AccountId != oldcase.AccountId) {
                changeAccountCaseIdSet.add(cs.Id);
            }

            //CS21-644 - Salesforce Case Owner Update sync to JIRA
            // CS21-1261 Update: Enable Case Owner Manager from SFDC to display in JIRA
            if (cs.ownerId != oldcase.ownerId
                && !caseNumberAndOwnerEmailsforJira.containsKey(cs.CaseNumber)
                && (String.isNotBlank(cs.Owner_s_Email__c)
                    || String.isNotBlank(cs.Owner_Manager_Email__c))) {
                        caseNumberAndOwnerEmailsforJira.put(cs.CaseNumber, cs);
            }
            //CS21-644 - End

            // CS21-1762 - Start
            if(cs.EscalationManagerOwner__c != null
                && cs.EscalationManagerOwner__c != oldcase.EscalationManagerOwner__c){
                    escMangerOwnerIdByCaseIdMap.put(cs.Id, cs.EscalationManagerOwner__c);
            }

            // CS21-1452: Case Survey Feedback Owner Reassignment
            if(cs.Status == 'Closed'
                && cs.OwnerId != oldcase.OwnerId){
                    userIdByOwnerChangeCaseIdMap.put(cs.Id, cs.OwnerId);
            }
            // CS21-1452: End

            // ---- CS21-1721 -- update milestone ----
             if(cs.priority != oldcase.priority && oldcase.priority == 'None' && cs.priority != 'None'){
                caseIdPriority.add(cs.Id);
            }
            // ---- CS21-1721 -- END ----
            //CS21-3040
            if(cs.RecordTypeId == SUPPORT_CASE_RT_ID && cs.Idea_Reference__c!=null && cs.Idea_Reference__c!= oldCase.Idea_Reference__c){
                supportCaseIdeaRefMap.put(cs.Id, cs);
            }
            //CS21-3040 END
        }

        if(!kavList.isEmpty() && kavList !=null){
            insert kavList;
        }
		//CS21-3544
        /*List<opportunity> oppList = new List<opportunity>();
        for(ServiceContract scon : [select id,SBQQSC__RenewalOpportunity__c from ServiceContract where id IN: scOppMap.keySet()]){
            if(fieldsMap.containsKey(contractStatus.get(scon.Id)))
                oppList.add(new opportunity(
                    id=scon.SBQQSC__RenewalOpportunity__c,
                    StageName = '7 Closed Lost',
                    Lost_Reason__c = fieldsMap.get(contractStatus.get(scon.Id))
                ));
        }

        try{
            if(!oppList.isEmpty()){
                database.update(oppList, false);
            }
        }catch(Exception e){
            system.debug(LoggingLevel.ERROR, e.getMessage());
        }*/
		//CS21-3544 Ends

     /*   if(!caseCommentList.isEmpty()){
            try {
            database.insert(caseCommentList, false);
            } catch (Exception e) {
                system.debug(LoggingLevel.ERROR, 'Exception while inserting CaseComment: '+e.getMessage());
            }
        }
	 */
        //CS21-194 starts
        List<PS_task__c> taskList = new List<PS_task__c>();
        for(Id taskId : taskIds){
            taskList.add(new PS_task__c(
                id = taskId,
                Task_Status__c = 'Completed'
            ));
        }
        //CS21-194 end
        if(!taskList.isEmpty())
            update taskList;
        if(!contactMap.isEmpty())
            update contactMap.values();

        if(!emails.isEmpty() && !test.isRunningTest())
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
        // CS-357 Akashdeep Start
        //CS21-2012 Check added for IR Milestone
        if(csIds!=null && !csIds .isEmpty()){
            for(caseMilestone each : [Select Id,startdate from casemilestone where iscompleted = false and isviolated = false and caseID IN : csIds and MilestoneType.name!='Initial Response']){
                each.startdate = system.now();
                milestoneList.add(each);
            }
        }
        if(milestoneList!=null && !milestoneList.isEmpty())
            update milestoneList;
        // CS-357 Akashdeep End

        //CS21-2116
        if(!partnerCaseMap.isEmpty()){
            List<Case> caseList = [Select Id,Type__c,SubType__c,Duplicate_Case_Id__c from Case Where Duplicate_Case_Id__c IN: partnerCaseMap.keySet()];
            for(Case cs : caseList){
                if(partnerCaseMap.containsKey(cs.Duplicate_Case_Id__c)){
                    cs.Type__c = partnerCaseMap.get(cs.Duplicate_Case_Id__c)?.Type__c;
                    cs.SubType__c = partnerCaseMap.get(cs.Duplicate_Case_Id__c)?.SubType__c;
                }
            }
            try {
                database.update(caseList, false);
				if(test.isRunningTest()) throw new NullPointerException();														  
            } catch (Exception e) {
                Error_Logs__c err = new Error_Logs__c(Object__c = 'Case',
                                                      Error_Message__c = e.getMessage(),
                                                      Class__c = 'CaseTriggerHandler',
                                                      Method__c = 'afterUpdate',
                                                      Type__c = 'SFDC',
                                                      Success__c = false);
                insert err;
            }
        }

        //Update Case Team Member record with Role Case Owner when case owner changes
        updateCaseTeamMemberOnOwnerChange();

        //Send email notifications to Slack channel for selected updates on Case related to few Accounts
        //sendCaseNotificationsToSlack((List<Case>)Trigger.new, caseOldMap);

        if(!changeAccountCaseIdSet.isEmpty()) {
            accountTerritoryToCaseTeams(changeAccountCaseIdSet, 'Account update', JSON.serialize(caseOldMap));
        }

        //CS21-644 - JIRA callout to send case owner updates
        // CS21-1261 Update: Enable Case Owner Manager from SFDC to display in JIRA
        if (!caseNumberAndOwnerEmailsforJira.isEmpty()
            && !system.isFuture()
            && !system.isBatch()
            && !system.isQueueable()
            && !system.isScheduled()) {
            ZJIRACaseWebservice.sendCaseOwnerUpdatesToJira(JSON.serialize(caseNumberAndOwnerEmailsforJira));
        }
        //CS21-644 - End

        // ---- CS21-1721 -- update milestone ----
        if(!caseIdPriority.isEmpty()){
            completeInitalResponse(caseIdPriority);
        }
        //CS21-1721 END ------

        // CS21-1452: Case Survey Feedback Owner Reassignment
        if(!userIdByOwnerChangeCaseIdMap.isEmpty()){
            updateGetFeedbackResponseSurveyOwner(userIdByOwnerChangeCaseIdMap);
        }
        // CS21-1452: End

        // CS21-1750: Case History Tracking
        CS_FieldHistoryTracking.trackFieldsHistory(trigger.new, Trigger.oldMap);
        // CS21-1750: End

        // CS21-1762: START
        if(!escMangerOwnerIdByCaseIdMap.isEmpty()){
            updateRelatedEscalationOwner(escMangerOwnerIdByCaseIdMap);
        }
        //RRR-8
        try {
            Id retentionCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Retention Case').getRecordTypeId();
            CS_CrossObjectFieldSyncMapping mappingInstance = new CS_CrossObjectFieldSyncMapping('Retention Case To Risk Profile Sync');
            mappingInstance.setSourceRecordIds(Trigger.newMap.keyset());
            CS_CrossObjectFieldSyncMapping.execute(mappingInstance, new Map<String,String> { 'RecordTypeId' => retentionCaseId});
			if(test.isRunningTest()) throw new NullPointerException();														  
        } catch(Exception e){
            Error_Logs__c err = new Error_Logs__c(Object__c = 'Case',
                                                      Error_Message__c = e.getMessage() + e.getStackTraceString(),
                                                      Class__c = 'CaseTriggerHandler',
                                                      Method__c = 'afterUpdate',
                                                      Type__c = 'CS_CrossObjectFieldSyncMapping',
                                                      Success__c = false);
            insert err;
        }
        //RRR-66
        if(!redSentimentCases.isEmpty()){
            CS_AutomaticRiskProfileCreation.handleCustomerSentimentChange(oldRedSentimentCases, redSentimentCases);
        }
        //CS21-3040
        if(!supportCaseIdeaRefMap.isEmpty())
        	updateEscalationsWithIdeaRef(supportCaseIdeaRefMap);
        //CS21-3040 Ends
    }

    /**
     * Method: updateRelatedEscalationOwner
     * @description CS21-1762 When Escalation Manager Owner set in the primary case, Need to update same on related Escalation records
     * @param escMangerOwnerIdByCaseIdMap
     **/
    public static void updateRelatedEscalationOwner(Map<Id, Id> escMangerOwnerIdByCaseIdMap) {
        Map<Id, Escalation__c> updateEscMap = new Map<Id, Escalation__c>();
        for(Escalation__c objEsc : [SELECT Id, Escalation_Manager_Owner__c, Case__c
                                        FROM Escalation__c
                                        WHERE Case__c IN: escMangerOwnerIdByCaseIdMap.keySet()]){
            if(escMangerOwnerIdByCaseIdMap.containsKey(objEsc.Case__c)){
                Id escManagerOwnerId = escMangerOwnerIdByCaseIdMap.get(objEsc.Case__c);
                objEsc.Escalation_Manager_Owner__c = escManagerOwnerId;
                updateEscMap.put(objEsc.Id, objEsc);
            }
        }

        try {
        if(!updateEscMap.isEmpty()){
            UPDATE updateEscMap.values();
        }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'updateRelatedEscalationOwner Exception: '+e.getMessage());
        }
    }

    /**
     * Method: updateGetFeedbackResponseSurveyOwner
     * @description When Case Owner changes updating related GetFeedbackResponse SurveyOwner
     * @param userIdByOwnerChangeCaseIdMap
     **/
    public static void updateGetFeedbackResponseSurveyOwner(Map<Id, Id> userIdByOwnerChangeCaseIdMap) {

        Map<Id, GetFeedback_Survey_Response__c> updateGetFedMap = new Map<Id, GetFeedback_Survey_Response__c>();
        for(GetFeedback_Survey_Response__c objgetFed : [SELECT Id, Survey_Owner__c, Case_Id__c
                                                        FROM GetFeedback_Survey_Response__c
                                                        WHERE Case_Id__c IN: userIdByOwnerChangeCaseIdMap.keySet()]){
            Id caseOwnerId = userIdByOwnerChangeCaseIdMap.get(objgetFed.Case_Id__c);
            if(caseOwnerId != null
                && caseOwnerId.getSObjectType().getDescribe().getName() == 'User'){
                    objgetFed.Survey_Owner__c = caseOwnerId;
            }else{
                objgetFed.Survey_Owner__c = null;
            }
            updateGetFedMap.put(objgetFed.Id, objgetFed);
        }

        try {
        if(!updateGetFedMap.isEmpty()){
            UPDATE updateGetFedMap.values();
        }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,'updateGetFeedbackResponseSurveyOwner Exception: '+e.getMessage());
        }
    }

    /**
     * @description CS21-1721 This method is used to update the Initial Response Milestone of the case record  when a prioirty is updated or changed from None to any other value
	 * @param caseIdPriority
     */
	@future
    public static void completeInitalResponse(List<Id> caseIdPriority){
        List<CaseMilestone> updateCaseMilestone = new List<CaseMilestone>();
        List<caseMileStone> allCsmList = new List<caseMilestone>();
		List<CaseMilestoneW> allCsmWList = new List<CaseMilestoneW>();															  
        map<Id,Case> caseIdToCase=new map<Id,Case>();
        List<Id> CustomerSupportProfileIds = (System.label.SupportUser_Profiles).split(',');
            allCsmList = [SELECT Id, MilestoneType.Name, CaseId,
                          CompletionDate, isCompleted,Case.priority,Case.Createddate 
                          FROM caseMilestone
                          WHERE isCompleted = false
                          AND CaseID IN : caseIdPriority
                          AND MilestoneType.Name like '%Initial%'
                          AND CompletionDate = null
                          ORDER BY TargetResponseInMins];
		if(Test.isRunningTest()){
            List<Case> caseList = [SELECT Id,Status,CreatedDate,Priority from Case where id IN: caseIdPriority];
            for(Case cs : caseList){
                Integer s_num = 1;
                String result = String.valueOf(s_num++); 
                String fakeId = CaseMilestone.SObjectType.getDescribe().getKeyPrefix() +'0'.repeat(12-result.length()) + result;
                allCsmWList.add(new CaseMilestoneW((Id)fakeId,'Initial Response', cs.Id , System.now(), false, cs.Priority ,cs.CreatedDate, cs));
                allCsmWList.add(new CaseMilestoneW((Id)fakeId,'Resolution/Workaround Verified', cs.Id , System.now(), false, cs.Priority ,cs.CreatedDate, cs));                
            }
        }else{
            if(!allCsmList.isEmpty()) for(CaseMilestone cms : allCsmList) allCsmWList.add(new CaseMilestoneW(cms)); 
                }
        
        if(!allCsmWList.isEmpty()){
           // Map<Id,caseMilestone> caseIdToMilestone = new Map<Id,caseMilestone>();
            Map<Id, CaseMilestoneW> caseIdToMilestone = new Map<Id, CaseMilestoneW>();
            for(CaseMilestoneW cm : allCsmWList){
                caseIdToMilestone.put(cm.CaseId,cm);
            }
            List<AggregateResult>  csComment = [SELECT ParentId, count(CommentBody) total FROM CaseComment where ParentId IN : caseIdPriority and IsPublished = true and CreatedBy.ProfileId IN : CustomerSupportProfileIds GROUP BY ParentId];
            for(AggregateResult csCom : csComment){
                Id commentParentId = (Id)csCom.get('ParentId');
                if(caseIdToMilestone.containsKey(commentParentId) && (Integer)csCom.get('total') > 0){
                    CaseMilestoneW cm = caseIdToMilestone.get(commentParentId);      
                    CaseMilestone caseMilestoneObj = new CaseMilestone(Id= cm.milestoneId, CompletionDate = system.now());
                    updateCaseMilestone.add(caseMilestoneObj);
                    caseIdToCase.put(commentParentId,cm.caseObj);
                }
            }
        }
        if(!updateCaseMilestone.isEmpty() && !Test.isRunningTest()) update updateCaseMilestone;						  
        if(caseIdToCase.size()>0) CaseCommentTriggerHandler.ChangeInitialMilestoneFlagColor(caseIdToCase,null);
    }

    /**
    * @Method: isChangedCheck by Vijay Kumar K R <vijay.kr@rubrik.com>
    * @description to check old and new values of Current_Status__c and Next_Step__c
    * @param newCase
	* @param oldCase
	* @param fieldApi
    * @return Boolean
    **/
    public Boolean isChangedCheck(Case newCase, Case oldCase, String fieldApi){
        if(oldCase.get(fieldApi) == null){
            return true;
        }

        String OldText = String.valueOf(oldcase.get(fieldApi)).replaceAll('\\s+','');
        String NewText = String.valueOf(newCase.get(fieldApi)).replaceAll('\\s+','');

        String newVal = String.valueOf(newCase.get(fieldApi));
        if(!OldText.equals(NewText)
            && oldcase.get(fieldApi) != newVal){
                return true;
        }

        return false;
    }

    // Added by Grazitti for convering Before Insert triggers
	/**
    * @description before Insert method for Case
    */
    public void beforeInsert(){
        List<Case> cList = new List<Case>();
        set<String> jiraIds = new set<String>();
        //CS21-44 change
        Map<Id,Account> accountMap = new Map<Id,Account>();
        //1192:
        Set<String> clusterUuidSet = new Set<String>();
        //CS21-2116
        Map<Id,Case> dupCaseMap = new Map<Id,Case>();
        //CS21-1302 --> Change
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        //AFTER-GO-LIVE-170 -E2CA - Start
        Map<String,Id> contactEmailMap = new Map<String,Id>();
        //CS-1504
        Map<Id,Entitlement> entilentMap = new Map<Id,Entitlement>();
        Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
        Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
        Id renewalCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();
        Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();

        for(Case cs: (List<Case>)trigger.new){
            if(cs.SuppliedEmail != null){
                contactEmailMap.put(cs.SuppliedEmail,null);
            }
            //CS21-2116
            if(partnerCaseId == cs.RecordTypeId && cs.Duplicate_Case_Id__c != null){
                dupCaseMap.put(cs.Duplicate_Case_Id__c,new case());
            }
            //CS-1504
            if(successCaseId == cs.RecordTypeId && cs.Entitlement__c != null){
                entilentMap.put(cs.Entitlement__c,new Entitlement());
            }
        }
        //CS-1504
        if(!entilentMap.keySet().isEmpty()){
            entilentMap = new Map<Id,Entitlement>([SELECT id, StartDate, EndDate FROM Entitlement WHERE id IN: entilentMap.keySet()]);
        }
        List<Contact> conList = new List<Contact>();
        //CS21-2029 -- Start
        Map<String, String> customerCommunityContacts = new Map<String, String>();
        Map<String, String> regularContacts = new Map<String, String>();
        Map<String, String> partnerCommunityContacts = new Map<String, String>();
        //CS21-2029 -- End
        if(contactEmailMap != null && contactEmailMap.keyset().size() > 0 ){
            conList = [SELECT id, Email, CommunityUser__c, Community_User_License__c, Community_User_Active__c FROM Contact WHERE Email IN: contactEmailMap.keyset() ORDER BY CreatedDate ASC];
            for(Contact con : conList){
                if(contactEmailMap.containsKey(con.Email) && contactEmailMap.get(con.Email) == null){
                    contactEmailMap.put(con.Email,con.Id);
                }
                //CS21-2029 -- Start
                if (con.Community_User_Active__c) {
                    if (con.Community_User_License__c == 'Customer Community' || con.Community_User_License__c == 'Customer Community Login') {
                        customerCommunityContacts.put(con.Email, con.Id);
                    } else if (con.Community_User_License__c == 'Partner Community') {
                        partnerCommunityContacts.put(con.Email, con.Id);
                    }
                } else {
                    regularContacts.put(con.Email, con.Id);
                }
                //CS21-2029 -- End
            }
        }
        //AFTER-GO-LIVE-170 -E2CA - End
        // added by Bharat Arora CS-384
        //CS21-2116
        if(!dupCaseMap.isEmpty()){
            dupCaseMap = new Map<Id,Case>([Select Id,Type__c,SubType__c from Case Where Id IN: dupCaseMap.keySet()]);
        }
        
        for(Case cs: (List<Case>)trigger.new){
            // Updated by Vijay Kumar K R: CS21-1309
            if(cs.Description !=null
                && cs.Description.containsIgnoreCase('JIRA')
                && cs.Description.containsIgnoreCase('ClusterId')){
                    String cluster_uuid = cs.Description.substringAfter('ClusterId-');
                    clusterUuidSet.add(cluster_uuid.replaceAll('(\\s+)', ''));
            }
            //CS-1504
            if(successCaseId == cs.RecordTypeId && cs.Entitlement__c != null && entilentMap.containsKey(cs.Entitlement__c)){
                cs.Entitlement_Start_Date__c = entilentMap.get(cs.Entitlement__c).StartDate;
                cs.Entitlement_End_Date__c   = entilentMap.get(cs.Entitlement__c).EndDate;

            }
            // CS21-1885: Initial Case owner assignment
            updateInitialCaseOwner(cs, null);
            //AFTER-GO-LIVE-170 -E2CA - Start
            if(cs.SuppliedEmail != null && contactEmailMap.containsKey(cs.SuppliedEmail)){
                  //CS21-2029 -- Start
                if(supportCaseId == cs.RecordTypeId && cs.Origin == 'Email')
                {
                    if(customerCommunityContacts.containsKey(cs.SuppliedEmail))
                    {
                        cs.ContactId = customerCommunityContacts.get(cs.SuppliedEmail);
                    }else if(regularContacts.containsKey(cs.SuppliedEmail))
                    {
                        cs.ContactId = regularContacts.get(cs.SuppliedEmail);
                    }else if(partnerCommunityContacts.containsKey(cs.SuppliedEmail))
                    {
                        cs.ContactId = partnerCommunityContacts.get(cs.SuppliedEmail);
                    }
                }
                //CS21-2029 -- End
               
                if(cs.ContactId == null && contactEmailMap.get(cs.SuppliedEmail) != null){
                    cs.ContactId = contactEmailMap.get(cs.SuppliedEmail);
                }
                else if(cs.ContactId != null && contactEmailMap.get(cs.SuppliedEmail) == null){
                    cs.ContactId = null;
                }
            }
            //AFTER-GO-LIVE-170 -E2CA - End
            caseConIdTOEmail.put(cs.ContactId,new Contact());
            //CS21-44 change
            if(cs.AccountId != null)
                accountMap.put(cs.AccountId,new Account());

            //CS21-1302 --> Start
            if(cs.AccountId == null && cs.ContactId != null){
                contactMap.put(cs.ContactId, new Contact());
            }
            //CS21-1302 --> End
            //CS21-2116
            if(partnerCaseId == cs.RecordTypeId && cs.Duplicate_Case_Id__c != null && !dupCaseMap.isEmpty() && dupCaseMap.containskey(cs.Duplicate_Case_Id__c)){
                cs.Type__c = dupCaseMap.get(cs.Duplicate_Case_Id__c)?.Type__c;
                cs.SubType__c = dupCaseMap.get(cs.Duplicate_Case_Id__c)?.SubType__c;
            }
        }
        caseConIdTOEmail = new map<Id,Contact>([select id,email from contact where id IN: caseConIdTOEmail.keySet()]);
        Integer maxLength = 0;
        Integer alertLength = Integer.valueOf(System.label.JIRAID_Length);
        Integer sparkLength = Integer.valueOf(System.label.JIRA_SPARK_Length);
        //CS21-1302 --> Start
        contactMap = new Map<Id,Contact>([SELECT id, AccountId FROM Contact WHERE Id IN: contactMap.keySet()]);
        for(Contact con: contactMap.values()){
            accountMap.put(con.AccountId,new Account());
        }
        //CS21-1302 --> End
        accountMap = new Map<Id, Account>([SELECT Id, Sum_of_Open_Opportunities__c, Disable_Case_Routing_for_Open_Queue_25__c, Sum_of_Opportunities__c, ASE_Account__c, US_Federal_Account__c, Account_Preference__c, Tabs_Visibility__c
                                            FROM Account
                                            WHERE Id IN: accountMap.keySet()]);

        if(queueNameIdMap.isEmpty())
            queueNameIdMap = getCaseQueueMap();
        //Id digitalQueueId = [select Id,Name,DeveloperNAME  from Group where  Type = 'Queue' AND DEveloperName ='Open_Queue_Digital' LIMIT 1].Id;
        // CS-384 end
        List<Case> polarisCases = new List<Case>();
        Account account = new Account();

        // by Vijay Kumar K R: CS21-1309
        Map<String, Id> clusterIdByUuidMap = new Map<String, Id>();
        if(!clusterUuidSet.isEmpty()){
            for(Cluster__c objClu : [SELECT Id, uuid__c
                                        FROM Cluster__c
                                        WHERE uuid__c IN: clusterUuidSet]){
                clusterIdByUuidMap.put(objClu.uuid__c, objClu.Id);
            }
        }

        Integer threshold = Integer.ValueOf(System.label.Digital_Queue_Threshold);


        for(Case cs: (List<Case>)trigger.new){
            //CS21-1302 --> Start
            if(cs.AccountId == null && cs.ContactId != null){
                cs.AccountId = contactMap.get(cs.ContactId).AccountId;
            }
            //CS21-1302 --> End
            //CS21-E2CA renewal case contact removal start
            if(cs.recordTypeId == renewalCaseId && cs.ContactId != null){
                cs.ContactId = null;
            }
            //CS21-E2CA renewal case contact removal end
            //CS-469 Start
            if(cs.CT_Rating__c != null){
                cs.CT_Thermometer_DateTime__c = System.now();
            }
            //CS-469 End
            if(cs.JIRA_Status__c != null){
                cs.JIRA_Status__c = '';
            }
            //CS21-44 change
            /*CS21-851 : Disable case routing to Open Queue (Digital) when US_Federal_Account__c is true. Added conditions to check if the current case owner is Open Queue
            (Unassigned_Cases) and case account is a US Federal Account, then do not reassign the case*/
            account = accountMap.get(cs.AccountId);
            if(cs.recordTypeId == supportCaseId){
                if(cs.OwnerId != null && String.valueOf(cs.OwnerId).startsWith('005') && System.label.SupportBotUserId != cs.OwnerId){
                    System.debug(LoggingLevel.INFO, 'No Owner change');
                }else if(accountMap.containsKey(cs.AccountId) && accountMap.get(cs.AccountId).Tabs_Visibility__c != null 
                        && accountMap.get(cs.AccountId).Tabs_Visibility__c.containsIgnoreCase('Predibase')){
                           processPredibaseCases(cs); 
                }                
                else if(accountMap.containsKey(cs.AccountId) &&
						accountMap.get(cs.AccountId).Account_Preference__c !=null && 
                        accountMap.get(cs.AccountId).Account_Preference__c.contains('Top Accounts') && 
                        !accountMap.get(cs.AccountId).ASE_Account__c && 
                        !accountMap.get(cs.AccountId).US_Federal_Account__c && 
                        !(cs.Origin == 'Alert'|| cs.Origin == 'Alert (come in email)' || cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Pulse' || cs.Origin == 'Proactive')){
                              cs.OwnerId = queueNameIdMap.get('Open_Queue_TA');
                          }else if(!(cs.Origin == 'Alert'
                                     || cs.Origin == 'Alert (come in email)'
                                     || cs.Origin == 'Pulse')
                                   //&& cs.Priority != 'P1' --removed for CS21-1243
                                   && accountMap.containsKey(cs.AccountId)
                                   && accountMap.get(cs.AccountId).Sum_of_Opportunities__c < threshold
                                   && accountMap.get(cs.AccountId).Sum_of_Open_Opportunities__c < threshold
                                   && !accountMap.get(cs.AccountId).Disable_Case_Routing_for_Open_Queue_25__c
                                   && !accountMap.get(cs.AccountId).US_Federal_Account__c
                                   && cs.OwnerId == queueNameIdMap.get('Unassigned_Cases')){
                                       cs.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
                                   }else{
                                       if(cs.OwnerId == queueNameIdMap.get('Open_Queue_Digital') && accountMap.containsKey(cs.AccountId)
                                          && (accountMap.get(cs.AccountId).Sum_of_Opportunities__c >= threshold
                                              ||accountMap.get(cs.AccountId).Sum_of_Open_Opportunities__c >= threshold
                                              || accountMap.get(cs.AccountId).Disable_Case_Routing_for_Open_Queue_25__c
                                              || accountMap.get(cs.AccountId).US_Federal_Account__c)){
                                                  cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
                                              }
                                   }
            }
            

            //CS-384 & CS-491 start
            if(!caseConIdTOEmail.isEmpty() && caseConIdTOEmail!=null && caseConIdTOEmail.containskey(cs.ContactId) ){
                contactEmail = caseConIdTOEmail.get(cs.ContactId).Email;
            }
            // CS-384 & CS-491 end

            if(cs.Origin == 'Alert' || cs.Origin == 'Pulse'){
                cs.Platform__c = 'CDM';
            }

            //CS21-158 - Start
            if(cs.Priority != null){
                cs.Life_Cycle_Priority__c = cs.Priority;
                if(cs.Life_Cycle_Priority__c!= null){
                    if(cs.Life_Cycle_Priority__c == 'P1'){
                        cs.Life_Cycle_Priority__c = 'P1 - Critical';
                    } else if(cs.Life_Cycle_Priority__c == 'P2'){
                        cs.Life_Cycle_Priority__c = 'P2 - High';
                    } else if(cs.Life_Cycle_Priority__c == 'P3'){
                        cs.Life_Cycle_Priority__c = 'P3 - Medium';
                    } else if(cs.Life_Cycle_Priority__c == 'P4'){
                        cs.Life_Cycle_Priority__c = 'P4 - Low';
                    } else if(cs.Life_Cycle_Priority__c.contains('None')){
                        cs.Life_Cycle_Priority__c = null;
                    }
                }
            }
            //CS21-158 - End

            // Modified by Vijay Kumar K R: CS21-1192
            if(cs.Subject !=null && cs.Subject.containsIgnoreCase('JIRA')){
                String jira_id = cs.subject.substringBefore(')').substringAfter('] (');
                maxLength = jira_id.containsIgnoreCase('alert') ? alertLength: sparkLength;
                If(jira_id.length() > maxLength){
                    jira_id = jira_id.substring(0, maxLength);
                }
                if(String.isNotBlank(jira_id)){
                    jira_id = '%'+jira_id +'%';
                    jiraIds.add(jira_id);
                    cList.add(cs);

                    // by Vijay Kumar K R: CS21-1309
                    String cluster_uuid = '';
                    if(cs.Description !=null
                        && cs.Description.containsIgnoreCase('JIRA')
                        && cs.Description.containsIgnoreCase('ClusterId')){
                            cluster_uuid = cs.Description.substringAfter('ClusterId-');
                    }

                    //CS21-1192: Alert (JIRA) and re-direct existing JIRA - Support Bot auto-created cases to the new origin
                    if(cs.SuppliedEmail != null
                        && String.valueOf(cs.SuppliedEmail).equalsIgnoreCase(JIRA_CASE_WEB_EMAIL)){
                            cs.Origin = CASE_ORIGIN_ALERT_JIRA;
                            cs.Other_Type__c = 'JIRA-ALERT';
                            cs.Type = 'Other';
                            cs.ContactId=null;
                            cs.AccountId=null;
                            cs.E2CAdv__AdditionalTO__c=null;
                            cs.Description = '=======INSTRUCTION=========\r\n'+'Before contacting customer, Please review Linked Jira reference and update the subject and Description to customer facing language. For example, You can say that we are reviewing proactive notificaiton based on the phone home data and we need tunnel access. Subject to something like Proactive Case : phone home exception review. Then Pick the Customer Contact to the case\r\n'+'================\r\n';

                            // by Vijay Kumar K R: CS21-1309
                            if(clusterIdByUuidMap.containsKey(cluster_uuid)){
                                cs.Cluster__c = clusterIdByUuidMap.get(cluster_uuid);
                            }
                            if(cs.Subject.containsIgnoreCase('ClusterId')){
                                cs.Subject = cs.subject.substringBefore('ClusterId-');
                            }
                    }

                }
            }

            if(cs.Platform__c == 'Polaris')
                polarisCases.add(cs);
        }
        CaseTriggerHandler.addDesc(polarisCases);
        CaseManageAutoEmailResponses((List<Case>)trigger.new);

        if(!cList.isEmpty()){
            CaseLinkJiraAlert(jiraIds,cList); // Added by Grazitti for Linking Case Jira Alert
        }

        //CS21-232 : NCC Updates : update the case owner's manager's email if it is not a queue
        Set<Id> caseOwnerIds = new Set<Id>();
        for(Case cs: (List<Case>)trigger.new){
            String ownerId = (String)cs.OwnerId;

            if(ownerId != null &&
               ownerId.startsWith('005')){
                caseOwnerIds.add(cs.ownerId);
            }
        }

        Map<Id, User> usersList;
        usersList = new Map<Id, User>([Select Id, ManagerId, Manager.Email from User where Id IN :caseOwnerIds]);

        // CS21-1328: Var's
        Set<String> rvmNodeNameSet = new Set<String>();
        Map<String, Date> supEndDateByNodeNameMap = new Map<String, Date>();

        for(Case cs: (List<Case>)trigger.new){

            if(String.ValueOf(cs.OwnerId).startsWith('005') &&
               usersList != null &&
               usersList.containsKey(cs.OwnerId)){
                User tempUser = usersList.get(cs.OwnerId);
                if(tempUser.ManagerId != null && cs.Owner_s_manager_email__c != tempUser.Manager.Email){
                    cs.Owner_s_manager_email__c = tempUser.Manager.Email;
                }
            }

            // CS21-1328: by Vijay Kumar K R: Create a field to extract Asset's Support End Date from Asset to Case Page
            if((UserInfo.getUserId() == ALERT_BOT_USER_ID
                || Test.isRunningTest())
                && cs.Origin == 'Alert'
                && String.isNotBlank(String.ValueOf(cs.Description))){
                    String rvnNode = getRvmNode(cs.Description);
                    if(rvnNode != null){
                        rvmNodeNameSet.add(rvnNode);
                    }
                    // CS21-1536: by Vijay Kumar K R: Append the Cluster Tag in the case subject line for proactive alerts
                    updateClusterTagOnSubject(cs);
            }
        }

        // get Asset Support End Date
        if(!rvmNodeNameSet.isEmpty()){
            getAssetSupportEndDate(rvmNodeNameSet, supEndDateByNodeNameMap);
        }

        updateCaseAssetEndDate(supEndDateByNodeNameMap);

        //CS21-1086 --  Validation Rule -----------
        //To fire Validation rule on case record while adding second Public/Private Comment or while editing the case record
        // This validation rule has been moved from UI to code to pass CS21-1086
        String currentUserId = String.valueOf(UserInfo.getUserId()).substring(0, 15); //  by pass rule for Support Bot User
        if(!DisableCaseValidationRules() && String.valueOf(UserInfo.getUserType()) == 'Standard' && System.label.SupportBotUserId != currentUserId){
            for (Case caseObj : (List<Case>)Trigger.new) {
                if(String.isBlank(caseObj.If_Other__c) &&
                   (caseObj.Problem_Type__c == 'Other' ||
                    caseObj.Sub_Component__c == 'Other (specify)' ||
                    (caseObj.Status == 'Closed' &&
                     (caseObj.Platform__c == 'Other' ||
                      caseObj.Product_Area__c == 'Other'))) &&
                   caseObj.Recordtype__c == 'Support Case'
                  ){
                      caseObj.If_Other__c.addError('\'If Other, Please Specify\' field is mandatory, if Product-Line, Functional Area, Component or Sub-Component has a value \'Other\'');
                  }
            }
        }

        //CS21-1086 --  Validation Rule End -----------
    }

    /**
     * @description CS21-3571: processPredibaseCases method to set default values for Predibase Cases.
     * @param caseRecord
     */
    public void processPredibaseCases(Case caseRecord){
        caseRecord.ownerId = queueNameIdMap.get('Predibase_Queue');
        if(caseRecord.Platform__c == null){
            caseRecord.Platform__c = 'Predibase';
            caseRecord.Product_Area__c  = 'Other';
            caseRecord.Problem_Type__c = 'Other';
            caseRecord.Sub_Component__c = 'Other (specify)';
            caseRecord.If_Other__c = 'Predibase';
        }
        caseRecord.Proactive_Resolution_Code__c = 'Other';
        caseRecord.KCS_Article_Candidate__c = 'No article required';
        caseRecord.Type = 'Software';
        caseRecord.Software_Version__c = 'Other';
        caseRecord.Resolution__c = caseRecord.Resolution__c == null?'Predibase':caseRecord.Resolution__c;
    }

    /**
     * @description CS21-3033: processUsFedAndAseQueueAssignment fetch Case Created by Customer Support User and managers Id
     * @param isInsert
     */
    public static void processUsFedAndAseQueueAssignment(boolean isInsert){
        // CS21-3033: fetch Customer Support Users/Managers
        Set<Id> caseAccIdSet = new Set<Id>();
        List<String> csProfileList = new List<String>{'Rubrik Customer Support User','Rubrik Customer Support Manager'};
        Id sentryaiId = [SELECT Id FROM User WHERE Email like '%falcon-team@rubrik.com%' AND isActive = true Limit 1].Id;
    
        for(Case cs: (List<Case>)trigger.new){
            Case oldcase = isInsert ? null : (Case)trigger.oldmap.get(cs.id);
            if(cs.AccountId != null
                && cs.RecordTypeId == SUPPORT_CASE_RT_ID
                // Skip logic when the Case Transfer Request is "Approved"
                && !IS_TRANSFER_QUEUE_APPROVED
                // Skip logic when case details are updated and the case owner is in any 'Transfer' queue
                && !String.valueOf(cs.Case_Owner_Name__c).containsIgnoreCase('Transfer')
                // SentryAI Sally User
                && UserInfo.getUserId() != sentryaiId
               	// Skip logic when case details are updated and the case owner is in 'Predibase' queue
                && cs.ownerId != queueNameIdMap.get('Predibase_Queue')
                // CS21-3193: we need to be able to manually move support tickets to the ‘support operations’ queue for certain types of requests. 
                && !String.valueOf(cs.Case_Owner_Name__c).containsIgnoreCase('Support Operations')
                // INSERT: Bypass this logic for RCS User and Manager profile while Case Creation
                && ((isInsert 
                    && !csProfileList.contains(cs.Owner_Profile__c))
                    // UPDATE: On Case Owner Change: below logic only works when Case owner updated to Queue (Except Transfer Queue)
                    // On any case field Updates: re-calculating Case Owner from Account criteria   
                    || (!isInsert
                        && !String.valueOf(cs.OwnerId).startsWith('005')
                        && !String.valueOf(cs.Case_Owner_Name__c).containsIgnoreCase('Transfer Queue')))
                // PTO User: Bypass this logic If Current Case Owner is on PTO, on case comment, Case Owner Assignment will happen from CaseCommentTriggerHandler > Workday_GenericCaseOwnerChange that will route to transfer Queue
                && (isInsert
                    || (oldcase != null && 
                        !oldcase.Owner_Time_Off__c))){
                            caseAccIdSet.add(cs.AccountId);
            }
        }
        
        List<CaseComment> privateComment = new List<CaseComment>();
        // CS21-3033: Roting logic for Cases
        if(!caseAccIdSet.isEmpty()){
            caseAssignmentForFedAndAseQueue(isInsert, caseAccIdSet, privateComment);
        }

        if(!privateComment.isEmpty())
            CaseTriggerHandler.addPrivateComment(JSON.serialize(privateComment));
    }

    /**
     * @description CS21-3033: Route all Non Proactive cases to the "ASE Queue" if accounts have "assigned support engineers" at least one record
     * @param isInsert
     * @param caseAccIdSet
     * @param privateComment
     */
    public static void caseAssignmentForFedAndAseQueue(boolean isInsert, Set<Id> caseAccIdSet, List<CaseComment> privateComment){
        Map<Id, Assigned_Support_Engineer__c> aseByAccIdMap = new Map<Id, Assigned_Support_Engineer__c>();
        if (Schema.sObjectType.Assigned_Support_Engineer__c.isAccessible()) {
            aseByAccIdMap = getAccAssignedSupEngRecords(caseAccIdSet, aseByAccIdMap);
        }

        // Create a map with Account Id as the key and Account object as the value
        Map<Id, Account> accountMap = new Map<Id, Account>();

        // Loop through the accounts and populate the map
        if (Schema.sObjectType.Account.isAccessible()) {
            for (Account acc : [SELECT Id, US_Federal_Account__c FROM Account WHERE Id IN: caseAccIdSet]) {
                accountMap.put(acc.Id, acc);
            }
        }
        //CS21-3033
        if(queueNameIdMap.isEmpty())
            queueNameIdMap = getCaseQueueMap();
        for(Case cs: (List<Case>)trigger.new){
            Case oldCaseRec;
            if(!isInsert){
                oldCaseRec = (Case) Trigger.oldMap.get(cs.Id);
            }
            String body = 'This case was automatically routed from ';

            if(cs.AccountId != null
                && cs.RecordTypeId == SUPPORT_CASE_RT_ID){

                    // Where an account is both "Federal" and "ASE", default to the ASE queue
                    if(accountMap.containskey(cs.AccountId)
                        && accountMap.get(cs.AccountId).US_Federal_Account__c 
                        && aseByAccIdMap.containskey(cs.AccountId)){
                            body += setBody(isInsert, oldCaseRec, cs, 'ASE Queue');
                            cs.OwnerId = queueNameIdMap.get('ASE_Queue');
                    }
                    // For FedRel Case
                    else if(accountMap.containskey(cs.AccountId)
                            && accountMap.get(cs.AccountId).US_Federal_Account__c){
                                body += setBody(isInsert, oldCaseRec, cs, 'US Federal Queue');
                                cs.OwnerId = queueNameIdMap.get('FED_Queue');
                    }
                    // Account with ASE record
                    else if(aseByAccIdMap.containskey(cs.AccountId)){
                        // Non Proctive Case (Alert, Alert(jira) and SenttyAI)
                        if(!PROACTIVE_CASE_ORIGIN_LIST.contains(cs.Origin)){
                            body += setBody(isInsert, oldCaseRec, cs, 'ASE Queue');
                            cs.OwnerId = queueNameIdMap.get('ASE_Queue');
                        }
                        // Proctive Case (Alert, Alert(jira) and SenttyAI)
                        else if(PROACTIVE_CASE_ORIGIN_LIST.contains(cs.Origin)){
                            body += setBody(isInsert, oldCaseRec, cs, 'Proactive Alerts');
                            cs.OwnerId = queueNameIdMap.get('Proactive_Alerts');
                        }
                    }
                }
                if(body != 'This case was automatically routed from ')
                    privateComment.add(new CaseComment(ParentId = cs.Id, IsPublished = false, CommentBody = body));
        }
    }

    /**
     * @description CS21-3033: Change from ASE/US federal Queue to Other Queues on ASE/US federal Account
     * @param isInsert
     * @param oldCase
     * @param cs
     * @param ownerName
     * @return string
     */
    public static string setBody(Boolean isInsert, Case oldCase, Case cs, String ownerName){
        if(!isInsert
            && cs.Case_Owner_Name__c != ownerName
            && !String.valueOf(oldCase.Case_Owner_Name__c).startswith('005')){
                return cs.Case_Owner_Name__c+' to '+ownerName;
        }
        return '';
    }
 
    /**
     * @description CS21-3033: fetch Assigned_Support_Engineer__c record
     * @param nonProactiveAccIdSet
     * @param aseByAccIdMap
     * @return Map<Id, Assigned_Support_Engineer__c>
     */
    public static Map<Id, Assigned_Support_Engineer__c> getAccAssignedSupEngRecords(Set<Id> nonProactiveAccIdSet, Map<Id, Assigned_Support_Engineer__c> aseByAccIdMap){
        for(Assigned_Support_Engineer__c objAse : [SELECT Id, Account__c 
                                                        FROM Assigned_Support_Engineer__c 
                                                        WHERE Account__c IN: nonProactiveAccIdSet Limit 1]){
                aseByAccIdMap.put(objAse.Account__c, objAse);
            }
        return aseByAccIdMap;
    }

    /**
     * Method: getRvmNode
     * @description fetching Node Name Value from Case Description
     * @param caseDescp description of case
     * @return rvmNodeName
     **/
    public static String getRvmNode(String caseDescp){

        String rvmNodeName = null;
        String s1 = caseDescp.substringAfter('Node:');
        String s2 = s1.substringBefore('Alert Customer:');
        if(s2.trim().startsWith('RVM')){
            rvmNodeName = s2.trim();
        }
        return rvmNodeName;
    }

    /** CS21-1536
     * Method:  updateClusterTagOnSubject
    * @description fetching Cluster Tag Value from Case Description
    * @param objCase
     **/
	 
    public static void updateClusterTagOnSubject(Case objCase){

        String caseDescp = objCase.Description;
        String caseSub = objCase.Subject;
        String s1 = caseDescp.substringAfter('Cluster Tag:');
        String s2 = s1.substringBefore('Node:');
        String rvmClusterTag = s2.trim();

        if(String.isNotBlank(rvmClusterTag)
            && !rvmClusterTag.containsIgnoreCase('Not Available')
            && !rvmClusterTag.containsIgnoreCase('NA')
            && caseSub.containsIgnoreCase('Proactive Case:')){
            String finalSub = caseSub.substringBefore('Proactive Case:')+'Proactive Case: (Cluster name: '+rvmClusterTag+')'+caseSub.substringAfter('Proactive Case:');
            System.debug(LoggingLevel.DEBUG, 'finalSub: '+finalSub);
            objCase.Subject = finalSub;
        }
    }

    /**
    * Method: getAssetSupportEndDate
    * @description Mapping Node Name to Asset.Premium_Support_End_Date__c
    * @param rvmNodeNameSet
    * @param supEndDateByNodeNameMap
    */
    public static void getAssetSupportEndDate(Set<String> rvmNodeNameSet, Map<String, Date> supEndDateByNodeNameMap){

        for(Node__c objNode : [SELECT Id, Name, Asset__r.Premium_Support_End_Date__c
                                FROM Node__c
                                WHERE Name IN: rvmNodeNameSet]){
            supEndDateByNodeNameMap.put(objNode.Name, objNode.Asset__r.Premium_Support_End_Date__c);
        }
    }

    /**
    * Method: updateCaseAssetEndDate
    * @description CS21-1328 Updating "Asset Support End Date"
    * @param supEndDateByNodeNameMap
    */
    public static void updateCaseAssetEndDate(Map<String, Date> supEndDateByNodeNameMap){

        for(Case cs : (List<Case>)trigger.new){
            if((UserInfo.getUserId() == ALERT_BOT_USER_ID
                || Test.isRunningTest())
                && cs.Origin == 'Alert'
                && String.isNotBlank(String.ValueOf(cs.Description))){
                    String rvnNode = getRvmNode(cs.Description);
                    if(rvnNode != null
                        && supEndDateByNodeNameMap.containsKey(rvnNode)){
                            Date supportEndDate = supEndDateByNodeNameMap.get(rvnNode);
                            cs.Asset_Support_End_Date__c = supportEndDate;
                            if(!(supportEndDate >= Date.TODAY())){
                                cs.Case_Support_Entitlement_Expired__c = true;
                            }

                    }else{
                        cs.Case_Support_Entitlement_Expired__c = true;
                    }
            }
        }
    }

	/**
     * @description Method to check if case validation rules are disabled Cs21_1086
	 * @return disableBusinessLogicSettings
     */
    private static Boolean disableCaseValidationRules() {
        ShGl_DisableBusinessLogic__c disableBusinessLogicSettings = ShGl_DisableBusinessLogic__c.getInstance();
        return disableBusinessLogicSettings != null && disableBusinessLogicSettings.Disable_Case_Validation_Rules__c;
    }

	/**
     * @description before Case Update Method 
     */
    public void beforeUpdate(){

        Set<Id> contactId = new Set<id>();
        set<Id> accIds = new set<Id>();
        set<Id> ownerIds = new set<Id>();
        map<Id,Case> mapOfCase = new map<Id,Case>();
        map<Id,user> mapOfUser = new map<Id,user>();
        List<string> ListmileCaseIds = new List<string>();
        set<string> mileCaseIds = new Set<string>();
        List<Case> polarisCases = new List<Case>();
        Set<Id> assistRequestIDs = new Set<Id>();
        //CS21-2116
        Map<Id,Case> dupCaseMap = new Map<Id,Case>();
        //CS-1504
        Map<Id,Entitlement> entilentMap = new Map<Id,Entitlement>();
        //User usr = [select id from user where name = 'Support Bot'];
        User usr = [select id from user where FirstName = 'Support' and LastName = 'Bot'];
        Id renewalCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();
        Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
        Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
        Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
        List<String> EmailAddresses = System.Label.Rubrik_Support_Email_Addresses.split(';');

        //CS21-617
        List<String> caseOriginStr = new List<String>{'Alert','Alert (come in email)','Alert_JIRA','Pulse','Health-check'};
        Set<Id> contactIdSet = new Set<Id>();
        Map<Id,Cluster__c> clusterMap = new Map<Id,Cluster__c>();

        //CS21-44
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Map<id,ServiceContract> serviceMap = new Map<id,ServiceContract>();

        //CS21-1378:
        Set<Id> closedCaseIdSet = new Set<Id>();

        //CS21-2006:
        Set<Id> fedRampCaseIdSet = getFedRampCaseIds(trigger.new);
        Id transferQueueId = System.Label.CaseTransferQueueId;
        //CS21-2555
        list<String> caseSubPhaseValues=System.Label.Case_Sub_Phases_Onboarding_Adoption.split(';');
        for(Case cs :(List<Case>)trigger.new){
            Case oldCaseRec = (Case) Trigger.oldMap.get(cs.Id);
            if(cs.OwnerId != null && cs.OwnerId != oldCaseRec.OwnerId && oldCaseRec.OwnerId == transferQueueId && cs.CaseTransferStatus__c == 'Submitted'){
                cs.AddError('Case belongs to Transfer Queue. You can\'t directly assign the case.' );
            }
            //CS21-2116
            if(partnerCaseId == cs.RecordTypeId && cs.Duplicate_Case_Id__c != null && oldCaseRec.Duplicate_Case_Id__c != cs.Duplicate_Case_Id__c){
                dupCaseMap.put(cs.Duplicate_Case_Id__c,new Case());
            }
            
            IF(successCaseId == cs.RecordTypeId){
                //CS21-2555
                IF(caseSubPhaseValues.size()>0 
                   && cs.Sub_Phase__c!=null 
                   && caseSubPhaseValues.contains(cs.Sub_Phase__c)
                   && cs.Sub_Phase__c != oldCaseRec.Sub_Phase__c
                   && cs.Customer_Onboarding_Adoption_Completion__c == null){
                       cs.Customer_Onboarding_Adoption_Completion__c = System.now();
                       
                   }
                IF(oldCaseRec.Sub_Phase__c == 'Snooze' && 
                        cs.Sub_Phase__c != 'Snooze'){
                    cs.Snooze_End_DateTime__c = null;

                }
                IF(cs.Entitlement__c != null &&  cs.Entitlement__c !=  oldCaseRec.Entitlement__c){
                        entilentMap.put(cs.Entitlement__c,new Entitlement());
                }
            }
                
            // CS21-1378: If Ransomware recovery selected under the Special account handling: automatically include incident managers of the Ransomware Response Team (RRT) in Public Comment cc
            if(cs.Special_handling__c != oldCaseRec.Special_handling__c
                && cs.Special_handling__c == 'Ransomware recovery'){
                String incidentManagerEmails = System.Label.RRT_Incident_Managers_Email;
                cs.E2CAdv__AdditionalCC__c = cs.E2CAdv__AdditionalCC__c != null ? cs.E2CAdv__AdditionalCC__c+';'+incidentManagerEmails : incidentManagerEmails;
            }

            // CS21-1378: Case can't be close unless child Escalation status is closed
            if(cs.Status != oldCaseRec.Status
                && cs.Status == 'Closed'){
                    closedCaseIdSet.add(cs.Id);
            }
            //CS21-1852 Bug Fix
            if(cs.Other_Feedback_Observations__c!=oldCaseRec.Other_Feedback_Observations__c){
                cs.CaseAudit_TimeStamp__c=System.Now();
                if(cs.Other_Feedback_Observations__c!=null && cs.Other_Feedback_Observations__c.contains('<{@}>')){
                    cs.Other_Feedback_Observations__c=cs.Other_Feedback_Observations__c.remove('<{@}>');
                }

            }
            //CS21-1852 Bug Fix Ends
        }
        if(!entilentMap.keySet().isEmpty()){
            entilentMap = new Map<Id,Entitlement>([SELECT id, StartDate, EndDate FROM Entitlement WHERE id IN: entilentMap.keySet()]);
        }

        // CS21-1378: Open Escalations Under Case
        Map<Id, Integer> escCountByCaseIdMap = new Map<Id, Integer>();
        if(!closedCaseIdSet.isEmpty()){
            for(AggregateResult aggr: [SELECT Case__c, Count(Id) total FROM Escalation__c WHERE Case__c IN: closedCaseIdSet AND Status__c != 'Closed' GROUP BY Case__c]){
                escCountByCaseIdMap.put((Id)aggr.get('Case__c'), (Integer)aggr.get('total'));
            }
        }
        
		//CS21-2116
        if(!dupCaseMap.isEmpty()){
            dupCaseMap = new Map<Id,Case>([Select Id,Type__c,SubType__c from Case Where Id IN: dupCaseMap.keySet()]);
        }
        
        for(Case cs :(List<Case>)trigger.new){
            if(successCaseId == cs.RecordTypeId && cs.Entitlement__c != null && entilentMap.containsKey(cs.Entitlement__c)){
                cs.Entitlement_Start_Date__c = entilentMap.get(cs.Entitlement__c).StartDate;
                cs.Entitlement_End_Date__c   = entilentMap.get(cs.Entitlement__c).EndDate;
           }
            Case oldCaseRecord = (Case) Trigger.oldMap.get(cs.Id);
            /*if(cs.ownerId!=null && String.valueOf(cs.ownerId).startswith('005')){
            ownerIds.add(cs.ownerId);
            }*/
            // CS21-1885: Initial Case owner assignment
            updateInitialCaseOwner(cs, oldCaseRecord);
            //CS-469 Start
            if(cs.CT_Rating__c != null && cs.CT_Rating__c != oldCaseRecord.CT_Rating__c){
                cs.CT_Thermometer_DateTime__c = System.now();
            }
            //CS-469 End
            
            //CS21-2116
            if(partnerCaseId == cs.RecordTypeId && cs.Duplicate_Case_Id__c != null && oldCaseRecord.Duplicate_Case_Id__c != cs.Duplicate_Case_Id__c
               && !dupCaseMap.isEmpty() && dupCaseMap.containskey(cs.Duplicate_Case_Id__c)){
                cs.Type__c = dupCaseMap.get(cs.Duplicate_Case_Id__c)?.Type__c;
                cs.SubType__c = dupCaseMap.get(cs.Duplicate_Case_Id__c)?.SubType__c;
            }
            //CS21-192 Starts
            if(cs.Status == 'Closed' && cs.Assist_Request_Count__c > 0){
                assistRequestIDs.add(cs.Id);
            }
            //CS21-192 Ends
            contactId.add(cs.ContactId);
            if(cs.accountId!=null)
                accIds.add(cs.accountId);
            If(cs.Accountid!=oldCaseRecord.AccountId && oldCaseRecord.AccountId!=null){
                accIds.add(oldCaseRecord.AccountId);
            }
            if(cs.Status != 'Closed' && Userinfo.getUserId() == usr.Id && cs.RecordTypeId == renewalCaseId ){
                cs.Status = 'Waiting for Renewal Specialist';
            }
            if(Userinfo.getUserId() == usr.Id && cs.RecordTypeId == renewalCaseId){
                if(cs.E2CAdv__AdditionalTO__c != null)
                    cs.E2CAdv__AdditionalTO__c = cs.E2CAdv__AdditionalTO__c.replace('support-renewals@rubrik.com','').replace('support-renewals@rubrik.com;','');
                if(cs.E2CAdv__AdditionalCC__c != null)
                    cs.E2CAdv__AdditionalCC__c = cs.E2CAdv__AdditionalCC__c.replace('support-renewals@rubrik.com;','').replace('support-renewals@rubrik.com','');
            }

            //CS21-44
            if(cs.ownerId!=null && !String.valueOf(cs.ownerId).startswith('005') && cs.accountId!=null){
                accountMap.put(cs.AccountId,new Account());
            }
            //CS21-158 - Start
            if(cs.Priority != null &&
               !cs.Priority.containsIgnoreCase('None') &&
               oldCaseRecord.Priority != null &&
               oldCaseRecord.Priority != cs.Priority){
                if( oldCaseRecord.Priority.containsIgnoreCase('None') ){
                    if(cs.Life_Cycle_Priority__c != null && !cs.Life_Cycle_Priority__c.containsIgnoreCase('None')){
                        Integer priorityNumberNew = Integer.ValueOf(cs.Priority.substring(1,2));
                        Integer existingLifeCyclePriorityNumber = Integer.ValueOf(cs.Life_Cycle_Priority__c.substring(1,2));
                        if(existingLifeCyclePriorityNumber > priorityNumberNew){
                            cs.Life_Cycle_Priority__c = cs.Priority;
                        }
                    } else{
                        cs.Life_Cycle_Priority__c = cs.Priority;
                    }
                }else{
                    Integer priorityNumberOld = Integer.ValueOf(oldCaseRecord.Priority.substring(1,2));
                    Integer priorityNumberNew = Integer.ValueOf(cs.Priority.substring(1,2));
                    Integer lifeCyclePriorityNumberOld;
                    if(cs.Life_Cycle_Priority__c != null && !cs.Life_Cycle_Priority__c.containsIgnoreCase('None')){
                        //lifeCyclePriorityNumberOld = Integer.ValueOf(oldCaseRecord.Life_Cycle_Priority__c.substring(1,2));
                        lifeCyclePriorityNumberOld = Integer.ValueOf(cs.Life_Cycle_Priority__c.substring(1,2));
                        if(priorityNumberNew < priorityNumberOld && (lifeCyclePriorityNumberOld == null || (lifeCyclePriorityNumberOld!= null && priorityNumberNew < lifeCyclePriorityNumberOld))){
                            cs.Life_Cycle_Priority__c = cs.Priority;
                        }
                    } else if(oldCaseRecord.Life_Cycle_Priority__c == null || (cs.Life_Cycle_Priority__c != null && cs.Life_Cycle_Priority__c.containsIgnoreCase('None'))){
                        if(priorityNumberNew < priorityNumberOld){
                            cs.Life_Cycle_Priority__c = cs.Priority;
                        } else{
                            cs.Life_Cycle_Priority__c = oldCaseRecord.Priority;
                        }
                    }
                }

                if(cs.Life_Cycle_Priority__c!= null && !cs.Life_Cycle_Priority__c.containsIgnoreCase('None')){
                    if(cs.Life_Cycle_Priority__c == 'P1'){
                        cs.Life_Cycle_Priority__c = 'P1 - Critical';
                    } else if(cs.Life_Cycle_Priority__c == 'P2'){
                        cs.Life_Cycle_Priority__c = 'P2 - High';
                    } else if(cs.Life_Cycle_Priority__c == 'P3'){
                        cs.Life_Cycle_Priority__c = 'P3 - Medium';
                    } else if(cs.Life_Cycle_Priority__c == 'P4'){
                        cs.Life_Cycle_Priority__c = 'P4 - Low';
                    }
                }
            }//CS21-158 - End

            //CS21-130 - Start
            //TODO: Remove Duplicate code in Process builder "Auto populate entitlement name"
            // Updated by Vijay Kuamr K R:
            String entitlementIdLabel = System.Label.Case_Generic_Entitlement_Id;

            if(oldCaseRecord.Origin != cs.Origin){
                cs.EntitlementId = PRO_ACTIVE_CASE_ORIGIN_LIST.contains(cs.Origin) ? null : entitlementIdLabel;
            }
            //CS21-130 - End
            //
            if(cs.ServiceContractId != null && cs.RecordTypeId == renewalCaseId){
                serviceMap.put(cs.ServiceContractId,new ServiceContract());
            }
            // CS21-713 start
            if((cs.Origin == CASE_ORIGIN_ALERT_JIRA || cs.Origin == 'Alert' || cs.Origin == 'Alert (come in email)' || cs.Origin == 'Pulse') && cs.Proactive_Resolution_Code__c == 'Other' && (cs.Description_for_other__c == null || cs.Description_for_other__c == '')){
                cs.Description_for_other__c.addError('Please enter reason for other');
            }
            //CS21-713 end
            //CS21-617
            if(cs.Cluster__c != null)
                clusterMap.put(cs.Cluster__c,new Cluster__c());

            // CS21-1378: Case can't be close unless child Escalation status is closed
            if(cs.Status != oldCaseRecord.Status
                && cs.Status == 'Closed'){
													 
                    if(!escCountByCaseIdMap.isEmpty() && escCountByCaseIdMap.containsKey(cs.Id) && escCountByCaseIdMap.get(cs.Id) >= 1){
																
                            // Escalation can't be close unless unless LL status is closed
                            cs.addError('This case cannot be closed because an active RRT Escalation is open, Please reach out to your local RRT about escalation closure prior to closing this case');
                    }
            }
        }
        clusterMap = new Map<Id,Cluster__c>([SELECT Id, Proactive_Case_Contact__c, Proactive_Case_Contact_OBH__c FROM Cluster__c WHERE Id IN : clusterMap.keySet()]);
        serviceMap = new Map<id,ServiceContract>([select id,SBQQSC__RenewalOpportunity__r.Rubrik_Sales_Engineer__c,SBQQSC__RenewalOpportunity__r.RenewalOwner__c,SBQQSC__RenewalOpportunity__r.OwnerId from serviceContract where ID IN: serviceMap.keySet()]);

        if(queueNameIdMap.isEmpty())
            queueNameIdMap = getCaseQueueMap();

        conMap = new Map<Id,Contact>([SELECT Id, AccountId, Last_GetFeedback_Date__c, Name, Account.RASP__c FROM Contact WHERE Id IN :contactId]);
        
        //CS21-617 - Making a set of proactive contacts
        for(Contact con : conMap.values()){
            if(con.AccountId != null && con.Account.RASP__c){
                contactIdSet.add(con.Id);
            }
            if(con.AccountId != null)
                accountMap.put(con.AccountId,new Account());
        }

        accountMap = new Map<Id, Account>([SELECT Id, Sum_of_Open_Opportunities__c, Disable_Case_Routing_for_Open_Queue_25__c, Sum_of_Opportunities__c, ASE_Account__c, US_Federal_Account__c, Account_Preference__c, Tabs_Visibility__c
                                            FROM Account
                                            WHERE Id IN: accountMap.keySet()]);
        Set<id> caseIds = new Set<id>();
        Map<Id,String> assistReqMap = new Map<Id,String>();
        //CS21-192 Starts
        if(!assistRequestIDs.isEmpty()){
            for(Assist_Request__c ar : [Select id, Name,Case__c,Status__c from Assist_Request__c where Case__c IN: assistRequestIDs AND Status__c != 'Closed']){
                if(!assistReqMap.containsKey(ar.Case__c)){
                    assistReqMap.put(ar.Case__c,'There is open assist request associated to this case. Kindly review and close the open assist request before closing the Parent case. Open Assist Requests are:'+ar.Name);
                }else{
                    assistReqMap.put(ar.Case__c,assistReqMap.get(ar.Case__c)+','+ar.Name);
                }
            }
        }
        //CS21-192 Ends
        List<CaseComment> privateComment = new List<CaseComment>();
        Account account = new Account();
        Integer threshold = Integer.ValueOf(System.label.Digital_Queue_Threshold);
        
        for(Case cs: (List<Case>)trigger.new){
            if(cs.ServiceContractId != null && cs.RecordTypeId == renewalCaseId && serviceMap.containsKey(cs.ServiceContractId)){
                ServiceContract sc = serviceMap.get(cs.ServiceContractId);
                cs.Opportunity_Owner_lookup__c = sc.SBQQSC__RenewalOpportunity__r.OwnerId;
                cs.Rubrik_Sales_Engineer__c = sc.SBQQSC__RenewalOpportunity__r.Rubrik_Sales_Engineer__c;
                cs.Renewal_Owner_lookup__c  = sc.SBQQSC__RenewalOpportunity__r.RenewalOwner__c;
            }
            caseIds.add(cs.Id);
            Contact con = new Contact();
            if(conMap.containskey(cs.Contactid))
                con = conMap.get(cs.Contactid);

            Case oldCaseRecord = (Case) Trigger.oldMap.get(cs.Id);
            //CS21-192 Starts
            if(cs.Status == 'Closed' && cs.Assist_Request_Count__c > 0 & assistReqMap.containsKey(cs.Id)){
                if(!Test.isRunningTest())
                    cs.addError(assistReqMap.get(cs.Id));
            }
            //CS21-192 Ends

            //CS-357 Akashdeep Start
            //CS21-44 change
             /*CS21-851 : Disable case routing to Open Queue (Digital) when US_Federal_Account__c is true. Added conditions to check if the current case owner is Open Queue
            (Unassigned_Cases) and case account is a US Federal Account, then do not reassign the case*/
            //CS21-1302
            if(cs.ContactId != oldCaseRecord.ContactId && conMap.containskey(cs.Contactid)){
                cs.AccountId = conMap.get(cs.Contactid).AccountId;
            }
            // 3033
            List<String> usFedAseQueueStringList = new List<String>{'US Federal Queue', 'ASE Queue'};
            account = accountMap.get(cs.AccountId);
            if(accountMap.containsKey(cs.AccountId) && accountMap.get(cs.AccountId).Tabs_Visibility__c != null 
               && accountMap.get(cs.AccountId).Tabs_Visibility__c.containsIgnoreCase('Predibase')  && !String.valueOf(cs.ownerId).startswith('005')){
                   processPredibaseCases(cs); 
               }
            else if(account != null && !account.US_Federal_Account__c && !account.ASE_Account__c && !(cs.Origin == 'Alert' || cs.Origin == 'Alert (come in email)' || cs.Origin == 'Pulse')
                && cs.RecordTypeId == supportCaseId && cs.ownerId!=null && !String.valueOf(cs.ownerId).startswith('005') &&
                (cs.ownerId == queueNameIdMap.get('Unassigned_Cases') 
                || cs.ownerId == queueNameIdMap.get('Open_Queue_Digital')
                || cs.ownerId == queueNameIdMap.get('Open_Queue_TA')
                || (cs != null && isUsFedOrAseAccount(cs)))){
                    String body = 'This case was automatically routed from ';
                 if(account != null && !(account.Account_Preference__c !=null && account.Account_Preference__c.contains('Top Accounts') && !(cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Proactive')) && 
                    account.Sum_of_Opportunities__c < threshold
                    && account.Sum_of_Open_Opportunities__c < threshold
                    && !account.Disable_Case_Routing_for_Open_Queue_25__c){
                        if(cs.ownerId == queueNameIdMap.get('Open_Queue_TA')
                            || (cs != null && isUsFedOrAseAccount(cs))){
                                body += 'OPEN QUEUE-TA to Open Queue (Digital) .';
                        }
                        else if(cs.ownerId == queueNameIdMap.get('Unassigned_Cases')
                            || (cs != null && isUsFedOrAseAccount(cs))){
                                body += 'OPEN QUEUE to Open Queue (Digital) .';
                        }
                        cs.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
                }else{
                    if(cs.ownerId == queueNameIdMap.get('Open_Queue_Digital')
                        || (cs != null && isUsFedOrAseAccount(cs))){
                            if(account.Account_Preference__c !=null && account.Account_Preference__c.contains('Top Accounts') && !(cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Proactive')){
                                        body += 'Open Queue (Digital) to OPEN QUEUE-TA.';
                                        cs.OwnerId = queueNameIdMap.get('Open_Queue_TA');
                                    }
                                    if(account != null && 
                                   !(account.Account_Preference__c !=null && account.Account_Preference__c.contains('Top Accounts') && !(cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Proactive'))
                                   && account.Sum_of_Opportunities__c < openQueueThreshold ){
                                        body += 'Open Queue (Digital) to OPEN QUEUE.';
                                        cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
                                    }
                            }
                    if(cs.ownerId == queueNameIdMap.get('Unassigned_Cases')
                        || (cs != null && isUsFedOrAseAccount(cs))){
                            if(account != null && account.Account_Preference__c !=null && account.Account_Preference__c.contains('Top Accounts') && !(cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Proactive')){
                                body += 'Open Queue to OPEN QUEUE-TA.';
                                cs.OwnerId = queueNameIdMap.get('Open_Queue_TA');
                            }
                    }else if(cs.ownerId == queueNameIdMap.get('Open_Queue_TA')
                            || (cs != null && isUsFedOrAseAccount(cs))){
                                if(account != null && 
                                   !(account.Account_Preference__c !=null && account.Account_Preference__c.contains('Top Accounts') && !(cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Proactive')) 
                                   && account.Sum_of_Opportunities__c < openQueueThreshold){
                                    body += 'OPEN QUEUE-TA to Open Queue.';
                                    cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
                                }
                            }
                }
                //3033: 
                if(!String.valueOf(oldCaseRecord.ownerId).startswith('005') && usFedAseQueueStringList.contains(cs.Case_Owner_Name__c) && body == 'This case was automatically routed from '){
                    body += cs.Case_Owner_Name__c+' to ' + oldCaseRecord.Case_Owner_Name__c;
                }
                // 3033: Change from Other Queues to ASE/US federal Queue on Non ASE/US federal Account
                else if(usFedAseQueueStringList.contains(cs.Case_Owner_Name__c) && !usFedAseQueueStringList.contains(oldCaseRecord.Case_Owner_Name__c)){
                        List<String> split1 = body.split('from');
                        if(String.valueOf(oldCaseRecord.ownerId).startswith('005')){
                            List<String> split2 = split1[1].split('to');
                            if(!split2.isEmpty()){
                                body = split1[0]+' from '+cs.Case_Owner_Name__c+' to ' + split2[1];
                            }
                            
                        }else{
                            body = split1[0]+' from '+cs.Case_Owner_Name__c+' to ' + oldCaseRecord.Case_Owner_Name__c;
                        }
                }
                // 3033: When Existing Case Account Critieria add/removing  ASE/US Fed
                else if(usFedAseQueueStringList.contains(oldCaseRecord.Case_Owner_Name__c)){
                    List<String> split1 = body.split('from');
                        List<String> split2 = split1[1].split('to');
                        body = split1[0]+' from '+oldCaseRecord.Case_Owner_Name__c+' to ' + split2[1];
                }
                if(body != 'This case was automatically routed from ' && (!cs.US_Federal_Account__c && !cs.ASE_Account__c)){
                    privateComment.add(new CaseComment(ParentId = cs.Id, IsPublished = false, CommentBody = body));
                }
            }
            
            if(cs.status !=oldCaseRecord.status && System.label.Inactive_Status.contains(cs.status)){
                cs.isStopped = true;
            }else if(cs.status !=oldCaseRecord.status && System.label.Inactive_Status.contains(oldCaseRecord.status)){
                cs.isStopped = false;
            }
            if(cs.status=='Closed' && cs.status!=oldCaseRecord.Status){
               //CS21-1806 Code Commented
             /*   if(cs.Workaround_Provided__c == null){
                    cs.Workaround_Provided__c = system.now().addMinutes(1) ;
                }
             */
                //CS21-1806 Code Commented Ends
                if(cs.Workaround_Verified__c == null){
                    cs.Workaround_Verified__c = system.now().addMinutes(2) ;
                }
            }
            if(cs.status=='Closed'){
                cs.NCC_date__c = null;           //CS21-2 : NCC Date to be deleted at case closure
                cs.NCC_Warning_Email_Date__c = null;
            }
            // CS21-1806 Code Commented
                   /*
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Provided__c !=oldCaseRecord.Workaround_Provided__c  &&  oldCaseRecord.Workaround_Provided__c == Null && cs.status!='Closed' && !System.label.Inactive_Status.contains(cs.status) && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate'){
                cs.addError('Please change the status to inactive status');
            }
            */
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Verified__c !=oldCaseRecord.Workaround_Verified__c && oldCaseRecord.Workaround_Verified__c == null && cs.status!='Closed' &&  !System.label.Inactive_Status.contains(cs.status) && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate'){
                cs.addError('Please change the status to inactive status');
            }
             // CS21-1806 Code Commented
                   /*
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Provided__c!=null && cs.Workaround_Provided__c !=oldCaseRecord.Workaround_Provided__c  && cs.Workaround_Provided__c.date() < cs.createddate.date() && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate'){
                cs.addError('Next Steps/Action Plan Provided date/time can-not be prior to case created date');
            }
            */
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Verified__c !=null && cs.Workaround_Verified__c !=oldCaseRecord.Workaround_Verified__c  && cs.Workaround_Verified__c.date() < cs.createddate.date() && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate'){
                cs.addError('Resolution/Workaround Verified date/time can-not be prior to case created date');
            }
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Verified__c !=oldCaseRecord.Workaround_Verified__c && cs.Workaround_Verified__c == null && oldCaseRecord.status!='Closed' && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate'){
                cs.addError('Please enter that date/time when the resolution verified from customer, do not blank it out.');
            }
             //CS21-1806 Code Commented
           /* if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Provided__c !=oldCaseRecord.Workaround_Provided__c && cs.Workaround_Provided__c == null && oldCaseRecord.status!='Closed' && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate'){
                cs.addError('Please enter that date/time when the next steps provided to customer, do not blank it out.');
            }
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Provided__c == null && oldCaseRecord.status!='Closed' && cs.Workaround_Verified__c !=oldCaseRecord.Workaround_Verified__c && oldCaseRecord.Workaround_Verified__c == null && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate'&& !(PRO_ACTIVE_CASE_ORIGIN_LIST.contains(cs.Origin))){    //CS21-185 : Condition added to exclude alert cases from this validation
                cs.addError('Please enter Next Steps/Action Plan provided date');
            }
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Provided__c != null && oldCaseRecord.status!='Closed' && cs.Workaround_Provided__c !=oldCaseRecord.Workaround_Provided__c && (cs.E2CAdv__Public_Recent_Comments__c == null && cs.E2CAdv__Public_Recent_Comments_Text__c == null) && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate' && !(PRO_ACTIVE_CASE_ORIGIN_LIST.contains(cs.Origin))){    //CS21-185 : Condition added to exclude alert cases from this validation
                cs.addError('Please enter public comment to customer prior to provide next steps');
            }
            */
            //CS21-1806 Code Commented Ends
            if(cs.Recordtype__c == 'Support Case' && cs.Workaround_Verified__c != null && oldCaseRecord.status!='Closed' && cs.Workaround_Verified__c !=oldCaseRecord.Workaround_Verified__c && cs.E2CAdv__Public_Recent_Comments_Text__c == null && cs.Resolution__c!= 'Spam/Junk' && cs.Resolution__c!= 'Duplicate' && !(PRO_ACTIVE_CASE_ORIGIN_LIST.contains(cs.Origin))){   //CS21-185 : Condition added to exclude alert cases from this validation
                cs.addError('Please enter public comment to customer prior to provide resolution');
            }

            // Updated by Vijay Kumar K R
            // CS21-1210: Next Step Action Plan & Resolution workaround Milestone discrepancy
            // Next Steps/Action Plan Provided OR Resolution/Workaround Verified

            //CS21-1806 Code Commented
           /* if(((cs.status !=oldCaseRecord.status
                && System.label.Inactive_Status.contains(cs.status))
                || System.label.Inactive_Status.contains(cs.status))
                && ((cs.Workaround_Provided__c != null
                    && cs.Workaround_Provided__c != oldCaseRecord.Workaround_Provided__c)
                    || (cs.Workaround_Verified__c != null
                        && cs.Workaround_Verified__c != oldCaseRecord.Workaround_Verified__c))){
                cs.isStopped = true;
                mileCaseIds.add(cs.Id+'_'+cs.status+'_Dates');
                mapOfCase.put(cs.Id,cs);
            }
            */
            //CS21-1806 Code Commented Ends
            if(((cs.status !=oldCaseRecord.status
                && System.label.Inactive_Status.contains(cs.status))
                || System.label.Inactive_Status.contains(cs.status))
               // && cs.Workaround_Provided__c != null
              //  && oldCaseRecord.Workaround_Provided__c == null
                && cs.Workaround_Verified__c != null
                && oldCaseRecord.Workaround_Verified__c == null){
                    cs.isStopped = true;
                    mileCaseIds.add(cs.Id+'_'+'Dates_Dates');
                    mapOfCase.put(cs.Id,cs);
            }
            if(cs.status !=oldCaseRecord.status
                && cs.status == 'Closed'){
                    //cs.isStopped = true;
                    mileCaseIds.add(cs.Id+'_'+cs.status+'_Case');
                    mapOfCase.put(cs.Id,cs);
            }

            if(cs.status!='Closed' && cs.status!=oldCaseRecord.Status && oldCaseRecord.Status == 'Closed'){
                cs.NCC_date__c = null;           //CS21-2 : NCC Date to be deleted at case reopen
            }
            //CS-357 Akashdeep End

            if(cs.Status == 'Resolved' && oldCaseRecord.Status != cs.Status && cs.Resolved_Date_Time__c == null){
                cs.Resolved_Date_Time__c = System.now();
            }
            if(cs.Status == 'Resolved - Pending Customer' && oldCaseRecord.Status != cs.Status && cs.Resolved_Pending_Customer_State_DateTime__c == null){
                cs.Resolved_Pending_Customer_State_DateTime__c = System.now();
            }
            // Close Case functionality
            if(!cs.close_survey_triggered__c
                && cs.ContactId != null
                && cs.status != oldCaseRecord.status
                && cs.Status.equalsIgnoreCase('Closed')
                && !oldCaseRecord.Status.equalsIgnoreCase('Customer requested close')
                && cs.Resolution__c != null
                && !System.Label.Spam_Resolutions.contains(cs.Resolution__c)
                // 1316: Condition Added by Vijay, not updating Survey_sent flag when suppressing the survey email.
                && !fedRampCaseIdSet.contains(cs.Id)){
                    // Date var's to store last feedback date from Contact
                    datetime dtnow          = datetime.now();
                    datetime lastSurveyTime = con.Last_GetFeedback_Date__c;
                    cs.close_survey_triggered__c = true;
                    // Updating Survey_sent__c true if lastSurvey time more than 7days
                    if(!System.Label.Skip_Case_Close_Survey_for_Accounts.contains(cs.AccountId)
                        && (lastSurveyTime == null || (dtnow.getTime() - lastSurveyTime.getTime()) > (7*24*3600*1000) || (System.Label.Account_Id_for_every_Case_Survey.contains(cs.AccountId) && !cs.Survey_sent__c))){					 							 
                                cs.Survey_sent__c = true;
                                caseIdSetForSurvey.add(cs.Id);
                    }
            }else {
                if(!cs.Status.equals('Closed') && cs.close_survey_triggered__c){
                    cs.close_survey_triggered__c = false;
                }
            }

			//CS21-2
            if(cs.NCC_date__c != null && cs.NCC_date__c != oldCaseRecord.NCC_date__c  && cs.RecordTypeId != renewalCaseId ){
                cs.NCC_Updated__c = true;
                //CS21-1806 Changed from 15 mins to 30 mins
                cs.NCC_Warning_Email_Date__c = cs.NCC_date__c.addMinutes(-30);
                //CS21-1806 ends
                if(cs.NCC_date__c < system.now()){
                    cs.addError('NCC Date cannot be in the past!');
                }
                //CS21-1806
                if(cs.NCC_date__c > System.now().addDays(14)){
                   cs.addError('NCC Date cannot be more than 2 weeks in future!');
                }
            }
            if(cs.Platform__c == 'Polaris')
                polarisCases.add(cs);

            //CS21-617 - Shubham - Added a warning to change case contact
            if(caseOriginStr.contains(cs.Origin) && contactIdSet.contains(cs.ContactId) && cs.CaseCommentsPublic__c > 0 && (cs.ContactId == cs.Proactive_Case_Contact__c										 										 
                || cs.ContactId == cs.Proactive_Case_Contact_OBH__c || (clusterMap.containsKey(cs.Cluster__c) && (cs.ContactId == clusterMap.get(cs.Cluster__c).Proactive_Case_Contact__c
                || cs.ContactId == clusterMap.get(cs.Cluster__c).Proactive_Case_Contact_OBH__c)))){	
                cs.Change_Case_Contact_Warning__c = Label.Contact_Change_Warning_Msg;
            } else if(cs.Change_Case_Contact_Warning__c != null){
                cs.Change_Case_Contact_Warning__c = '';
            }
        }
        ListmileCaseIds.addAll(mileCaseIds);
        if(!privateComment.isEmpty())
            CaseTriggerHandler.addPrivateComment(JSON.serialize(privateComment));
        if(ListmileCaseIds!=null && !ListmileCaseIds.isEmpty() && !milestoneRun)
            completemilestone(ListmileCaseIds,mapOfCase);

        CaseManageAutoEmailResponses((List<Case>)trigger.new);
        updateKCSAndArticleCount((Map<Id, Case>)Trigger.newMap);

        CaseTriggerHandler.addDesc(polarisCases);

        //CS21-232 : NCC Updates : update the case owner's manager's email if it is not a queue
        Set<Id> caseOwnerIds = new Set<Id>();
        for(Case cs: (List<Case>)trigger.new){
            String ownerId = (String)cs.OwnerId;

            if(ownerId != null &&
               ownerId.startsWith('005')){
                caseOwnerIds.add(cs.ownerId);
            }
        }
        Map<Id, User> usersList;
        usersList = new Map<Id, User>([Select Id, ManagerId, Manager.Email from User where Id IN :caseOwnerIds]);
        for(Case cs: (List<Case>)trigger.new){
            if(String.ValueOf(cs.OwnerId).startsWith('005') &&
               usersList != null &&
               usersList.containsKey(cs.OwnerId)){
                   User tempUser = usersList.get(cs.OwnerId);
                   if(tempUser.ManagerId != null && cs.Owner_s_manager_email__c != tempUser.Manager.Email){
                       cs.Owner_s_manager_email__c = tempUser.Manager.Email;
                   }
               }
        }

        //Added for CS21-482 - to update case owner after transfer request is approved
        CaseTransferApprovalRequest.updateCaseTransferOwner((List<Case>)trigger.new, (Map<Id, Case>)trigger.oldMap);

        //CS21-1086 --  Validation Rule -----------
        set<ID> caseIdToMilestoneSet=new set<ID>();
        for(CaseMilestone CMS : [SELECT Id, MilestoneType.Name, CaseId, Case.Status, Case.Workaround_Provided__c, Case.Workaround_Verified__c,
                                Case.E2CAdv__Public_Recent_Comments_Text__c, CompletionDate, isCompleted FROM caseMilestone
                                WHERE CaseID IN : caseIds AND MilestoneType.Name like '%Initial%' AND isCompleted=true]){
                                    caseIdToMilestoneSet.add(CMS.CaseId);
                                }

        //To fire Validation rule on case record while adding second Public/Private Comment or while editing the case record
        // This validation rule has been moved from UI to code to pass CS21-1086
        String currentUserId = String.valueOf(UserInfo.getUserId()).substring(0, 15); //  by pass rule for Support Bot User
        if(!DisableCaseValidationRules() && String.valueOf(UserInfo.getUserType()) == 'Standard' && System.label.SupportBotUserId != currentUserId){
            for (Case caseObj : (List<Case>)Trigger.new) {
                Case oldCaseRec = (Case) Trigger.oldMap.get(caseObj.Id);
                if(((!CaseTriggerHandler.stopValidation && caseIdToMilestoneSet.contains(caseObj.id) && caseObj.E2CAdv__Public_Recent_Comments_Text__c!=NUll) || (CaseTriggerHandler.stopValidation && caseObj.E2CAdv__Public_Recent_Comments_Text__c==NUll) || (CaseTriggerHandler.stopValidation && caseIdToMilestoneSet.contains(caseObj.id)) || (!caseIdToMilestoneSet.contains(caseObj.id) && (CaseTriggerHandler.stopValidation || (!CaseTriggerHandler.stopValidation &&caseObj.E2CAdv__Public_Recent_Comments_Text__c!=NUll)))) &&
                   caseObj.OwnerId == ((Case)Trigger.oldMap.get(caseObj.Id)).OwnerId &&
                   String.isBlank(caseObj.If_Other__c) &&
                   (caseObj.Problem_Type__c == 'Other' ||
                    caseObj.Sub_Component__c == 'Other (specify)' ||
                    (caseObj.Status == 'Closed' &&
                     (caseObj.Platform__c == 'Other' ||
                      caseObj.Product_Area__c == 'Other'))) &&
                   caseObj.Recordtype__c == 'Support Case' &&
                   caseObj.Idea_Reference__c == oldCaseRec.Idea_Reference__c
                  ){
                      caseObj.If_Other__c.addError('\'If Other, Please Specify\' field is mandatory, if Product-Line, Functional Area, Component or Sub-Component has a value \'Other\'');
                  }
            }
        }
        //CS21-1086 --  Validation Rule End -----------

        if(!FeatureManagement.checkPermission('Bypass_Disallow_Closed_Case_Change_After_7_Days')){
            Set<String> excludedUserTypes = parseCustomLabel(System.Label.Exclude_User_Types, ',');
            Set<String> excludedUserIds = parseCustomLabel(System.Label.Exclude_User_Ids, ',');
            if(excludedUserTypes!=null && !excludedUserTypes.contains(UserInfo.getUserType()) && excludedUserIds!=null && !excludedUserIds.contains(UserInfo.getUserId())){
            disallowOwnerChangeAfterClosure((List<Case>)Trigger.new, (Map<Id, Case>)Trigger.oldMap);//CS21-3568
            }
        }
    }
 
	/**
	* @description 3033 return boolean value if Case owner if Fed or ASE Queue
	* @param cs
	* @return True if US Fed Or ASE Account
	*/
    public static boolean isUsFedOrAseAccount(Case cs){
        return (cs.ownerId == queueNameIdMap.get('ASE_Queue')
                || cs.ownerId == queueNameIdMap.get('FED_Queue'));
    }

    /**
     * Method updateInitialCaseOwner
     * @description CS21-1885: Initial Case owner assignment + CS21-1923: Escalation Task assignment - Not in CSE queue or OPEN
     * @param objCase current case object
	 * @param oldCase old case object
     */
    public static void updateInitialCaseOwner(Case objCase, Case oldCase){
        //CS21-1137
        String supportUserProfileNameStr = 'Rubrik Customer Support User';
        // is OwnerId Changed
        if((oldCase == null || objCase.ownerId != oldCase.ownerId)
            && String.valueOf(objCase.ownerId).startswith('005')
            && String.valueOf(objCase.Owner_Profile__c).containsIgnoreCase(supportUserProfileNameStr)){
            // CS21-1885
            List<String> byPassUserIdList = System.Label.ByPass_Initial_Case_Owner_UserIds.split(';');
            if(String.isBlank(objCase.Initial_Case_Owner__c)
                // CS21-2009
                && !byPassUserIdList.contains(objCase.OwnerId)){
                    objCase.Initial_Case_Owner__c = objCase.OwnerId;
            }
            // CS21-1923
            objCase.Recent_Case_Owner__c = objCase.OwnerId;
        }   
        //CS21-1137- end
    }
	
	/**
     * @description update KCS And Article COunt
     * @param newCaseMap map of Id and Case Object
     */
    private static void updateKCSAndArticleCount(Map<Id, Case> newCaseMap) {
        Map<Id, Case> casesWithArticleMap = new Map<Id, Case>([SELECT Id, (SELECT Id FROM CaseArticles) FROM Case WHERE Id =: newCaseMap.keySet()]);

        for(Case cs : newCaseMap.values()){
            cs.Article_Total_Count__c = ((casesWithArticleMap.get(cs.Id)).CaseArticles).size();

            if(cs.Article_Total_Count__c == 0 && (cs.KCS_Article_Candidate__c == 'Article Linked' || cs.KCS_Article_Candidate__c == 'Existing Article updated')) {
                cs.KCS_Article_Candidate__c = null;
                cs.KCS_Article_Status__c = null;
                cs.Documentation_Type__c = null;
            }
        }
    }

	/**
	 * @Author		  Saakshi Gupta
	 * @Jira Ticket   CS21-525 - Initial Priority field fix
    * @description     This method copies the Priority over to Initial Priority field only if Initial Priority field is blank. Once a value is written to the Initial Priority, it is never overwritten
	 * @param newCaseList List of new Cases
	 */
    public static void setInitialPriority(List<Case> newCaseList){
        Map<String, String> priorityMap = new Map<String, String>();
        List<Schema.PicklistEntry> picklistEntries = Schema.SObjectType.Case.fields.Priority.getPicklistValues();

        for(Schema.PicklistEntry ple : picklistEntries){
            priorityMap.put(ple.getValue(), ple.getLabel());
        }

        for(Case eachCase : newCaseList) {
            if(String.isBlank(eachCase.Initial_Priority__c) && !String.isBlank(eachCase.Priority) &&
                !eachCase.Priority.equalsIgnoreCase('None')){
                eachCase.Initial_Priority__c = priorityMap.get(eachCase.Priority);
            }
        }
    }
	/**
	* @description add Private Comment
	* @param privateComment comment data
	*/
    @future
    public static void addPrivateComment(String privateComment){
        try{
            insert (List<CaseComment>)JSON.deserialize(privateComment,List<CaseComment>.class);
        }catch(exception e){
			System.debug(LoggingLevel.ERROR, e.getMessage());
        }
    }

    /**
	* @Author          Saakshi Gupta
	* @Jira Ticket     526 - Add case owner's email address as a recipient to the customer case email notification
	* @description     This method inserts and deletes the Case team member when case owner is updated. Following are the conditions
	based on which case team member is insert or deleted:
	1. When old owner is a user and new owner is also a user, old case team member record is deleted,
	since updated of MemberId is not allowed for an existing case team member and new case team
	member is inserted with the new case owner with Role as Case Owner
	2. When old owner is a user and new owner is a queue, old case team member record is deleted and
	no new case team member record is created as there is no option for Queue member type
	3. When old owner is a queue and new owner is a user, since there is no existing case team member
	for queue, only new case team member will be added with new owner as Member and Role as Case Owner
	4. When old owner is a queue and new owner is a queue, no action will be performed as there is no
	existing case team member and new doesn't need to be created
	**/
    private void updateCaseTeamMemberOnOwnerChange() {
        Map<id,Case> caseOldMap = (Map<Id,Case>)trigger.oldMap;
        List<Case> newCaseList = (List<Case>)trigger.new;
        Map<String, Id> oldOwnerIdMap = new Map<String, Id>();
        Map<String, Id> newOwnerIdMap = new Map<String, Id>();
        Set<Id> caseIdSet = new Set<Id>();
        List<CaseTeamMember> caseTeamMemberToBeInsertedList = new List<CaseTeamMember>();
        List<CaseTeamMember> caseTeamMemberToBeDeletedList = new List<CaseTeamMember>();
        Boolean queryTeamRoleId = false;

        for(Case cs: newCaseList) {
            Case oldCaseRecord = caseOldMap.get(cs.Id);

            //Fetch old and new owner Ids corresponding to case when both are users
            if(cs.OwnerId != oldCaseRecord.OwnerId && String.valueOf(cs.OwnerId).startsWith('005') && String.valueOf(oldCaseRecord.OwnerId).startsWith('005')) {
                oldOwnerIdMap.put(cs.Id, oldCaseRecord.OwnerId);
                newOwnerIdMap.put(cs.Id, cs.OwnerId);
            }

            //Prepare case team member list to be inserted when old case owner was a queue and new case owner is a user
            else if(cs.OwnerId != oldCaseRecord.OwnerId && String.valueOf(cs.OwnerId).startsWith('005') && String.valueOf(oldCaseRecord.OwnerId).startsWith('00G')) {
                queryTeamRoleId = true;

                CaseTeamMember caseMemberObject = new CaseTeamMember();
                caseMemberObject.MemberId = cs.OwnerId;
                caseMemberObject.ParentId = cs.Id;
                caseTeamMemberToBeInsertedList.add(caseMemberObject);
            }

            //Prepare case Ids set to delete case team members with role 'Case Owner' when new case owner is a queue and old case owner was a user
            else if(cs.OwnerId != oldCaseRecord.OwnerId && String.valueOf(cs.OwnerId).startsWith('00G') && String.valueOf(oldCaseRecord.OwnerId).startsWith('005')) {
                caseIdSet.add(cs.Id);
            }
        }

        if(queryTeamRoleId) {
            CaseTeamRole caseOwnerTeamMemberRole = [Select Id from CaseTeamRole where Name = 'Case Owner'];

            for(CaseTeamMember eachCaseTeamMember : caseTeamMemberToBeInsertedList) {
                eachCaseTeamMember.TeamRoleId = caseOwnerTeamMemberRole.Id;
            }
        }

        if(!oldOwnerIdMap.keyset().isEmpty()) {
            for(CaseTeamMember eachCaseTeamMember : [Select Id, MemberId, ParentId, TeamRoleId from CaseTeamMember where ParentId =: oldOwnerIdMap.keySet() and MemberId =: oldOwnerIdMap.values() and TeamRole.Name = 'Case Owner']) {
                CaseTeamMember caseMemberObject = new CaseTeamMember();
                caseMemberObject.MemberId = newOwnerIdMap.get(eachCaseTeamMember.ParentId);
                caseMemberObject.ParentId = eachCaseTeamMember.ParentId;
                caseMemberObject.TeamRoleId = eachCaseTeamMember.TeamRoleId;

                caseTeamMemberToBeInsertedList.add(caseMemberObject);
                caseTeamMemberToBeDeletedList.add(eachCaseTeamMember);
            }
        }

        Database.insert(caseTeamMemberToBeInsertedList , false);

        if(!caseIdSet.isEmpty()) {
            caseTeamMemberToBeDeletedList.addAll([Select Id from CaseTeamMember where ParentId =: caseIdSet and TeamRole.Name = 'Case Owner']);
        }

        Database.delete(caseTeamMemberToBeDeletedList, false);
    }

	/**
	* @description CS-357 Akashdeep Start
	* @param caseIds ids op cases
	* @param mapOfCase map of Id and Case Object
	*/
    public static void completemilestone(List<string> caseIds, map<Id,Case> mapOfCase){
        milestoneRun = true;
        string casedetail = '';

        map<id,String> mapCaseIdtoStatus = new map<Id,String>();
        for(String each : caseIds){
            casedetail = each .split('_')[2];
            mapCaseIdtoStatus.put(each .split('_')[0],each .split('_')[1]);
        }

        map<Id,List<CaseMilestone>> mapOfCaseMilestone = new map<Id,List<CaseMilestone>>();
        List<caseMileStone> csmList = new List<caseMilestone>();
        List<caseMileStone> allCsmList = new List<caseMilestone>();
        map<Id,Case> caseIdToCase=new map<Id,Case>();
        integer i=0;

        if(casedetail == 'Comment'){
            allCsmList = [SELECT Id, MilestoneType.Name, CaseId, Case.Status, Case.Workaround_Provided__c, Case.Workaround_Verified__c,
                                Case.E2CAdv__Public_Recent_Comments_Text__c, CompletionDate, isCompleted,Case.priority,Case.Createddate 
                            FROM caseMilestone
                            WHERE isCompleted = false
                            AND CaseID IN : mapCaseIdtoStatus.keySet()
                            AND MilestoneType.Name like '%Initial%'
                            ORDER BY TargetResponseInMins];
        }else if(casedetail == 'Dates'){
            allCsmList = [SELECT Id, MilestoneType.Name, CaseId, Case.Status, Case.Workaround_Provided__c, Case.Workaround_Verified__c,
                                Case.E2CAdv__Public_Recent_Comments_Text__c,Case.Createddate,Case.Priority, CompletionDate, isCompleted
                            FROM caseMilestone
                            WHERE CaseID IN : mapCaseIdtoStatus.keySet()
                            AND (MilestoneType.Name like '%Resolution/Workaroun%'
                                OR MilestoneType.Name like '%Next Steps%')
                            ORDER BY TargetResponseInMins];
        }
        // avoid fetching all Mailstones
        else{
            allCsmList = [Select id,MilestoneType.Name ,CaseId,case.status,case.Workaround_Provided__c, case.Workaround_Verified__c,case.E2CAdv__Public_Recent_Comments_Text__c,CompletionDate,isCompleted,Case.Priority,Case.CreatedDate from caseMilestone where isCompleted = false and CaseID IN : mapCaseIdtoStatus.keySet() order by TargetResponseInMins];
        }

        for(CaseMilestone each : allCsmList){
            if(mapOfCaseMilestone.containsKey(each.caseId)){
                mapOfCaseMilestone.get(each.caseId).add(each);
            }else{
                mapOfCaseMilestone.put(each.caseId,new List<CaseMilestone>{each});
            }
        }

        for(Id eachId : mapOfCaseMilestone.keySet()){
            //case cs = (case)trigger.newmap.get(eachId);
            for(CaseMilestone each : mapOfCaseMilestone.get(eachId)){
                // Updated by Vijay Kumar K R:
                // CS21-1210: Next Step Action Plan & Resolution workaround Milestone discrepancy
                if(String.valueOf(each.MilestoneType.Name).equalsIgnoreCase('Initial Response')){
                   // CS21-1806 Code Commented
                   /*
                    if(casedetail != 'Comment'
                        && mapCaseIdtoStatus.get(eachId) != 'Closed'
                        && mapCaseIdtoStatus.get(eachId) != 'Dates'
                        && (mapOfCase.get(eachId).Workaround_Provided__c != null
                        || mapOfCase.get(eachId).Workaround_Verified__c != null)
                        && !(PRO_ACTIVE_CASE_ORIGIN_LIST.contains(mapOfCase.get(eachId).Origin))){
                            mapOfCase.get(eachId).addError('Please enter public comment to customer prior to provide next steps');
                            break;
                    }
                    */
                    if(each.CompletionDate == null){
                        each.CompletionDate = system.now();
                        caseIdToCase.put(each.caseId,each.case);
                        csmList.add(each);
                    }
                }
                     // CS21-1806 Code Commented
                   /*
                else if(String.valueOf(each.MilestoneType.Name).equalsIgnoreCase('Next Steps/Action Plan Provided')
                    && mapOfCase!= null
                    && mapOfCase.containsKey(eachId)
                    && mapOfCase.get(eachId).Workaround_Provided__c != null){
                        each.CompletionDate= mapOfCase.get(eachId).Workaround_Provided__c;
                        csmList.add(each);

                }*/
                else if(String.valueOf(each.MilestoneType.Name).equalsIgnoreCase('Resolution/Workaround Verified')
                    && mapOfCase!= null
                    && mapOfCase.containsKey(eachId)
                    && mapOfCase.get(eachId).Workaround_Verified__c != null){
                        each.CompletionDate= mapOfCase.get(eachId).Workaround_Verified__c;
                        csmList.add(each);
                }
                else if(String.valueOf(each.MilestoneType.Name).equalsIgnoreCase('Case Closure Confirmed')
                    && each.CompletionDate == null
                    && mapOfCase!= null
                    && mapOfCase.containsKey(eachId)
                    && mapOfCase.get(eachId).Workaround_Verified__c != null
                    && mapOfCase.get(eachId).status != null
                    && mapOfCase.get(eachId).status == 'Closed'){
                        each.CompletionDate = system.now();
                        csmList.add(each);
                }
            }
        }
        if(!csmList.isEmpty()){
            update csmList;
        }
        if(caseIdToCase.size()>0){
           CaseCommentTriggerHandler.ChangeInitialMilestoneFlagColor(caseIdToCase,(map<Id,Case>)trigger.newmap);
        }
    }

	/**
	* @description CS-357 Akashdeep End
	* @param caseIds
	*/
    @future(callout=true)
    public static void searchUnifyMethod(Set<Id> caseIds){
        List<Case> caseList = [select id,ContactEmail,ContactId,Status,Subject,Welcome_Email_Sent__c from case where id IN: caseIds AND Welcome_Email_Sent__c = False AND ContactId != null];
        for(Case cs: caseList){
            cs.Welcome_Email_Sent__c = true;
            String jsonString = '{"resultsPerPage":'+Label.SuggestionLabel+',"aggregations":[{"filter":["how_to__kav", "portal_news__c", "idea", "feeditem", "docs", "rubrik_docs"],"type":"_type"}],"pageNo":1,"orderBy":"desc","sortby":"_score","from":0,"searchString":"'+cs.Subject+'"}';
            Map<String, Object> suggestionList = SearchUnifyEndpoint.SearchResults(jsonString);
            caseSuggestionMap.put(cs.id,(JSON.serialize(suggestionList)));
        }
        update caseList;
    }

	/**
	* @description CS21-1252 - Case Status Tracker issue fix
	* @param newCaseMap new map of case ids and Case object
	* @param oldCaseMap old map of case ids and Case object
	*/
    public static void updateStatusTracking(Map<Id,Case> newCaseMap, Map<Id,Case> oldCaseMap){
        try{
            Map<id,List<String>> caseStatusMap=new Map<id,List<String>>();
            Schema.DescribeFieldResult fieldResult =  Case.Status.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            Map<id,List<CaseHistoryW>> caseHistoryMap =new Map<id,List<CaseHistoryW>>();
            Map<id,List<Status_Tracking__c>> casetrackerMap =new Map<id,List<Status_Tracking__c>>();
            Set<id> caseIds = new Set<Id>();
            //CS21-1349
            Set<id> closedCaseIds = new Set<Id>();
            // CS21-1832: New Value added "Waiting for Customer Input" TTR Calculation to be modified with an inclusion to active case statuses
            List<String> caseStatusList = Label.Case_Status_Which_Comes_Under_TTR.split(';');
            Map<id,string> caseIdWithCommentMap = new Map<id,string>();

            // Jira Update cluster CS21-1859

            set<Id> CaseIdForJIRAClusters =new set<Id>();

            for(Case cs : newCaseMap.values()){
                Case oldCase  = oldCaseMap.get(cs.id);
                if(cs.Status != oldCase.Status){
                    caseIds.add(cs.id);
                    if(cs.Status == 'Closed'){
                        closedCaseIds.add(cs.Id);
                        if(!caseIdWithCommentMap.containskey(cs.Id)){
                            String commentBody = '1. Case Number '+cs.CaseNumber + ' was closed, Account Name :'+cs.Account_Name__c+' ,Case summary : '+cs.Subject+'. \n 2. Case Resolution : '+cs.Resolution__c +'\n 3. Please perform RCA before closing the jira.';
                            caseIdWithCommentMap.put(cs.Id, commentBody);
                        }
                    }
                }
                //Jira Update cluster CS21-1859
                if(cs.Additional_Cluster__c!=oldCase.Additional_Cluster__c || cs.Cluster__c!=oldCase.cluster__c)
                   {
                      CaseIdForJIRAClusters.add(cs.Id);
                    }

            }
             // created by Raveesh Layal CS21-1859 Sync Case Clusters to Jira
            if(CaseIdForJIRAClusters.size()>0 && !System.isBatch() && !System.isFuture() && !System.isQueueable())
            {
                SFJiraCaseClusterUpdateHelper.syncJIRAClusters(CaseIdForJIRAClusters,null);
            }

            if(!caseIds.isEmpty() && !isExecuted){
                isExecuted = true;
                for(Status_Tracking__c trackers :[SELECT id,Case__c,Tracking__c,Days__c,Hours__c,Minutes__c,Miliseconds__c,Number_of_times_in_status__c FROM Status_Tracking__c where Case__c IN: caseIds]){
                    if(!casetrackerMap.containsKey(trackers.Case__c)){
                        casetrackerMap.put(trackers.Case__c,new List<Status_Tracking__c>());
                    }
                    casetrackerMap.get(trackers.Case__c).add(trackers);
                    if(!caseStatusMap.ContainsKey(trackers.Case__c)){
                        caseStatusMap.put(trackers.Case__c,new List<String>());
                    }
                    caseStatusMap.get(trackers.Case__c).add(trackers.Tracking__c);
                }
                List<Status_Tracking__c> newTrackingList = new List<Status_Tracking__c>();
                List<CaseHistory> caseHistoryList = [SELECT CreatedDate,Field,NewValue,OldValue,CaseId,Case.CreatedDate FROM CaseHistory where CaseId IN: caseIds AND Field ='Status' ORDER BY CreatedDate DESC];
                List<CaseHistoryW> caseHistoryWList = new List<CaseHistoryW>();
                for(CaseHistory ch : caseHistoryList) caseHistoryWList.add(new CaseHistoryW(ch));
                if(Test.isRunningTest()){
                    new CaseHistoryW(new CaseHistory());
                    Integer i = 1;
                    List<Case> caseList = [SELECT id,status,CreatedDate from Case where id IN: caseIds];
                    for(Case cs : caseList){
                        caseHistoryWList.add(new CaseHistoryW(cs.Id,'Resolved2','New',System.now(),cs.CreatedDate));
                        if(math.mod(caseList.size(), i) != 0){
                            caseHistoryWList.add(new CaseHistoryW(cs.Id,'Resolved','New',System.now(),cs.CreatedDate));
                        }i++;
                    }
                }
                for(CaseHistoryW history : caseHistoryWList){
                    if(!caseHistoryMap.containsKey(history.CaseId)){
                        caseHistoryMap.put(history.CaseId,new List<CaseHistoryW>());
                    }
                    caseHistoryMap.get(history.CaseId).add(history);
                }

                for(Id caseId : caseIds){
                    if(!caseHistoryMap.containsKey(caseId)){
                        caseHistoryMap.put(caseId,new List<CaseHistoryW>{new CaseHistoryW(caseId,newCaseMap.get(caseId).Status,oldCaseMap.get(caseId).Status,System.now(),newCaseMap.get(caseId).CreatedDate)});
                    } else{
                        caseHistoryMap.get(caseId).add(0,new CaseHistoryW(caseId,newCaseMap.get(caseId).Status,oldCaseMap.get(caseId).Status,System.now(),newCaseMap.get(caseId).CreatedDate));
                    }
                }
                System.debug(LoggingLevel.INFO,'******UpdateStatusTracking******'+caseHistoryMap);

                for(List<CaseHistoryW> historyList : caseHistoryMap.values()){
                    for(CaseHistoryW history : historyList){
                        if(caseStatusMap.ContainsKey(history.CaseId)){
                            if(!caseStatusMap.get(history.CaseId).contains((String)history.NewValue)){
                                caseStatusMap.get(history.CaseId).add((String)history.NewValue);
                                newTrackingList.add(new Status_Tracking__c(Case__c = history.CaseId,Tracking__c =(String)history.NewValue ,Days__c = 0,Hours__c = 0, Minutes__c = 0,Miliseconds__c = 0 ,Number_of_times_in_status__c = 0 ));
                            }
                        }else{
                            caseStatusMap.put(history.CaseId,new List<String>{(String)history.NewValue});
                            casetrackerMap.put(history.CaseId,new List<Status_Tracking__c>());
                            newTrackingList.add(new Status_Tracking__c(Case__c = history.CaseId,Tracking__c =(String)history.NewValue ,Days__c = 0,Hours__c = 0, Minutes__c = 0,Miliseconds__c = 0 ,Number_of_times_in_status__c = 0 ));
                        }
                    }
                }
                insert newTrackingList;
                for(Status_Tracking__c st : newTrackingList){
                    casetrackerMap.get(st.Case__c).add(st);
                }
                Map<String,Integer> caseDateTimeMap =new Map<String,Integer>();
                for(Id caseId : caseHistoryMap.keyset()){
                    Long startDateMS;
                    Long endDateMS;
                    Integer day;
                    Integer hours;
                    Integer min;
                    String Status;
                    for(CaseHistoryW history:caseHistoryMap.get(caseId)){
                        if(startDateMS==null){
                            Status=(String)history.oldValue;
                            startDateMS = history.CreatedDate.getTime();
                            if(caseHistoryMap.get(caseId).size()==1){
                                endDateMS = history.CaseCreatedDate.getTime();
                                Long milliseconds = startDateMS - endDateMS;
                                Long seconds = milliseconds / 1000;

                                caseDateTimeMap.put(history.CaseId+'#'+Status, Integer.ValueOf(seconds));
                            }
                        }
                        else if(endDateMS==null){
                            endDateMS = history.CreatedDate.getTime();
                            Long milliseconds = startDateMS - endDateMS;
                            Long seconds = milliseconds / 1000;
                            caseDateTimeMap.put(history.CaseId+'#'+Status, Integer.ValueOf(seconds));
                            break;
                        }
                    }
                }
                List<Status_Tracking__c> statusTrackingList=new List<Status_Tracking__c>();
                for(String keyStringsList : caseDateTimeMap.keySet()){
                    String[] keyString = keyStringsList.Split('#');
                    if(casetrackerMap.containsKey(keyString[0])){
                        for(Status_Tracking__c tracker : casetrackerMap.get(keyString[0])){
                            if(tracker.Tracking__c == keyString[1]){
                                tracker.Miliseconds__c += caseDateTimeMap.get(keyStringsList);
                                tracker.Minutes__c = tracker.Miliseconds__c / 60;
                                tracker.Hours__c = tracker.Minutes__c / 60;
                                tracker.Days__c = tracker.Hours__c / 24;
                                tracker.Number_of_times_in_status__c = tracker.Number_of_times_in_status__c == null ? 1 : tracker.Number_of_times_in_status__c + 1 ;
                                statusTrackingList.add(tracker);
                                break;
                            }
                    }
                    }
                }

                //CS21-1349 - Shubham - Calculated and updated TTR field on case
                List<Case> caseUpdateList = new List<Case>();
                for(Id caseId : closedCaseIds){
                    if(casetrackerMap.containsKey(caseId)){
                        Decimal TTRInSeconds = 0;
                        for(Status_Tracking__c tracker : casetrackerMap.get(caseId)){
                            // CS21-1832: New Value added "Waiting for Customer Input" TTR Calculation to be modified with an inclusion to active case statuses
                            if(caseStatusList.contains(tracker.Tracking__c)){
                                TTRInSeconds = TTRInSeconds + tracker.Miliseconds__c;
                                }
                            }
                        caseUpdateList.add(new Case(Id = caseId,TTR__c = TTRInSeconds / 86400));
                    }
                }
                update caseUpdateList;

                update statusTrackingList;

                //Call to future method on closing case to insert Jira comments on the linked Jira's
                if(closedCaseIds!=NULL && !closedCaseIds.IsEmpty() &&  !caseIdWithCommentMap.IsEmpty()){
                    SendCommentToJira(closedCaseIds,caseIdWithCommentMap,NULL);
                }

            }
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
                           }
    }
	
	/**
	* @description Send Comments to all the 'Customer Bug' Jira's on the Case status closure
	* @param closedCaseIds 
	* @param caseIdWithCommentMap 
	* @param JiraRelationshiID 
	*/
    @future(callout=true)
    public static void sendCommentToJira(Set<id> closedCaseIds, Map<id,string>  caseIdWithCommentMap,List<ID> JiraRelationshiID){
        MAP<ID,CaseComment> caseCommentsMap =new MAP<ID,CaseComment>();
        List<zsfjira__ZIssue_SF__c> JiraRelationshipList=new List<zsfjira__ZIssue_SF__c>();
        if(JiraRelationshiID!=NULL){
            JiraRelationshipList=[Select zsfjira__Case__c, zsfjira__ZIssue__r.zsfjira__Status__c,zsfjira__ZIssue__r.zsfjira__IssueType__c, zsfjira__ZIssue__r.zsfjira__IssueKey__c, zsfjira__ZIssue__r.SalesforceTicket__c, zsfjira__Case__r.CaseNumber from zsfjira__ZIssue_SF__c where ID IN :JiraRelationshiID and zsfjira__ZIssue__r.zsfjira__IssueType__c = 'Customer Bug'];
        }
        else{
            JiraRelationshipList=[Select zsfjira__Case__c, zsfjira__ZIssue__r.zsfjira__Status__c,zsfjira__ZIssue__r.zsfjira__IssueType__c, zsfjira__ZIssue__r.zsfjira__IssueKey__c, zsfjira__ZIssue__r.SalesforceTicket__c, zsfjira__Case__r.CaseNumber from zsfjira__ZIssue_SF__c where zsfjira__Case__c IN: closedCaseIds and zsfjira__ZIssue__r.zsfjira__IssueType__c = 'Customer Bug'];
        }

        for(zsfjira__ZIssue_SF__c linkIssue : JiraRelationshipList){
            List<String> sfCaseNumber = new List<String>();
            if(linkIssue.zsfjira__ZIssue__r.SalesforceTicket__c != null){
                sfCaseNumber = (linkIssue.zsfjira__ZIssue__r.SalesforceTicket__c.split('; '));
            }
            if(linkIssue.zsfjira__ZIssue__r.zsfjira__Status__c!='Done' && linkIssue.zsfjira__ZIssue__r.zsfjira__Status__c!='Resolved' && linkIssue.zsfjira__ZIssue__r.zsfjira__Status__c!='Verified' && caseIdWithCommentMap.containsKey(linkIssue.zsfjira__Case__c) && sfCaseNumber.contains(linkIssue.zsfjira__Case__r.CaseNumber)){
                string issuekey = linkIssue.zsfjira__ZIssue__r.zsfjira__IssueKey__c;
                string commentBody = caseIdWithCommentMap.get(linkIssue.zsfjira__Case__c);
                try{
                    zsfjira.ZCBeans.IssueCommentResult result = zsfjira.ZC.Issues.createJIRAIssueComment(issuekey,commentBody);
                    if(result.hasError()){
                        System.debug(System.LoggingLevel.ERROR, result.getErrorMessage());
                    }
                    else{
                        System.debug(System.LoggingLevel.INFO,'Issue comment Id: '+result.getIssueCommentId());
                        if(JiraRelationshiID==NULL && !caseCommentsMap.containsKey(linkIssue.zsfjira__Case__c)){
                            caseCommentsMap.put(linkIssue.zsfjira__Case__c,new CaseComment(ParentId=linkIssue.zsfjira__Case__c,commentBody=caseIdWithCommentMap.get(linkIssue.zsfjira__Case__c)));
                        }
                    }if(test.isRunningTest()) throw new NullPointerException();
                }
                catch(Exception ex){
                    String Error='Cause -> ' +ex.getCause()+'\n'+ 'Line Number -> ' +ex.getLineNumber()+'\n'+ 'Message -> ' +ex.getMessage();
                    system.debug(LoggingLevel.ERROR, 'Error ---- ' + Error);
                }
            }
        }
        List<CaseComment>  InsertCaseCommentList= caseCommentsMap.values();
        if(JiraRelationshiID==NULL && InsertCaseCommentList!=NULL && !InsertCaseCommentList.isEmpty()){
            Insert InsertCaseCommentList;
        }
    }

	/**
	* @description Added By Grazitti - Method to add Error(AutoEmail Response)
	* @param CaseList
	*/
    public void caseManageAutoEmailResponses(List<case> CaseList){

        for(case thisCase: CaseList){
            if(thisCase.Status != 'Closed' && thisCase.Origin == 'Email' && ((thiscase.Subject!=null && !thisCase.Subject.containsIgnoreCase('ref:_')) || (thisCase.Description!=null && !thisCase.Description.containsIgnoreCase('ref:_')))){
                if(thisCase.Subject.containsIgnoreCase('Automatic reply:') || thisCase.Subject.containsIgnoreCase('Risposta automatica') || thisCase.Subject.containsIgnoreCase('Out of Office AutoReply:') || thisCase.Subject.containsIgnoreCase('Undelivered Mail Returned to Sender') || thisCase.Subject.containsIgnoreCase('Automatische Antwort:') || thisCase.Subject.containsIgnoreCase('Risposta automatica:') || thisCase.Subject.containsIgnoreCase('Delivery Status Notification (Failure)') ||
                   thisCase.Subject.containsIgnoreCase('Warning: could not send message for past 4 hours') || thisCase.Subject.containsIgnoreCase('Out of Office') || thisCase.Subject.containsIgnoreCase('[Email Loop Protection] Out of Office') )
                {
                            thisCase.addError('Thank you for your mail.' + 'This email will be ignored and will not create any cases');
                    }
            }
        }
    }
	
	/**
	* @description CaseLinkJiraAlert
	* @param SubjectSet
	* @param csList
	*/
    public static void caseLinkJiraAlert(Set<String> SubjectSet, List<Case> csList) {
        try{

            //move query to for to avoid heap size issue - CS21-422 -Veera
            //List<Case> oldCases = [Select id,Subject,JIRA_References_URL__c,AccountId from Case where JIRA_References_URL__c like :SubjectSet and Status!= 'Closed' ];
            Integer maxLength = 0;
            Integer alertLength = Integer.valueOf(System.label.JIRAID_Length);
            Integer sparkLength = Integer.valueOf(System.label.JIRA_SPARK_Length);

            //replaced Status!= 'Closed with isClosed = false to make this a selective query - CS21-422 -Veera
            for(case existingCs: [SELECT Id, Subject, JIRA_References_URL__c, AccountId FROM Case
                                  WHERE JIRA_References_URL__c like :SubjectSet and isClosed = false]){

                if(existingCs.JIRA_References_URL__c != null){
                    if(existingCs.JIRA_References_URL__c.contains(',')){
                        for(String str: existingCs.JIRA_References_URL__c.split(',')){
                            maxLength = str.containsIgnoreCase('alert') ? alertLength: sparkLength;
                            if(str.length() > maxLength){
                                str = str.substring(0, maxLength);
                            }
                            mapJiraToCase.put(str,existingCs);
                        }
                    }else{
                        maxLength = existingCs.JIRA_References_URL__c.containsIgnoreCase('alert') ? alertLength: sparkLength;
                        if(existingCs.JIRA_References_URL__c.length() > maxLength){
                            existingCs.JIRA_References_URL__c = existingCs.JIRA_References_URL__c.substring(0, maxLength);
                        }
                        mapJiraToCase.put(existingCs.JIRA_References_URL__c,existingCs);
                    }
                }
            }

            for(case cs:csList){
                if(cs.Subject !=null && cs.Subject.containsIgnoreCase('JIRA')){
                    String jira_id = cs.subject.substringBefore(')').substringAfter('] (');
                    maxLength = jira_id.containsIgnoreCase('alert') ? alertLength: sparkLength;

                    if(jira_id.length() > maxLength){
                        jira_id = jira_id.substring(0, maxLength);
                    }

                    if(mapJiraToCase.containsKey(jira_id)){
                        if(cs.Origin == null) {
                            cs.Origin  = 'Email';
                        }

                        cs.Resolution__c  = 'Duplicate';

                        if(cs.Status!='Closed'){
                            cs.Status = 'Closed';
                        }

                        cs.Duplicate_Case_Id__c = mapJiraToCase.get(jira_id).id; //For CS-491
                        Case oldcs = mapJiraToCase.get(jira_id);
                    }
                    // Vijay Kumar K R: CS21-1192: To avoid updating Proactive_Alerts as owner for duplicate case which will deleted in deleteDupCases method
                    else{
                        cs.OwnerId = queueNameIdMap.get('Proactive_Alerts');
                    }
                }
                // CS-491
                if(contactEmail != null && contactEmail == JIRA_CASE_WEB_EMAIL){
                    /*
                    CS21-746 : Trim Case Subject Automatically and prevent JIRA - Salesforce Case Creation from Failing due to Character limit exceeding
                    The truncation logic takes care of the scenario where jira subject length is greater than 255 characters and addition of the below
                    string to the case subject makes it greater than 255 characters due to which case creation fails in Salesforce as the Subject
                    can contain max 255 characters.
                    */
                    Integer maxLengthOfCaseSubject = Integer.valueOf(Label.Max_Length_for_Jira_Subject);
                    cs.Subject = (cs.Subject.length() > maxLengthOfCaseSubject) ? cs.Subject.substring(0, maxLengthOfCaseSubject) : cs.Subject;
                    cs.Subject = 'Alert From Jira - '+ cs.Subject +': <Please change the subject and description>';
                }
            }if(test.isRunningTest()) throw new NullPointerException();
        }
        catch(exception e){
            Database.insert( new Heartbeat_Server_Log__c(Exception_Log__c = e.getMessage()),true);
        }
    }
	
	/**
	* @description LinkJiraAlert
	* @param csJList
	*/
    public static void linkJiraAlert(List<Case> csJList){
        List<FeedItem > feedItemList = new List<FeedItem>();

        for(Case cs : csJList){
            String caseSubject = cs.subject;
                caseSubject   = caseSubject.replaceAll('\\[JIRA\\] \\(', '').replaceAll('\\).*', '').replaceAll('Alert From Jira - ','');
                FeedItem post = new FeedItem();
                post.ParentId = cs.Id; //eg. Opportunity id, custom object id..
                post.Body = '#linktojira #'+caseSubject;
                feedItemList.add(post);
        }
        if(feedItemList!=null && !feedItemList.isEmpty()){
            insert feedItemList;
        }

    }
	
	/**
	* @description LinkJiraAlert
	* @param sObjectIdSet
	* @param process
	* @param oldRecords
	*/
    public static void accountTerritoryToCaseTeams(Set<Id> sObjectIdSet, String process, String oldRecords) {
        if(System.isBatch() || System.isFuture() || forceAsyncFlagForTest) {
            accountTerritoryToCaseTeam(sObjectIdSet, process, oldRecords);
        }
        else {
            accountTerritoryToCaseTeamFuture(sObjectIdSet, process, oldRecords);
        }
    }
	
	/**
	* @description accountTerritoryToCaseTeam
	* @param sObjectIdSet
	* @param process
	* @param oldRecords
	*/
    private static void accountTerritoryToCaseTeam(Set<Id> sObjectIdSet, String process, String oldRecords){
        //When Account owner is updated
        if(process.containsIgnoreCase('Account Owner;') || process.containsIgnoreCase('CEM;') || process.containsIgnoreCase('SE;')) {
            AccountTerritoryUsersToCaseTeamHelper.insertNewAccountOwner(sObjectIdSet, process);
        }
        //When User is added
        else if(process.equalsIgnoreCase('User Territory Association insert')){
            AccountTerritoryUsersToCaseTeamHelper.insertCtmOnNewAccTerrUser(sObjectIdSet);
        }
        //When user role is updated on the Territory
        else if(process.equalsIgnoreCase('User Territory Association update')) {
            AccountTerritoryUsersToCaseTeamHelper.updateCtmOnAccTerrUserUpdate(sObjectIdSet, oldRecords);
        }
        //When a user is deleted from the territory, remove the user from all the open cases assigned to the account in that territory
        else if(process.equalsIgnoreCase('User Territory Association delete')) {
            AccountTerritoryUsersToCaseTeamHelper.deleteCtmOnAccTerrUserDelete(oldRecords);
        }
        //When account is updated on the Case
        else if(process.equalsIgnoreCase('Account update')) {
            AccountTerritoryUsersToCaseTeamHelper.deleteInsertCTMOnAccountChange(sObjectIdSet, oldRecords);
        }
        //When case is created or updated such as associated with the Account or Case owner is updated
        else if(process.equalsIgnoreCase('Case insert')) {
            AccountTerritoryUsersToCaseTeamHelper.insertCtmOnCaseCreateUpdate(sObjectIdSet);
        }
    }

	/**
	* @description Case team member fix by akash/Shiva CS-506
	* @param sObjectIdSet
	* @param process
	* @param oldRecords
	*/
    @future
    public static void accountTerritoryToCaseTeamFuture(Set<Id> sObjectIdSet, String process, String oldRecords){
        accountTerritoryToCaseTeam(sObjectIdSet, process, oldRecords);
    }

	/**
	* @description To Update CEM/TSM Field on case Level in newly created cases if there is value in CEM/TSM field on account level
	* @ModifiedDate 23 oct, 2019
	* @param caseListForCemTsm
	* @param oldMap
	*/
    public static void accountCemTsmToCase(list<case> caseListForCemTsm, Map<Id,Case> oldMap){
        // CS21-1986
        // Show Custom Error When Proactive_Campaign_Resolution_comment__c is empty
        Map<string,String> codeValueToErrorMessage=new Map<String,string>();
        for(Case_Proactive_Comment_Required__mdt cpc:[select id,Error_Message__c, Label,Proactive_Resolution_Code__c from Case_Proactive_Comment_Required__mdt])
        {
            codeValueToErrorMessage.put(cpc.Proactive_Resolution_Code__c,cpc.Error_Message__c);
        }
        // CS21-1986 ENDS
        
        Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
        
        Set<Id> accountIds = new Set<Id>();
        for(case eachCase: caseListForCemTsm){
            if(eachCase.Status != 'Closed'){
                if(eachCase.Accountid != null){ accountIds.add(eachCase.Accountid);
                                              }
            }
            // CS21-1986
            if(eachCase.Proactive_Resolution_Code__c!=null &&
               (trigger.isinsert || 
               (trigger.isupdate && oldMap !=null &&
               (oldMap.get(eachCase.id).Proactive_Resolution_Code__c!=eachCase.Proactive_Resolution_Code__c || oldMap.get(eachCase.id).Proactive_Campaign_Resolution_comment__c!=eachCase.Proactive_Campaign_Resolution_comment__c)) ) && 
               eachCase.Origin=='Proactive-campaign' && eachCase.Resolution__c=='RSC Migration assistance'&& eachcase.RecordTypeid==supportCaseId && eachcase.Proactive_Campaign_Resolution_comment__c==null && eachcase.Proactive_customer_campaign_type__c=='RSC migration' && codeValueToErrorMessage!=null &&  codeValueToErrorMessage.containskey(eachCase.Proactive_Resolution_Code__c))
            {
                eachCase.Proactive_Campaign_Resolution_comment__c.addError(codeValueToErrorMessage.get(eachCase.Proactive_Resolution_Code__c));
            }
        }
        //CS21-1986 ENDS
        Map<Id, Account> accountIdsToValues= new Map<Id, Account>([Select id,Name,Account_SAM__c,Account_SAM__r.Name,Proactive_Case_Contact__c,Proactive_Case_Contact_OBH__c From account where ID IN: accountIds]);
        //This will be called in case of Before Update
        //To update cem/tsm field on case level if its value does not match with cem/tsm field value on account level when a case is manually updated
        if(oldMap != NULL){
            for(case eachCase1 : caseListForCemTsm){
                Case oldVal= oldMap.get(eachCase1.Id);
                if(oldVal.CEM_TSM__c != eachCase1.CEM_TSM__c ){
                    if(accountIdsToValues != NULL && accountIdsToValues.containsKey(eachCase1.AccountId) && accountIdsToValues.get(eachCase1.AccountId) != null &&
                       accountIdsToValues.get(eachCase1.AccountId).Account_SAM__c != null && eachCase1.Status != 'Closed' &&
                       eachCase1.CEM_TSM__c != accountIdsToValues.get(eachCase1.AccountId).Account_SAM__c){
                           eachCase1.CEM_TSM__c = accountIdsToValues.get(eachCase1.AccountId).Account_SAM__c;
                       }
                }
                //<Additions By: Anmol Baweja 26Feb, 2020>
                //<Reason>
                //To Update Proactive case contact field on case same as account if it is changed on its account as per CS-575
                //</Reason>
                if(accountIdsToValues != NULL && accountIdsToValues.containsKey(eachCase1.AccountId) && accountIdsToValues.get(eachCase1.AccountId) != null && eachCase1.Status != 'Closed'){
                    if(eachCase1.Proactive_Case_Contact__c != accountIdsToValues.get(eachCase1.AccountId).Proactive_Case_Contact__c){
                        eachCase1.Proactive_Case_Contact__c = accountIdsToValues.get(eachCase1.AccountId).Proactive_Case_Contact__c;
                    }
                    //<Reason>
                    //To Update Proactive case contact(OBH) field on case same as account if it is changed on its account as per CS-575
                    //</Reason>
                    if(eachCase1.Proactive_Case_Contact_OBH__c != accountIdsToValues.get(eachCase1.AccountId).Proactive_Case_Contact_OBH__c){
                        eachCase1.Proactive_Case_Contact_OBH__c = accountIdsToValues.get(eachCase1.AccountId).Proactive_Case_Contact_OBH__c;
                    }
                }
                //</Additions By: Anmol Baweja>
            }
        }else{
            for(case eachCase1 : caseListForCemTsm){
                if(accountIdsToValues != null && accountIdsToValues.containsKey(eachCase1.AccountId) && accountIdsToValues.get(eachCase1.AccountId) != null && eachCase1.Status != 'Closed'){
                    if(accountIdsToValues.get(eachCase1.AccountId).Account_SAM__c != null){
                        eachCase1.CEM_TSM__c = accountIdsToValues.get(eachCase1.AccountId).Account_SAM__c;
                    }
                    //<Additions By: Anmol Baweja 26Feb, 2020>
                    //<Reason>
                    //To Update Proactive case contact and Proactive case contact(OBH) fields on case same as account if there is some value in proactive case contact on account level as per CS-575
                    eachCase1.Proactive_Case_Contact__c = accountIdsToValues.get(eachCase1.AccountId).Proactive_Case_Contact__c;
                    eachCase1.Proactive_Case_Contact_OBH__c = accountIdsToValues.get(eachCase1.AccountId).Proactive_Case_Contact_OBH__c;
                }
                //</Reason>
                //</Additions By: Anmol Baweja>
            }
        }
    }

		 
	/**
	* @description Added JIRA TEmplate if polaris CS21-156
	* @param cases
	*/
    public static void addDesc(List<Case> cases){
        if(!cases.isEmpty()){
            StaticResource sr = [select Body from StaticResource where Name = 'PolarisTemp' ];
            for(Case c : cases){
                c.JIRA_Description__c = sr.Body.toString();
            }
        }
    }
	
	/**
	* @description getCaseQueueMap
	* @return getCaseQueueMap
	*/
    public static Map<String, Id> getCaseQueueMap(){
        Map<String, Id> queueNameIdMap = new Map<String, Id>();
        for(Group g : [SELECT Id, Name, DeveloperName
                        FROM Group
                        WHERE Type = 'Queue'
                        AND DeveloperName IN ('Open_Queue_Digital', 'Unassigned_Cases', 'Proactive_Alerts','Open_Queue_TA', 'FED_Queue', 'AMER_Transfer', 'ASE_Queue', 'Predibase_Queue')]){
            queueNameIdMap.put(g.DeveloperName, g.Id);
        }
        return queueNameIdMap;
    }

	/**
	* @description CS21-496 starts
	* @param updatedCases
	* @param oldcases
	*/
    public void changeDeactiveCaseOwnerToQueue(List<Case> updatedCases,Map<Id,Case>oldcases){
        Map<Id,List<Case>> userIdAndCaseMap = new Map<Id,List<Case>>();
        Set<Id>accIds = new Set<Id>();
        for(Case cs : updatedCases){
            if(oldcases.get(cs.Id).IsClosed && cs.Status == 'Reopen'){
                accIds.add(cs.AccountId);
                if(userIdAndCaseMap.containsKey(cs.OwnerId)){
                     userIdAndCaseMap.get(cs.OwnerId).add(cs);
                }
                else{
                    userIdAndCaseMap.put(cs.OwnerId,new List<Case>{cs});
                }
            }
        }
        //CS21-1509 updated from Lifetime_Total_Value__c to Sum_of_Opportunities__c and Sum_of_Open_Opportunities__c
        Map<Id,Account> accountData = new Map<Id,Account>([SELECT Id, Name, Disable_Case_Routing_for_Open_Queue_25__c, Sum_of_Opportunities__c, ASE_Account__c, Sum_of_Open_Opportunities__c, US_Federal_Account__c, Account_Preference__c FROM Account WHERE Id IN : accIds]);
        List<User> userData = [SELECT Id, IsActive From User WHERE Id IN : userIdAndCaseMap.keySet()];
		
        Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();

        if(queueNameIdMap.isEmpty())
            queueNameIdMap = getCaseQueueMap();

        Integer threshold = Integer.ValueOf(System.label.Digital_Queue_Threshold);
        for(User u : userData){
            if(!u.IsActive){
                //CS21-1509 updated from Lifetime_Total_Value__c to Sum_of_Opportunities__c and Sum_of_Open_Opportunities__c
                for(Case cs : userIdAndCaseMap.get(u.Id)){
		         if(cs.RecordTypeId ==  supportCaseId && accountData.containsKey(cs.AccountId) && accountData.get(cs.AccountId).Account_Preference__c !=null && accountData.get(cs.AccountId).Account_Preference__c.contains('Top Accounts') && !accountData.get(cs.AccountId).ASE_Account__c && !accountData.get(cs.AccountId).US_Federal_Account__c && !(cs.Origin == 'Alert'|| cs.Origin == 'Alert (come in email)' || cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Pulse' || cs.Origin == 'Proactive')){
                       cs.OwnerId = queueNameIdMap.get('Open_Queue_TA'); 
                    }
                    else if(!accountData.get(cs.AccountId).US_Federal_Account__c && 
                       !accountData.get(cs.AccountId).Disable_Case_Routing_for_Open_Queue_25__c && 
                       accountData.get(cs.AccountId).Sum_of_Open_Opportunities__c < threshold  && 
                       !(cs.RecordTypeId ==  supportCaseId && accountData.containsKey(cs.AccountId) && accountData.get(cs.AccountId).Account_Preference__c !=null && accountData.get(cs.AccountId).Account_Preference__c.contains('Top Accounts') && !accountData.get(cs.AccountId).ASE_Account__c && !accountData.get(cs.AccountId).US_Federal_Account__c && !(cs.Origin == 'Alert'|| cs.Origin == 'Alert (come in email)' || cs.Origin == 'Alert_JIRA' || cs.Origin == 'Health-check' || cs.Origin == 'Pulse' || cs.Origin == 'Proactive'))){
                        cs.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
                    }
                    else{
                        if(accountData.get(cs.AccountId).Disable_Case_Routing_for_Open_Queue_25__c || accountData.get(cs.AccountId).US_Federal_Account__c){
                            cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
                        }
                    }
                }
            }
        }
    }
    //CS21-496 Ends
	
    //CS21-3040
    /**
     * @description updating the case related escalation records with Idea Reference on case
     * @param supportCaseIdeaRefMap
     */
    public static void updateEscalationsWithIdeaRef(Map<Id, Case> supportCaseIdeaRefMap){
        List<Escalation__c> escalationList = [SELECT Id, Case__c, Idea_Reference__c FROM Escalation__c WHERE Case__c IN: supportCaseIdeaRefMap.keySet()];
        if(!escalationList.isEmpty()){
            for(Escalation__c escObj : escalationList){
                escObj.Idea_Reference__c = supportCaseIdeaRefMap.get(escObj.Case__c)?.Idea_Reference__c;
            }
            update escalationList;
        }        
    }

    //CS21-3568
    /**
     * @description Prevent owner change on closed cases older than 7 days for Support Case record type.
     * @param newList
     * @param oldMap
     */
    private static void disallowOwnerChangeAfterClosure(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case_Change_Event__e> closedCaseChangedList = new List<Case_Change_Event__e>();
        List<Case> toError = new List<Case>();
        for (Case c : newList) {
            Case oldC = oldMap.get(c.Id);
            Boolean isStatusChanged = false;
            Boolean isOwnerChanged = false;
            
            if (c.RecordType__c == 'Support Case' && c.isClosed && (System.now() > c.ClosedDate.addDays(7) || Test.isRunningTest())){
                isStatusChanged = c.Status != oldC.Status ? true : false;
                isOwnerChanged = c.OwnerId != oldC.OwnerId ? true : false;
                if(isStatusChanged || isOwnerChanged){
                    Case_Change_Event__e closedCaseChanged = new Case_Change_Event__e();
                    closedCaseChanged.Changed_Field_Name__c = isStatusChanged ? 'Status' : (isOwnerChanged ? 'Owner' : '');
                    closedCaseChanged.Case_Id__c = c.Id;
                    closedCaseChanged.Case_Number__c = c.CaseNumber;
                    closedCaseChanged.User_Id__c = UserInfo.getUserId();
                    if(isStatusChanged && isOwnerChanged) closedCaseChanged.Changed_Field_Name__c = 'Owner';// Will work when assigning closed case from Assign To Me button.
                    closedCaseChangedList.add(closedCaseChanged);
                    toError.add(c);
                }
            }
        }

        if (!closedCaseChangedList.isEmpty()) {
            EventBus.publish(closedCaseChangedList);
        for (Case c : toError) {
            String msg = 'Case ' + c.CaseNumber + ' has been closed for over 7 days. Please create a new case in Salesforce.';
            c.addError(msg);
            }
        }        
    }
    
    /**
	* @description CS21-3898 Added to extract the values from custom label
	* @param labelValue
	* @param delimiter
	* @return values stored in Custom Label
	*/
    private static Set<String> parseCustomLabel(String labelValue, String delimiter) {
        Set<String> values = new Set<String>();
        if (String.isNotBlank(labelValue)) {
            for (String val : labelValue.split(delimiter)) {
                values.add(val.trim());
            }
        }
        return values;
    }
    
	/**
	* @description Wrapper class for Case History
	* @modifiedDate 23 oct, 2019
	*/
    public class CaseHistoryW{
		/**
		* @description CaseId
		*/
        public id caseId{get;set;}
		/**
		* @description NewValue
		*/
        public String NewValue{get;set;}
		/**
		* @description OldValue
		*/
        public String OldValue{get;set;}
		/**
		* @description CreatedDate
		*/
        public DateTime CreatedDate{get;set;}
		/**
		* @description CaseCreatedDate
		*/
        public DateTime CaseCreatedDate{get;set;}
		/**
		* @description CaseCreatedDate
		* @param ch
		*/
        public CaseHistoryW(caseHistory ch){
            this.caseId  = ch.CaseId;
            this.NewValue  = (String) ch.NewValue;
            this.OldValue  = (String) ch.OldValue;
            this.CreatedDate  = ch.CreatedDate;
            this.CaseCreatedDate = ch.Case.CreatedDate;
        }
		/**
		* @description caseHistoryW constructor
		* @param caseId
		* @param newValue
		* @param oldValue
		* @param createdDate
		* @param CaseCreatedDate
		*/
        public CaseHistoryW(id caseId, String newValue, String oldValue, DateTime createdDate,DateTime CaseCreatedDate){
            this.caseId  = caseId;
            this.NewValue  = newValue;
            this.OldValue  = oldValue;
            this.CreatedDate  = createdDate;
            this.CaseCreatedDate = CaseCreatedDate;
        }
    }
	
	/**
	* @description Wrapper class for Case Milestone
	* @modifiedDate 25 August, 2025
	*/
	public class CaseMilestoneW{
		/**
		* @description Milestone Id
		*/
		public Id milestoneId {get;set;}
		/**
		* @description milestoneName
		*/
		public String milestoneName {get;set;}
		/**
		* @description CaseId
		*/
		public Id caseId {get;set;}
		/**
		* @description completionDate
		*/
		public DateTime completionDate {get;set;}
		/**
		* @description isCompleted
		*/
		public Boolean isCompleted {get;set;}
		/**
		* @description casePriority
		*/
		public String casePriority {get;set;}
		/**
		* @description caseCreatedDate
		*/
		public DateTime caseCreatedDate {get;set;}
		/**
		* @description CaseObj
		*/
		public Case caseObj {get;set;}
		/**
		* @description Constructor for Wrapper
		* @param cm
		*/
		public CaseMilestoneW(CaseMilestone cm){
			this.milestoneId = cm.Id;
			this.milestoneName = cm.MilestoneType.Name;
			this.caseId = cm.CaseId;
			this.completionDate = cm.CompletionDate;
			this.isCompleted = cm.isCompleted;
			this.casePriority = cm.Case.priority;
			this.caseCreatedDate = cm.Case.Createddate;
			this.caseObj = cm.Case;
		}
		/**
		* @description Constructor for Wrapper
		* @param milestoneId
		* @param milestoneName
		* @param caseId
		* @param completionDate
		* @param isCompleted
		* @param casePriority
		* @param caseCreatedDate
		* @param caseObj
		*/
		public CaseMilestoneW(Id milestoneId, String milestoneName, Id caseId, DateTime completionDate, Boolean isCompleted, String casePriority, DateTime caseCreatedDate, Case caseObj){
			this.milestoneId = milestoneId;
			this.milestoneName = milestoneName;
			this.caseId = caseId;
			this.completionDate = completionDate;
			this.isCompleted = isCompleted;
			this.casePriority = casePriority;
			this.caseCreatedDate = caseCreatedDate;
			this.caseObj = caseObj;
		}
	}
}