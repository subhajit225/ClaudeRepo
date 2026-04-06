@isTest
public class PC_PartnerSpecializationRequestCtrlrTest {
      
    @isTest static void method2() {
        User admin = [SELECT Id FROM User WHERE Profile.Name= 'System Administrator' AND IsActive = TRUE AND Id != :UserInfo.getUserId() AND UserRole.PortalType = 'None' LIMIT 1];
        User user;
        System.runAs(admin) { 
            //Create Account
            Id accountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account docebo_Account = new Account(Name = 'DoceboTest', type='MSP', billingCountry = 'United States', recordtypeId=accountRecTypeId);
            insert docebo_Account;
            
            //insert contact
            Contact con = new Contact (
                AccountId = docebo_Account.id,
                LastName = 'doceboTestContact',
                PSE_Shadow_Completed__c = Date.today()
            );
            insert con;
            
            Profile p = [SELECT Id,name FROM Profile  
                         WHERE name = 'Rubrik Partner Community Manager' LIMIT 1];
            
            //Create user
            user = new User(alias = 'docebo', email='doceboTestUser@svg.com',
                            emailencodingkey='UTF-8', lastname='doceboTest', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = p.Id, country='United States',IsActive = true,
                            ContactId = con.Id,
                            timezonesidkey='America/Los_Angeles', username='doceboTestUser@svg.com');
            
            
            
            insert user;
        }
        User partnerUser = [SELECT Id FROM User WHERE Profile.Name= 'Rubrik Partner Community Manager' AND IsActive = TRUE  LIMIT 1];
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        System.runAs(partnerUser) { 
            PC_PartnerSpecializationRequestCtrlr.getAccountAndContacts();
            
            
        }
        Partner_Specialization_Request__c req= new Partner_Specialization_Request__c();
        req.Contact__c = con.Id;
        req.Partner_Company_Name__c = acc.id;
        PC_PartnerSpecializationRequestCtrlr.response_Wrapper resp = new PC_PartnerSpecializationRequestCtrlr.response_Wrapper();
        resp = PC_PartnerSpecializationRequestCtrlr.createSpecilizationRequest(req);
        Partner_Specialization_Request__c savedReq= [SELECT Id FROM Partner_Specialization_Request__c Limit 1];
        List<Id> reqIds = new List<Id>();
        reqIds.add(savedReq.Id);
        PC_PartnerSpecializationRequestCtrlr.setRoleToQueue(reqIds);
        
        
    }
    
    @isTest static void method1() {
        
        //Create Account
        Id accountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account docebo_Account = new Account(Name = 'DoceboTest', type='MSP', billingCountry = 'United States', recordtypeId=accountRecTypeId);
        insert docebo_Account;
        
        //insert contact
        Contact con = new Contact (
            AccountId = docebo_Account.id,
            LastName = 'doceboTestContact',
            PSE_Shadow_Completed__c = Date.today()
        );
        insert con;
        
        
        Partner_Specialization_Request__c req= new Partner_Specialization_Request__c();
        //req.Contact__c = con.Id;
        //req.Partner_Company_Name__c = acc.id;
        PC_PartnerSpecializationRequestCtrlr.response_Wrapper resp = new PC_PartnerSpecializationRequestCtrlr.response_Wrapper();
        // Partner_Specialization_Request__c savedReq= [SELECT Id FROM Partner_Specialization_Request__c Limit 1];
        List<Id> reqIds = new List<Id>();
        //reqIds.add(savedReq.Id);
        //PC_PartnerSpecializationRequestCtrlr.setRoleToQueue(reqIds);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PC_PactsafeCalloutMockup_Test());
        PC_PartnerSpecializationRequestCtrlr.callpactsafe(docebo_Account.Id, docebo_Account.Name,'test@rubrik.com',con.Id,'', 'United State');    
        Test.stopTest();
        
    }
    
    public class PC_PactsafeCalloutMockup_Test implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('https://pactsafe.com/example/test', req.getEndpoint()); //EXCL-6
            System.assertEquals('GET', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"page_query":"groupType=RUBRIK_PROFESSIONAL_SERVICES_PARTNER&partnerType=Reseller&email=pavanaja@accenture.com","download_url":"https://public.pactsafe.com/v1.1/download/activity/5c4ff210647c037683283650?expires=0&signature=PbVp~tkczVg4jl4AQ9OQ7SUi6wFMCKcqtpAYJoY3GqtMus5ICe0fn4eRMH~L4TelpOTHGfYZA6o9LaPt8w3qOrOUdzwp8Og~nRn8ioJGfnyFo4PHHDursUpC0wXoJKSdt6es~W7C4Pa5o~HNKsoDzZYykJBf7-vsfrhITssmLsGfGm6TPPjT6ucb76sPT5Ni0pAYGmrMNpk8qyLSAFVLvGvubd-E4lwrm5LotGuW~tqHkPwbJQrZUI-0pDgwNUTk3BMkhASkZC~cNWV~OqxcqAwyYLFd~2ed4LU4mWxYYqRjWFR18YfZYF8IN-C5aIhMjfVemlgCqTAEYasVSoPPzw__","id":"5c4ff210647c037683283650"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
}