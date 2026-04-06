@isTest
public class DealRegHomeExtnClass_Test{
    @testSetup static void methodName() {
        UserRole r=[Select id from userrole where name='CEO'];
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'TestUser101',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId =r.Id
        );
        insert u; 
        
    }
    static testMethod void testMethod1() {
        User ur=[Select userrole.Name from User where lastname='TestUser101'];
        System.runAs(ur){
            Test.startTest();
            Account acc=new Account(Name='Rubrik');
            insert acc;
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            for(integer i=0;i<=29;i++) {
                dealList.add(new Deal_Registration__c(Partner_Lookup__c=acc.Id,Deal_Registration_Status__c='Submitted'));
                System.debug('List:'+dealList);
            }
           
            insert dealList;  
            Test.stopTest();
            Test.setCurrentPageReference(new PageReference('Page.DealRegHome')); 
            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(dealList);
            DealRegHomeExtnClass controller = new DealRegHomeExtnClass(sc);
            Deal_Registration__c[] allLeads = controller.getDealRegs();
            controller.searchText='Approved';
            controller.Beginning();
            controller.Next();
            controller.Previous();
            controller.Beginning();
            controller.End();
            controller.getsearchByList();
            controller.searchBy='Company';
            controller.searchManagers();     
            Boolean boolprev = controller.getDisablePrevious();
            Boolean boolnext = controller.getDisableNext();
            Integer totalsize = controller.getTotal_size();
            Integer pageNum = controller.getPageNumber();
            Integer totalPages = controller.getTotalPages();
            System.debug('totalPages' +totalPages);
            system.assertEquals(totalPages,2);
            
        }   
    }

    static testMethod void testMethod2() {
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];

        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'portalAccountOwner1@randomtestdomain.com',
            Alias = 'batman',
            Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        
        Account portalAccount1;
        User portalUser;

        System.runAs(portalAccountOwner1) {
        //Create account
        portalAccount1 = new Account(
            Name = 'TestAccount',
            OwnerId = portalAccountOwner1.Id
        );
        Database.insert(portalAccount1);

        //Create contact
        Contact contact1 = new Contact(
            FirstName = 'Test',
            Lastname = 'McTesty',
            AccountId = portalAccount1.Id,
            Email = System.now().millisecond() + 'test@test.com'
        );
        Database.insert(contact1);
        
         Profile portalProfile = [SELECT Id FROM Profile Where UserType = 'PowerPartner' Limit 1];
         portalUser = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = System.now().millisecond() + 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(portalUser);
        }
        
        System.runAs(portalUser){
            Test.startTest();
            Account acc=new Account(Name='Rubrik');
            insert acc;
            List<Deal_Registration__c> dealList = new List<Deal_Registration__c>();
            for(integer i=0;i<=29;i++) {
                dealList.add(new Deal_Registration__c(Partner_Lookup__c=acc.Id,Deal_Registration_Status__c='Submitted'));
                System.debug('List:'+dealList);
            }
           
            insert dealList;  
            Test.stopTest();
            Test.setCurrentPageReference(new PageReference('Page.DealRegHome')); 
            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(dealList);
            DealRegHomeExtnClass controller = new DealRegHomeExtnClass(sc);
            controller.searchText='Approved';
            controller.sortOrder='fName';
            Deal_Registration__c[] allLeads = controller.getDealRegs();
            DealRegHomeExtnClass value=controller.degExt;
            
            
            
        }   
    }
   
}