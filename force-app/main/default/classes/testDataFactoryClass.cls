/*
 * Class Name :- testDataFactoryClass
 * Author :- Shiva Sharma
 * Created-Date :- 24-05-2018
 * Description : This Controller is being to create Data for Self Register , customer Registration Request  , CaseTrigger Handler
 * 
 // ********************Change Logs ******************************************************************************************************************************************************
 * 
 * Modified By          Date        Description 
 * Shiva Sharma			11-07-2018	Added Case Data method createCase()
 * 
 // ********************Change Logs Ends**************************************************************************************************************************************************
*/
@isTest
public class testDataFactoryClass {
    
    public static Product2 createProduct(){
        Product2 pro = new Product2();
        pro.Name = 'EVALUATION-CDM';
        pro.IsActive = true;
        insert pro;
        return pro;
    }
    
    public static Product2 createTrialProduct(){
        Product2 pro = new Product2();
        pro.Name = 'EVALUATION-EDGE-TRIAL';
        pro.ProductCode = 'EDGE-TRIAL';
        pro.IsActive = true;
        insert pro;
        return pro;
    }
    
    public static List<Case> createCase(integer i){
        List<Case> caseList = new List<Case>();
        for(integer j=0 ; j< i ;j++){
            caseList.add(new Case(Status = 'New',Priority='P1 - Critical',Subject='sasadf'));
        }
        insert caseList;
        return caseList;
	}
   
    public static List<Account> createAccount(Integer j,Integer k){
        List<Account> testAccts = new List<Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        ID userId = userinfo.getUserId();
        for(Integer i = 0;i < j ; i++){
            
            testAccts.add(new Account(Name = 'TestAcct1'+i,Website='www.test3.com',OwnerId = userId,type='Customer',Partner_Agreement_Status__c ='Signed - Active', RecordTypeId =partnerRecordTypeId));
            testAccts.add(new Account(Name = 'TestAcct2'+i,Website='www.tests.com',OwnerId = userId,type='Partner',Partner_Agreement_Status__c ='Signed - Inactive', RecordTypeId =partnerRecordTypeId));
            testAccts.add(new Account(Name = 'TestAcct3'+i,Website='www.test4.com',OwnerId = userId,type='Prospect',Partner_Agreement_Status__c ='Unsigned', RecordTypeId =partnerRecordTypeId));
        }
        insert testAccts; 
        
        createDomainList(testAccts,k);
        return testAccts;
    }
       
    public static List<Account> createAccounts(){
       
        List<Account> testAccts = new List<Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        testAccts.add(new Account(Name = 'TestAcct1',RecordTypeId =partnerRecordTypeId));
        insert testAccts; 
        return testAccts;
    } 
    public static List<Account> createAccount(){
        List<Account> testAccts = new List<Account>();
        //ID userId = [select id from user where Alias ='tUser' Limit 1].Id;
        ID userId = userinfo.getUserId();
        testAccts.add(new Account(Name = 'TestAcct1',Website='www.test3.com',OwnerId = userId,type='Customer',Agreed_to_Edge_Trial_Agreement__c=true,Partner_Agreement_Status__c ='Signed - Active'));
        insert testAccts; 
        return testAccts;
    }
    
