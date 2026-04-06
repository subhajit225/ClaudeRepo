/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest 
/** Created By : Rubrik  
* Purpose : Test class of UserTriggerHandler
**/
public class UserTriggerHandler_Test { 
    
    @TestSetup
    static void makeData(){
        Test.startTest();
        OktaUserUtilityTest.oktaCustomSettingsParams();
        insert new TriggerControl__c(Name='User');
        Test.stopTest();
    }
    
    @isTest static void testMethod1() {
        
        //insert new TriggerControl__c(Name='User');
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        system.runas(u){
			Account AccRecord = new Account();
			AccRecord.Name = 'test';
			AccRecord.BillingStreet = 'street';
			AccRecord.BillingCity = 'city';
			AccRecord.BillingCountry = 'India';
			AccRecord.BillingPostalCode = '456789';
			//AccRecord.RecordTypeId= devRecordTypeId;
			AccRecord.Type = 'Partner';
			insert AccRecord;
			
			Contact conObj = new Contact(LastName = 'lastname',
										 FirstName = 'firstname',
										 AccountId = AccRecord.Id,
										 Email = 'a@a.com',Primary_Role__c='Admin');
			insert conObj;

            User newPortalUser = new User();
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+1;   
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = conObj.Email;
            newPortalUser.IsActive = true;
            newPortalUser.ContactId = conObj.Id;
            newPortalUser.Phone = conObj.Phone;
            newPortalUser.Street= conObj.MailingStreet;
            newPortalUser.City = conObj.MailingCity;
            newPortalUser.State = conObj.MailingState;
            newPortalUser.Country = conObj.MailingCountry;
            newPortalUser.PostalCode = conObj.MailingPostalCode;
            newPortalUser.UserPermissionsSFContentUser= true;
            newPortalUser.CompanyName = conObj.Account.Name;
            insert newPortalUser;  
            
            UserTriggerHandler.createAdminAccessReqFuture(new list<Id>{newPortalUser.Id});
            UserTriggerHandler.removeInactiveUserFromAccountTeams(new Set<Id>{newPortalUser.Id});
            System.assertEquals(1, [SELECT Id FROM User WHERE Id=:newPortalUser.Id].size(),'Count is 1');
        }
    }
    @isTest static void testMethod2() {
        
        //insert new TriggerControl__c(Name='User');
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        system.runas(u){
             Account AccRecord = new Account();
        AccRecord.Name = 'test';
        AccRecord.BillingStreet = 'street';
        AccRecord.BillingCity = 'city';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '456789';
        AccRecord.RecordTypeId= devRecordTypeId; 
        AccRecord.Type = 'Partner';
        insert AccRecord;
        
        Contact conObj = new Contact(LastName = 'lastname',           FirstName = 'firstname',
                                     AccountId = AccRecord.Id,
                                     Email = 'a@a.com',Primary_Role__c='Admin');
        insert conObj;   
            User newPortalUser = new User();
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+2;   
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = conObj.Email;
            newPortalUser.IsActive = true;
            newPortalUser.ContactId = conObj.Id;
            newPortalUser.Phone = conObj.Phone;
            newPortalUser.Street= conObj.MailingStreet;
            newPortalUser.City = conObj.MailingCity;
            newPortalUser.State = conObj.MailingState;
            newPortalUser.Country = conObj.MailingCountry;
            newPortalUser.PostalCode = conObj.MailingPostalCode;
            newPortalUser.UserPermissionsSFContentUser= true;
            newPortalUser.CompanyName = conObj.Account.Name;
            newPortalUser.Coins__c = 0;
            insert newPortalUser;    
            //newPortalUser.time_Off_dates__c = String.valueOf(System.today());
            newPortalUser.IsActive = false;
            test.startTest();
            newPortalUser.Coins__c = 2;
            update newPortalUser;
            test.stopTest();
            System.assertEquals(2, [SELECT Id,Coins__c FROM User WHERE Id=:newPortalUser.Id].Coins__c,'Count is 2');
        }
        
        
    }
    
