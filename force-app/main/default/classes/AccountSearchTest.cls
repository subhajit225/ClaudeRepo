@isTest()
public class AccountSearchTest {
    
    static AccountSearch extension;
    static PageReference pgref;
    
    @testSetup static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
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
        insert tuser;
        insert new SetupCompanyMaster__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_CM__c =true , Log_API_Calls__c=true);
        
    }
    static testMethod void accountSearchtestMethod1() {       
       User tuser = [select Id from user limit 1];
        System.runAs(tuser) {
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
                List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
            insert newActList[0];
            ApexPages.StandardController stdCntrlr = new ApexPages.StandardController(newActList[0]);
            extension = new AccountSearch(stdCntrlr);
            extension.BillingStateName = 'California';  
            // Successfull search results
            string mckresp ='{"requestId":"12","requester":"chaitra.padashetty@ru","results":{"CMAccount":{"CMID":"19060517101452000025","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":30794726},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::0011W000023bvvHQAQ","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            Continuation conti = (Continuation)extension.createSearchAccount();
            Map<String, HttpRequest> requests = conti.getRequests();
            HttpResponse response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);    
            Test.setContinuationResponse(extension.requestLabel, response);
            Test.invokeContinuationMethod(extension, conti);
            system.debug('search acc'+extension.searchAccount);
            extension.init();
            extension.createSearchAccount();
            extension.selectedRow = '0-pm'; // selecting potential account
            extension.RequestAccCreation();
            extension.selectedRow = '0-em'; // selecting exact account match
            extension.RequestAccCreation();
            extension.accToinsert = newActList[1];
            extension.CreateAccount();
            extension.Cancel();    
            extension.AccRedirect();
            
            //internal appln failure -error code 500
            mckresp ='{"requestId":"13","requester":"test@ru","results":{"CMAccount":{},"potentialAccounts":[]},"status":{"statusCode":"500","statusDescription":"Match Found"}}';   
            conti = (Continuation)extension.createSearchAccount();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);    
            Test.setContinuationResponse(extension.requestLabel, response);
            Test.invokeContinuationMethod(extension, conti);
            
            //internal appln failure -error code 300
            mckresp ='{"requestId":"13","requester":"test@ru","results":{"CMAccount":{},"potentialAccounts":[]},"status":{"statusCode":"300","statusDescription":"Match Found"}}';   
            system.debug('Internal 300 series');
            conti = (Continuation)extension.createSearchAccount();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(200);    
            Test.setContinuationResponse(extension.requestLabel, response);
            Test.invokeContinuationMethod(extension, conti);
            
            //Server error -500
            mckresp ='{"error":"server down"}';   
            conti = (Continuation)extension.createSearchAccount();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(500);    
            Test.setContinuationResponse(extension.requestLabel, response);
            Test.invokeContinuationMethod(extension, conti);
            
            // Bad request -404
            mckresp ='{"error":"Bad request"}';   
            conti = (Continuation)extension.createSearchAccount();
            requests = conti.getRequests();
            response = new HttpResponse();
            response.setBody(mckresp);
            response.setStatusCode(404);    
            Test.setContinuationResponse(extension.requestLabel, response);
            Test.invokeContinuationMethod(extension, conti);
            
            
            extension.searchAccount = newActList[1];
            extension.searchInternalAccount();
            
            //Federal account search
            newActList[0].isFederalIntel__c = true;
            update newActList[0];
            stdCntrlr = new ApexPages.StandardController(newActList[0]);
            extension = new AccountSearch(stdCntrlr);
            extension.BillingStateName = 'California';  
            extension.createSearchAccount();
            
            Test.startTest();
            // Post account API test case
            extension.accToinsert = newActList[0];
            extension.IsfederalIntel = false; 
            extension.searchType = 'External-CM';
            mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "test-1001", "sourceName": "test", "accountName": "","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "N", "dunsBusinessName": "", "industryCategory": "Natural Resources","industrySubCategory": "Agricultural Production Crops", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "201", "statusDescription": "Account created"}}';
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
            extension.PostAccounttoCM();
            Test.stopTest();
            
        }
    }
    static testMethod void accountSearchtestMethod2() {       
       User tuser = [select Id from user limit 1];
        System.runAs(tuser) {
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
                List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
            insert newActList[0];
            
            Test.startTest();
            string mckresp ='{"requestId":"12","requester":"chaitra.padashetty@ru","results":{"CMAccount":{"CMID":"19060517101452000025","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":30794726},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::0011W000023bvvHQAQ","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
        	accountsearchLWCController.createSearchAccount(newActList[0]);
            Id recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            
            string mckresp1 ='[{"accountName":"test","accountOwner":"","addressLine1":"fdgfg","addressLine2":"","city":"Hyderabad","country":"India","isoCountrycode":"IN","newAccount":"Y","postalCode":"45677","sourceID":"","stateCode":""}]';
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp1,200));
            accountsearchLWCController.RequestAccCreation(mckresp1,recTypeId,false,'');
            accountsearchLWCController.ShowPage();
            Test.stopTest();
        }
    }
    static testMethod void accountSearchtestMethod3() {       
       User tuser = [select Id from user limit 1];
        System.runAs(tuser) {
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
                List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
            insert newActList[0];
            
            Test.startTest();
            string mckresp1 ='{"CMAccount": {"cmid": "None", "source_id": "0017900000EHcE2AAL", "source_name": "SFDC", "request_id": "20220703102322818_SFDC", "requester": "pavanaja.yellajosyula@rubrik.com.rbkqa"}, "status": {"statusCode": "200"}}';
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp1,200));
            accountsearchLWCController.PostAccounttoCM(newActList[0],'',false);
            Test.stopTest();
        }
    }
    static testMethod void accountSearchtestMethod4() {       
       User tuser = [select Id from user limit 1];
        System.runAs(tuser) {
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
                List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
            insert newActList[0];
            
            Test.startTest();
            string mckresp ='{"requestId":"12","requester":"chaitra.padashetty@ru","results":{"CMAccount":{"CMID":"19060517101452000025","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":30794726},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::0011W000023bvvHQAQ","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,500));
        	accountsearchLWCController.createSearchAccount(newActList[0]);
            Test.stopTest();
        }
    }
   /* static testMethod void accountSearchtestMethod5() {       
       User tuser = [select Id from user limit 1];
        System.runAs(tuser) {
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
                List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
            insert newActList[0];
            
            Test.startTest();
            string mckresp ='{"requestId":"12","requester":"chaitra.padashetty@ru","results":{"CMAccount":{"CMID":"19060517101452000025","sourceID":"SFDC::0011W000023c3G4QAI","sourceName":"SFDC","accountName":"Telvista, Inc.","addressLine1":"1605 Lyndon B Johnson Fwy Ste 200","addressLine2":"","city":"Dallas","state":"Texas","stateCode":"TX","postalCode":"75234-6803","country":"United States","isoCountrycode":"US","dunsNumber":30794726},"potentialAccounts":[{"CMID":"19060517565092000093","sourceID":"SFDC::0011W000023bvvHQAQ","sourceName":"SFDC","accountName":"Testa Produce, Inc.","addressLine1":"4555 S Racine Ave","addressLine2":"","city":"Chicago","state":"Illinois","stateCode":"IL","postalCode":"60609-3371","country":"United States","isoCountrycode":"US","dunsNumber":785808569},{"CMID":"19060518102871000075","sourceID":"SFDC::0011W00001zFy0KQAS","sourceName":"SFDC","accountName":"Teamsters","addressLine1":"25 Louisiana Ave NW","addressLine2":"","city":"Washington","state":"District of Columbia","stateCode":"DC","postalCode":"20001-2130","country":"United States","isoCountrycode":"US","dunsNumber":807896415}]},"status":{"statusCode":"200","statusDescription":"Match Found"}}';  
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,211));
        	accountsearchLWCController.createSearchAccount(newActList[0]);
            Test.stopTest();
        }
    }*/
     static testMethod void accountSearchtestMethod6() {       
       User tuser = [select Id from user limit 1];
        System.runAs(tuser) {
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
                List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
            insert newActList[0];
            
            Test.startTest();
            string mckresp1 ='{"CMAccount": {"cmid": "None", "source_id": "0017900000EHcE2AAL", "source_name": "SFDC", "request_id": "20220703102322818_SFDC", "requester": "pavanaja.yellajosyula@rubrik.com.rbkqa"}, "status": {"statusCode": "200"}}';
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp1,500));
            accountsearchLWCController.PostAccounttoCM(newActList[0],'',false);
            Test.stopTest();
        }
    }
   /*  static testMethod void accountSearchtestMethod7() {       
       User tuser = [select Id from user limit 1];
        System.runAs(tuser) {
            map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
                List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
            insert newActList[0];
            
            Test.startTest();
            string mckresp1 ='{"CMAccount": {"cmid": "None", "source_id": "0017900000EHcE2AAL", "source_name": "SFDC", "request_id": "20220703102322818_SFDC", "requester": "pavanaja.yellajosyula@rubrik.com.rbkqa"}, "status": {"statusCode": "200"}}';
            Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp1,211));
            accountsearchLWCController.PostAccounttoCM(newActList[0],'',false);
            Test.stopTest();
        }
    }*/
}