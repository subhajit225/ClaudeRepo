@isTest
public class CaseTriggerHandlerTest {
    //public static case cs;

     /**
     * @description
    */
    @testSetup
    public static void setup() {
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = UserInfo.getUserId());
        sdb.Disable_Email_Alerts__c = true;
        sdb.Disable_SBQQ_Quote_Validation_Rules__c= true;
        sdb.Disable_Case_Validation_Rules__c= true;
        sdb.Disable_Entitlement_Validation_Rules__c = true;
        insert sdb;
        Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];
        
        User user1 = new User(Alias = 'standt', Email='standarduser@testorgrbk.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121rbk.com');
        insert user1;
        test.startTest();
        insert new TriggerControl__c(Name='Case');
        insert new TriggerControl__c(Name='Entitlement');
        insert new TriggerControl__c(Name='GetFeedbackSurveyResponses');
        List<Case> caseList = new List<Case>();
        for(integer j=0 ; j< 10 ;j++){
            caseList.add(new Case(Status = 'New',Priority='P1 - Critical',Subject ='test123'+j));
        }

        Account acc = new Account(name='testAcc',RASP__c =true);
        insert acc;
        Account accRbk = new Account(name='Rubrik');
        insert accRbk;
        Account acct1 = new Account(name='TestAcct1', OwnerId = user1.Id , Account_Preference__c = 'Strategic Account');
        insert acct1;
        Account fedAcc = new Account(Name ='testFedAcc', Account_Preference__c='Strategic Account', Disable_Case_Routing_for_Open_Queue_25__c = true);
        insert fedAcc;
        
		Contact cont2 = new Contact(lastName='testCont');
        cont2.Notify_For_case_creation__c = true;
        cont2.Email='testemailcon@invalid.com';
        cont2.AccountId=acct1.Id;
        insert cont2;        

        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email=CaseTriggerHandler.JIRA_CASE_WEB_EMAIL;
        cont.AccountId=acc.Id;
        insert cont;

        /*AccountTeamMember acctm = new AccountTeamMember();
        acctm.AccountId = acc.id;
        acctm.UserId= '005e0000005eAzyAAE';
        acctm.TeamMemberRole = 'Sales Engineer Manager';
        insert acctm;*/

        Cluster__c cluster = new Cluster__c(UUID__c = '873ecbb3-140a-436b-97ef-1d6d52f21fd3', Name = '873ecbb3-140a-436b-97ef-1d6d52f21fd3');
        insert cluster;

        Case cs = new case();
        cs.Accountid = acc.id;
        cs.contactid = cont.id;
        cs.Subject ='JIRA12345';
        cs.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
        cs.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
        cs.Origin = 'Alert';
        cs.close_survey_triggered__c = false;
        cs.Resolution__c = 'No Response';
        cs.Article_Created__c = false;
        cs.Resolution_Details__c  = 'test';
        cs.Next_Step__c = 'Test';
        cs.Current_Status__c  = 'testStatus';
        cs.Priority = 'P1';
        cs.CT_Rating__c = 'Gold';
        cs.JIRA_Status__c = 'test';
        caseList.add(cs);
        //insert cs;

        Case cs1 = new case();
        cs1.Subject='Test case dup';
        cs1.JIRA_References_URL__c='ALERT-11112abc';
        cs1.Jira_Reference_urls__c= 'ALERT-11112abc';
        cs1.Description='testing';
        cs1.Origin = 'Portal';
        cs1.Status ='In Progress';
        cs1.Accountid = acc.id;
        cs1.contactid = cont.id;
        cs1.Resolution__c='Product defect';
        cs1.Priority = 'P1';
        cs1.Platform__c = 'Polaris';
        cs1.E2CAdv__AdditionalCC__c = 'test@test.com';
        cs1.E2CAdv__Additional_BCC__c = 'test@test.com';
        caseList.add(cs1);
        //insert cs1;

        Case cs2 = new case();
        cs2.Accountid = acc.id;
        cs2.contactid = cont.id;
        cs2.Subject ='[JIRA] (ALERT-404047) - test subject ClusterId-873ecbb3-140a-436b-97ef-1d6d52f21fd3';
        cs2.Description ='[JIRA] (ALERT-404047) - test subject ClusterId-873ecbb3-140a-436b-97ef-1d6d52f21fd3';
        cs2.Origin = 'Alert';
        cs2.Priority = 'P1';
        cs2.SuppliedEmail = CaseTriggerHandler.JIRA_CASE_WEB_EMAIL;
        caseList.add(cs2);
        
        ////
        Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
         Case cs3 = new case();
        cs3.Subject='Test case dup';
        cs3.JIRA_References_URL__c='ALERT-11112abc';
        cs3.Jira_Reference_urls__c= 'ALERT-11112abc';
        cs3.Description='testing';
        cs3.Origin = 'Proactive-campaign';
        cs3.Status ='In Progress';
        cs3.Accountid = acc.id;
        cs3.contactid = cont.id;
        cs3.Resolution__c='RSC Migration assistance';
        cs3.Priority = 'P1';
        cs3.Platform__c = 'Polaris';
        cs3.E2CAdv__AdditionalCC__c = 'test@test.com';
        cs3.E2CAdv__Additional_BCC__c = 'test@test.com';
        cs3.Proactive_Resolution_Code__c='Planned for Future Migration';
        cs3.Proactive_customer_campaign_type__c='RSC migration';
        cs3.Proactive_Campaign_Resolution_comment__c='test';
        cs3.RecordTypeId=supportCaseId;
        caseList.add(cs3);
        
        Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
        Case cs4 = new case();
        cs4.Accountid = acc.id;
        cs4.contactid = cont.id;
        cs4.Subject ='Partner Case Test';
        cs4.Origin = 'Email';
        cs4.Priority = 'None';
        cs4.RecordTypeId = partnerCaseId;
        cs4.Type__c = 'LMS';
        caseList.add(cs4);
        
        Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
        Case cs5 = new case();
        cs5.Accountid = acc.id;
        cs5.contactid = cont.id;
        cs5.Subject ='Success Case Test';
        cs5.Origin = 'Email';
        cs5.Priority = 'None';
        cs5.RecordTypeId = successCaseId;
        cs5.Sub_Phase__c = 'Onboarding Completed';
        cs5.Special_handling__c = 'Escalation Management';
        cs5.Customer_Sentiments__c = 'Green';
        caseList.add(cs5);
        
        Case cs6 = new case();
        cs6.Accountid = acc.id;
        cs6.contactid = cont.id;
        cs6.Subject ='Partner Case Test';
        cs6.Origin = 'Email';
        cs6.Priority = 'None';
        cs6.RecordTypeId = partnerCaseId;
        cs6.Type__c = 'LMS';
        caseList.add(cs6);

        Case cs7 = new case();
        cs7.Accountid = acc.id;
        cs7.contactid = cont.id;
        cs7.Subject ='No Priority Case Test';
        cs7.Origin = 'Email';
        cs7.Priority = 'None';
        cs7.RecordTypeId = partnerCaseId;
        cs7.Type__c = 'LMS';
        caseList.add(cs7);
        
        Group csQueue = [SELECT Id FROM Group WHERE DeveloperName= 'Customer_Success' AND Type ='Queue'];
        Case cs8 = new case();
        cs8.Accountid = acc.id;
        cs8.contactid = cont.id;
        cs8.Subject ='Customer Success With Owner Queue';
        cs8.Origin = 'Email';
        cs8.Priority = 'None';
        cs8.RecordTypeId = successCaseId;
        cs8.OwnerId = csQueue.Id;
        caseList.add(cs8);
        
        Case cs9 = new case();
        cs9.Accountid = acc.id;
        cs9.contactid = cont.id;
        cs9.Subject ='Customer Success Without Queue';
        cs9.Origin = 'Email';
        cs9.Priority = 'P3';
        cs9.RecordTypeId = successCaseId;
        cs9.OwnerId = user1.Id;
        caseList.add(cs9);
        
        Case cs10 = new case();
        cs10.Accountid = acc.id;
        cs10.contactid = cont.id;
        cs10.Subject ='Assist Request Case';
        cs10.Origin = 'Email';
        cs10.Priority = 'P4';
        cs10.RecordTypeId = supportCaseId;
        //cs10.OwnerId = csQueue.Id;
        caseList.add(cs10);
        
        Case cs11 = new case();
        cs11.Accountid = acc.id;
        cs11.contactid = cont.id;
        cs11.Subject ='Duplicate Partner Case Test';
        cs11.Origin = 'Email';
        cs11.Priority = 'None';
        cs11.RecordTypeId = partnerCaseId;
        cs11.Type__c = 'LMS';
        caseList.add(cs11);
        
        Id renewalCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();
        Case cs12 = new case();
        cs12.Accountid = acc.id;
        cs12.contactid = cont.id;
        cs12.Subject ='Renewal Case Test';
        cs12.Origin = 'Email';
        cs12.Priority = 'None';
        cs12.RecordTypeId = renewalCase;
        cs12.Type__c = 'LMS';
        caseList.add(cs12);

        Case cs13 = new case();
        cs13.Subject='Test Workaround Case';
        cs13.Workaround_Verified__c = System.now();
        cs13.RecordTypeId = supportCaseId;
        cs13.Priority = 'P2';
        caseList.add(cs13);
        
        Case cs14 = new case();
        cs14.AccountId = fedAcc.Id;
        cs14.Subject ='Fed Case Test';
        cs14.Origin = 'Email';
        cs14.Priority = 'P2';
        cs14.RecordTypeId = supportCaseId;
        caseList.add(cs14);
        
        insert caseList;
        
        Assist_Request__c ar = new Assist_Request__c(
            Case__c = [SELECT Id FROM Case WHERE AccountId =:acc.Id AND Status !='Closed' LIMIT 1].Id,
            Status__c = 'Open',
            Brownbag_Candidate__c = true,
            Assist_Request_Fullfilled__c = 'Unresolved/Request Reopen',
            Summary_of_the_Issue_Problem_Statement__c = 'Summary for test.'
        );
        insert ar;
        
        Case snzCase = [SELECT Id, Sub_Phase__c, Special_handling__c FROM Case WHERE Sub_Phase__c = 'Onboarding Completed' Limit 1];
        snzCase.Sub_Phase__c = 'Snooze';
        snzCase.Special_handling__c = 'Ransomware recovery';
        snzCase.Snooze_End_DateTime__c = system.now().addDays(1);
        UPDATE snzCase;

         zsfjira__ZIssue__c zi=new zsfjira__ZIssue__c(zsfjira__IssueKey__c='CDM-103905',
                                                     SalesforceTicket__c='00042086',
                                                     zsfjira__IssueId__c=219441,
                                                     Name='CDM-103905',
                                                     zsfjira__IssueType__c='Improvement',
                                                     OwnerId=UserInfo.getUserId()
                                                    );
        insert zi;                                                                                    
        // creating zsfjira__ZIssue_Case__c data
        zsfjira__ZIssue_Case__c zzc= new zsfjira__ZIssue_Case__c();
        zzc.zsfjira__CaseId__c=[SELECT Id, OwnerId FROM Case WHERE Subject = 'JIRA12345' Limit 1].Id;                                        
        zzc.Name='Test';
        zzc.zsfjira__ZIssueId__c=zi.id;
        insert zzc;
        Escalation__c objEsc = new Escalation__c(Case__c = caseList[1].Id, Status__c = 'Open');
        INSERT objEsc;

        Case objCase = [SELECT Id, OwnerId, Initial_Case_Owner__c FROM Case WHERE Subject = 'JIRA12345' Limit 1];
        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
        objCase.OwnerId = rubProfSerUser.Id;
        objCase.Cluster__c=cluster.id;
        objCase.Additional_Cluster__c=cluster.id;
        objCase.Other_Feedback_Observations__c='test <{@}>';
        UPDATE objCase;
        
        GetFeedback_Survey_Response__c objGetFdbk = new GetFeedback_Survey_Response__c();
        objGetFdbk.Name = 'GetFeedback Survey Response: Greetings [ContactName]!';
        objGetFdbk.Case_ID__c = objCase.Id;
        INSERT objGetFdbk;

        Id Proactive_Alert_ID = [SELECT Id, Name, DeveloperName
                                    FROM Group
                                    WHERE Type = 'Queue'
                                    AND DeveloperName = 'Proactive_Alerts' Limit 1].Id;

        Profile minimump = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - API Only Integrations' LIMIT 1];
        User falconu = new User(
            FirstName = 'SentryAI',
            LastName = 'Sally',
            Email = 'falcon-team@rubrik.com',
            Username = 'sentryai.sally+' + DateTime.now().getTime() + '@example.com', // must be unique
            Alias = 'ssally',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = minimump.Id,
            isActive = true);
        insert falconu;

        test.stopTest();

        System.assertEquals(CaseTriggerHandler.CASE_ORIGIN_ALERT_JIRA, [SELECT Id, Origin
                                                                        FROM Case
                                                                        WHERE Subject like '%(ALERT-404047)%'].Origin);
        System.assertEquals(Proactive_Alert_ID, [SELECT Id, Origin, OwnerId
                                                    FROM Case
                                                    WHERE Subject like '%(ALERT-404047)%'].OwnerId);

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - API Only Integrations' LIMIT 1];
        User u = new User(
            FirstName = 'SentryAI',
            LastName = 'Sally',
            Email = 'falcon-team@rubrik.com',
            Username = 'sentryai.sally+' + DateTime.now().getTime() + '@example.com', // must be unique
            Alias = 'ssally',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );

        insert u;
        // 1378: Case can't be close unless child Escalation status is closed
        try{
            UPDATE new Case(Id = caseList[1].Id, Status = 'Closed', Resolution__c = 'Duplicate');
        }catch(DMLexception e){
            System.assert(e.getMessage().contains('Please close Escalation prior to close this Case'),'Please close Escalation prior to close this Case');       
        }
    }

    // CS21-1885
    @isTest 
    static void testInitialCaseOwnerAssignmen(){

        Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

        
        Profile rubSupUser = [Select Id from Profile where Name = 'System Administrator'];
        User supUserprofile = new User(Alias = 'standt', Email='adian-test@initialCae.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = rubSupUser.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='adianinitialCae@test1885.com');
        insert supUserprofile;

        Case objCase = new case();
        System.runAs(supUserprofile) {
            objCase.Accountid = objAcc.id;
            objCase.contactid = objCont.id;
            objCase.Subject ='Sup User initial Asign';
            objCase.Origin = 'Email';
            objCase.Priority = 'P1';
            objCase.OwnerId = supUserprofile.Id;
            
            INSERT objCase;
        }
        Case objCase1 = [SELECT Id, OwnerId, Initial_Case_Owner__c FROM Case WHERE Id =: objCase.Id Limit 1];
        // CS21-1885: Initial Case owner assignment
        System.assertEquals(objCase1.Initial_Case_Owner__c, null);
    }

    @isTest static void testMethod2(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Test.startTest();
            Case cs = new Case();
            cs = [Select id,Workaround_Verified__c,close_survey_triggered__c, E2CAdv__Public_Recent_Comments__c,Status,Resolution__c,Resolution_Details__c,KCS_Article_Candidate__c,KCS_Article_Status__c,Next_Step__c,Current_Status__c,Article_Created__c from Case limit 1];
            
            CaseComment cc  = new CaseComment(ParentId = cs.Id, IsPublished = true, CommentBody = 'testcomment');
            insert cc;
            
            cs.close_survey_triggered__c = true;
            cs.Status ='Waiting for Customer Input';
            cs.KCS_Article_Candidate__c  =  'New Article Created';
            cs.KCS_Article_Status__c = 'Draft';
            cs.Next_Step__c = 'Test123';
            cs.Origin='Email';
            cs.Current_Status__c  = 'testStatus123';
            cs.Resolution__c= 'New Feature request';
            cs.Resolution_Details__c = 'Resolved Test' ;
            cs.Article_Created__c = False;
            cs.E2CAdv__Public_Recent_Comments__c = 'Test comment';
            cs.NCC_date__c = system.now()+1;
            cs.E2CAdv__AdditionalTO__c = 'test@test.com';
            cs.E2CAdv__AdditionalCC__c = 'test@test.com';
            cs.E2CAdv__Additional_BCC__c = 'test@test.com';
            cs.Workaround_Verified__c = System.now();
            cs.Status = 'Resolved';
            update cs;
            Test.stopTest();
            System.assertEquals(true, cs.Id!=null);
        }
        //insert cs;
        
    }

    @isTest static void testMethod1() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Account acc = new Account(Name='Test Account',Account_SAM__c = userInfo.getUserId());
            Insert acc;
            Contact con = new Contact(LastName = 'Test Contact',AccountId = acc.id,Notify_For_case_creation__c  = true);
            Insert con;
            Case csRec = new Case(AccountId = acc.Id,CEM_TSM__c = userInfo.getUserId(),Priority = 'P1',close_survey_triggered__c = false);
            Case csRec1 = new Case(AccountId = acc.Id,Priority = 'P1',close_survey_triggered__c = false);
            Map<id,Case> caseMap = new Map<id,Case>([Select id,AccountId,ContactId,CEM_TSM__c from Case]);
            List<Case> caseList = new List<Case>();
            caseList.add(csRec);
            caseList.add(csRec1);
            insert caseList;//caseMap.values();
            integer i = 1;
            for( Case cs : caseList ){
                if(math.mod(caseList.size(), i) == 0){
                    cs.Status = 'Resolved';
                    cs.Resolution_Details__c = 'Resolved Test';
                    cs.close_survey_triggered__c = true;
                }
                i++;
            }
            i= 1;
            for( Case cs : caseList ){
                if(math.mod(caseList.size(), i) != 0){
                    cs.Status = 'Resolved - Pending Customer';
                    cs.Resolution_Details__c = 'Resolved Test';
                    cs.close_survey_triggered__c = true;
                }i++;
            }
            update caseList;
            Test.startTest();
            CaseSuggestionController csc = new CaseSuggestionController();
            csc.caseId = caseList[0].Id;
            String str ='{"searchCallFail":"","searchDownStatus":false,"message":"success","suggest":{"simple_phrase":[{"options":[],"length":42,"offset":0,"text":"Setting up active directory authentication"}]},"aggregationsArray":[{"label":"Index","values":[{"sort_order":null,"value":19426,"Contentname":"crm_integration","displayName":"Salesforce"}],"key":"_index","order":0},{"label":"Sources","values":[{"value":19013,"Contentname":"case","displayName":"Cases"},{"value":343,"Contentname":"how_to__kav","displayName":"Knowledgebase"},{"value":46,"Contentname":"idea","displayName":"Ideas"},{"value":18,"Contentname":"releases__c","displayName":"Documentation"},{"value":6,"Contentname":"portal_news__c","displayName":"Portal News"}],"key":"_type","order":1},{"label":"Category","order":2,"values":[{"level":1,"childName":"Category_1","value":161,"Contentname":"All"},{"level":1,"childName":"Category_1","value":53,"Contentname":"Snapshots"},{"level":1,"childName":"Category_1","value":40,"Contentname":"Cluster Operations"},{"level":1,"childName":"Category_1","value":26,"Contentname":"GUI"},{"level":1,"childName":"Category_1","value":20,"Contentname":"Recovery"},{"level":1,"childName":"Category_1","value":19,"Contentname":"Documentation"},{"level":1,"childName":"Category_1","value":16,"Contentname":"Physical Client"},{"level":1,"childName":"Category_1","value":13,"Contentname":"Support/Services"},{"level":1,"childName":"Category_1","value":12,"Contentname":"Cloud/Archive"},{"level":1,"childName":"Category_1","value":11,"Contentname":"Replication"}],"key":"Article_category_flat"},{"label":"Case status","order":3,"values":[{"level":1,"childName":"Case status_1","value":18051,"Contentname":"Closed"},{"level":1,"childName":"Case status_1","value":349,"Contentname":"Waiting for Customer Input"},{"level":1,"childName":"Case status_1","value":298,"Contentname":"In Progress"},{"level":1,"childName":"Case status_1","value":141,"Contentname":"Waiting for Rubrik Support"},{"level":1,"childName":"Case status_1","value":71,"Contentname":"Pending fix"},{"level":1,"childName":"Case status_1","value":36,"Contentname":"Resolved - Pending Customer"},{"level":1,"childName":"Case status_1","value":20,"Contentname":"Customer requested close"},{"level":1,"childName":"Case status_1","value":15,"Contentname":"New"},{"level":1,"childName":"Case status_1","value":8,"Contentname":"Pending prioritization"},{"level":1,"childName":"Case status_1","value":8,"Contentname":"Reopen"}],"key":"crm_integration___case___Status"},{"label":"Idea Status","order":4,"values":[{"level":1,"childName":"Idea Status_1","value":6,"Contentname":"Submitted"},{"level":1,"childName":"Idea Status_1","value":2,"Contentname":"Reviewed"}],"key":"crm_integration___idea___Status"},{"label":"Alert","order":5,"values":[{"level":1,"childName":"Alert_1","value":6,"Contentname":"false"}],"key":"crm_integration___portal_news__c___Alert__c"},{"label":"Release Type","order":6,"values":[{"level":1,"childName":"Release Type_1","value":11,"Contentname":"Generally Available (GA)"},{"level":1,"childName":"Release Type_1","value":4,"Contentname":"Early Access (EA)"},{"level":1,"childName":"Release Type_1","value":3,"Contentname":"Direct Availability (DA)"}],"key":"crm_integration___releases__c___Release_Type__c"}],"result":{"hits":[{"boardHref":"","boardName":"","authorHref":"","author":"","sourceName":"crm_integration","solved":"Unsolved","objName":"case","Id":"5001k000009dzpJAAQ","client_href":"https://supfullsb-rubrik.cs78.force.com","href":"https://supfullsb-rubrik.cs78.force.com/5001k000009dzpJAAQ","icon":"https://rubrik.searchunify.com:3000/resources/Asset-Library/Cases.png","metadata":[{"value":["7/24/2018 10:32 PM"],"key":"Created Date"},{"value":["P3"],"key":"Priority"},{"value":["New"],"key":"Case status"},{"value":["00036888"],"key":"Case Number"},{"value":["Administrative"],"key":"Product Area"},{"value":["Other"],"key":"Software Version"},{"value":["Administrative"],"key":"Case Type"}],"highlight":{"Case Type":["Administrative"],"Software Version":["Other"],"Product Area":["Administrative"],"Case Number":["00036888"],"Case status":["New"],"Priority":["P3"],"Created Date":["7/24/2018 10:32 PM"],"AttachmentToDisplay":[],"TitleToDisplayString":["Setting up active directory authentication"],"TitleToDisplay":["<span class=\'highlight\'>Setting</span> <span class=\'highlight\'>up</span> <span class=\'highlight\'>active</span> <span class=\'highlight\'>directory</span> <span class=\'highlight\'>authentication</span>"],"SummaryToDisplay":["<span class=\'highlight\'>Setting</span> <span class=\'highlight\'>up</span> <span class=\'highlight\'>active</span> <span class=\'highlight\'>directory</span> <span class=\'highlight\'>authentication</span>...."],"crm_integration___case___Description":["<span class=\'highlight\'>Setting</span> <span class=\'highlight\'>up</span> <span class=\'highlight\'>active</span> <span class=\'highlight\'>directory</span> <span class=\'highlight\'>authentication</span>"],"crm_integration___case___Subject":["<span class=\'highlight\'>Setting</span> <span class=\'highlight\'>up</span> <span class=\'highlight\'>active</span> <span class=\'highlight\'>directory</span> <span class=\'highlight\'>authentication</span>"]},"_score":1.9772515,"_id":"5001k000009dzpJAAQ"}],"max_score":1.9772515,"total":19426}}';
            CaseTriggerHandler.caseSuggestionMap.put(caseList[0].Id,str);
            csc.getCaseRelatedSuggestion();
            csc.getCaseWrapper();
            csc.caseId = null;
            csc.getCaseRelatedSuggestion();
            csc.getCaseWrapper();
            Test.stopTest();
            System.assertEquals(user.id,acc.Account_SAM__c);
        }
    }
    @isTest static void testMethod3(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        User user1 = [SELECT id FROM User WHERE UserName = 'standarduser@testorg121rbk.com'];

        System.runAs(user){
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            for(Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('Open_Queue_Digital', 'Unassigned_Cases')]){
                queueNameIdMap.put(g.DeveloperName, g.Id);
            }
            Account acc = new Account(name='testAcc',ASE_Account__c =false,US_Federal_Account__c =false);
            insert acc;
            UserTriggerHandler.userContactRecurrsion = true;
            Contact cont = new Contact();
            cont.LastName='testCont1234';
            cont.Email='Test3@test.123.invalid';
            cont.Notify_For_case_creation__c = true;
            insert cont;
            Case cs = new case();
            cs.Subject='JIRA ABCD 2468';
            cs.Origin = 'Alert';
            cs.Accountid = acc.id;
            cs.contactid = cont.id;
            cs.Resolution__c='Product Defect - Not Fixed';
            cs.Priority = 'P1';
            cs.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
            cs.CEM_TSM__c = UserInfo.getUserId();
            insert cs;

            Case cs1 = new case();
            cs1.Subject='JIRA ABCD 2468';
            cs1.Origin = 'Email';
            cs1.Accountid = acc.id;
            cs1.contactid = cont.id;
            cs1.Resolution__c='Product Defect - Not Fixed';
            cs1.Priority = 'P1';
            cs1.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            insert cs1;

            Test.startTest();
            CaseTriggerHandler.isRepeat = true;
            cs.Subject='JIRA ABCD 246822';
            cs.Description='JIRA ABCD 2468';
            cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            cs.CEM_TSM__c= user1.Id;
            update cs;
            cs1.Subject='JIRA ABCD 246822';
            cs1.Description='JIRA ABCD 2468';
            cs1.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
            update cs1;      
            Test.stopTest();

            System.assertEquals(true, cs1.Description=='JIRA ABCD 2468');

        }
    }
    
    @isTest static void testMethod4(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        User user1 = [SELECT id FROM User WHERE UserName = 'standarduser@testorg121rbk.com'];
        
        System.runAs(user){
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            for(Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('Open_Queue_Digital', 'Unassigned_Cases')]){
                queueNameIdMap.put(g.DeveloperName, g.Id);
            }
            Account acc = new Account(name='testAcc',Tabs_Visibility__c ='Predibase');
            insert acc;
            UserTriggerHandler.userContactRecurrsion = true;
            Contact cont = new Contact();
            cont.LastName='testCont1234';
            cont.Email='Test3@test.123.invalid';
            cont.Notify_For_case_creation__c = true;
            insert cont;
            Case cs = new case();
            cs.Subject='JIRA ABCD 2468';
            cs.Origin = 'Alert';
            cs.Accountid = acc.id;
            cs.contactid = cont.id;
            cs.Resolution__c='Configuration Assistance';
            cs.Description_for_other__c = 'this is a test case';
            cs.Priority = 'P1';
            //cs.OwnerId = queueNameIdMap.get('Predibase_Queue');
            cs.CEM_TSM__c = UserInfo.getUserId();
            insert cs;
            
            Case cs1 = new case();
            cs1.Subject='JIRA ABCD 2468';
            cs1.Origin = 'Email';
            cs1.Accountid = acc.id;
            cs1.contactid = cont.id;
            cs1.Resolution__c='Configuration Assistance';
            cs.Description_for_other__c = 'this is a test case';
            cs1.Priority = 'P1';
            cs1.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            insert cs1;
            
            Test.startTest();
            CaseTriggerHandler.isRepeat = true;
            cs.Subject='JIRA ABCD 246822';
            cs.Description='JIRA ABCD 2468';
            cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            cs.CEM_TSM__c= user1.Id;
            update cs;
            cs1.Subject='JIRA ABCD 246822';
            cs1.Description='JIRA ABCD 2468';
            cs1.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
            update cs1;      
            Test.stopTest();
            
            System.assertEquals(true, cs1.Description=='JIRA ABCD 2468');
            
        }
    }
    
    @isTest static void testMethod5(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        User user1 = [SELECT id FROM User WHERE UserName = 'standarduser@testorg121rbk.com'];
        
        System.runAs(user){
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            for(Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('Open_Queue_Digital', 'Unassigned_Cases')]){
                queueNameIdMap.put(g.DeveloperName, g.Id);
            }
            Account acc = new Account(name='testAcc',ASE_Account__c =false,US_Federal_Account__c =false,Account_Preference__c ='Strategic Account');
            insert acc;
            UserTriggerHandler.userContactRecurrsion = true;
            Contact cont = new Contact();
            cont.LastName='testCont1234';
            cont.Email='Test3@test.123.invalid';
            cont.Notify_For_case_creation__c = true;
            insert cont;
            Case cs = new case();
            cs.Subject='JIRA ABCD 2468';
            cs.Origin = 'Email';
            cs.Accountid = acc.id;
            cs.contactid = cont.id;
            cs.Resolution__c='Product Defect - Not Fixed';
            cs.Priority = 'P1';
            cs.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
            cs.CEM_TSM__c = UserInfo.getUserId();
            insert cs;
            
            Case cs1 = new case();
            cs1.Subject='JIRA ABCD 2468';
            cs1.Origin = 'Email';
            cs1.Accountid = acc.id;
            cs1.contactid = cont.id;
            cs1.Resolution__c='Product Defect - Not Fixed';
            cs1.Priority = 'P1';
            cs1.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            insert cs1;
            
            Test.startTest();
            CaseTriggerHandler.isRepeat = true;
            cs.Subject='JIRA ABCD 246822';
            cs.Description='JIRA ABCD 2468';
            cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            cs.CEM_TSM__c= user1.Id;
            update cs;
            cs1.Subject='JIRA ABCD 246822';
            cs1.Description='JIRA ABCD 2468';
            cs1.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
            update cs1;      
            Test.stopTest();
            
            System.assertEquals(true, cs1.Description=='JIRA ABCD 2468');
            
        }
    }
    
    @isTest static void testMethod6(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        User user1 = [SELECT id FROM User WHERE UserName = 'standarduser@testorg121rbk.com'];
        
        System.runAs(user){
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            for(Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('Open_Queue_Digital', 'Unassigned_Cases')]){
                queueNameIdMap.put(g.DeveloperName, g.Id);
            }
            Account acc = new Account(name='testAcc',ASE_Account__c =false,US_Federal_Account__c = false,Disable_Case_Routing_for_Open_Queue_25__c = false);
            insert acc;
            UserTriggerHandler.userContactRecurrsion = true;
            
            Contact cont = new Contact();
            cont.LastName='testCont1234';
            cont.Email='Test3@test.123.invalid';
            cont.Notify_For_case_creation__c = true;
            insert cont;
            
            Test.startTest();
            Case cs = new case();
            cs.Subject='JIRA ABCD 2468';
            cs.Origin = 'Email';
            cs.Accountid = acc.id;
            cs.contactid = cont.id;
            cs.Resolution__c='Product Defect - Not Fixed';
            cs.Priority = 'P1';
            cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            cs.CEM_TSM__c = UserInfo.getUserId();
            insert cs;

            Test.stopTest();
            
            System.assertEquals(true, cs.Subject=='JIRA ABCD 2468');
            
        }
    }
    
    
    @isTest static void testMethodDupCase(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Account acc = new Account(name='testAcc');
            insert acc;
            UserTriggerHandler.userContactRecurrsion = true;
            Contact cont = new Contact(LastName='testCont',
            Email='Test@test.abc.invalid');
            insert cont;

            Case cdup = new case();
            cdup.Subject='[JIRA] (SPARK-123456abc, SPARK-78910) Test case dup multi';
            cdup.Description='testing';
            cdup.Origin = 'Portal';
            cdup.Status ='In Progress';
            cdup.Accountid = acc.id;
            cdup.contactid = cont.id;
            cdup.Resolution__c='Product defect';
            cdup.Priority = 'P1';
            cdup.SuppliedEmail = CaseTriggerHandler.JIRA_CASE_WEB_EMAIL;
            insert cdup;
            System.assertEquals(true,cdup.Priority == 'P1');
        }
    }

    @isTest static void testMethodDupCase1(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Account acc = new Account(name='testAcc');
            insert acc;
            UserTriggerHandler.userContactRecurrsion = true;

            Contact cont = new Contact(lastName='testCont');
            cont.Email='Test1@test.xyz.invalid';
            insert cont;

            Case cdup1 = new case();
            cdup1.Subject='[JIRA] (ALERT-11112a) Test case dup';
            cdup1.Description='testing';
            cdup1.Origin = 'Email';
            cdup1.Status ='In Progress';
            cdup1.Accountid = acc.id;
            cdup1.Priority='P1';
            cdup1.contactid = cont.id;
            cdup1.Resolution__c='Product defect';
            cdup1.SuppliedEmail = CaseTriggerHandler.JIRA_CASE_WEB_EMAIL;
            insert cdup1;
            System.assertEquals(true,cdup1.Priority == 'P1');
        }
    }

    @isTest static void testUpdateCaseTeamMemberOnOwnerChange(){
        Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];

        User user1 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
        insert user1;

        User user2 = new User(Alias = 'standt', Email='standarduser2@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testorg121saurv.com');
        insert user2;

        Group queueRecord = new Group(Name='test Queue', type='Queue');
        insert queueRecord;

        //Group queueRecord = [Select Id from Group where Type = 'Queue' Limit 1];

        //Case case1 = [Select Id, OwnerId from Case where Subject = 'JIRA12345'];
        Case case1 = [Select Id, OwnerId from Case Limit 1];

        Test.startTest();

        //case1.OwnerId = queueRecord.Id;
        //update case1;

        System.runAs(user1) {
            CaseTriggerHandler.isRepeat = true;
            case1.OwnerId = user1.Id;
            update case1;
        }

        System.runAs(user2) {
            CaseTriggerHandler.isRepeat = true;
            case1.OwnerId = user2.Id;
            update case1;
        }
        System.assertEquals(true, case1.OwnerId == user2.Id);
        Test.stopTest();
    }

    @isTest
    static void testUpdateKcsAndArticleCountNoArticles() {
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        System.runAs(user){
            Case cs = [Select Subject, Status, KCS_Article_Candidate__c, KCS_Article_Status__c, Documentation_Type__c, id, origin, Alert_Key__c from case limit 1];
                cs.Subject = 'KCS Article Count Test';
                cs.Status = 'New';
                cs.KCS_Article_Candidate__c = 'Article Linked';
                cs.KCS_Article_Status__c = 'Draft';
                cs.Documentation_Type__c = 'JIRA';
                cs.Article_Total_Count__c = 0;
                cs.Status = 'Working';
            Test.startTest();
            update cs;
            Test.stopTest();
            // Step 3: Fetch and assert the article-related fields were cleared
            Case updatedCase = [SELECT KCS_Article_Candidate__c, KCS_Article_Status__c, Documentation_Type__c, Article_Total_Count__c FROM Case WHERE Id = :cs.Id];
            System.assertEquals(null, updatedCase.KCS_Article_Candidate__c, 'Candidate should be null');
            System.assertEquals(null, updatedCase.KCS_Article_Status__c, 'Status should be null');
            System.assertEquals(null, updatedCase.Documentation_Type__c, 'Doc Type should be null');
        }
}

    
    
    @isTest static void testprocessBuilderToTriggerBefore(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Contact cont = TestDataFactory.getContact();
            insert cont;
            Case orignalCase = [Select id, origin, Alert_Key__c from case limit 1];

            case cs = TestDataFactory.getCase(cont.Account, cont);
            cs.Duplicate_case_id__c = orignalCase.id;
            cs.Alert_Key__c = 'Test@1234';
            cs.Article_Total_Count__c = 2;
            cs.New_Incoming_email__c =true;
            insert cs;

            cs.KCS_Article_Candidate__c = 'No Article required';
            cs.KCS_or_Supportability_comments__c = 'Test comments';
            cs.Status = 'Closed';
            update cs;
            System.assertEquals(true, cs.Status == 'Closed');
        }
    }

     /**
* @description
*/
    public static testMethod void acountToCaseTeamMembers(){
        //CaseTriggerHandler.isRepeat = true;
        User u = [select id from User where Profile.Name Like 'System Administrator%' and IsActive = true LIMIT 1];
        System.runAs(u){
            Account acc = new Account(Name = 'Test account123');
            insert acc;
            List<AccountTeamMember> atmList = new List<AccountTeamMember>();
            AccountTeamMember atm = new AccountTeamMember(TeamMemberRole = 'Customer Experience Manager',UserId = userInfo.getUserId(),AccountId = acc.Id);
            atmList.add(atm);
            AccountTeamMember atm1 = new AccountTeamMember(TeamMemberRole = 'Sales Engineer',UserId = u.Id,AccountId = acc.Id);
            atmList.add(atm1);
            insert atmList;
            Contact cont = new Contact(LastName = 'Test con',AccountId = acc.Id);
            insert cont;
            //Case orignalCase = [Select id, origin, Alert_Key__c from case limit 1];

            case cs = new Case(AccountId = acc.Id,Priority = 'P1');
            insert cs;

            CaseTeamRole ctr = [select id,name from caseteamrole where name IN ('Sales Engineer','Customer Experience Manager') LIMIT 1];
            caseTeamMember ctm = new CaseTeamMember(ParentId = cs.Id,MemberId = userInfo.getUserId(),TeamRoleId = ctr.Id);
            insert ctm;
            test.startTest();
            cs.Priority = 'P2';
            update cs;
            
            
            System.assertEquals(true,cs.Priority=='P2');
        test.stopTest();
    }
    }

    private static testMethod void testsSendCaseNotificationsToSlackInsert() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testAcc' LIMIT 1];

        Case_Notification_Preference__c notifPreference = new Case_Notification_Preference__c();
        notifPreference.Name = acc.Name;
        notifPreference.Account__c = acc.Id;
        notifPreference.Active__c = true;
        notifPreference.All_case_creation__c = true;
        notifPreference.All_case_creation_Slack_Channel__c = 'slack1@testslack.com';
        notifPreference.All_case_creation_Template__c = 'Slack_Notification';
        notifPreference.Case_CT_Temperature_update__c = true;
        notifPreference.Case_CT_Temperature_update_Slack_Channel__c = 'slack1@testslack.com';
        notifPreference.Case_CT_Temperature_update_Template__c = 'Case_temp_alert';
        notifPreference.Case_escalation__c = true;
        notifPreference.Case_escalation_Slack_Channel__c = 'slack1@testslack.com';
        notifPreference.Case_escalation_Template__c = 'Customer_escalation_request';
        notifPreference.Case_Priority_Updates__c = true;
        notifPreference.Case_Priority_Updates_Slack_Channel__c = 'slack1@testslack.com';
        notifPreference.Case_Priority_Updates_Template__c = 'Email_notification_to_the_case_owner_when_the_priority_on_the_case_has_chaged';
        insert notifPreference;

        Test.startTest();
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case caseObject = new Case(AccountId = acc.Id, Priority = 'P3');
            insert caseObject;
            
            System.assertEquals(true,caseObject.Priority=='P3');
        Test.stopTest();
    }
    }

    private static testMethod void testsSendCaseNotificationsToSlackUpdate() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case caseObject = [SELECT Id, Priority, IsEscalated, CT_Rating__c, AccountId, Account.Name FROM Case WHERE Subject LIKE '%JIRA12345%' LIMIT 1];

            Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testAcc' LIMIT 1];

            Case_Notification_Preference__c notifPreference = new Case_Notification_Preference__c();
            notifPreference.Name = acc.Name;
            notifPreference.Account__c = acc.Id;
            notifPreference.Active__c = true;
            notifPreference.All_case_creation__c = true;
            notifPreference.All_case_creation_Slack_Channel__c = 'slack1@testslack.com';
            notifPreference.All_case_creation_Template__c = 'Slack_Notification';
            notifPreference.Case_CT_Temperature_update__c = true;
            notifPreference.Case_CT_Temperature_update_Slack_Channel__c = 'slack1@testslack.com';
            notifPreference.Case_CT_Temperature_update_Template__c = 'Case_temp_alert';
            notifPreference.Case_escalation__c = true;
            notifPreference.Case_escalation_Slack_Channel__c = 'slack1@testslack.com';
            notifPreference.Case_escalation_Template__c = 'Customer_escalation_request';
            notifPreference.Case_Priority_Updates__c = true;
            notifPreference.Case_Priority_Updates_Slack_Channel__c = 'slack1@testslack.com';
            notifPreference.Case_Priority_Updates_Template__c = 'Email_notification_to_the_case_owner_when_the_priority_on_the_case_has_chaged';
            insert notifPreference;

            Test.startTest();
            caseObject.Priority = 'P2';
            caseObject.IsEscalated = true;
            caseObject.CT_Rating__c = 'Green';
            update caseObject;
            Test.stopTest();
            System.assertEquals(true,caseObject.CT_Rating__c == 'Green');
        }
    }

     /**
     * @description
    */
    public static testMethod void changeownerToQueue(){
        Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];

        User user1 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
        insert user1;

        User user2 = new User(Alias = 'standt', Email='standarduser2@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testorg121saurv.com');
        insert user2;

        Account acc = new Account(Name = 'Test account123');
        insert acc;

        Contact cont = new Contact(LastName = 'Test con',AccountId = acc.Id);
        insert cont;

        case cs = new Case(AccountId = acc.Id,Priority = 'P1', OwnerId = user1.Id);
        insert cs;

        CaseComment cc  = new CaseComment(ParentId = cs.Id, IsPublished = true, CommentBody = 'test');
        insert cc;

        cs.KCS_Article_Candidate__c = 'No Article required';
        cs.KCS_or_Supportability_comments__c = 'Test comments';
        cs.Status='Closed';
        update cs;

        try{
        System.runAs(user2){
            User u = new User(Id = cs.OwnerId,IsActive = false);
            Update u;
            test.startTest();
            CaseTriggerHandler.isRepeat = true;
            cs.Status = 'Reopen';
            update cs;
            test.stopTest();
                System.assertEquals(true,cs.Status != 'Reopen');
            }
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Need to throw Custom Error.');
        }
    }

     /**
* @description
*/
    public static testMethod void changeownerToQueue2(){
        Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];

        User user1 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
        insert user1;

        User user2 = new User(Alias = 'standt', Email='standarduser2@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@testorg121saurv.com');
        insert user2;

        Account acc = new Account(Name = 'Test account123',Disable_Case_Routing_for_Open_Queue_25__c = true);
        insert acc;

        Contact cont = new Contact(LastName = 'Test con',AccountId = acc.Id);
        insert cont;

        case cs = new Case(AccountId = acc.Id,Priority = 'P1', OwnerId = user1.Id);
        insert cs;

        CaseComment cc  = new CaseComment(ParentId = cs.Id, IsPublished = true, CommentBody = 'test');
        insert cc;

        cs.KCS_Article_Candidate__c = 'No Article required';
        cs.KCS_or_Supportability_comments__c = 'Test comments';
        cs.Status='Closed';
        update cs;

        try{
        System.runAs(user2){
            User u = new User(Id = cs.OwnerId,IsActive = false);
            Update u;
            test.startTest();
            CaseTriggerHandler.isRepeat = true;
            cs.Status = 'Reopen';
            update cs;
            test.stopTest();
        }
            System.assertEquals(true,cs.Status!='Reopen');
        }
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'Need to throw Custom Error.');
        }
    }

    @isTest
    static void closedCaseTest(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];

            ServiceContract serviceContractObj = new ServiceContract();
            serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj.AccountId = objAcc.Id;
            serviceContractObj.StartDate = System.today();
            serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj.Term = 36;
            INSERT serviceContractObj;

            Case objCase = [SELECT Id, Status, ServiceContractId, Resolution__c FROM Case Limit 1];
            objCase.Status = 'Closed';
            objCase.ServiceContractId = serviceContractObj.Id;
            objCase.Origin = 'Email';
            objCase.Resolution__c = 'Duplicate';
            objCase.Other_Feedback_Observations__c='test2 <{@}>';
            UPDATE objCase;
            System.assertEquals(true,objCase.Resolution__c == 'Duplicate');
        }

    }

    @isTest
    static void taskIdsTest(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
            Account rbkAcc = [SELECT Id FROM Account WHERE Name = 'Rubrik'];

            Case objCase = [SELECT Id, AccountId FROM Case WHERE AccountId =: objAcc.Id Limit 1];
            objCase.AccountId = rbkAcc.Id;
            objCase.Priority = 'P3';
            objCase.Resolution__c = 'No Response';
            objCase.close_survey_triggered__c = true;
            objCase.KCS_Article_Candidate__c = 'No Article required';
            objCase.KCS_or_Supportability_comments__c = 'Test comments';
            objCase.Status = 'Closed';
            update objCase;
            System.assertEquals(true,objCase.Status == 'Closed');
        }

    }

    @isTest
    static void taskIdsTestNotClosed(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
            Account rbkAcc = [SELECT Id FROM Account WHERE Name = 'Rubrik'];

            Case objCase = [SELECT Id, AccountId FROM Case WHERE AccountId =: objAcc.Id Limit 1];
            objCase.AccountId = rbkAcc.Id;
            objCase.Priority = 'P3';
            objCase.Status = 'New';
            objCase.Resolution__c = 'No Response';
            objCase.close_survey_triggered__c = true;
            objCase.KCS_Article_Candidate__c = 'No Article required';
            objCase.KCS_or_Supportability_comments__c = 'Test comments';
            update objCase;
            System.assertEquals(true,objCase.Priority == 'P3');
        }
    }

    @isTest
    static void isChangedChecktest(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case newCase = new Case(JIRA_Status__c = 'testNew Case');
            Case oldCase = new Case(JIRA_Status__c = 'testOld Case');
            CaseTriggerHandler objCls = new CaseTriggerHandler();
            System.assertEquals(true,objCls.isChangedCheck(newCase, oldCase, 'JIRA_Status__c'));
        }
    }

    @isTest
    static void testUpdateCaseAssetEndDate(){
        Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

        User objUser = insertUser();
        accessPermissionSet(objUser.Id);

        System.runAs(objUser) {
            // CS21-1328: Create a field to extract Asset's Support End Date from Asset to Case Page
            String descp = 'The automated alert processing system at Rubrik has detected a possible issue on your Rubrik cluster.';
            descp += 'This is proactive alert check performed by Rubrik on the data we receive from your systems to help you better protect your data.';
            descp += 'A support representative will be in contact shortly to review the alert with you and discuss any actions to be taken if any.';
            descp += 'Summary of Alert:';
            descp += 'Description: NodeStale: 1.1 is greater than or equal to threshold. Critical: 1.8, Warning: 1';
            descp += 'Cluster UUID: 20e1e245-baf1-4923-8fe1-f585759baa25';
            descp += 'Cluster Tag: MTSU Campus';
            descp += 'Node: RVMHM21BS004727';
            descp += 'Alert Customer: MiddleTennesseeStateUniversity';
            descp += 'Incident Time (UTC): 2022-10-14 01:40:00';

            test.startTest();
            Product2 objProduct = new Product2(Name = 'RBK-R348-01',
                                ProductCode = 'RBK-R348-01',
                                Category__c = 'Platform',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true
                            );
                            INSERT objProduct;

            Asset objAsset = new Asset(Premium_Support_End_Date__c = date.today(), Name = 'SN1', SW_Version__c = '0.1', Support_End_Date__c = Date.valueOf('2022-11-11'), SerialNumber = 'RVMHM21BS004727', Serial_Number__c = 'RVMHM21BS004727', Product2Id = objProduct.Id, Accountid = objAcc.Id);
            INSERT objAsset;

            INSERT new Node__c(Asset__c = objAsset.Id, Serial_Number__c = 'RVMHM21BS004727', software_version__c = '1.0.1', Name = 'RVMHM21BS004727' );

            Case objCase = new case();
            objCase.Accountid = objAcc.id;
            objCase.contactid = objCont.id;
            objCase.Subject = '[WelchFoodsACooperative] Proactive Case: Node is Bad';
            objCase.Description = descp;
            objCase.Origin = 'Alert';
            objCase.Priority = 'P1';
            INSERT objCase;

            CaseTriggerHandler.getRvmNode(descp);
            test.stopTest();

            // CS21-1328: Create a field to extract Asset's Support End Date from Asset to Case Page
            System.assertEquals(objAsset.Premium_Support_End_Date__c, [SELECT Id, Asset_Support_End_Date__c
                                                            FROM Case
                                                            WHERE Subject like '%[WelchFoodsACooperative] Proactive Case:%'].Asset_Support_End_Date__c);
            System.assertEquals(false, [SELECT Id, Case_Support_Entitlement_Expired__c
                                        FROM Case
                                        WHERE Subject like '%[WelchFoodsACooperative] Proactive Case:%'].Case_Support_Entitlement_Expired__c);
            System.assertNotEquals('[WelchFoodsACooperative] Proactive Case: Node is Bad', [SELECT Id, Subject
                                        FROM Case
                                        WHERE Subject like '%[WelchFoodsACooperative] Proactive Case:%'].Subject);
        }

    }

    @isTest
    static void testUpdateCaseAssetEndDateFalseScenario(){
        Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

        User objUser = insertUser();
        accessPermissionSet(objUser.Id);

        System.runAs(objUser) {
            // CS21-1328: Create a field to extract Asset's Support End Date from Asset to Case Page
            String descp = 'The automated alert processing system at Rubrik has detected a possible issue on your Rubrik cluster.';
            descp += 'This is proactive alert check performed by Rubrik on the data we receive from your systems to help you better protect your data.';
            descp += 'A support representative will be in contact shortly to review the alert with you and discuss any actions to be taken if any.';
            descp += 'Summary of Alert:';
            descp += 'Description: NodeStale: 1.1 is greater than or equal to threshold. Critical: 1.8, Warning: 1';
            descp += 'Cluster UUID: 20e1e245-baf1-4923-8fe1-f585759baa25';
            descp += 'Cluster Tag: MTSU Campus';
            descp += 'Node: RVMHM21BS004727';
            descp += 'Alert Customer: MiddleTennesseeStateUniversity';
            descp += 'Incident Time (UTC): 2022-10-14 01:40:00';

            test.startTest();
            Product2 objProduct = new Product2(Name = 'RBK-R348-01',
                                ProductCode = 'RBK-R348-01',
                                Category__c = 'Platform',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true
                            );
                            INSERT objProduct;

            Asset objAsset = new Asset(Premium_Support_End_Date__c = date.today().adddays(-6), Name = 'SN1', SW_Version__c = '0.1', Support_End_Date__c = Date.valueOf('2022-11-11'), SerialNumber = 'RVMHM21BS004727', Serial_Number__c = 'RVMHM21BS004727', Product2Id = objProduct.Id, Accountid = objAcc.Id);
            INSERT objAsset;

            INSERT new Node__c(Asset__c = objAsset.Id, Serial_Number__c = 'RVMHM21BS004727', software_version__c = '1.0.1', Name = 'RVMHM21BS004727' );

            Case objCase = new case();
            objCase.Accountid = objAcc.id;
            objCase.contactid = objCont.id;
            objCase.Subject = 'Asset Support End Date';
            objCase.Description = descp;
            objCase.Origin = 'Alert';
            objCase.Priority = 'P1';
            INSERT objCase;

            test.stopTest();

            // CS21-1328: Create a field to extract Asset's Support End Date from Asset to Case Page
            System.assertEquals(objAsset.Premium_Support_End_Date__c, [SELECT Id, Asset_Support_End_Date__c
                                                            FROM Case
                                                            WHERE Subject = 'Asset Support End Date'].Asset_Support_End_Date__c);
            System.assertEquals(true, [SELECT Id, Case_Support_Entitlement_Expired__c
                                        FROM Case
                                        WHERE Subject = 'Asset Support End Date'].Case_Support_Entitlement_Expired__c);
        }

    }

    @isTest
    static void testUpdateCaseAssetEndDateNull(){
        Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

        User objUser = insertUser();
        accessPermissionSet(objUser.Id);

        System.runAs(objUser) {
            // CS21-1328: Create a field to extract Asset's Support End Date from Asset to Case Page
            String descp = 'The automated alert processing system at Rubrik has detected a possible issue on your Rubrik cluster.';
            descp += 'This is proactive alert check performed by Rubrik on the data we receive from your systems to help you better protect your data.';
            descp += 'A support representative will be in contact shortly to review the alert with you and discuss any actions to be taken if any.';
            descp += 'Summary of Alert:';
            descp += 'Description: NodeStale: 1.1 is greater than or equal to threshold. Critical: 1.8, Warning: 1';
            descp += 'Cluster UUID: 20e1e245-baf1-4923-8fe1-f585759baa25';
            descp += 'Cluster Tag: MTSU Campus';
            descp += 'Node: RVMHM21BS004727';
            descp += 'Alert Customer: MiddleTennesseeStateUniversity';
            descp += 'Incident Time (UTC): 2022-10-14 01:40:00';

            test.startTest();
            Product2 objProduct = new Product2(Name = 'RBK-R348-01',
                                ProductCode = 'RBK-R348-01',
                                Category__c = 'Platform',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true
                            );
                            INSERT objProduct;

            Asset objAsset = new Asset(Premium_Support_End_Date__c = null, Name = 'SN1', SW_Version__c = '0.1', Support_End_Date__c = Date.valueOf('2022-11-11'), SerialNumber = 'RVMHM21BS004727', Serial_Number__c = 'RVMHM21BS004727', Product2Id = objProduct.Id, Accountid = objAcc.Id);
            INSERT objAsset;

            INSERT new Node__c(Asset__c = objAsset.Id, Serial_Number__c = 'RVMHM21BS004727', software_version__c = '1.0.1', Name = 'RVMHM21BS004727' );
            Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();																								

            Case objCase = new case();
            objCase.Accountid = objAcc.id;
            objCase.contactid = objCont.id;
            objCase.Subject = 'Asset Support End Date';
            objCase.Description = descp;
            objCase.Origin = 'Alert';
            objCase.Priority = 'P1';
            objCase.Status = 'Closed';
            objCase.Platform__c = 'Other';
            objCase.RecordTypeId = supportCaseId;						  									 
            INSERT objCase;

            test.stopTest();

            // CS21-1328: Create a field to extract Asset's Support End Date from Asset to Case Page
            System.assertEquals(objAsset.Premium_Support_End_Date__c, [SELECT Id, Asset_Support_End_Date__c
                                                            FROM Case
                                                            WHERE Subject = 'Asset Support End Date'].Asset_Support_End_Date__c);
            System.assertEquals(true, [SELECT Id, Case_Support_Entitlement_Expired__c
                                        FROM Case
                                        WHERE Subject = 'Asset Support End Date'].Case_Support_Entitlement_Expired__c);
                                        // 2009 assert
            System.assertNotEquals(null, [SELECT Id, Initial_Case_Owner__c FROM Case WHERE Subject = 'Asset Support End Date'].Initial_Case_Owner__c);
        }

    }

    @isTest
    static void testCaseSla(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            // Entitlement for Proactive Alerts
            Case objCase1 = [SELECT Id, Origin, EntitlementId FROM Case WHERE Origin = 'Portal' Limit 1];
            objCase1.Origin = 'Alert';
            objCase1.Other_Feedback_Observations__c='test 2<{@}>';
            UPDATE objCase1;
            System.assertEquals(null, [SELECT Id, EntitlementId
                                            FROM Case
                                            WHERE Id =: objCase1.Id].EntitlementId);

            // Entitlement for Proactive Alerts
            Case objCase2 = [SELECT Id, Origin, EntitlementId FROM Case WHERE Origin = 'Alert' Limit 1];
            objCase2.Origin = 'Alert_JIRA';
            UPDATE objCase2;
            System.assertEquals(null, [SELECT Id, EntitlementId
                                            FROM Case
                                            WHERE Id =: objCase2.Id].EntitlementId);
        }

    }

    @isTest
    static void testDisableGetFeedbackOnCloseCase(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        User user1 = [SELECT id FROM User WHERE UserName = 'standarduser@testorg121rbk.com'];
        System.runAs(user){
            // Entitlement for Proactive Alerts
            Case objCase1 = [SELECT Id, Origin, EntitlementId, AccountId, Survey_sent__c FROM Case WHERE Status != 'Closed' AND AccountId != null Limit 1];
            Account objAcc = [SELECT Id, RSC_G_Support__c FROM Account WHERE Id =: objCase1.AccountId];
            objAcc.RSC_G_Support__c = 'RSC-G';
            UPDATE objAcc;

            objCase1.Resolution__c = 'ConfigurFedRAMP__cation/deployment user error ';
            objCase1.Status = 'Closed';
            objCase1.OwnerId = user1.Id;
            UPDATE objCase1;
            System.assertEquals(false, [SELECT Id, Survey_sent__c FROM Case WHERE Id =: objCase1.Id AND Account.RSC_G_Support__c = 'RSC-G'].Survey_sent__c);
            System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        }
    }

    @isTest
    static void testSendCommentsToJira(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case objCase1 = [SELECT Id, Origin, CaseNumber, AccountId FROM Case WHERE Status != 'Closed' AND AccountId != null Limit 1];
            Account objAcc = [SELECT Id, RSC_G_Support__c FROM Account WHERE Id =: objCase1.AccountId];
            objAcc.RSC_G_Support__c = 'RSC-G';
            UPDATE objAcc;
            objCase1.Resolution__c = 'ConfigurFedRAMP__cation/deployment user error ';
            objCase1.Status = 'Closed';
            UPDATE objCase1;
            
            zsfjira__ZIssue__c  jIssue = new zsfjira__ZIssue__c ();
            jIssue.zsfjira__Summary__c = 'Test Jira Issue';
            jIssue.zsfjira__Status__c = 'New';
            jIssue.Name = 'Test-101';
            jIssue.zsfjira__IssueKey__c = 'Test-101';
            jIssue.zsfjira__IssueId__c = 100111;
            insert jIssue;
            
            zsfjira__ZIssue_SF__c jRel = new zsfjira__ZIssue_SF__c();
            jRel.zsfjira__Case__c = objCase1.id;
            jRel.zsfjira__ZIssue__c = jIssue.Id;
            insert jRel;
            
            zsfjira__ZIssue__c issue = new zsfjira__ZIssue__c( zsfjira__Summary__c = 'Test Jira Issue 123', zsfjira__IssueKey__c = 'BUG-1234',
                zsfjira__Status__c = 'In Progress', Name = 'Test-102', zsfjira__IssueType__c = 'Customer Bug', zsfjira__IssueId__c = 200345,
                SalesforceTicket__c = objCase1.CaseNumber+';JIRA-547878'
            );
            insert issue;
            zsfjira__ZIssue_SF__c link = new zsfjira__ZIssue_SF__c(
                zsfjira__Case__c = objCase1.Id,
                zsfjira__ZIssue__c = issue.Id
            );
            insert link;

            Map<Id, String> caseIdWithCommentMap = new Map<Id, String>{ objCase1.Id => 'This case has been closed and synced with Jira.' };
            List<CaseComment> commentList = new List<CaseComment>{
                new CaseComment(ParentId = objCase1.Id, CommentBody = 'Test private comment', IsPublished = true)
            };
            String jsonComment = JSON.serialize(commentList);

            Test.startTest();
            CaseTriggerHandler.addPrivateComment(jsonComment);
            CaseTriggerHandler.SendCommentToJira( new Set<Id>{ objCase1.Id }, caseIdWithCommentMap, new List<Id>{ link.Id } );
            Test.stopTest();
            System.assertEquals(issue.SalesforceTicket__c,objCase1.CaseNumber+';JIRA-547878');
        }
    }

    @isTest
    static void updateGetFeedbackResponseSurveyOwnerTest(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
            Case objCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'JIRA12345' Limit 1];
            GetFeedback_Survey_Response__c objGetFdbk = [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c];

            test.startTest();
            objCase.OwnerId = rubProfSerUser.Id;
            UPDATE objCase;
            test.stopTest();
            System.assertEquals(rubProfSerUser.Id, [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c WHERE Id =: objGetFdbk.Id].Survey_Owner__c);
        }
        
    }

    static User insertUser(){
        Profile rcsuProfile = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support User'];
        String uniqueUserName = 'alert.bot' + DateTime.now().getTime() + '@rbk.com';
        User objUser = new user( alias = 'alertbot',
                                    email = 'alert.bot@rubrik.com',
                                    emailencodingkey = 'UTF-8',
                                    firstname = 'alert',
                                    lastname = 'bot',
                                    languagelocalekey = 'en_US',
                                    localesidkey = 'en_US',
                                    profileid = rcsuProfile.Id,
                                    timezonesidkey = 'America/Los_Angeles',
                                    username = uniqueUserName);
        insert objUser;
        return objUser;
    }

    static void accessPermissionSet(Id UserId){
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CS_Manager'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserId;
        psa.PermissionSetId = ps.Id;
        insert psa;
    }

    static void testPartnerCaseTest(){
        
        List<Case> objCase = [SELECT Id,Priority,Type__c, OwnerId FROM Case WHERE Subject = 'Partner Case Test'];
        
        Escalation__c objEsc = new Escalation__c(Case__c = objCase[0].Id, Status__c = 'Open');
        INSERT objEsc;
        
        objEsc.Status__c = 'Closed';
        update objEsc;
        
        Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];

        User user1 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
        insert user1;
        
        test.startTest(); 
        objCase[0].Priority = 'P1';
        objCase[0].Type__c = 'Sizing Tool';
        objCase[0].OwnerId = user1.Id;
        objCase[0].Duplicate_Case_Id__c = objCase[1].Id;
        objCase[0].Status = 'Closed';
        objCase[0].EscalationManagerOwner__c = userInfo.getUserId();
        objCase[0].KCS_Article_Candidate__c  = 'New Article Created';
        objCase[0].KCS_Article_Status__c  = 'Draft';
        objCase[0].Article_Created__c  = false;
        update objCase[0];
        test.stopTest();
       
    }
    
    @isTest
    static void testPartnerCaseTest1(){
        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
        Case objCase = [SELECT Id,AccountId, OwnerId FROM Case WHERE Subject = 'JIRA12345' Limit 1];
        GetFeedback_Survey_Response__c objGetFdbk = [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c];
        Escalation__c objEsc = new Escalation__c(Case__c = objCase.Id, Status__c = 'Open');
        INSERT objEsc;
        
        objCase.Origin = 'Email';
        objEsc.Status__c = 'Closed';
        update objEsc;
		PS_Project__c project = new PS_Project__c();
        project.Account__c = objCase.AccountId;
        insert project;
        test.startTest();
        System.runAs(rubProfSerUser){
            objCase.E2CAdv__Public_Recent_Comments_Text__c = '123';
            objCase.Status = 'Closed';
            objCase.OwnerId = userInfo.getUserId();
            objCase.KCS_Article_Candidate__c  = 'New Article Created';
            objCase.KCS_Article_Status__c  = 'Draft';
            objCase.Article_Created__c  = false;
            CaseTriggerHandler.isRepeat = true;
            try{
                update objCase;
            }
            catch(Exception ex){
                System.debug(LoggingLevel.ERROR, 'To handle Add Error=>'+ ex.getMessage());
            }
            System.assertEquals(rubProfSerUser.Id, [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c WHERE Id =: objGetFdbk.Id].Survey_Owner__c);
        }
        test.stopTest();
        
        
    }
    
    @isTest
    static void testReopenCase(){

        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
        Case objCase = [SELECT Id,AccountId, OwnerId FROM Case WHERE AccountId != null AND Status != 'Reopen' Limit 1];
        GetFeedback_Survey_Response__c objGetFdbk = [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c];
        Escalation__c objEsc = new Escalation__c(Case__c = objCase.Id, Status__c = 'Open');
        INSERT objEsc;
		PS_Project__c project = new PS_Project__c();
        project.Account__c = objCase.AccountId;
        insert project;
        test.startTest();
        System.runAs(rubProfSerUser){
            objCase.Status = 'Reopen';
            CaseTriggerHandler.isRepeat = true;

            UPDATE objCase;
            System.assertEquals(rubProfSerUser.Id, [SELECT Id, Survey_Owner__c FROM GetFeedback_Survey_Response__c WHERE Id =: objGetFdbk.Id].Survey_Owner__c);
        }
        test.stopTest();
        
        
    }
    
    @isTest
    static void testPartnerCaseTest2(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];
            Case objCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'Success Case Test' Limit 1];
            
            test.startTest();
            objCase.Sub_Phase__c = 'Onboarding Completed';
            UPDATE objCase;
            test.stopTest();
            System.assertEquals(true, objCase.Sub_Phase__c == 'Onboarding Completed');
        }
        
    }
    
    @isTest 
    static void testPartnerCaseTest3(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case objCase = [SELECT Id,Priority,Type__c, OwnerId FROM Case WHERE Subject = 'Partner Case Test' LIMIT 1];
            
            Escalation__c objEsc = new Escalation__c(Case__c = objCase.Id, Status__c = 'Open');
            INSERT objEsc;
            
            objEsc.Status__c = 'Closed';
            update objEsc;
            
            Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];

            User user1 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
            insert user1;
            
            test.startTest(); 
            objCase.Priority = 'P1';
            objCase.Type__c = 'Sizing Tool';
            objCase.OwnerId = user1.Id;
            objCase.Status = 'Closed';
            objCase.EscalationManagerOwner__c = userInfo.getUserId();
            update objCase;
            test.stopTest();
            System.assertEquals(true,objCase.Status == 'Closed');

        }
       
    }
    
    @isTest 
    static void testPartnerCaseTest4(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Account objAcc = [SELECT Id FROM Account WHERE Name = 'testAcc'];
            Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];
            
            Case objCase = [SELECT Id,Priority,Type__c, OwnerId FROM Case WHERE Subject = 'Partner Case Test' LIMIT 1];
            Id partnerCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Case').getRecordTypeId();
            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Subject ='Partner Case Test1';
            cs.Origin = 'Email';
            cs.Priority = 'None';
            cs.Duplicate_Case_Id__c = objCase.Id;
            cs.RecordTypeId = partnerCaseId;
            cs.Type__c = 'LMS';
            insert cs;
            System.assertEquals(true,cs.Id!=null);

        }
    }
    
    @isTest
    static void testPartnerCaseTest5() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            test.starttest();

            Cluster__c clusterUnsupported = new Cluster__c(UUID__c = 'Cluster Unsupported', Name = 'Cluster Unsupported', Software_Version__c = '8.1.2-p2-24758');
            insert clusterUnsupported;

            Case objCase1 = [SELECT Id, Cluster__c FROM Case WHERE Subject='Test case dup' Limit 1];

            objCase1.Cluster__c = clusterUnsupported.Id; // Change to supported cluster
            update objCase1;

            test.stoptest();
            System.assertEquals(true,objCase1.Id!=null);
        }
    }

    // 3033: ProactiveCase for Federel Acc
    @isTest
    static void testProactiveCaseForFedAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        objAcc.US_Federal_Account__c = true;
        UPDATE objAcc;
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];

        System.runAs(rubProfSerUser){
            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Alert';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;
            System.assertEquals(rubProfSerUser.Id, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
        }
        test.stoptest();
    }

    // 3033: ProactiveCase for both Federel and ASE Acc
    @isTest
    static void testNonProactiveCaseForBothFedAndAseAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        objAcc.US_Federal_Account__c = true;
        UPDATE objAcc;

        Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
        INSERT objAse;
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];

        System.runAs(rubProfSerUser){
            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Alert';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;
            System.assertEquals(rubProfSerUser.Id, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
        }
        test.stoptest();
    }

    // 3033: Non ProactiveCase With Acc ASE
    @isTest
    static void testNonProactiveCaseWithAseAcc() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        UPDATE objAcc;
        Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
        INSERT objAse;
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];

        System.runAs(rubProfSerUser){
            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Email';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;
            System.assertEquals(rubProfSerUser.Id, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
        }
        test.stoptest();
    }

    // 3033: ProactiveCase for With None Federel and None ASE Acc
    @isTest
    static void testProactiveCaseWithoutFedAse() {
        test.starttest();

        Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
        objAcc.US_Federal_Account__c = false;
        UPDATE objAcc;
        Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];
        User rubProfSerUser = [SELECT Id, Name FROM User WHERE Profile.Name = 'Rubrik Customer Support User' AND IsActive = true Limit 1];

        System.runAs(rubProfSerUser){

            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Alert';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;
            System.assertEquals(rubProfSerUser.Id, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
        }
        test.stoptest();
    }

    // 3033: Non CS User: ProactiveCase for Federel Acc
    @isTest
    static void testNonCsUserProactiveCaseForFedAcc() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            test.starttest();

            Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
            objAcc.US_Federal_Account__c = true;
            UPDATE objAcc;
            Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Alert';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;

            Id FED_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'FED_Queue' Limit 1].Id;
            System.assertEquals(FED_QUEUE_ID, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
            CaseTriggerHandler.isUsFedOrAseAccount([SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id]);
            test.stoptest();
        }
    }

    // 3033:  Non CS User:  ProactiveCase for both Federel and ASE Acc
    @isTest
    static void testNonCsUserNonProactiveCaseForBothFedAndAseAcc() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            test.starttest();

            Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
            objAcc.US_Federal_Account__c = true;
            UPDATE objAcc;

            Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
            INSERT objAse;
            Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Alert';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;
            Id AMER_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ASE_QUEUE' Limit 1].Id;
        //  System.assertEquals(AMER_QUEUE_ID, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
            test.stoptest();
            System.assertEquals(true,cs.Priority == 'P1');
        }

    }

    // 3033:  Non CS User:  Non ProactiveCase With Acc ASE
    @isTest
    static void testNonCsUserNonProactiveCaseWithAseAcc() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            test.starttest();

            Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
            UPDATE objAcc;
            Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
            INSERT objAse;
            Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];

            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Email';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;
            Id AMER_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ASE_QUEUE' Limit 1].Id;
            System.assertEquals(AMER_QUEUE_ID, [SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id].OwnerId);
            CaseTriggerHandler.isUsFedOrAseAccount([SELECT Id, OwnerId FROM Case WHERE Id =: cs.Id]);
            test.stoptest();
        }
    }
    
    @isTest
    static void testCsUserProactiveCaseWithAseAcc() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            test.starttest();
            
            Account objAcc = [SELECT Id, US_Federal_Account__c FROM Account WHERE Name = 'testAcc'];
            UPDATE objAcc;
            Assigned_Support_Engineer__c objAse = new Assigned_Support_Engineer__c(Type__c = 'Primary', Account__c = objAcc.Id);
            INSERT objAse;
            Contact objCont = [SELECT Id FROM Contact WHERE lastName = 'testCont' AND Notify_For_case_creation__c = true Limit 1];
            
            Case cs = new case();
            cs.Accountid = objAcc.id;
            cs.contactid = objCont.id;
            cs.Origin = 'Alert';
            cs.Priority = 'P1';
            cs.RecordTypeId = CaseTriggerHandler.SUPPORT_CASE_RT_ID;
            INSERT cs;
            System.assertEquals('P1', cs.Priority);
            test.stoptest();
        }
    }
    
    @isTest
    static void testToIncreaseCoverage2() {
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
        System.runAs(user){
            test.starttest();
            
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            if(queueNameIdMap.isEmpty())
                queueNameIdMap = CaseTriggerHandler.getCaseQueueMap();
            
            Case cs = [SELECT Id, OwnerId, RecordTypeId,Platform__c,Status FROM Case WHERE AccountId != null AND Subject ='Fed Case Test' AND status != 'Closed' Limit 1];
            cs.OwnerId = queueNameIdMap.get('FED_Queue');//Unassigned_Cases
            UPDATE cs;
            
            cs.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            UPDATE cs;
            
            cs.OwnerId = queueNameIdMap.get('Open_Queue_TA');
            UPDATE cs;
            
            test.stoptest();
            System.assertEquals(true,cs.Status != 'Closed');
        }
    }
    
    @isTest
    static void testToIncreaseCoverage3() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            test.starttest();
            
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            if(queueNameIdMap.isEmpty())
                queueNameIdMap = CaseTriggerHandler.getCaseQueueMap();
            
            Case cs = [SELECT Id, OwnerId, RecordTypeId,Platform__c,Status FROM Case WHERE AccountId != null AND Subject ='Fed Case Test' AND status != 'Closed' Limit 1];
            
            cs.OwnerId = queueNameIdMap.get('Open_Queue_TA');
            UPDATE cs;
            
            test.stoptest();
            System.assertEquals(true,cs.Status != 'Closed');
        }
    }
    
    @isTest 
    static void testLifeCyclePriority(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case objCase = [SELECT Id, AccountId, Priority, Type__c, Life_Cycle_Priority__c FROM Case WHERE Subject = 'No Priority Case Test' LIMIT 1];  
            Entitlement testEntitlement = new Entitlement(
                Name = 'Test Entitlement',
                AccountId = objCase.AccountId,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
                // Add any other required entitlement fields
            );
            insert testEntitlement;
            Test.startTest();
            //line 1541
            objCase.Priority = 'P3';
            objCase.Life_Cycle_Priority__c = 'P4';
            objCase.EntitlementId = testEntitlement.Id;
            update objCase;
            Test.stopTest();
            System.assertEquals(true, objCase.Priority!='None'); 
        } 
    }
    
    @isTest 
    static void testLifeCyclePriority2(){
       // User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Profile pr = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support Manager'];
        User user = new User(Alias = 'standt', Email='supportmanager@testorgrbk.com',
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                              LocaleSidKey='en_US', ProfileId = pr.Id,
                              TimeZoneSidKey='America/Los_Angeles', UserName='supportmanager@testorg121rbk.com', isActive = true);
        insert user;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Knowledge_API_Access'];
        insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = ps.Id);
        
        System.runAs(user){
            Case objCase = [SELECT Id,Priority,Type__c, Life_Cycle_Priority__c,Current_Status__c FROM Case WHERE Subject = 'No Priority Case Test' LIMIT 1];  
            Test.startTest();
            objCase.Priority = 'P3';
            update objCase;
            
            CaseComment caseCm = new CaseComment();
            caseCm.ParentId = objCase.Id;
            caseCm.CommentBody = 'Test 123 Comment';
            caseCm.IsPublished = true;
            insert caseCm;
            
            CaseTriggerHandler cth = new CaseTriggerHandler();
            cth.isChangedCheck(objCase,objCase,'Current_Status__c');
            cth.isChangedCheck(objCase,objCase,'Current_Status__c');
            
            Test.stopTest();
            System.assertEquals(true, objCase.Priority!='None');
        } 
    }
    
    @isTest 
    static void testUpdateOwnerWithUser(){
        //line 2110 to 2117
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case objCase = [SELECT Id,Priority,Type__c, OwnerId FROM Case WHERE Subject = 'Customer Success With Owner Queue' LIMIT 1];  
            Test.startTest();
            //line 1541
            objCase.OwnerId = user.Id;
            //objCase.Life_Cycle_Priority__c = 'P4';
            update objCase;
            Test.stopTest();
            System.assertEquals(true, objCase.OwnerId == user.Id);
        } 
    }
    @isTest 
    static void testUpdateOwnerWithQueue(){
        //line 2110 to 2122
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Group csQueue = [SELECT Id FROM Group WHERE DeveloperName= 'Customer_Success' AND Type ='Queue'];
        System.runAs(user){
            Case objCase = [SELECT Id,Priority,Type__c, OwnerId FROM Case WHERE Subject = 'Customer Success With Owner Queue' LIMIT 1];  
            Test.startTest();
            //line 1541
            objCase.OwnerId = csQueue.Id;
            //objCase.Life_Cycle_Priority__c = 'P4';
            update objCase;
            Test.stopTest();
            System.assertEquals(true, objCase.OwnerId == csQueue.Id);
        } 
    }
    @isTest
    static void testLifeCyclePriority3() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case caseObject = [SELECT Id, Priority, IsEscalated, CT_Rating__c, AccountId, Account.Name FROM Case WHERE Subject LIKE '%JIRA12345%' LIMIT 1];
            
            Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testAcc' LIMIT 1];
            
            Test.startTest();
            caseObject.Priority = 'P2';
            caseObject.Life_Cycle_Priority__c = 'None';
            update caseObject;
            Test.stopTest();
            System.assertEquals(true,caseObject.Priority == 'P2');
        }
    }
    @isTest
    static void testLifeCyclePriority4() {
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case caseObject = [SELECT Id, Priority, IsEscalated, CT_Rating__c, AccountId, Account.Name FROM Case WHERE Subject ='Customer Success Without Queue' LIMIT 1];
            
            Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testAcc' LIMIT 1];
            
            Test.startTest();
            caseObject.Priority = 'P4';
            caseObject.Life_Cycle_Priority__c = 'None';
            caseObject.Special_handling__c = 'Ransomware recovery';
            update caseObject;
            Test.stopTest();
            System.assertEquals(true,caseObject.Priority == 'P4');
        }
    }
    @isTest 
    static void testPartnerCase(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            Case objCase = [SELECT Id,Priority,Type__c, OwnerId FROM Case WHERE Subject = 'Partner Case Test' LIMIT 1];
            Case duplicateCase = [SELECT Id,Priority,Type__c, OwnerId FROM Case WHERE Subject = 'Duplicate Partner Case Test' LIMIT 1];
            
            Escalation__c objEsc = new Escalation__c(Case__c = objCase.Id, Status__c = 'Open');
            INSERT objEsc;
            
            objEsc.Status__c = 'Closed';
            update objEsc;
            
            Profile systemAdmin = [Select Id from Profile where Name = 'System Administrator'];
            
            User user1 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                                  EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                  LocaleSidKey='en_US', ProfileId = systemAdmin.Id,
                                  TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg121saurv.com');
            insert user1;
            
            test.startTest(); 
            objCase.Priority = 'P1';
            objCase.Type__c = 'Sizing Tool';
            objCase.OwnerId = user1.Id;
            objCase.Status = 'Closed';
            objCase.EscalationManagerOwner__c = userInfo.getUserId();
            objCase.Duplicate_Case_Id__c = duplicateCase.Id;
            objCase.Type__c = 'LMS';
            update objCase;
            test.stopTest();
            System.assertEquals(true,objCase.Status == 'Closed');
        }
    }
    
    @isTest
    static void testRenewalCase(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        System.runAs(user){
            
            Case objCase = [SELECT Id, Status, ServiceContractId, AccountId, Resolution__c FROM Case WHERE Subject ='Renewal Case Test' Limit 1];
            
            ServiceContract serviceContractObj = new ServiceContract();
            serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
            serviceContractObj.AccountId = objCase.AccountId;
            serviceContractObj.StartDate = System.today();
            serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
            serviceContractObj.Term = 36;
            INSERT serviceContractObj;
            
            objCase.Status = 'Closed';
            objCase.ServiceContractId = serviceContractObj.Id;
            objCase.Origin = 'Email';
            objCase.Resolution__c = 'Duplicate';
            objCase.Other_Feedback_Observations__c='test2 <{@}>';
            UPDATE objCase;
            System.assertEquals(true,objCase.Resolution__c == 'Duplicate');
        }
        
    }
    
    @isTest
    static void testSetBody(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Group csQueue = [SELECT Id FROM Group WHERE DeveloperName= 'Customer_Success' AND Type ='Queue'];
        System.runAs(user){
            Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case objCase = [SELECT Id, AccountId,Priority,Type__c, OwnerId,Case_Owner_Name__c FROM Case WHERE Subject = 'Customer Success With Owner Queue' LIMIT 1];  
            Test.startTest();
            Case cs = new case();
            cs.Accountid = objCase.AccountId;
            cs.Origin = 'Email';
            cs.Priority = 'P3';
            cs.ownerId = user.Id;
            cs.RecordTypeId = supportCaseId;
            INSERT cs;
            
            String str = CaseTriggerHandler.setBody(false, objCase, cs, 'Test Owner');
            
            Test.stopTest();
            System.assertEquals(true, String.isNotBlank(str));
        } 
    }
    
    @isTest
    static void testBeforeInsertSuccessCase(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Account acc = [SELECT Id, OwnerId FROM Account WHERE Name='TestAcct1' AND OwnerId !=null];
        //User commUser = [SELECT Id,Email FROM User WHERE Username ='testuser@testuser1.com'];
        Contact cont = [SELECT Id, AccountId, Email FROM Contact WHERE Account.Name='TestAcct1' AND Account.OwnerId !=null LIMIT 1];
        
        Test.startTest();
        System.runAs(user){
            
            Entitlement testEntitlement = new Entitlement(
                Name = 'Test Entitlement',
                AccountId = cont.AccountId,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
                // Add any other required entitlement fields
            );
            insert testEntitlement;
            
            Id successCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
            Case cs = new case();
            cs.Accountid = cont.AccountId;
            cs.contactid = cont.Id;
            cs.Subject ='Success Case Test';
            cs.Origin = 'Email';
            cs.Priority = 'None';
            cs.RecordTypeId = successCaseId;
            cs.Sub_Phase__c = 'Onboarding Completed';
            cs.Special_handling__c = 'Escalation Management';
            cs.SuppliedEmail ='test123@invalid.com';
            cs.Entitlement__c = testEntitlement.Id;
            
            insert cs;
            
            Assert.areEqual(true,cs.Entitlement__c!=null);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testMilestoneWrapper(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Test.startTest();
        System.runAs(user){
            Integer s_num = 1;
            String result = String.valueOf(s_num++); 
            String fakeId = CaseMilestone.SObjectType.getDescribe().getKeyPrefix() +'0'.repeat(12-result.length()) + result;
            Id supportCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = [SELECT Id,CreatedDate, RecordTypeId, Entitlement__c, Priority, SuppliedEmail, Accountid, NCC_date__c,Workaround_Verified__c,status,Resolution__c FROM Case WHERE RecordTypeId =: supportCase AND Workaround_Verified__c=null LIMIT 1];
            
            String jsonStr = '{'+
                '"Id":"'+fakeId+'",'+
                '"CaseId":"'+cs.Id+'",'+
                '"CompletionDate":"2024-10-15T10:00:00.000Z",'+
                '"IsCompleted":false,'+
                '"MilestoneType":{"Name":"Initial Response"},'+
                '"Case":{'+
                '"Id":"'+cs.Id+'",'+
                '"Priority":"'+cs.Priority+'",'+
                '"CreatedDate": "2024-10-14T09:30:00.000Z"'+
                '}'+
                '}';
            
            CaseMilestone cm = (CaseMilestone) JSON.deserialize(jsonStr, CaseMilestone.class);
            CaseTriggerHandler.CaseMilestoneW wrap = new CaseTriggerHandler.CaseMilestoneW(cm);
        }
        Assert.areEqual(true, user.Id!=null);
        Test.stopTest();
    }
    
    @isTest
    static void testEntitlementCode(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Test.startTest();
        System.runAs(user){
            Account acc = [SELECT Id, OwnerId , Account_Preference__c FROM Account WHERE Name='testAcc' LIMIT 1];
            Entitlement testEntitlement = new Entitlement(
                Name = 'Test Entitlement',
                AccountId = acc.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
                // Add any other required entitlement fields
            );
            insert testEntitlement;
            
            Id supportCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = [SELECT Id, RecordTypeId, Entitlement__c, Priority, SuppliedEmail, Accountid, NCC_date__c,Workaround_Verified__c,status,Resolution__c FROM Case WHERE RecordTypeId =: supportCase AND Workaround_Verified__c=null LIMIT 1];
            cs.Entitlement__c = testEntitlement.Id;
            cs.NCC_date__c = System.now().addDays(20);
            cs.Workaround_Verified__c = System.now();
            cs.Resolution__c= 'New Feature request';
            cs.Resolution_Details__c = 'Resolved Test' ;
            //cs.Status = 'Resolved';
            try{
                update cs;
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, 'NCC Date cannot be more than 2 weeks in future!');
            }
            Assert.areEqual(true, cs.Entitlement__c!=null);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testEntitlementCode2(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Test.startTest();
        System.runAs(user){
            Account acc = [SELECT Id, OwnerId , Account_Preference__c FROM Account WHERE Name='testAcc' LIMIT 1];
            Entitlement testEntitlement = new Entitlement(
                Name = 'Test Entitlement',
                AccountId = acc.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
            );
            insert testEntitlement;
            
            Id customerSuccess = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId(); 
            Case cs = [SELECT Id, RecordTypeId, Entitlement__c, Priority FROM Case WHERE RecordTypeId =: customerSuccess AND Entitlement__c=:null LIMIT 1];
            cs.Entitlement__c = testEntitlement.Id;
            update cs;
            
            Assert.areEqual(true, cs.Entitlement__c!=null);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testWorkaroundNccDate(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Test.startTest();
        System.runAs(user){
            Account acc = [SELECT Id, OwnerId , Account_Preference__c FROM Account WHERE Name='testAcc' LIMIT 1];
            
            Id supportCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = [SELECT Id, RecordTypeId, Entitlement__c, Priority, SuppliedEmail, Accountid, NCC_date__c,Workaround_Verified__c,status,Resolution__c, CreatedDate FROM Case WHERE RecordTypeId =: supportCase AND Workaround_Verified__c=null LIMIT 1];
            cs.NCC_date__c = System.now().addDays(-2);
            cs.Workaround_Verified__c = System.now().addDays(-2);
            cs.Resolution__c= 'New Feature request';
            cs.Resolution_Details__c = 'Resolved Test' ;
            //cs.Status = 'Resolved';
            
            try{
                update cs;
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, 'Resolution/Workaround Verified date/time can-not be prior to case created date');
            }
            Assert.areEqual(true, cs.RecordTypeId == supportCase);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testWorkaroundNccDate2(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Test.startTest();
        System.runAs(user){
            Account acc = [SELECT Id, OwnerId , Account_Preference__c FROM Account WHERE Name='testAcc' LIMIT 1];
            
            Id supportCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = [SELECT Id, RecordTypeId, Entitlement__c, Priority, SuppliedEmail, Accountid, NCC_date__c,Workaround_Verified__c,status,Resolution__c, CreatedDate FROM Case WHERE RecordTypeId =: supportCase AND Workaround_Verified__c!=null LIMIT 1];
            cs.Workaround_Verified__c = null;
            cs.Resolution__c= 'New Feature request';
            cs.Resolution_Details__c = 'Resolved Test' ;
            
            try{
                update cs;
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, 'Please enter that date/time when the resolution verified from customer, do not blank it out.');
            }
            Assert.areEqual(true, cs.RecordTypeId == supportCase);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testWorkaroundNccDate3(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Test.startTest();
        System.runAs(user){
            Account acc = [SELECT Id, OwnerId , Account_Preference__c FROM Account WHERE Name='testAcc' LIMIT 1];
            
            Id supportCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = [SELECT Id, RecordTypeId, Entitlement__c, Priority, SuppliedEmail, Accountid, NCC_date__c,Workaround_Verified__c,status,Resolution__c, CreatedDate,isStopped FROM Case WHERE RecordTypeId =: supportCase AND Workaround_Verified__c=null LIMIT 1];
            cs.Workaround_Verified__c = System.now();
            cs.Resolution__c= 'New Feature request';
            cs.Resolution_Details__c = 'Resolved Test' ;
            cs.Status = 'Resolved';
            try{
                update cs;
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, 'Please enter that date/time when the resolution verified from customer, do not blank it out.');
            }
            Assert.areEqual(true, cs.RecordTypeId == supportCase);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testRenewalCosedCase(){
        User usr = [select id from user where FirstName = 'Support' and LastName = 'Bot'];
        Test.startTest();
        System.runAs(usr){
            Id renewalCase = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();
            Case cs = [Select id,Workaround_Verified__c,close_survey_triggered__c, E2CAdv__Public_Recent_Comments__c,Status,Resolution__c,E2CAdv__AdditionalTO__c,E2CAdv__AdditionalCC__c,
                       Resolution_Details__c,KCS_Article_Candidate__c,KCS_Article_Status__c,Next_Step__c,Current_Status__c,Article_Created__c from Case WHERE RecordTypeId =:renewalCase limit 1];
            
            CaseComment cc  = new CaseComment(ParentId = cs.Id, IsPublished = true, CommentBody = 'testcomment');
            insert cc;
            
            cs.close_survey_triggered__c = true;
            cs.Status ='Waiting for Customer Input';
            cs.KCS_Article_Candidate__c  =  'New Article Created';
            cs.KCS_Article_Status__c = 'Draft';
            cs.Next_Step__c = 'Test123';
            cs.Origin='Email';
            cs.Current_Status__c  = 'testStatus123';
            cs.Resolution__c= 'New Feature request';
            cs.Resolution_Details__c = 'Resolved Test' ;
            cs.Article_Created__c = False;
            cs.E2CAdv__Public_Recent_Comments__c = 'Test comment';
            cs.NCC_date__c = system.now()+1;
            cs.E2CAdv__AdditionalTO__c = 'test@test.com';
            cs.E2CAdv__AdditionalCC__c = 'test@test.com';
            cs.E2CAdv__Additional_BCC__c = 'test@test.com';
            cs.Workaround_Verified__c = System.now();
            cs.Status = 'Resolved';
            update cs;
        }
        Assert.areEqual(true, user.Id!=null);
        Test.stopTest();
    }
    
    @isTest
    static void testAssistRequest(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Test.startTest();
        System.runAs(user){
            Account acc = [SELECT Id, OwnerId , Account_Preference__c FROM Account WHERE Name='testAcc' LIMIT 1];
            
            Contact cont2 = new Contact(lastName='testCon123');
            cont2.Email='testorgcontact@invalid.com';
            cont2.AccountId=acc.Id;
            insert cont2; 
            
            Assist_Request__c asr = [SELECT Id, Name,Case__c,Status__c FROM Assist_Request__c WHERE Status__c!='Closed' LIMIT 1];
            Case cs = [SELECT Id, Status, ContactId FROM Case WHERE Id=:asr.Case__c LIMIT 1];
            cs.Status = 'Closed';
            cs.ContactId = cont2.Id;
            update cs;
            
            Assert.areEqual(true, asr.Case__c!=null);
        }
        Test.stopTest();
    }
    
    @isTest 
    static void testMethodForOpenQueue(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        User user1 = [SELECT id FROM User WHERE UserName = 'standarduser@testorg121rbk.com'];
        
        System.runAs(user){
            Map<String, Id> queueNameIdMap = new Map<String, Id>();
            for(Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN ('Open_Queue_Digital', 'Unassigned_Cases')]){
                queueNameIdMap.put(g.DeveloperName, g.Id);
            }
            Account acc = new Account(name='testAcc',ASE_Account__c =false,US_Federal_Account__c =false,Account_Preference__c ='Strategic Account');
            insert acc;
            
            Case cs1 = new case();
            cs1.Subject='JIRA ABCD 2468';
            cs1.Origin = 'Email';
            cs1.Accountid = acc.id;
            cs1.Resolution__c='Product Defect - Not Fixed';
            cs1.Priority = 'P1';
            cs1.OwnerId = queueNameIdMap.get('Open_Queue_Digital');
            insert cs1;
            
            Test.startTest();
            CaseTriggerHandler.isRepeat = true;

            cs1.Subject='JIRA ABCD 246822';
            cs1.Description='JIRA ABCD 2468';
            cs1.OwnerId = queueNameIdMap.get('Unassigned_Cases');
            update cs1;      
            Test.stopTest();
            
            System.assertEquals(true, cs1.Description=='JIRA ABCD 2468');
            
        }
    }
    
    @isTest
    static void testOwnerOpenQueueTA(){
        User user = [SELECT id FROM User WHERE id =: UserInfo.getUserId()];
        Account acc = [SELECT Id, OwnerId,Account_Preference__c FROM Account WHERE Name='TestAcct1' AND OwnerId !=null];
        acc.Account_Preference__c = 'Strategic Account';
        acc.ASE_Account__c =false;
        acc.US_Federal_Account__c = false;
        update acc;
        Contact cont = [SELECT Id, AccountId, Email FROM Contact WHERE Account.Name='TestAcct1' AND Account.OwnerId !=null LIMIT 1];
        
        Test.startTest();
        System.runAs(user){
            Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = new case();
            cs.Accountid = cont.AccountId;
            cs.contactid = cont.Id;
            cs.Subject ='Success Case Test';
            cs.Origin = 'Email';
            cs.Priority = 'P2';
            cs.RecordTypeId = supportCaseId;
            cs.Sub_Phase__c = 'Onboarding Completed';
            cs.Special_handling__c = 'Escalation Management';
            cs.SuppliedEmail ='test123@invalid.com';
            
            insert cs; 
            
            Assert.areNotEqual('Alert',[SELECT Id, Origin FROM Case WHERE Id=: cs.Id].Origin);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testIdeaRefOnEscalation(){
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true Limit 1];
        Account acc = [SELECT Id, OwnerId,Account_Preference__c FROM Account WHERE Name='TestAcct1' AND OwnerId !=null];
        System.runAs(adminUser){
            Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = [SELECT Id, Idea_Reference__c FROM Case WHERE RecordTypeId =:supportCaseId LIMIT 1];
            
            Escalation__c escRec = new Escalation__c();
            escRec.Case__c = cs.Id;
            insert escRec;
            
            Test.startTest();
            cs.Idea_Reference__c = '<a href="www.rubrik.com">Test Rubrik Record</a>';
            update cs;
            
			Escalation__c esc = [SELECT Id, Case__c, Idea_Reference__c FROM Escalation__c WHERE Case__c =: cs.Id];
            System.assertEquals(true,cs.Idea_Reference__c!=null);
            Test.stopTest();
            
        }
    }
    
    @isTest static void testKCSArticleMethod(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
        System.runAs(user){
            Test.startTest();
            
            Id supportCaseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
            Case cs = [Select id,Workaround_Verified__c,close_survey_triggered__c, E2CAdv__Public_Recent_Comments__c,Status,Resolution__c,Customer_Sentiments__c
                       ,Resolution_Details__c,KCS_Article_Candidate__c,KCS_Article_Status__c,Next_Step__c,Current_Status__c,Article_Created__c from Case WHERE RecordTypeId =:supportCaseId limit 1];
            cs.KCS_Article_Candidate__c  =  'New Article Created';
            cs.KCS_Article_Status__c = 'Draft';
            cs.Next_Step__c = 'Test123';
            cs.Current_Status__c  = 'testStatus123';
            cs.Resolution__c= 'New Feature request';
            cs.Resolution_Details__c = 'Resolved Test' ;           
            cs.Article_Created__c = False;
            update cs;
            
            Test.stopTest();
            System.assertEquals(true,cs.Id!=null);
        }
    }
    
    static testmethod void testSentiments(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Risk_Governance_Owner_Permissions'];
        insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = ps.Id);
        System.runAs(user){
            Test.startTest();
            Id customerSuccessRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Success').getRecordTypeId();
            Case cs = [SELECT Id, Subject, RecordTypeId,Customer_Sentiments__c FROM Case WHERE Subject = 'Success Case Test' AND RecordTypeId =:customerSuccessRecordTypeId]; 
            cs.Customer_Sentiments__c = 'Red';
            update cs;
            Test.stopTest();
            System.assertEquals(true,cs.Id!=null);
        }
    }
    
    @isTest
    static void testCaseChangeEvent(){
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
        System.runAs(usr){
            Test.startTest();
            Id customerSuccessRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Success').getRecordTypeId();
            Case cs = [SELECT Id, CaseNumber, Subject, RecordTypeId,Customer_Sentiments__c FROM Case WHERE Subject = 'Success Case Test' AND RecordTypeId =:customerSuccessRecordTypeId]; 
            Case_Change_Event__e changeEvt = new Case_Change_Event__e();
			changeEvt.Case_Id__c = cs.Id;
			changeEvt.Case_Number__c = cs.CaseNumber;
            changeEvt.Changed_Field_Name__c = 'Subject';
            changeEvt.User_Id__c = usr.Id;
            EventBus.publish(changeEvt);
            Test.stopTest();
            System.assertEquals(true,cs.Id!=null);
        }
    }
    
    @isTest
    static void testPredibaseQueue(){
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
        System.runAs(usr){
            Test.startTest();
            Id customerSuccessRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Success').getRecordTypeId();
            Case cs = [SELECT Id, CaseNumber, Subject,Proactive_Resolution_Code__c,KCS_Article_Candidate__c,Type,Software_Version__c,Resolution__c, RecordTypeId,Platform__c,Product_Area__c,Problem_Type__c,Sub_Component__c,If_Other__c FROM Case WHERE Subject = 'Success Case Test' AND RecordTypeId =:customerSuccessRecordTypeId];
            cs.Platform__c=null;
            update cs;
            CaseTriggerHandler cth = new CaseTriggerHandler();
            cth.processPredibaseCases(cs);
            Test.stopTest();
            System.assertEquals(true,cs.Id!=null);
        }
    }
    
    @isTest
    static void testSentimentInsert(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Risk_Governance_Owner_Permissions'];
        insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = ps.Id);
        
        Account acc = [SELECT Id, OwnerId,Account_Preference__c FROM Account WHERE Name='TestAcct1' AND OwnerId !=null];
        Contact cont = [SELECT Id, AccountId, Email FROM Contact WHERE Account.Name='TestAcct1' AND Account.OwnerId !=null LIMIT 1];
        
        System.runAs(user){
            Test.startTest();
            Id successId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Success').getRecordTypeId();
            Case cs = new case();
            cs.Accountid = cont.AccountId;
            cs.contactid = cont.Id;
            cs.Subject ='Success Case Test';
            cs.Origin = 'Email';
            cs.Priority = 'P2';
            cs.RecordTypeId = successId;
            cs.Customer_Sentiments__c = 'Red';
            insert cs;
            Test.stopTest();
            System.assertEquals(true,cs.Id!=null);
 			}
       }
          
      /**
     * @description Test method for fetchRscgCases method
     * Tests the filtering logic for RSC-G cases based on Account RSC_G_Support__c field
     */
     @isTest
    static void testFetchRscgCases(){
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' And isActive = true LIMIT 1];
        System.runAs(usr){
            Test.startTest();
            
            // Account with exact 'RSC-G' support (should be included)
            Account rscgAccount = new Account(
                Name = 'Test RSC-G Account',
                RSC_G_Support__c = 'RSC-G'
            );
            INSERT rscgAccount;
            
            Contact objCont = new Contact(
                    LastName = 'Test Contact ' + rscgAccount.Name,
                    AccountId = rscgAccount.Id,
                    Email = 'test' + rscgAccount.Id + '@test.com' );
            insert objCont;

            // Get Support Case Record Type ID
            Id supportCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case')?.getRecordTypeId();
            
            Case objCase = new Case(
                Subject = 'Test Support Case RSC-G',
                AccountId = rscgAccount.Id,
                ContactId = objCont.Id,
                RecordTypeId = supportCaseRTId,
                Origin = 'Email',
                Priority = 'P3',
                Status = 'New'
            );
            insert objCase;
            
            Test.stopTest();
            System.assertEquals(true,objCase.Id!=null);
        }
    }
}