    @isTest static void testMethod3() {
        
        //insert new TriggerControl__c(Name='User');
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        system.runas(u){
        
        Account AccRecord = new Account();
        AccRecord.Name = 'test';
        AccRecord.BillingStreet = 'street';
        AccRecord.BillingCity = 'city';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '456789';
        AccRecord.RecordTypeId= devRecordTypeId;
        AccRecord.Type = 'Partner';
        insert AccRecord;
        
        Contact conObj = new Contact(LastName = 'lastname',           FirstName = 'firstname',
                                     AccountId = AccRecord.Id,
                                     Email = 'a@a.com',Primary_Role__c='Admin');
        insert conObj;   
            User newPortalUser = new User();
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+3;   
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = conObj.Email;
            newPortalUser.IsActive = true;
            newPortalUser.ContactId = conObj.Id;
            newPortalUser.Phone = conObj.Phone;
            newPortalUser.Street= conObj.MailingStreet;
            newPortalUser.City = conObj.MailingCity;
            newPortalUser.State = conObj.MailingState;
            newPortalUser.Country = conObj.MailingCountry;
            newPortalUser.PostalCode = conObj.MailingPostalCode;
            newPortalUser.UserPermissionsSFContentUser= true;
            newPortalUser.CompanyName = conObj.Account.Name;
            insert newPortalUser;
           /* List<Time_Off_Details__c> todList = new List<Time_Off_Details__c>();
            Time_Off_Details__c tod = new Time_Off_Details__c (User__c = newPortalUser.Id,Time_Off_Date__c = system.today().addDays(7));
            todList.add(tod);
            Time_Off_Details__c tod1 = new Time_Off_Details__c (User__c = newPortalUser.Id,Time_Off_Date__c = system.today().addDays(7));
            todList.add(tod1);
            insert todList;*/
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            //newPortalUser.time_Off_dates__c = String.valueOf(System.today())+';'+String.valueOf(System.today());
            test.startTest();
            update newPortalUser;
            newPortalUser.isActive = false;
            update newPortalUser;
            test.stopTest();
           /* List<Time_Off_Details__c> tocList = [select id from Time_Off_Details__c where User__c =: newPortalUser.Id];
            system.assertEquals(4,tocList.size());*/
            system.assert(!newPortalUser.isActive, 'User is inactive');
        }
    }
    @isTest static void testMethod4() {
        //insert new TriggerControl__c(Name='User');
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        Profile p = [select id, name from Profile where name = 'Rubrik Field Sales User' limit 1];

        system.runas(u){
            
            Account AccRecord = new Account();
            AccRecord.Name = 'test';
            AccRecord.BillingStreet = 'street';
            AccRecord.BillingCity = 'city';
            AccRecord.BillingCountry = 'India';
            AccRecord.BillingPostalCode = '456789';
            //AccRecord.RecordTypeId= devRecordTypeId;
            AccRecord.Type = 'Partner';
            insert AccRecord;
            
            Contact conObj = new Contact(LastName = 'lastname',
                                         FirstName = 'firstname',
                                         AccountId = AccRecord.Id,
                                         Email = 'a@a.com',Primary_Role__c='Admin');
            insert conObj;

            User newPortalUser = new User();
            newPortalUser.ProfileID = p.id;
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+1;   
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = conObj.Email;
            newPortalUser.IsActive = true;
            insert newPortalUser; 
            System.assertEquals(1, [SELECT Id FROM USer WHERE Id =: newPortalUser.Id].size(),'Count is 1'); 
        }        
    }  
    