     public static List<Account> createAccountwithEntitlement(){
        List<Account> testAccts = new List<Account>();
        //ID userId = [select id from user where Alias ='tUser' Limit 1].Id;
        ID userId = userinfo.getUserId();
        testAccts.add(new Account(Name = 'TestAcct1',Website='www.test3.com',OwnerId = userId,type='Customer',Agreed_to_Edge_Trial_Agreement__c=true,Partner_Agreement_Status__c ='Signed - Active'));
        insert testAccts; 
        insert new Entitlement(Name='Testing', AccountId=testAccts[0].Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addDays(90)));
        return testAccts;
    }
    
    public static void createCustomSettings(){
        insert new TriggerControl__c(Name='Customer Registration Request');
        insert new TriggerControl__c(Name='Opportunity');
        insert new TriggerControl__c(Name='Entitlement');
        insert new TriggerControl__c(Name='Case');
    }
    
    public static void createDomainList(List<Account> testAccts,Integer k){
        integer j = testAccts.size();
        List<WL_Domain__c> wlList = new List<WL_Domain__c>();
        // Added isApproved__c = true, Since domains are allowed only when they are approved: CS21-1218
        wlList.add(new WL_Domain__c(Name = 'test1.com',Account__c = testAccts[0].Id, isApproved__c = true));
        wlList.add(new WL_Domain__c(Name = 'test2.com',Account__c = testAccts[1].Id, isApproved__c = true));
        wlList.add(new WL_Domain__c(Name = 'test3.com',Account__c = testAccts[2].Id, isApproved__c = true));
        wlList.add(new WL_Domain__c(Name = 'test4.com',Account__c = testAccts[1].Id, isApproved__c = true));
        wlList.add(new WL_Domain__c(Name = 'test5.com',Account__c = testAccts[2].Id, isApproved__c = true));
        wlList.add(new WL_Domain__c(Name = 'testuser1.com',Account__c = testAccts[k].Id, isApproved__c = true));
        wlList.add(new WL_Domain__c(Name = 'testuser2.com',Account__c = testAccts[k].Id, isApproved__c = true));
        wlList.add(new WL_Domain__c(Name = 'test'+UserInfo.getOrganizationId()+'.org',Account__c = testAccts[k].Id, isApproved__c = true));
        insert wlList;
    }
    
    public static List<Contact> createContact(List<Account> testAccts){
        integer j = testAccts.size();
        List<Contact> testData = new List<Contact>();
        for(Integer i=1;i<j+1;i++) {
            testData.add(new Contact(firstname='Test',LastName = 'testl',email='test@test'+i+'.com',phone='testPhone',AccountId = testAccts[i-1].id,OwnerId =testAccts[i-1].ownerId ));
        }
        insert testData;
        return testData;
    }
    
    public static List<Contact> createContactCustomEmail(List<Account> testAccts,String email,Boolean istrue){
        integer j = testAccts.size();
        List<Contact> testData = new List<Contact>();
        for(Integer i=1;i<j+1;i++) {
            testData.add(new Contact(firstname='Test',LastName = 'testl',email=email+i+'.com',phone='testPhone',AccountId = testAccts[i-1].id,OwnerId =testAccts[i-1].ownerId,create_Portal_User__c= istrue ));
        }
        createPartnerRegistrationRequest(testData);
        insert testData;
        return testData;
    }
    
    public static void createPartnerRegistrationRequest(List<Contact> conList){
        integer j = conList.size();
        List<Partner_Registration_Request__c> prr = new List<Partner_Registration_Request__c>();
        for(Integer i=1;i<j+1;i++) {
        	prr.add(new Partner_Registration_Request__c(
                First_Name__c = 'First '+i,
                Last_Name__c = 'last '+i,
                Company_Name__c = 'Test Company '+i,
                Email__c = 'rent@rows'+i+'.com'));

        }
        insert prr;
    }
    
    public static List<Opportunity> createOpporunitywithAccountEntitlement(List<Account> testAccts){
        integer j = testAccts.size();
        List<Opportunity> testData = new List<Opportunity>();
        List<Entitlement> testEntitlement = new List<Entitlement>();
        for(Integer i=1;i<j+1;i++) {
            testData.add(new Opportunity(Name = 'TestOpp'+i,AccountId=testAccts[i-1].id,StageName='1 Discovery',CloseDate = System.today()));
            testData.add(new Opportunity(Name = 'TestOpp'+i,AccountId=testAccts[i-1].id,Partner_Lookup__c=testAccts[i-1].id,StageName='1 Discovery',CloseDate = System.today()));
            testEntitlement.add(new Entitlement(Name='Testing', AccountId=testAccts[i-1].Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2))));
        }

        insert testData; 
        insert testEntitlement;
        return testData;
    }
    
    public static List<Opportunity> createExpiredOpporunitywithAccountEntitlement(List<Account> testAccts){
        integer j = testAccts.size();
        List<Opportunity> testData = new List<Opportunity>();
        List<Entitlement> testEntitlement = new List<Entitlement>();
        for(Integer i=1;i<j+1;i++) {
            testData.add(new Opportunity(Name = 'TestOpp'+i,AccountId=testAccts[i-1].id,StageName='7 Closed Lost',CloseDate = System.today(),Lost_To_Won_Against__c='Actifio'));
            testData.add(new Opportunity(Name = 'TestOpp'+i,Partner_Lookup__c=testAccts[i-1].id,StageName='7 Closed Lost',CloseDate = System.today(),Lost_To_Won_Against__c='Actifio'));
            testEntitlement.add(new Entitlement(Name='Testing', AccountId=testAccts[i-1].Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addDays(-1))));
        }

        insert testData; 
        insert testEntitlement;
        return testData;
    }
    
    public static List<Opportunity> createOpporunity(List<Account> testAccts){
        integer j = testAccts.size();
        List<Opportunity> testData = new List<Opportunity>();
        for(Integer i=0;i < j;i++) {
            testData.add(new Opportunity(Name = 'TestOpp'+i,AccountId=testAccts[i].id,StageName='1 Discovery',CloseDate = System.today()));
        }
        insert testData;   
        return testData;
    }
    public static List<Customer_Registration_Request__c> createCustomerRegRequest(Integer j,List<Account> testAccts){
        List<Customer_Registration_Request__c> csrList = new List<Customer_Registration_Request__c>();
        for(Integer i=0;i<j;i++){
           csrList.add(new Customer_Registration_Request__c(firstName__c='t'+i,Last_Name__c='p'+i,Email__c='test@test'+i+'.com',Phone__c='phn',Title__c='title',Domain_Name__c='test'+i,has_Domain__c = true,Description__c ='Test',Account__c = testAccts[i].Id));
        }
        csrList.add(new Customer_Registration_Request__c(firstName__c='t6',Last_Name__c='p5',Email__c='testuser@testuser0.com',Phone__c='phn',Title__c='title',Domain_Name__c='test6',has_Domain__c = true,Description__c ='Test'));
        csrList.add(new Customer_Registration_Request__c(firstName__c='t6',Last_Name__c='p5',Email__c='test@test5.com',Phone__c='phn',Title__c='title',Domain_Name__c='test6',has_Domain__c = true,Description__c ='Test'));
        csrList.add(new Customer_Registration_Request__c(firstName__c='t7',Last_Name__c='p6',Email__c='testuser@testuser1.com',Phone__c='phn',Title__c='title',Domain_Name__c='test7',has_Domain__c = true,Description__c ='Test'));
        insert csrList;
        return csrList;
    }
    
    @future
    public static void createUser(){
        Profile profiles=[Select Id From Profile Where Name='System Administrator'];
        String roleId = [SELECT Id FROM UserRole WHERE Name ='CEO' ].Id;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
        String uniqueName = orgId + dateString + randomInt;        
        User u = new User();
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.ProfileId = profiles.Id;
        u.UserRoleId = roleId;
        u.LastName = 'test';
        u.Alias = 'tUser';
        u.Email = 'testuser@testuser1.com';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.localesidkey='en_US';
        u.emailencodingkey='UTF-8';
        u.languagelocalekey='en_US';
        insert u;
    }
    public static List<Contact> createContactWithUserLogin(Integer j){
        Id pId = [select id from user where UserRoleId != null AND Profile.Name = 'System Administrator' LIMIT 1].Id;
        List<Account> testAccts = new List<Account>();
        testAccts.add(new Account(Name = 'TestAcct1',Website='www.test1.com',OwnerId = pId,type='Customer',Partner_Agreement_Status__c ='Signed - Active'));
        testAccts.add(new Account(Name = 'TestAcct2',Website='www.test1.com',OwnerId = pId,type='Prospect'));
        testAccts.add(new Account(Name = 'TestAcct3',Website='www.test1.com',OwnerId = pId,type='Partner'));
        testAccts.add(new Account(Name = 'TestAcct4',Website='www.test1.com',OwnerId = pId,type='Customer',Partner_Agreement_Status__c ='Signed - Active'));
        testAccts.add(new Account(Name = 'TestAcct5',Website='www.test1.com',OwnerId = pId,type='Partner'));
        insert testAccts;
        insert new Entitlement(Name='Testing', AccountId=testAccts[3].Id, StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)));
        List<Contact> testData = new List<Contact>();
        for(Integer i=0;i<j;i++) {
            testData.add(new Contact(FirstName = 'teetl',LastName = 'testl',email='testuser@testuser'+i+1+'.com',phone='testPhone',AccountId = testAccts[i].id,OwnerId =testAccts[i].ownerId ));
        }
        insert testData;
        Set<Id> conIds = new Set<Id>();
        for(Contact c : testData){
            if(testData[4] == c){
                break;
            }
            conIds.add(c.id);
        }
        createPortalUsers(conIds);
        createInactivePortalUser(testData[4].id);
        return testData;
    }
    
    public static List<Contact> createContactWithUser(Integer j){
        List<Account> testAccts = new List<Account>();
        
        testAccts.add(new Account(Name = 'TestAcct1',Website='www.test1.com',OwnerId = [select id from user where UserRoleId != null AND Profile.Name = 'System Administrator' LIMIT 1].Id,type='Prospect'));
        insert testAccts;
        List<Contact> testData = new List<Contact>();
        for(Integer i=0;i<j+1;i++) {
            testData.add(new Contact(FirstName = 'teetl'+i,LastName = 'atestl',email='testuser@testuser'+i+ '' + j +'.com',phone='12345678'+i,AccountId = testAccts[0].id,OwnerId =testAccts[0].ownerId ));
        }
        testData.add(new Contact(FirstName = 'cteetl',LastName = 'ctestl',email='testuser1@testuser2.com',phone='123456787',AccountId = testAccts[0].id,OwnerId =testAccts[0].ownerId ));

        insert testData;
        createPortalUser(testData[0].id);
        createInactivePortalUser(testData[1].id);
        return testData;
    }
    
    @future
    public static void createPortalUser(Id conId){
        Profile pf = [SELECT Id FROM profile WHERE name='Rubrik Customer Community Login User' limit 1]; 
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
        String uniqueName = orgId + dateString + randomInt;        
        User u = new User();
        u.Username = 'testuser@testuser1.com';
        u.ProfileId = pf.Id;
        u.LastName = 'test';
        u.Alias = 'tUser22';
        u.ContactId = conId;
        u.Email = 'testuser@testuser1.com';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.localesidkey='en_US';
        u.emailencodingkey='UTF-8';
        u.languagelocalekey='en_US';
        u.isActive = true;
        insert u;
    }
    
    public static List<Contact> createContactWithPartnerUser(Integer j){
        List<Account> testAccts = new List<Account>();
        
        testAccts.add(new Account(Name = 'TestAcct1',Website='www.test1.com',OwnerId = [select id from user where UserRoleId != null AND Profile.Name = 'System Administrator' LIMIT 1].Id,type='Prospect'));
        insert testAccts;
        List<Contact> testData = new List<Contact>();
        for(Integer i=0;i<j+1;i++) {
            testData.add(new Contact(FirstName = 'teetl',LastName = 'testl',email='testuser@testuser'+i+'.com',phone='testPhone',AccountId = testAccts[0].id,OwnerId =testAccts[0].ownerId ));
        }
        testData.add(new Contact(FirstName = 'teetl',LastName = 'testl',email='testuser@testuser2.com',phone='testPhone',AccountId = testAccts[0].id,OwnerId =testAccts[0].ownerId ));

        insert testData;
        createPartnerPortalUser(testData[0].id);
        return testData;
    }
    
    @future
    public static void createPartnerPortalUser(Id conId){
        Profile pf = [SELECT Id FROM profile WHERE name='Rubrik Partner Community User' limit 1]; 
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
        String uniqueName = orgId + dateString + randomInt;        
        User u = new User();
        u.Username = 'partner.testuser@testuser1.com';
        u.ProfileId = pf.Id;
        u.LastName = 'test';
        u.Alias = 'tpart2';
        u.ContactId = conId;
        u.Email = 'partner@testuser1.com';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.localesidkey='en_US';
        u.emailencodingkey='UTF-8';
        u.languagelocalekey='en_US';
        u.isActive = true;
        insert u;
    }
    
    @future
    public static void createPortalUsers(Set<Id> conIds){
        Profile pf = [SELECT Id FROM profile WHERE name='Rubrik Customer Community Login User' limit 1]; 
        Integer count = 4;
        List<User> usrList = new List<User>();
        for(Id i : conIds){
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
            String uniqueName = orgId + dateString + randomInt;        
            User u = new User();
            u.Username = 'testuser@testuser'+count+'.com';
            u.ProfileId = pf.Id;
            u.LastName = 'test';
            u.Alias = 'tUser22'+count;
            u.ContactId = i;
            u.Email = 'testuser@testuser'+count+'.com';
            u.TimeZoneSidKey = 'America/Los_Angeles';
            u.localesidkey='en_US';
            u.emailencodingkey='UTF-8';
            u.languagelocalekey='en_US';
            u.isActive = true;
            usrList.add(u);
            count++;
        }
        
        insert usrList;
    }
    
    @future
    public static void createInactivePortalUser(Id conId){
        Profile pf = [SELECT Id FROM profile WHERE name='Rubrik Customer Community Login User' limit 1]; 
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
        String uniqueName = orgId + dateString + randomInt;        
        User u = new User();
        u.Username = 'testuser@testuser2.com';
        u.ProfileId = pf.Id;
        u.LastName = 'test';
        u.Alias = 'tUser12';
        u.ContactId = conId;
        u.Email = 'testuser@testuser2.com';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.localesidkey='en_US';
        u.emailencodingkey='UTF-8';
        u.languagelocalekey='en_US';
        u.IsActive = false;
        insert u;
    }

}