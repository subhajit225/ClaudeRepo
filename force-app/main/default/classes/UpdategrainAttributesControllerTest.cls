@isTest()
public class UpdategrainAttributesControllerTest {
    
    public static string mckresp ;
    @testSetup static void setup() {
        Map<string,object> accMap = new map<string,object>{'BillingStateCode'=>'CA','BillingCountryCode'=>'US','phone'=>'802394','website'=>'test.com','D_U_N_S__c'=>'82093','BillingpostalCode'=>'809','BillingStreet'=>'sdf'};
            List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,accMap);
        flowcontroll.accountTrigger = false;
        insert newActList;
        insert new SetupCompanyMaster__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_CM__c =true , Log_API_Calls__c=true);
        
    }
    @isTest static void grainUpdateTest() {
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
        Test.setCurrentPageReference(new PageReference('Page.UpdateAccountGrainAttributes')); 
        System.currentPageReference().getParameters().put('id',acct.id);
        ApexPages.StandardController stdCntrlr = new ApexPages.StandardController(acct);
        UpdategrainAttributesController  extension = new UpdategrainAttributesController(stdCntrlr);
        extension.updateAcc.billingCity = 'test city';
        
        UpdategrainAttributesControllerLWC.getAccessDetails(acct.id);
        
        //appln error
        mckresp = '{"CMAccount": {}, "status": {"statusCode": "300", "statusDescription": "Account created"}}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
        extension.updateAccount();
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
        UpdategrainAttributesControllerLWC.saveAccountLWC(acct);
        
        // Success updating account
        system.debug('Success');
        mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "'+acct.id+'", "sourceName": "test", "accountName": "testAcc","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "N", "dunsBusinessName": "", "industryCategory": "","industrySubCategory": "", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "200", "statusDescription": "Account created"}}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
        extension.updateAccount();
        extension.redirectToAcc();
        Test.stopTest(); 
    }
    
     @isTest static void grainUpdateTest2() {
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
         // Success updating account
        system.debug('Success');
        mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "'+acct.id+'", "sourceName": "test", "accountName": "testAcc","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "N", "dunsBusinessName": "", "industryCategory": "","industrySubCategory": "", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "200", "statusDescription": "Account created"}}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
        UpdategrainAttributesControllerLWC.saveAccountLWC(acct);
        Test.stopTest();  
     }
    
    @isTest static void grainUpdate_accErrorTest() {
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
        Test.setCurrentPageReference(new PageReference('Page.UpdateAccountGrainAttributes')); 
        System.currentPageReference().getParameters().put('id',acct.id);
        ApexPages.StandardController stdCntrlr = new ApexPages.StandardController(acct);
        UpdategrainAttributesController  extension = new UpdategrainAttributesController(stdCntrlr);
        extension.updateAcc.billingCity = 'test city';
        
        UpdategrainAttributesControllerLWC.getAccessDetails(acct.id);
        
        // Error updating account
        mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "'+acct.id+'", "sourceName": "", "accountName": "testAcc","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "N", "dunsBusinessName": "", "industryCategory": "Natural Resources","industrySubCategory": "Agricultural Production Crops", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "200", "statusDescription": "Account created"}}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
        extension.updateAccount();
		Test.stopTest(); 
    } 
    
    @isTest static void grainUpdate_accErrorTest2() {
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
         // Error updating account
        mckresp = '{"CMAccount": {"CMID": "19060514110818000089", "sourceID": "'+acct.id+'", "sourceName": "", "accountName": "testAcc","addressLine1": "", "addressLine2": "", "city": "", "state": "", "stateCode": "", "postalCode": "", "country": "","isoCountrycode": "", "dunsNumber": "", "newAccount": "N", "dunsBusinessName": "", "industryCategory": "Natural Resources","industrySubCategory": "Agricultural Production Crops", "guEmployeeCount": "", "guRevenueUSD": "", "dunsSIC2Code": "", "dunsSIC2Description": "","dunsDomainName": "", "dunsTradeStyleName": "", "duDunsNumber": "", "duBusinessName": "", "guDunsNumber": "","guBusinessName": ""}, "status": {"statusCode": "200", "statusDescription": "Account created"}}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,200));
        UpdategrainAttributesControllerLWC.saveAccountLWC(acct);
        Test.stopTest(); 
    }
    
    @isTest static void grainUpdate_ServerErrorTest() {
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
        Test.setCurrentPageReference(new PageReference('Page.UpdateAccountGrainAttributes')); 
        System.currentPageReference().getParameters().put('id',acct.id);
        ApexPages.StandardController stdCntrlr = new ApexPages.StandardController(acct);
        UpdategrainAttributesController  extension = new UpdategrainAttributesController(stdCntrlr);
        extension.updateAcc.billingCity = 'test city';
        
        UpdategrainAttributesControllerLWC.getAccessDetails(acct.id);
        
        // Server error
        mckresp = '{"error":"serverdowntime"}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,500));
        extension.updateAccount();

        mckresp = '{"error":"serverdowntime"}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,300));
        extension.updateAccount();
        Test.stopTest(); 
    }
    
     @isTest static void grainUpdate_ServerErrorTest2() {
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
        mckresp = '{"error":"serverdowntime"}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,300));
        UpdategrainAttributesControllerLWC.saveAccountLWC(acct); 
        Test.stopTest(); 
     }
    	
    @isTest static void grainUpdate_ServerErrorTest3() {
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
        mckresp = '{"error":"serverdowntime"}';
        Test.setMock(HttpCalloutMock.class, new GenericMockHttpResponseGenerator('application/Json',mckresp,500));
        UpdategrainAttributesControllerLWC.saveAccountLWC(acct); 
        Test.stopTest(); 
     }
    
    @isTest static void getAccessDetailsTest1() {
        SetupCompanyMaster__c scm = [select Id,Enable_CM__c from SetupCompanyMaster__c where SetupOwnerId=:UserInfo.getOrganizationId()];
        scm.Enable_CM__c = false;
        update scm;
        Test.startTest();
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
        UpdategrainAttributesControllerLWC.getAccessDetails(acct.id);
        Test.stopTest(); 
     }
    
     @isTest static void getAccessDetailsTest2() {
        Account acct = [SELECT Id,name,billingCity,billingCountry,CMID__c,isFederalIntel__c, BillingState,BillingStatecode, BillingCountrycode,billingpostalcode,billingstreet FROM Account LIMIT 1];
        system.debug('Test acct'+acct);
        acct.isFederalIntel__c = true;
        flowcontroll.accountTrigger = false;
        update acct;
        Test.startTest(); 
        UpdategrainAttributesControllerLWC.getAccessDetails(acct.id);
        Test.stopTest(); 
     }
}