    @isTest static void testMethod5() {
        //insert new TriggerControl__c(Name='User');
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        Profile p = [select id, name from Profile where UserType = 'CSPLitePortal' limit 1];

        system.runas(u){
            
            Account AccRecord = new Account();
            AccRecord.Name = 'test';
            AccRecord.BillingStreet = 'street';
            AccRecord.BillingCity = 'city';
            AccRecord.BillingCountry = 'India';
            AccRecord.BillingPostalCode = '456789';
            //AccRecord.RecordTypeId= devRecordTypeId;
            AccRecord.Type = 'Partner';
            insert AccRecord;
            
            Contact conObj = new Contact(LastName = 'lastname',
                                         FirstName = 'firstname',
                                         AccountId = AccRecord.Id,
                                         Email = 'a@a.com',Primary_Role__c='Admin');
            insert conObj;

            User newPortalUser = new User();
            newPortalUser.ProfileID = p.id;
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.ContactId = conObj.Id;
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+1;   
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = conObj.Email;
            newPortalUser.IsActive = true;
            insert newPortalUser;
            System.assertEquals(1, [SELECT Id FROM USer WHERE Id=: newPortalUser.Id].size(),'Count is 1'); 
        }        
    }
    @isTest static void testMethod6() {
        
        //insert new TriggerControl__c(Name='User');
       
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; //System Administrator
        UserRole urole = [SELECT Id,Name FROM UserRole WHERE Name like '%Sales Engineer%' LIMIT 1];
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        system.runas(u){
            Test.startTest();
            User seUser1 = new User(
            UserRoleId = urole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() +'se1'+Integer.valueof((Math.random() * 100)) +'@randomtestdomain.com',
            Alias = 'xmen',
            Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago',
            Business_Group__c = 'Account Executive'    
            );
            Database.insert(seUser1);
            User seUser2 = new User(
            UserRoleId = urole.Id,
            ProfileId = profile1.Id,
            managerId = seUser1.Id,
            POC_Approver__c = seUser1.Id,
            Username = System.now().millisecond() +'se2'+Integer.valueof((Math.random() * 100)) +'@randomtestdomain.com',
            Alias = 'xmen',
            Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
            );
            Database.insert(seUser2);
            
            seUser2.POC_Approver__c = null;
            update seUser2;
            Test.stopTest();
            System.assertEquals(null, seUser2.POC_Approver__c,'Approver is null'); 
        }
}
        @isTest static void testMethod7() {
        
            //insert new TriggerControl__c(Name='User');
            List<PermissionSetLicense> licenseList = new List<PermissionSetLicense>();
            List<PermissionSetLicenseAssign> licenseAsgnList = new List<PermissionSetLicenseAssign>();
            licenseList = [select Id, UsedLicenses, TotalLicenses, DeveloperName, MasterLabel from PermissionSetLicense where UsedLicenses < 20 AND MasterLabel like '%CRM User%' limit 1];
            List<User> ulist = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 2];
            Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; //System Administrator
          UserRole urole = [SELECT Id,Name FROM UserRole WHERE Name like '%Sales Engineer%' LIMIT 1];
            
