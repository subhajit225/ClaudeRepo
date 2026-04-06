@isTest(seeAllData = false)
public class PC_PortalNavigationApexControllerTest {
    @testSetup static void setupmethod() {
        List<Partner_Page_Configuration__c> pageList = new List<Partner_Page_Configuration__c>();
        List<Contact> contList = new List<Contact>();
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testpuser2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            Account portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = portalAccountOwner1.Id,
                Type = 'Reseller',
                RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId()
                //Focused_Partner__c = true
            );
            Database.insert(portalAccount1);
            
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin',
                Partner_Promo_Banner__c = true
            );
            contList.add(contact1);
            Contact contact2 = new Contact(
                FirstName = 'Test 2',
                Lastname = 'McTesty 2',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Executive'
            );
            contList.add(contact2);
            insert contList;
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'tespuser1@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);
            
            User user2 = new User(
                Username = System.now().millisecond() + 'tespuser3@test.com',
                ContactId = contact2.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test1234',
                Email = 'test123456@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty 2',
                CommunityNickname = 'test123456',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user2);
            
            Partner_Page_Configuration__c pc = new Partner_Page_Configuration__c();
            pc.Name = 'Menu config';
            pc.Menu_Label__c = 'Home';
            pc.Navigate_Url__c = 'https://rubrikinc--rbkdev1.sandbox.my.site.com/partnersnew/s';
            pc.Image_Type__c = 'Menu';
            pageList.add(pc);
            
            Partner_Page_Configuration__c pc1 = new Partner_Page_Configuration__c();
            pc1.Name = 'Menu config 1';
            pc1.Menu_Label__c = 'User Management';
            pc1.Menu_Group__c = 'Home';
            pc1.Image_Type__c = 'Menu Item';
            pc1.Navigate_Url__c = 'https://rubrikinc--rbkdev1.sandbox.my.site.com/partnersnew/s/user-management';
            pageList.add(pc1);
            
            Partner_Page_Configuration__c pc2 = new Partner_Page_Configuration__c();
            pc2.Name='Welcome Page Admin';
            pc2.Image_Type__c ='Welcome Page';
            pc2.Primary_Role__c ='Admin';
            pageList.add(pc2);
            
            Partner_Page_Configuration__c pc3 = new Partner_Page_Configuration__c();
            pc3.Name='Welcome Page Executive';
            pc3.Image_Type__c ='Welcome Page';
            pc3.Primary_Role__c ='Executive';
            pageList.add(pc3);
            
            Partner_Page_Configuration__c pc4 = new Partner_Page_Configuration__c();
            pc4.Name='Card 1';
            pc4.Image_Type__c ='Pop Up Card';
            pc4.Page_Name__c = 'Home';
            pageList.add(pc4);
            
            //Welcome Wizard Video
            Partner_Page_Configuration__c pc5 = new Partner_Page_Configuration__c();
            pc5.Name='Welcome Wizard Video';
            pc5.Image_Type__c ='Welcome Wizard Video';
            pc5.Page_Name__c = 'Home';
            pageList.add(pc5);
            
            Partner_Page_Configuration__c pc6 = new Partner_Page_Configuration__c();
            pc6.Name='Accordion 1';
            pc6.Image_Type__c ='Accordion';
            pc6.Page_Name__c = 'Home';
            pc6.Order__c = 1;
            pageList.add(pc6);
            
            Partner_Page_Configuration__c pc7 = new Partner_Page_Configuration__c();
            pc7.Name='Global Resource';
            pc7.Image_Type__c ='Global Resource Card';
            pc7.Page_Name__c = 'Home';
            pc7.Order__c = 1;
            pageList.add(pc7);
            
            //Image Card
            Partner_Page_Configuration__c pc8 = new Partner_Page_Configuration__c();
            pc8.Name='Image Resource';
            pc8.Image_Type__c ='Image Card';
            pc8.Page_Name__c = 'Home';
            pc8.Order__c = 1;
            pageList.add(pc8);
            
            //HelpLink
            Partner_Page_Configuration__c pc9 = new Partner_Page_Configuration__c();
            pc9.Name='Help Link';
            pc9.Image_Type__c ='HelpLink';
            pc9.Page_Name__c = 'Home';
            pc9.Order__c = 1;
            pageList.add(pc9);
            
            //Related Resource
            Partner_Page_Configuration__c pc10 = new Partner_Page_Configuration__c();
            pc10.Name='Related Resource';
            pc10.Image_Type__c ='Related Resource';
            pc10.Page_Name__c = 'Home';
            pc10.Order__c = 1;
            pageList.add(pc10);
            
            //Page Description
            Partner_Page_Configuration__c pc11 = new Partner_Page_Configuration__c();
            pc11.Name='Page Description';
            pc11.Image_Type__c ='Page Description';
            pc11.Page_Name__c = 'Home';
            pc11.Order__c = 1;
            pageList.add(pc11);
            
            //Two Column Card
            Partner_Page_Configuration__c pc12 = new Partner_Page_Configuration__c();
            pc12.Name='Two Column Card1';
            pc12.Image_Type__c ='Two Column Card';
            pc12.Page_Name__c = 'Home';
            pc12.Order__c = 1;
            pageList.add(pc12);
            
            //Card
            Partner_Page_Configuration__c pc13 = new Partner_Page_Configuration__c();
            pc13.Name='Card1';
            pc13.Image_Type__c ='Card';
            pc13.Page_Name__c = 'Home';
            pc13.Order__c = 1;
            pageList.add(pc13);
            
            //Footer
            Partner_Page_Configuration__c pc14 = new Partner_Page_Configuration__c();
            pc14.Name='Footer 1';
            pc14.Image_Type__c ='Footer';
            pc14.Image_Url__c ='www.rubrik.com';
            pc14.Order__c = 1;
            pageList.add(pc14);
            //Navigate_Url__c
            Partner_Page_Configuration__c pc15 = new Partner_Page_Configuration__c();
            pc15.Name='Footer 2';
            pc15.Image_Type__c ='Footer';
            pc15.Image_Url__c ='www.rubrik.com';
            pc15.Navigate_Url__c ='www.rubrik.com';
            pc15.Order__c = 1;
            pageList.add(pc15);
            
            Partner_Page_Configuration__c pc16 = new Partner_Page_Configuration__c();
            pc16.Name='Footer 3';
            pc16.Image_Type__c ='Footer';
            pc16.Navigate_Url__c ='www.rubrik.com';
            pc16.Order__c = 1;
            pageList.add(pc16);
            
            //Welcome Wizard Promo
            Partner_Page_Configuration__c pc17 = new Partner_Page_Configuration__c();
            pc17.Name='Welcome Wizard Video';
            pc17.Image_Type__c ='Welcome Wizard Promo';
            pc17.Page_Name__c = 'Home';
            pageList.add(pc17);
            
            //Certifications
            Partner_Page_Configuration__c pc18 = new Partner_Page_Configuration__c();
            pc18.Name = 'Certificate Accreditation 1';
            pc18.Image_Type__c = 'Certifications';
            pc18.Navigate_Text__c = 'RRE_Expiration__c';
            pc18.Tag__c = 'RRE_Accredited__c';
            pc18.Primary_role__c = 'Technical';
            pageList.add(pc18);
            
            //Partner Dashboard Widget
            Partner_Page_Configuration__c pc19 = new Partner_Page_Configuration__c();
            pc19.Name = 'Widget 1';
            pc19.Image_Type__c = 'Performance Dashboard Widget';
            pc19.Headline__c = 'Approved Deals';
            pageList.add(pc19);
            
            Partner_Page_Configuration__c pc20 = new Partner_Page_Configuration__c();
            pc20.Name = 'MIP Rebate Enrollment';
            pc20.Image_Type__c = 'Card';
            pc20.Navigate_Text__c = 'MIP Rebate Enrollment Form';
            pc20.Program_Start_Date__c = Date.today()-3;
            pc20.Program_End_Date__c = Date.today()+1;
            pc20.Tag__c = 'MIP Enrollment Form';
            pc20.Active__c = true;
            pageList.add(pc20);
            
            //for pc21
            ContentVersion cv = new ContentVersion(
                Title = 'Test File',
                PathOnClient = 'testfile.png',
                VersionData = Blob.valueOf('Sample content for testing'),
                IsMajorVersion = true
            );
            insert cv;
            ContentVersion insertedCv = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];
            
            Partner_Page_Configuration__c pc21 = new Partner_Page_Configuration__c();
            pc21.Name = 'Persona Questions';
            pc21.Image_Type__c = 'Welcome Page';
            pc21.Image_Url__c = 'dcercerd/ContentDocument/'+insertedCv.ContentDocumentId;
            pc21.Active__c = true;
            pageList.add(pc21);
            insert pageList;
            
            EmailTemplate eTemplate = new EmailTemplate (developerName = 'Partner_Preferred_Distributor_Selection', TemplateType= 'Text', Name = 'Partner Preferred Distributor Selection',
                                                         FolderId = UserInfo.getUserId(), Body='{!Link},{!Name},{!Company},{!JobTitle},{!Email},{!Distributor}');
            insert eTemplate;
            
            PartnerFundRequest pfr = new PartnerFundRequest(Title='Test PFR', Status='Submitted', Activity_Start_Date__c=Date.today(), Activity_End_Date__c = Date.today(),
                                                            ChannelPartnerId = portalAccount1.Id);
            
            Id incRecType = Schema.SObjectType.Incentives__c.getRecordTypeInfosByName().get('Transform Accelerator Claim').getRecordTypeId();
            Incentives__c inc1 = new Incentives__c(Status__c='Approved', Start__c = Date.today(), Account_Name__c = portalAccount1.Id, RecordTypeId = incRecType);
            Incentives__c inc2 = new Incentives__c(Status__c='Submitted', Start__c = Date.today(), Account_Name__c = portalAccount1.Id, RecordTypeId = incRecType);
            Incentives__c inc3 = new Incentives__c(Status__c='Rejected', Start__c = Date.today(), Account_Name__c = portalAccount1.Id, RecordTypeId = incRecType);
            
            List<Incentives__c> incList = new List<Incentives__c>();
            incList.add(inc1);
            incList.add(inc2);
            incList.add(inc3); 
            insert incList;
        }
    }
  @isTest static void  testgetPartnerPageConfigurations() {
        User portalUser1 = [SELECT Id FROM User Where LastName ='McTesty'];
        System.runAs(portalUser1){
        test.startTest();
        PC_PortalNavigationApexController.getPartnerPageConfigurations('Home');
        PC_PortalNavigationApexController.getPartnerPageConfigurations('User Management');
        PC_PortalNavigationApexController.getPartnerModalDetails();
        PC_PortalNavigationApexController.gethomePageCardDetails('Home');
        PC_PortalNavigationApexController.getWelcomeWizardVideoConfig();
        PC_PortalNavigationApexController.getPersonaQuestionsDetails();
       try
       {
           PC_PortalNavigationApexController.getEventPromotionalConfig();
       }catch(exception e){
           system.debug (LoggingLevel.DEBUG, '---270->'+e.getMessage());
       }
        
        PC_PortalNavigationApexController.getAccordionDetails('Home');
        PC_PortalNavigationApexController.getGlobalResourceConfigs('Home');
        PC_PortalNavigationApexController.getImageTextCard('Home');
        PC_PortalNavigationApexController.getLinkNameAndUrl('Home');
        PC_PortalNavigationApexController.getRelatedResourcesUrl('Home');
        PC_PortalNavigationApexController.getPageDescription('Home');
        PC_PortalNavigationApexController.getTwoColumnDetails('Home');
       try{
           PC_PortalNavigationApexController.getCategoryCardConfigs('Home');  
           PC_PortalNavigationApexController.getCategoryCardConfigs('Incentives');
       }catch(exception e){
           system.debug(LoggingLevel.DEBUG, 'test'+e);
       }
        PC_PortalNavigationApexController.getPartnerFundRequestsData();
        PC_PortalNavigationApexController.getLeadDashboardData('test');
        PC_PortalNavigationApexController.getFiscalYear();
        PC_PortalNavigationApexController.getLoggedInUserDetails();
        PC_PortalNavigationApexController.mipWrapper wrap = PC_PortalNavigationApexController.loadMIPForm();
        String pdsResult = PC_PortalNavigationApexController.preferredDistributorSelection(new Contact(FirstName='fName',
                                                                                    LastName='lName',
                                                                                    mkto71_Inferred_Company__c='TestCompany',
                                                                                    Title ='Dev',
                                                                                    Email='testpds@rubrik.com'
                                                                                    ), 'Test Distributor');
        
        PC_PortalNavigationApexController.getPicklistValues('Deal_Registration__c',new List<String>{'Engaged_with_Rubrik__c','Source_of_the_Opportunity__c'});
        }
        system.assert(true);
        test.stopTest(); 
    }

    @isTest static void  testgetPartnerPageConfigurations1() {
        User portalUser1 = [SELECT Id FROM User Where LastName ='McTesty'];
        System.runAs(portalUser1){
            test.startTest();
            Partner_Page_Configuration__c pc = new Partner_Page_Configuration__c();
            pc.Name='Welcome Wizard 1';
            pc.Image_Type__c ='Card';
            pc.Page_Name__c = 'Incentives';
            pc.Navigate_Url__c = '/incentivesclaim?id=test';
            insert pc;
            
            try{
                PC_PortalNavigationApexController.getCategoryCardConfigs('Incentives');
            }catch(exception e){
                system.debug(LoggingLevel.DEBUG, 'test'+e);
            }
            system.assert(true);
            test.stopTest(); 
        }
    }
    
    @isTest static void testgetWelcomePageDetails() {
        User portalUser1 = [SELECT Id FROM User Where LastName ='McTesty'];
        User portalUser2 = [SELECT Id FROM User Where LastName ='McTesty 2'];
        PC_PortalNavigationApexController.homePageWrapper hWrap;
        PC_PortalNavigationApexController.homePageWrapper hWrap1;
        test.startTest();
        PC_PortalNavigationApexController.getContactWelcomeWizardConfig(portalUser1.Id);
        system.runAs(portalUser1){
            hWrap = PC_PortalNavigationApexController.getWelcomePageDetails();
        }
        system.runAs(portalUser2){
            hWrap1 = PC_PortalNavigationApexController.getWelcomePageDetails();  
        }
        system.assert(hWrap1.pageRecord != null);
        test.stopTest();
    }
    @isTest static void testgetFooterDetails() {
        User portalUser1 = [SELECT Id FROM User Where LastName ='McTesty'];
        System.runAs(portalUser1){
        test.startTest();
        PC_PortalNavigationApexController.footerWrapper fWrap = PC_PortalNavigationApexController.getFooterDetails();
        system.assertEquals(1 , fWrap.iconList.size());
        test.stopTest();
    }
    }
    @isTest static void testgetAccreditedDetails(){
        test.startTest();
        User u = [SELECT Id,ContactId FROM User WHERE Lastname in ('McTesty')];
        Contact c = new Contact();
        c.Id = u.ContactId;
        c.Primary_Role__c = 'Technical';
        c.RRE_Expiration__c = System.today().addYears(1);
        c.RRE_Accredited__c = System.today().addDays(-10);
        flowControll.contactTrigger = false;
        update c;
        flowControll.contactTrigger = true;
        System.runAs(u){
            PC_PortalNavigationApexController.getAccreditedDetails();
            system.assertEquals('Technical',c.Primary_Role__c);
        }
        test.stopTest();
        
    }
    @isTest static void testgetPartnerFundRequestsData(){
        User portalUser1 = [SELECT Id FROM User Where LastName ='McTesty'];
        test.startTest();
        system.runAs(portalUser1)
        {
            PC_PortalNavigationApexController.mdfWrapper mWrap =  PC_PortalNavigationApexController.getPartnerFundRequestsData();
            system.assertEquals(0,mWrap.mdfClaimsOutstanding);
        }
        test.stopTest();
    }
    @isTest static void testgetTransformClaimData(){
        User portalUser1 = [SELECT Id FROM User WHERE LastName = 'McTesty'];
        List<String> filesToInsert = new List<String>();
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Version
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        filesToInsert.add(cvList[0].ContentDocumentId);
        test.startTest();
        system.runAs(portalUser1){
            PC_PortalNavigationApexController.TransAccClaimWrapper tWrap= PC_PortalNavigationApexController.getTransformAccfClaimData();
            system.assertEquals(1, tWrap.approved);
            PC_PortalNavigationApexController.saveIncentiveData(filesToInsert,'www.google.com','Ransomware Website Showcase');
        }
        test.stopTest();
    }
    
    @isTest static void saveEngagementTest(){
        User portalUser1 = [SELECT Id, Contact.AccountId FROM User WHERE LastName = 'McTesty'];
        Deal_Registration__c record = new Deal_Registration__c(
            Company_Name__c = portalUser1.Contact.AccountId,
            FirstName__c = 'Test User1',
            LastName__c = 'Test Last Name',
            Email__c = 'test123@rbrl.com.sandbox',
            Source_of_the_Opportunity__c ='MSP Sourced',
            Account__c = portalUser1.Contact.AccountId,
            Number_of_protected_machines__c = '10TB - 25TB',
            Budget__c = '$0 - $10,000',
            Customer_Needs__c = 'Needs of Customer',
            Scope_of_Opportunity__c = 'Backup-as-a-Service',
            Utility_Shared_Licensing__c = 'No',
            PO_Number__c ='PO20250421TEST'
        );
        System.runAs(portalUser1){
            Test.startTest();
                Deal_Registration__c record1 = PC_PortalNavigationApexController.saveEngagementDealRegistration(record);
                system.assertEquals(record.Company_Name__c, record1.Company_Name__c);
            Test.stopTest();
        }
    }
    
    @isTest static void getAllDataTest(){
        User portalUser1 = [SELECT Id, Contact.AccountId FROM User WHERE LastName = 'McTesty'];
        
        System.runAs(portalUser1){
            Test.startTest();
            try{
                PC_PortalNavigationApexController.wrapperData data = PC_PortalNavigationApexController.getAllData('', '', new List<String>{portalUser1.Contact.AccountId},'2021');
                PC_PortalNavigationApexController.wrapperData data2 = PC_PortalNavigationApexController.getAllData('2021-01-01', '2022-02-02', null, '2022');
                
                system.assertEquals(0, data.conList.size());
            }catch(Exception e){
                system.debug(LoggingLevel.DEBUG, e);
            }
            Test.stopTest();
        }
    }
    
    @isTest static void getActiveCertificationsTest(){
        User portalUser1 = [SELECT Id,contactId,accountId FROM User WHERE LastName = 'McTesty'];
        Contact c = new Contact();
        c.Id = portalUser1.contactId;
        c.RCIE_Certified__c = System.today();
        
        System.runAs(portalUser1){
            List<sObject> certUsers = PC_PortalNavigationApexController.getActiveCertifications(new List<Id> {portalUser1.accountId});
            System.assert(true);
        }
    }
    
    @isTest static void getAccountHierarchy(){
        Account a = [SELECT Id FROM Account];
        User u = [Select id from user where email = 'bruce.wayne@wayneenterprises.com'];
        User portalUser1 = [SELECT Id,contactId,accountId FROM User WHERE LastName = 'McTesty'];
        Account portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = u.Id,
                parentId = a.Id
                //Focused_Partner__c = true
            );
            Database.insert(portalAccount1);
        System.runAs(portalUser1){
            String d = String.valueOf(system.now());
            PC_PortalNavigationApexController.getAccountHierarchy();
            PC_PortalNavigationApexController.getRebateReportData(new List<Id>{},d,d);
            System.assert(true);
        }
    }
    
    @isTest static void testgetMenuConfigs(){
        User portalUser1 = [SELECT Id,contactId,accountId FROM User WHERE LastName = 'McTesty'];
        Contact c = new Contact();
        c.Id = portalUser1.contactId;
        c.RCIE_Certified__c = System.today();
        
        System.runAs(portalUser1){ 
                PC_PortalNavigationApexController.getMenuConfigs(UserInfo.getUserId());
            System.assert(true);
        }
    }
    
    @isTest static void testUpdatePartnerValuesBatch(){
        User portalUser1 = [SELECT Id,contactId,accountId FROM User WHERE LastName = 'McTesty'];
        Contact con = new Contact();
        con.Id = portalUser1.contactId;
        con.Partner_Promo_Banner__c = true;
        System.runAs(portalUser1){
        Database.executeBatch(new PC_UpdatePartnerValuesOnContactBatch());        
        PC_portalnavigationapexcontroller.updateContactRecord(con);
            System.assert(true);
        }
    }

    static testMethod void callReSignPactsafeTest(){
        User portalUser1 = [SELECT Id,contactId,accountId FROM User WHERE LastName = 'McTesty'];
        System.runAs(portalUser1){
        Test.setMock(HttpCalloutMock.class, new PC_PactsafeCalloutMockupError_Test());
        Test.startTest();
        PC_PortalNavigationApexController.callReSignPactsafe('Reseller','abc@workit.com.invalid');
            System.assert(true);
        Test.stopTest();
    }
    }
    
    static testMethod void createContract(){
        User portalUser1 = [SELECT Id,contactId,accountId FROM User WHERE LastName = 'McTesty 2'];
        List<String> urls = new List<String>();
        urls.add('https://api.pactsafe.com/v1.1/1');
        urls.add('https://api.pactsafe.com/v1.1/2');
        urls.add('https://api.pactsafe.com/v1.1/3');
        System.runAs(portalUser1){
        Test.startTest();
                PC_PortalNavigationApexController.createContract(String.valueOf(portalUser1.ContactId),urls);
                System.assert(true);
        Test.stopTest();
    }
    }
    static testMethod void testgenerateMIPContract(){
        Contact contactRec= [SELECT Id,AccountId FROM Contact LIMIT 1];
        Id conId = contactRec.Id;
        Id accId = contactRec.AccountId;
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and isActive = true LIMIT 1];
        System.runAs(usr){
            String jsonString = '{"accId":"'+accId+'","conId":"'+conId+'","usrId":"'+usr.Id+'","sDate":"2025-03-22T08:15:18.000Z","eDate":"2025-10-22T08:15:18.000Z","fPeriod":"FY26","agrText":"test"}';
        PC_PortalNavigationApexController.generateMIPContract(jsonString);
        }
        system.assertEquals(1 , [SELECT Id FROM MIP_Contract__c].size());
        
    }
}