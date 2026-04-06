@isTest()
public class CustomLeadConvCntrlrTest{
    
    static CustomLeadConvCntrlr customContllr;
    static List<Lead> newLeadList = new List<Lead>();
    static List<Account> newActList = new List<Account>(); 
    @testSetup static void setupTestData() {
      insert new SetupCompanyMaster__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_CM__c =true , Log_API_Calls__c=true);
      List<WorkflowTriggerBypass__c> WorflwCS = new List<WorkflowTriggerBypass__c>();
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c = true));
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c = true));
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c = true));
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c = true));
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c = true));
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c = true));
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c = true));
            WorflwCS.add(new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c = true));
            insert WorflwCS;
        	flowControll.LeadTriggerHandler = false;
        	flowControll.accountTrigger = false;
            insert new TriggerControl__c(name='Opportunity',DisableTrigger__c=true);
            map<string,object> leadFieldMap = new map<string,object>{'Status'=>'Open','StateCode'=>'CA','State'=>'california','CountryCode'=>'US','country'=>'United States','postalCode'=>'809','Street'=>'sdf','CompanyDunsNumber__c'=>'82093','City'=>'New York','website'=>'test.com','phone'=>'802394'};
             newLeadList = (List<Lead>) ShGl_TestFactory.createSObjectList(new Lead(),7,leadFieldMap);
            insert newLeadList;
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf','NumberOfEmployees'=>10,'Duns_SIC2_code__c'=>'testcode' ,'Duns_SIC2_description__c'=>'sic desc','Tradestyle__c'=>'test','DU_Duns_Number__c'=>'56','DU_Business_Name__c'=>'Bu','GU_Duns_Number__c'=>'89','GU_Business_Name__c'=>'testbu','Industry'=>null,'website'=>'test.com','Industry_Subcategory__c'=>null,'AnnualRevenue'=>10.1,'BillingCity'=>'New York'};
              newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),2,accMap);
            insert newActList;
            Event eve = new Event(Type = 'Inside Sales Led Meeting',Subject='call',whoId=newLeadList[0].Id,DurationInMinutes=60,ActivityDate=Date.today(),ActivityDateTime= system.now(), Completed_Date__c = Date.today(), Post_Meeting_Status__c = 'Opportunity Sourced');
            insert eve;

}
     static testMethod void leadConvtestMethod4 () {       
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id from lead];
            newActList = [select id from account];
            List<string> resList = new List<string>();
            newLeadList[3].isFederalIntel__c = true;
            update newLeadList[3];
            string mckresp ='{"requestId":"5","requester":"test.com","results":{"CMAccount":{"CMID":"19060517101452000078","newAccount": "Y","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
			Test.startTest();
          
            Continuation conti2 = (Continuation)LeadConversionController.startRequest(newLeadList[3].Id);
			HttpResponse response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);
            //Test.setContinuationResponse(LeadConversionController.continuationLabel, response);
            //List<String> labels = new List<String>{LeadConversionController.continuationLabel};
            //LeadConversionController.processResponse(labels, LeadConversionController.continuationState);
            Test.stopTest();
        }
     }
     static testMethod void leadConvtestMethodNew (){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id from lead];
             
            Account acc = new Account(Name ='Test Company',Billingcountrycode='US',BillingStateCode = 'CA' , BillingCity = 'New York' , BillingStreet = 'sdf' , BillingpostalCode = '809',Phone ='1234567890' , Website = 'test.com',isFederalIntel__c =true, D_U_N_S__c = '82093');
            insert acc;
            List<Account> acclist = new List<Account>();
            acclist.add(acc);
            newActList = acclist;
            List<string> resList = new List<string>();
            newLeadList[3].isFederalIntel__c = true;
            update newLeadList[3];
            string mckresp ='{"requestId":"5","requester":"test.com","results":{"CMAccount":{"CMID":"19060517101452000078","newAccount": "Y","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
			Test.startTest();
          
            Continuation conti2 = (Continuation)LeadConversionController.startRequest(newLeadList[3].Id);
			HttpResponse response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);
            Test.stopTest();
            Assert.areEqual(acc.Name, 'Test Company');
        }
    }
     static testMethod void leadConvtestMethod5 () {       
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id from lead];
            newActList = [select id from account];
            List<string> resList = new List<string>();
            string mckresp ='{"requestId":"5","requester":"test.com","results":{"CMAccount":{"CMID":"19060517101452000078","newAccount": "Y","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            Test.startTest();
            //Error - 500
            Continuation conti3 = (Continuation)LeadConversionController.startRequest(newLeadList[3].Id);
            HttpResponse response2 = new HttpResponse();
            response2.setBody(mckresp);
            response2.setStatusCode(500);
			
            Test.setContinuationResponse(LeadConversionController.continuationLabel, response2);
            List<String> labels = new List<String>{LeadConversionController.continuationLabel};
            LeadConversionController.processResponse(labels, LeadConversionController.continuationState);
            Test.stopTest();
        }
     }
     static testMethod void leadConvtestMethod6() {       
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id from lead];
            newActList = [select id from account];
            List<string> resList = new List<string>();
            Test.startTest();
            //success - 200 & searchRes.status.statusCode == '204'
            string mckresp ='{"requestId":"5","requester":"test.com","results":{"CMAccount":{"CMID":"19060517101452000078","newAccount": "Y","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"204","statusDescription":"Match Not Found"}}';  
            Continuation conti4 = (Continuation)LeadConversionController.startRequest(newLeadList[3].Id);
            HttpResponse response3 = new HttpResponse();
            response3.setBody(mckresp);
            response3.setStatusCode(200);
			
            Test.setContinuationResponse(LeadConversionController.continuationLabel, response3);
            List<String> labels = new List<String>{LeadConversionController.continuationLabel};
            LeadConversionController.processResponse(labels, LeadConversionController.continuationState);
            Test.stopTest();
        }
     }
    static testMethod void leadConvtestMethod7() {       
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id from lead];
            newActList = [select id from account];
            List<string> resList = new List<string>();
            Test.startTest();
            //success - 200 & searchRes.status.statusCode == '204'
            string mckresp ='{"requestId":"5","requester":"test.com","results":{"CMAccount":{"CMID":"19060517101452000078","newAccount": "Y","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"500","statusDescription":"Match Not Found"}}';  
            Continuation conti4 = (Continuation)LeadConversionController.startRequest(newLeadList[3].Id);
            HttpResponse response3 = new HttpResponse();
            response3.setBody(mckresp);
            response3.setStatusCode(200);
			
            Test.setContinuationResponse(LeadConversionController.continuationLabel, response3);
            List<String> labels = new List<String>{LeadConversionController.continuationLabel};
            LeadConversionController.processResponse(labels, LeadConversionController.continuationState);
            Test.stopTest();
        }
     }
    static testMethod void leadConvtestMethod3 () {       
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id from lead];
            newActList = [select id from account];
            List<string> resList = new List<string>();
            
            
            Test.startTest();
            Continuation conti = (Continuation)LeadConversionController.startRequest(newLeadList[4].Id);
            HttpResponse response = new HttpResponse();
            string mckresp ='{"requestId":"5","requester":"test.com","results":{"CMAccount":{"CMID":"19060517101452000078","newAccount": "Y","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            response.setBody(mckresp);
            response.setStatusCode(200); 
            resList.add(response.toString());  
            
            Test.setContinuationResponse(LeadConversionController.continuationLabel, response);
            List<String> labels = new List<String>{LeadConversionController.continuationLabel};
            LeadConversionController.processResponse(labels, LeadConversionController.continuationState);
            
            //LeadConversionController.StateResponse sr = new LeadConversionController.StateResponse();
            //Test.invokeContinuationMethod(LeadConversionController.processResponse(new List<String>{LeadConversionController.continuationState}, sr), conti);

			//LeadConversionController.processResponse(resList,sr);
            
            
            
            
            
            
            
            //Test.setContinuationResponse(LeadConversionController.continuationState, response2);
			//LeadConversionController.processResponse(resList,sr);
            
            
            //LeadConversionController.StateResponse sr = new LeadConversionController.StateResponse();
            //LeadConversionController.processResponse(resList,sr);
            CMAccountSearch.CMAccount exactMatch = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
            exactMatch.newAccount = 'Y';
            exactMatch.CMID = 'test-0002';
            List<CMAccountSearch.CMAccount> exactMatchList = new List<CMAccountSearch.CMAccount>();
            exactMatchList.add(exactMatch);
            String potentialAccMatchPayload = JSON.serialize(exactMatchList);
            Test.stopTest();
        }
    }
    static testMethod void leadConvtestMethod () {       
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
    String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
    Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
    String uniqueName = orgId + dateString + randomInt;
    flowControll.LeadTriggerHandler = false;
    flowControll.accountTrigger = false;    
    User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id from lead];
            newActList = [select id from account];
            Test.setCurrentPageReference(new PageReference('Page.CustomLeadConversion')); 
            System.currentPageReference().getParameters().put('id',newLeadList[0].id);
            ApexPages.StandardController stdCntrlr = new ApexPages.StandardController(newLeadList[0]);
            customContllr = new CustomLeadConvCntrlr(stdCntrlr);
            customContllr.selectedLeadStatus ='Marketing Nurture';
            customContllr.sendEmailToOwner = false;
            customContllr.getLeadStatus();
            string mckresp ='{"requestId":"1","requester":"test@ru","results":{"CMAccount":{},"potentialAccounts":[]},"status":{"statusCode":"500","statusDescription":"Match Found"}}';   
            Continuation conti = (Continuation)customContllr.AccountDetails();
            Map<String, HttpRequest>  requests = conti.getRequests();
            HttpResponse response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);    
            Test.setContinuationResponse(customContllr.requestLabel, response);
            Test.invokeContinuationMethod(customContllr, conti);
            //internal appln failure -error code 300
            mckresp ='{"requestId":"2","requester":"test@ru","results":{"CMAccount":{},"potentialAccounts":[]},"status":{"statusCode":"300","statusDescription":"Match Found"}}';   
            system.debug('Internal 300 series');
            conti = (Continuation)customContllr.AccountDetails();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);    
            Test.setContinuationResponse(customContllr.requestLabel, response);
            Test.invokeContinuationMethod(customContllr, conti);
            
            //Server error -500
            mckresp ='{"error":"server down"}';   
            conti = (Continuation)customContllr.AccountDetails();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(500);    
            Test.setContinuationResponse(customContllr.requestLabel, response);
            Test.invokeContinuationMethod(customContllr, conti);
            // Bad request -404
            mckresp ='{"error":"Bad request"}';   
            conti = (Continuation)customContllr.AccountDetails();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(404);    
            Test.setContinuationResponse(customContllr.requestLabel, response);
            Test.invokeContinuationMethod(customContllr, conti);
            customContllr.RedirectBack();
            // Successfull search results with existing exact match
            mckresp ='{"requestId":"3","requester":"test.com","results":{"CMAccount":{"CMID":"000011111","newAccount": "n","sourceID":"SFDC::'+newActList[1].id+'","sourceName":"SFDC","accountName":"OldAcc, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            customContllr.CMErrorMsg = null;
            conti = (Continuation)customContllr.AccountDetails();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);    
            Test.setContinuationResponse(customContllr.requestLabel, response);
            Test.invokeContinuationMethod(customContllr, conti);
            customContllr.selectedrowIndex ='2-em';
            system.debug('accsearch start');
            customContllr.createORsetAccount();  
            // Successfull search results with new exact match
            mckresp ='{"requestId":"5","requester":"test.com","results":{"CMAccount":{"CMID":"19060517101452000067","newAccount": "Y","sourceID":"SFDC::'+newActList[1].id+'","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"test","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":"30794726"},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::'+newActList[0].id+'","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            conti = (Continuation)customContllr.AccountDetails();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);    
            Test.setContinuationResponse(customContllr.requestLabel, response);
            Test.invokeContinuationMethod(customContllr, conti);
            //CM error scenario
            customContllr.selectedrowIndex ='0-pm';
            customContllr.selectAccount();
            //no-error 
            customContllr.searchAccount();
            system.debug('Success potential');
            customContllr.selectedrowIndex = customContllr.temAccRowIndex='0-pm';
            customContllr.selectAccount();
            customContllr.createORsetAccount();
            system.debug('Success Exact');
            customContllr.selectedrowIndex =customContllr.temAccRowIndex='0-em';
            customContllr.selectAccount();
            customContllr.createORsetAccount();  
            customContllr.closePopUp();
            
            
        }
        
    }
    
    static testMethod void postAccountTestmethod () {       
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
    String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
    Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
    String uniqueName = orgId + dateString + randomInt;
    flowControll.LeadTriggerHandler = false;
    flowControll.accountTrigger = false;    
    User tuser = new User(  firstname = 'TestFName',
                            lastName = 'TestLName',
                            email = uniqueName + '@test' + orgId + '.org',
                            Username = uniqueName + '@test' + orgId + '.org',
                            EmailEncodingKey = 'ISO-8859-1',
                            Alias = uniqueName.substring(18, 23),
                            TimeZoneSidKey = 'America/Los_Angeles',
                            LocaleSidKey = 'en_US',
                            LanguageLocaleKey = 'en_US',
                            ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id,ownerId,Company,State,country,CompanyDunsNumber__c,countrycode,StateCode,City,Street,postalCode,Phone,Website from lead];
            newActList = [select id from account];
            Test.setCurrentPageReference(new PageReference('Page.CustomLeadConversion')); 
            System.currentPageReference().getParameters().put('id',newLeadList[0].id);
            ApexPages.StandardController stdCntrlr = new ApexPages.StandardController(newLeadList[0]);
            customContllr = new CustomLeadConvCntrlr(stdCntrlr);
            customContllr.accId =customContllr.leadConvStatus= newActList[0].id ;
            customContllr.selectedrowIndex ='0-em';
            CMAccountSearch.CMAccount searchRes = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
            searchRes.newAccount = 'Y';
            searchRes.CMID = 'test-0001';
            customContllr.exactAccMatch.add(searchRes);
            System.currentPageReference().getParameters().put('id',newLeadList[1].id);
            customContllr.ldSource = [SELECT Id, FirstName, isFederalIntel__c,Website,LastName,CountryCode,OwnerId, Company, CompanyDunsNumber__c, Phone,city,country,street,state,statecode,PostalCode FROM Lead WHERE Id =: newLeadList[1].id];
            customContllr.leadConvertErrMsg = null;
            customContllr.taskSobj = new task();
            customContllr.searchType = 'External-CM';
            
            CMAccountSearch.CMAccount exactMatch = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
            exactMatch.newAccount = 'Y';
            exactMatch.CMID = 'test-0002';
            List<CMAccountSearch.CMAccount> exactMatchList = new List<CMAccountSearch.CMAccount>();
            exactMatchList.add(searchRes);
            exactMatchList.add(exactMatch);
            String exactAccMatchPayload = JSON.serialize(exactMatchList);
            String potentialAccMatchPayload = JSON.serialize(exactMatchList);
            Test.startTest();
            
            string mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "test-1001", "sourceName": "test", "accountName": "","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "Y", "dunsBusinessName": "", "industryCategory": "Natural Resources","industrySubCategory": "Agricultural Production Crops", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "201", "statusDescription": "Account created"}}';
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
            customContllr.postAccountConvertLead();
            //server error
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,500));
            customContllr.PostAccountConvertLead();
            //application error
            mckresp ='{"requestId":"1","requester":"test@ru","CMAccount":{},"potentialAccounts":[],"status":{"statusCode":"500","statusDescription":"Match Found"}}';   
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
            customContllr.PostAccountConvertLead();
            Test.stopTest();    
        }
      }
    static testMethod void createORsetAccount () { 
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser = new User(  firstname = 'TestFName',
                              lastName = 'TestLName',
                              email = uniqueName + '@test' + orgId + '.org',
                              Username = uniqueName + '@test' + orgId + '.org',
                              EmailEncodingKey = 'ISO-8859-1',
                              Alias = uniqueName.substring(18, 23),
                              TimeZoneSidKey = 'America/Los_Angeles',
                              LocaleSidKey = 'en_US',
                              LanguageLocaleKey = 'en_US',
                              ProfileId = p.Id);
        System.runAs(tuser) {
            newLeadList = [select id,ownerId,Company,State,country,CompanyDunsNumber__c,countrycode,StateCode,City,Street,postalCode,Phone,Website from lead];
            newActList = [select id from account];
            CMAccountSearch.CMAccount searchRes = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
            searchRes.newAccount = 'Y';
            searchRes.CMID = 'test-0001';
            CMAccountSearch.CMAccount exactMatch = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
            exactMatch.newAccount = 'Y';
            exactMatch.CMID = 'test-0002';
            
            List<CMAccountSearch.CMAccount> exactMatchList = new List<CMAccountSearch.CMAccount>();
            exactMatchList.add(searchRes);
            exactMatchList.add(exactMatch);
            String exactAccMatchPayload = JSON.serialize(exactMatchList);
            String potentialAccMatchPayload = JSON.serialize(exactMatchList);
            
            Test.startTest();
            LeadConversionController.createORsetAccount(exactAccMatchPayload,potentialAccMatchPayload,'1-pm','SF Internal',newLeadList[1].id,false,true,'oppname',2000,'Nurture',userinfo.getUserId());
            LeadConversionController.createORsetAccount(exactAccMatchPayload,potentialAccMatchPayload,'1-em','SF Internal',newLeadList[2].id,false,true,'oppname',2000,'Nurture',userinfo.getUserId());
            LeadConversionController.createORsetAccount(exactAccMatchPayload,potentialAccMatchPayload,'1-em','External-CM',newLeadList[3].id,false,true,'oppname',2000,'Nurture',userinfo.getUserId());
            Test.stopTest();           
        }
    }
    static testMethod void createORsetAccount2 () { 
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId1 = UserInfo.getOrganizationId();
        String dateString1 = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt1 = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName1 = orgId1 + dateString1 + randomInt1;
        flowControll.LeadTriggerHandler = false;
        flowControll.accountTrigger = false;
        User tuser1 = new User(  firstname = 'TestFName',
                              lastName = 'TestLName',
                              email = uniqueName1 + '@test' + orgId1 + '.org',
                              Username = uniqueName1 + '@test' + orgId1 + '.org',
                              EmailEncodingKey = 'ISO-8859-1',
                              Alias = uniqueName1.substring(18, 23),
                              TimeZoneSidKey = 'America/Los_Angeles',
                              LocaleSidKey = 'en_US',
                              LanguageLocaleKey = 'en_US',
                              ProfileId = p1.Id);
        System.runAs(tuser1) {
            newLeadList = [select id,ownerId,Company,State,country,CompanyDunsNumber__c,countrycode,StateCode,City,Street,postalCode,Phone,Website from lead LIMIT 10000];
            newActList = [select id from account LIMIT 10000];
            CMAccountSearch.CMAccount searchRes = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser1.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
            searchRes.newAccount = 'Z';
            searchRes.CMID = 'test-0001';
            CMAccountSearch.CMAccount exactMatch = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser1.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
            exactMatch.newAccount = 'Z';
            exactMatch.CMID = 'test-0002';
            
            List<CMAccountSearch.CMAccount> exactMatchList1 = new List<CMAccountSearch.CMAccount>();
            exactMatchList1.add(searchRes);
            exactMatchList1.add(exactMatch);
            String exactAccMatchPayload = JSON.serialize(exactMatchList1);
            String potentialAccMatchPayload = JSON.serialize(exactMatchList1);
            Event eve = [SELECT Id FROM Event LIMIT 1]; 
            Test.startTest();
            LeadConversionController.createORsetAccount(exactAccMatchPayload,potentialAccMatchPayload,'1-em','SF Internal',newLeadList[0].id,false,true,'oppname',2000,'Nurture',userinfo.getUserId());
            Lead ld = [SELECT Id, SDR_Led__c, Meeting_Id__c FROM Lead LIMIT 1];
            System.assertEquals(eve.Id, ld.Meeting_Id__c);
            Test.stopTest();           
        }
    }
     static testMethod void postAccountTestmethod2 () {  
         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
         String orgId = UserInfo.getOrganizationId();
         String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
         Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
         String uniqueName = orgId + dateString + randomInt;
         flowControll.LeadTriggerHandler = false;
         flowControll.accountTrigger = false;
         User tuser = new User(  firstname = 'TestFName',
                               lastName = 'TestLName',
                               email = uniqueName + '@test' + orgId + '.org',
                               Username = uniqueName + '@test' + orgId + '.org',
                               EmailEncodingKey = 'ISO-8859-1',
                               Alias = uniqueName.substring(18, 23),
                               TimeZoneSidKey = 'America/Los_Angeles',
                               LocaleSidKey = 'en_US',
                               LanguageLocaleKey = 'en_US',
                               ProfileId = p.Id);
         System.runAs(tuser) {
             newLeadList = [select id,ownerId,Company,State,country,CompanyDunsNumber__c,countrycode,StateCode,City,Street,postalCode,Phone,Website from lead];
             newActList = [select id from account];
             CMAccountSearch.CMAccount searchRes = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
             searchRes.newAccount = 'Y';
             searchRes.CMID = 'test-0001';
             CMAccountSearch.CMAccount exactMatch = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
             exactMatch.newAccount = 'Y';
             exactMatch.CMID = 'test-0002';
            
             List<CMAccountSearch.CMAccount> exactMatchList = new List<CMAccountSearch.CMAccount>();
             exactMatchList.add(searchRes);
             exactMatchList.add(exactMatch);
             String exactAccMatchPayload = JSON.serialize(exactMatchList);
             String potentialAccMatchPayload = JSON.serialize(exactMatchList);
             
             string mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "test-1001", "sourceName": "test", "accountName": "","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "Y", "dunsBusinessName": "", "industryCategory": "Natural Resources","industrySubCategory": "Agricultural Production Crops", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "201", "statusDescription": "Account created"}}';
             string mckresp1 ='{"requestId":"1","requester":"test@ru","CMAccount":'+mckresp+',"potentialAccounts":[],"status":{"statusCode":"500","statusDescription":"Match Found"}}';   
             
             Test.startTest();
             Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp1,200));
             LeadConversionController.postAccountConvertLead(potentialAccMatchPayload,'0-em','External-CM','',newActList[0].id,newActList[0].id);
             Test.stopTest();    
         }
     }
    static testMethod void postAccountTestmethod3 () {  
         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
         String orgId = UserInfo.getOrganizationId();
         String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
         Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
         String uniqueName = orgId + dateString + randomInt;
         flowControll.LeadTriggerHandler = false;
         flowControll.accountTrigger = false;
         User tuser = new User(  firstname = 'TestFName',
                               lastName = 'TestLName',
                               email = uniqueName + '@test' + orgId + '.org',
                               Username = uniqueName + '@test' + orgId + '.org',
                               EmailEncodingKey = 'ISO-8859-1',
                               Alias = uniqueName.substring(18, 23),
                               TimeZoneSidKey = 'America/Los_Angeles',
                               LocaleSidKey = 'en_US',
                               LanguageLocaleKey = 'en_US',
                               ProfileId = p.Id);
         System.runAs(tuser) {
             newLeadList = [select id,ownerId,Company,State,country,CompanyDunsNumber__c,countrycode,StateCode,City,Street,postalCode,Phone,Website from lead];
             newActList = [select id from account];
             CMAccountSearch.CMAccount searchRes = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
             searchRes.newAccount = 'Y';
             searchRes.CMID = 'test-0001';
             CMAccountSearch.CMAccount exactMatch = new CMAccountSearch.CMAccount(newActList[0].id,'test',tuser.FirstName,'sdsd','city','Telangana','TS','2323','India','3442','IN','Partner/Distributor','Open');
             exactMatch.newAccount = 'Y';
             exactMatch.CMID = 'test-0002';
            
             List<CMAccountSearch.CMAccount> exactMatchList = new List<CMAccountSearch.CMAccount>();
             exactMatchList.add(searchRes);
             exactMatchList.add(exactMatch);
             String exactAccMatchPayload = JSON.serialize(exactMatchList);
             String potentialAccMatchPayload = JSON.serialize(exactMatchList);
             
             string mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "test-1001", "sourceName": "test", "accountName": "","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "Y", "dunsBusinessName": "", "industryCategory": "Natural Resources","industrySubCategory": "Agricultural Production Crops", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "201", "statusDescription": "Account created"}}';
             string mckresp1 ='{"requestId":"1","requester":"test@ru","CMAccount":'+mckresp+',"potentialAccounts":[],"status":{"statusCode":"500","statusDescription":"Match Found"}}';   
             
             Test.startTest();
             //server error
             Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp1,500));
             LeadConversionController.postAccountConvertLead(potentialAccMatchPayload,'0-em','External-CM','',newActList[0].id,newActList[0].id);
             LeadConversionController.getRecordsByName('Account','test');
             Test.stopTest();  
         }
    }
    
}