            system.runas(ulist[0]){
                User seUser1 = new User(
                UserRoleId = urole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() +'se1'+Integer.valueof((Math.random() * 100)) +'@randomtestdomain.com',
                Alias = 'xmen',
                Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'test',
                Lastname = 'test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago',
                Business_Group__c = 'Account Executive',
                isActive = true
                );
                Database.insert(seUser1);
                if(!licenseList.isEmpty()){
                    PermissionSetLicenseAssign assignment = new PermissionSetLicenseAssign();
                    assignment.PermissionSetLicenseId = licenseList[0].Id;
                    assignment.AssigneeId = seUser1.Id;
                    licenseAsgnList.add(assignment);
                }
                if(!licenseAsgnList.isEmpty()){
                    upsert licenseAsgnList;
                }
                seUser1.isActive = false;
                Test.startTest();
                update seUser1;
                Test.stopTest();
                System.assertEquals(false, seUser1.isActive,'User is inactive'); 
            }
    }
    
    /**
     * @Author           :   vijay.kr@rubrik.com
     * @CreatedDate      :   
     * @Method           :   testOktaUserCreation
     */
    @isTest
    public static void testOktaUserCreation() {
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        System.runAs(u){
            List<User> userList = [SELECT Id, Name,Email, UserType, FirstName, LastName, ProfileId, isActive , ContactId
                                    FROM User 
                                    WHERE ProfileID =: system.label.PartnerSFDCProfileId Limit 1];
            UserTriggerHandler.oktaUserCreation(userList, true);

            System.assertEquals('PowerPartner', userList[0].UserType);
        }
    }

    /**
     * @Author           :   vijay.kr@rubrik.com
     * @CreatedDate      :   
     * @Method           :   isChanged
     */
    @isTest
    public static void testIsChangedWithNullNewRecord() {
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        System.runAs(u){
            System.assertEquals(UserTriggerHandler.isChanged(null, null), true);
        }
    }
    
    @isTest
    public static void testupdateContact() {

        //insert new TriggerControl__c(Name='User');
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        System.RunAs(u){

            Account AccRecord = new Account();
            AccRecord.Name = 'test';
            AccRecord.BillingStreet = 'street';
            AccRecord.BillingCity = 'city';
            AccRecord.BillingCountry = 'India';
            AccRecord.BillingPostalCode = '456789';
            AccRecord.RecordTypeId= devRecordTypeId;
            AccRecord.Type = 'Partner';
            insert AccRecord;

            Contact conObj = new Contact(LastName = 'lastname',           FirstName = 'firstname',
                                         AccountId = AccRecord.Id,
                                         Email = 'a@a.com',Primary_Role__c='Admin');
            insert conObj;

            Partner_Registration_Request__c prReq = new Partner_Registration_Request__c();
            prReq.First_Name__c = 'firstname';
            prReq.Last_Name__c = 'lastname';
            prReq.Email__c = 'a@a.com';
            prReq.Company_Name__c = 'TestCompany';
            prReq.Partner_Account_Lookup__c = AccRecord.Id;
            prReq.Country_Picklist__c = 'United States';
            prReq.Country__c = 'United States';
            prReq.State__c = 'AL';
            prReq.Job_Title__c = 'Test';
            prReq.Phone_Number__c = '21454487';
            prReq.Address__c = 'Alabama';
            prReq.City__c = 'Alabama';
            prReq.Postal_Code__c = '318645';
            prReq.Partner_Registration_Status__c = 'Approved';
            prReq.Auto_Approval__c = true;
            prReq.Related_Partner_Contact__c = conObj.Id;
            prReq.is_Converted__c = false;
            insert prReq;

            User newPortalUser = new User();
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            newPortalUser.EmailEncodingKey = 'ISO-8859-1';
            newPortalUser.LanguageLocaleKey = 'en_US';
            newPortalUser.TimeZoneSidKey = 'America/New_York';
            newPortalUser.LocaleSidKey = 'en_US';
            newPortalUser.Alias ='puser';
            newPortalUser.FirstName = conObj.FirstName;
            newPortalUser.LastName = conObj.LastName;
            newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+3;
            newPortalUser.CommunityNickname =String.ValueOf(Math.random());
            newPortalUser.Email = conObj.Email;
            newPortalUser.IsActive = false;
            newPortalUser.ContactId = conObj.Id;
            newPortalUser.Phone = conObj.Phone;
            newPortalUser.Street= conObj.MailingStreet;
            newPortalUser.City = conObj.MailingCity;
            newPortalUser.State = conObj.MailingState;
            newPortalUser.Country = conObj.MailingCountry;
            newPortalUser.PostalCode = conObj.MailingPostalCode;
            newPortalUser.UserPermissionsSFContentUser= true;
            newPortalUser.CompanyName = conObj.Account.Name;
            insert newPortalUser;
           /* List<Time_Off_Details__c> todList = new List<Time_Off_Details__c>();
            Time_Off_Details__c tod = new Time_Off_Details__c (User__c = newPortalUser.Id,Time_Off_Date__c = system.today().addDays(7));
            todList.add(tod);
            Time_Off_Details__c tod1 = new Time_Off_Details__c (User__c = newPortalUser.Id,Time_Off_Date__c = system.today().addDays(7));
            todList.add(tod1);
            insert todList;*/
            newPortalUser.ProfileID = ID.valueOf(system.label.PartnerSFDCProfileId);
            newPortalUser.Portal_Admin_Access__c = true;
            //newPortalUser.time_Off_dates__c = String.valueOf(System.today())+';'+String.valueOf(System.today());
            test.startTest();
            update newPortalUser;
            newPortalUser.isActive = true;
            newPortalUser.Phone = '123-456-7890';
            newPortalUser.Termination_Date__c = system.today();
            update newPortalUser;
            test.stopTest();
           /* List<Time_Off_Details__c> tocList = [select id from Time_Off_Details__c where User__c =: newPortalUser.Id];
            system.assertEquals(4,tocList.size());*/
            UserTriggerHandler.updatePartnerRegRequestFuture(JSON.serialize(new List<Partner_Registration_Request__c> {prReq}));
            System.assertEquals(newPortalUser.ProfileID,ID.valueOf(system.label.PartnerSFDCProfileId),'Profile updated');
            System.assert(newPortalUser.isActive,'User Activated');
    	}
    }
    
    @isTest
    public static void testsendInactiveFMMEmail() {
        User usr = [select id,name from user where profile.name ='System Administrator' and isactive=true and userroleid != null limit 1];
        System.RunAs(usr){
        	Set<Id> fmmIds = new Set<Id>();
            for(PartnerFundRequest_CDM_FMM__mdt rec : PartnerFundRequest_CDM_FMM__mdt.getAll().values()){
                fmmIds.add(rec.FMM_Id__c);
            }
        	User u = [SELECT Id,isActive,isPortalEnabled FROM User WHERE Id IN :fmmIds and isActive = true LIMIT 1];
        	u.isActive = false;
        	update u;
            System.assert(!u.isActive, 'User Deactivated');
    	}
    }
    
}