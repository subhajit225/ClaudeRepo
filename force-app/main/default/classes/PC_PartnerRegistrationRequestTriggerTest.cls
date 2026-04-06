@isTest
public class PC_PartnerRegistrationRequestTriggerTest {
	@testSetup static void setupmethod() {
        Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
		Userrole usrRole = [SELECT Id FROM UserRole WHERE DeveloperName='Channel_Development_Manager'];
        String userName = 'PRUsr';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testuserdetail@gmail.com'+userName, UserRoleId = usrRole.Id);
        System.runAs(u){
            Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            accRec.Name = 'TestCompany';
            update accRec;
                        
            List<Contact> contList = ShGl_TestFactory.testMethod_PartnerContact(2,accRec);
            contList[0].Email = 'abc2@gmailtest.sandbox.com';
            contList[1].Email = 'abc3@gmailtest.sandbox.com';
            update contList;
            
            CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
            CountrySetting1.Name = 'United States';
            CountrySetting1.Code__c = 'US';
            insert CountrySetting1;
    
            StateCodeName__C stateSetting1 = new StateCodeName__C();
            stateSetting1.Name = 'US-AL';
            stateSetting1.State_Name__c = 'Alabama';
            insert stateSetting1;
            
            User portalUser = ShGl_TestFactoryHelper.createPortalUser(1,contList[1]); 
            portalUser.isActive = false;
            insert portalUser;
        }
	}
	
	@isTest
    public static void testPRWithoutContact(){
        Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'admin';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='admintestuser@gmail.com'+userName);
		System.runAs(u){
            Partner_Registration_Request__c prReq = createPR();
            prReq.First_Name__c = 'Test1';
            prReq.Partner_Registration_Status__c = 'Approved';
            prReq.Auto_Approval__c = true;
            insert prReq;
            
            List<Contact> clist = [SELECT Id FROM Contact WHERE FirstName = : prReq.First_Name__c];
			System.assertEquals(1,clist.size(),'Contact created Successfully');
    	}
    }
    
	@isTest
    public static void testPRWithoutUser(){
		Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'admin';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='admintestuser@gmail.com'+userName);
		System.runAs(u){
			Id contId = [SELECT Id FROM Contact WHERE Email ='abc2@gmailtest.sandbox.com' LIMIT 1].Id;
       
			Partner_Registration_Request__c prReq = createPR();
			prReq.First_Name__c = 'Test2';
			prReq.Partner_Registration_Status__c = 'Approved';
			prReq.Auto_Approval__c = true;
			prReq.Related_Partner_Contact__c = contId;
            insert prReq;
            
            List<Contact> cList = [SELECT Id FROM Contact WHERE Email = 'abc2@gmailtest.sandbox.com'];
			System.assertNotEquals(2,cList.size(),'No extra contacts created');
        }
    }
	
	@isTest
    public static void testPRWithInactiveUser(){
		Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'admin';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='admintestuser@gmail.com'+userName);
		System.runAs(u){
			Id contId = [SELECT Id FROM Contact WHERE Email = 'abc3@gmailtest.sandbox.com' LIMIT 1].Id;
            
			Partner_Registration_Request__c prReq = createPR();
			prReq.First_Name__c = 'Test3';
			prReq.Partner_Registration_Status__c = 'Approved';
			prReq.Auto_Approval__c = true;
			prReq.Related_Partner_Contact__c = contId;
            insert prReq;
            
            List<User> ulist = [SELECT Id FROM User WHERE Email = 'abc3@gmailtest.sandbox.com'];
			System.assertEquals(1,ulist.size(),'User activated Successfully');
        }
    }
    
    @isTest
    public static void testPRWithActiveUser(){
		Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'admin';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='admintestuser@gmail.com'+userName);
		System.runAs(u){
			Id contId = [SELECT Id FROM Contact WHERE Email = 'abc3@gmailtest.sandbox.com' LIMIT 1].Id;
            Id accId = [Select Id from Account Where Name = 'TestCompany' LIMIT 1].Id;
			List<User> ulist = [SELECT Id FROM User WHERE Email = 'abc3@gmailtest.sandbox.com'];
            
			Partner_Registration_Request__c prReq = createPR();
			prReq.First_Name__c = 'Test3';
            prReq.Email__c = 'abc3@gmailtest.sandbox.com';
			prReq.Partner_Registration_Status__c = 'Submitted';
            insert prReq;
            
            prReq.Partner_Registration_Status__c = 'Approved';
			prReq.Partner_Account_Lookup__c = accId;
            update prReq;
            
			System.assertEquals(1,ulist.size(),'User activated Successfully');
        }
    }
    
    @isTest
    public static void testPRWithManualApproval(){
		Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'admin';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='admintestuser@gmail.com'+userName);
		System.runAs(u){ 
			Partner_Registration_Request__c prReq = createPR();
			prReq.First_Name__c = 'Test4';
			prReq.Partner_Registration_Status__c = 'Submitted';
            insert prReq;
            
			prReq.Partner_Registration_Status__c = 'Approved';
			update prReq;
            
            List<Partner_Registration_Request__c> plist = [SELECT Id, Partner_Registration_Status__c FROM Partner_Registration_Request__c];
			System.assertEquals('Approved',plist[0].Partner_Registration_Status__c,'PR is approved');
		}
    }
    
    @isTest
    public static void testPRWithError(){
		Profile p = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
        String userName = 'admin';
		User u = new User(Alias = 'std'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='admintestuser@gmail.com'+userName);
		System.runAs(u){
			Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
			
			Account AccRecord = new Account();
			AccRecord.Name = 'test customer';
			AccRecord.BillingStreet = 'street';
			AccRecord.BillingCity = 'city';
			AccRecord.BillingCountry = 'India';
			AccRecord.BillingPostalCode = '55555';
			AccRecord.RecordTypeId= devRecordTypeId;
			AccRecord.Type = 'Reseller';
			insert AccRecord;
			
			Partner_Registration_Request__c prReq = createPR();
			prReq.First_Name__c = 'Test5';
			prReq.Partner_Registration_Status__c = 'Submitted';
            insert prReq;
			prReq.Partner_Account_Lookup__c = null;
			prReq.Partner_Registration_Status__c = 'Approved';
			try{
				update prReq;
			}catch(Exception e){
				system.debug(LoggingLevel.ERROR, e);
			}
			
			prReq.Partner_Account_Lookup__c = AccRecord.Id;
			prReq.Partner_Registration_Status__c = 'Approved';
			try{
				update prReq;
			}catch(Exception e){
				system.debug(LoggingLevel.ERROR, e);
			}
            
            List<Partner_Registration_Request__c> plist = [SELECT Id, Partner_Registration_Status__c FROM Partner_Registration_Request__c];
			System.assertEquals('Submitted',plist[0].Partner_Registration_Status__c,'PR is still in submitted status');
		}
    }
    
    private static Partner_Registration_Request__c createPR(){
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        
        Partner_Registration_Request__c prReq = new Partner_Registration_Request__c();
        prReq.Last_Name__c = 'Test Lastname';
        prReq.Email__c = 'abc4@gmailtest.sandbox.com';
        prReq.Company_Name__c = 'TestCompany';
        prReq.Partner_Account_Lookup__c = accId;
        prReq.Country_Picklist__c = 'United States';
        prReq.Country__c = 'United States';
        prReq.State__c = 'AL';
        prReq.Job_Title__c = 'Test';
        prReq.Phone_Number__c = '21454487';
        prReq.Address__c = 'Alabama';
        prReq.City__c = 'Alabama';
        prReq.Postal_Code__c = '318645';
        return prReq;
    }
}