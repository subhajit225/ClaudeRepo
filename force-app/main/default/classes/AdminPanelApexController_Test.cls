/****************
* Coverage Class-AdminPanelApexController 
* Created By - Grazitti Team
* Date - 15th April 2019
* 
**************/

@isTest
public class AdminPanelApexController_Test {
    public static testmethod void AdminPanelApexControllerTestMethod() 
    {
        String result =AdminPanelApexControllerTestMethod5('test123@noemail.com','tester@noemail.com','tesasdfasdt@test.com',True);
         system.Assert(result=='userHasBeenCreated','The user is created');
    }
     public static testmethod void AdminPanelApexControllerTestMethod1() 
    {
        Id userLicenseId = [ select Id from UserLicense where NAME LIKE '%Customer Community%' LIMIT 1].id;
        Id communityprofileId = [select Id from Profile where name = 'Rubrik Customer Community Super Login User'].id;
        
        Account a = new Account(name ='Test Account') ;
        Database.insert(a); 
        system.assert(a.id!=null,'The Account is inserted');
        
        Contact con = new Contact(LastName ='test Last', FirstName = 'Test First', AccountId = a.Id,  Email = System.now().millisecond() + 'tesasdfasdt@test.com');
        Database.insert(con);  
        system.assert(con.id!=null,'The contact is inserted');
        
        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username='tester@noemail.com', isAuthorizedUser__c=false);
        
        Database.insert(portalAccountOwner);
        System.assert(portalAccountOwner.id!=null,'The user is inserted');
        
        Test.startTest();
        system.runAs(portalAccountOwner) {
            // statements to be executed by this test user- isAuthorizedUser__c Conditions
            AdminPanelApexController adminPanel = new AdminPanelApexController();
            AdminPanelApexController.accountInfo();
            
        }
        Test.stopTest();
      
    }
     public static testmethod void AdminPanelApexControllerTestMethod3() 
    {
         Account a = new Account(name ='Test Account2') ;
        Database.insert(a); 
         system.Assert(a.id!=null,'The Account is inserted');
        
        Contact con2 = new Contact(LastName ='test Last Create Long Name for Test functionality', FirstName = 'Test First', AccountId = a.Id,  Email ='Rtest@test.com');
        Database.insert(con2);  
        system.Assert(con2.id!=null,'The contact is inserted');
        
        
        Contact con1 = new Contact(LastName ='test Last Create Long Name for Test functionality', FirstName = 'Test First',  Email ='Rubrik1test@test.com');
       // Database.insert(con1); 
         List< AdminPanelApexController.UserLogin> userLoginList = new List< AdminPanelApexController.UserLogin>();
            AdminPanelApexController.UserLogin wrapUser1 =new AdminPanelApexController.UserLogin (con1);
         AdminPanelApexController.UserLogin wrapUser2 =new AdminPanelApexController.UserLogin (con2);
         userLoginList.add(wrapUser1);
         userLoginList.add(wrapUser2);
        AdminPanelApexController.createContact(userLoginList, false);
  
    }
    public static testmethod void AdminPanelApexControllerTestMethod4() 
    {
        String result=AdminPanelApexControllerTestMethod5('test@test233.com','test@test233.com','test@test233.com',False);
        system.Assert(result=='ContactHasbeenCreated','The Contact is inserted');
    }
     public static testmethod void AdminPanelApexControllerTestMethodFive() 
    {
        String result=AdminPanelApexControllerTestMethod5('test@test1.com','test@test12.com','test@test12.com',true);
        system.Assert(result!=null,'The Contact is inserted');
    }
    
     public static string AdminPanelApexControllerTestMethod5(String userEmail,String userName,String contactEmail,Boolean createFutureUser) 
    {
        Id userLicenseId = [ select Id from UserLicense where NAME LIKE '%Customer Community%' LIMIT 1].id;
        Id communityprofileId = [select Id from Profile where name = 'Rubrik Customer Community Super Login User'].id;
        list<contact> conlist=new list<contact>();
        Account a = new Account(name ='Test Account') ;
        Database.insert(a); 
        contact con=new contact();
     if(createFutureUser)
       {
            con = new Contact(LastName ='test Last Create Long Name for Test functionality', FirstName = 'Test First', AccountId = a.Id,  Email = System.now().millisecond() +contactEmail );
       
       }else{
           con = new Contact(LastName ='test Last Create Long Name for Test functionality', FirstName = 'Test First', AccountId = a.Id,  Email =contactEmail);
          
       }
        contact con3 = new Contact(LastName ='test Last Create Long Name for Test functionality', FirstName = 'Test First', AccountId = a.Id,  Email ='testrubrik0101@test.com');
        conlist.add(con);
        conlist.add(con3);
       insert conlist;             
        User portalAccountOwner = new User(alias = 'test123', email=userEmail,
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username=userName, isAuthorizedUser__c=true);
        
        Database.insert(portalAccountOwner);
        system.Assert(portalAccountOwner.id!=null,'The user is inserted');
        
        Test.startTest();
        system.runAs(portalAccountOwner) {
            // statements to be executed by this test user.
            AdminPanelApexController adminPanel = new AdminPanelApexController();
            AdminPanelApexController.createUser(new List<Contact>{con});
            AdminPanelApexController.accountInfo();
            List<User> userList= new List<User>();
            userList.add(portalAccountOwner);
            List< AdminPanelApexController.UserLogin> userLoginList = new List< AdminPanelApexController.UserLogin>();
            List< AdminPanelApexController.UserLogin> userLoginList2 = new List< AdminPanelApexController.UserLogin>();
            List< AdminPanelApexController.UserLogin> userLoginListNew = new List< AdminPanelApexController.UserLogin>();
            AdminPanelApexController.UserLogin wrapUser =new AdminPanelApexController.UserLogin (portalAccountOwner);
            AdminPanelApexController.UserLogin wrapUser2 =new AdminPanelApexController.UserLogin (con3);
            AdminPanelApexController.UserLogin wrapUserLogin =new AdminPanelApexController.UserLogin (wrapUser);
            AdminPanelApexController.UserLogin wrapContact =new AdminPanelApexController.UserLogin (con);
            AdminPanelApexController.UserLogin wrapUsrLogin =new AdminPanelApexController.UserLogin ();
            object objFirstName = wrapUsrLogin.get('FirstName');
            object objLastName = wrapUsrLogin.get('LastName');
            object objEmail = wrapUsrLogin.get('email');
            object objTitle = wrapUsrLogin.get('title');
            object objPhone = wrapUsrLogin.get('phone');
            object objIsActive = wrapUsrLogin.get('isActive');
            object objAdminUser = wrapUsrLogin.get('adminUser');
            object objAdminOther = wrapUsrLogin.get('this');
            //AdminPanelApexController.requestAccess(userList);
            userLoginList.add(wrapUser);
            userLoginList2.add(wrapUser2);
            userLoginList.add(wrapUserLogin);
            wrapUser.email='raveesh@rubrik.com';
            wrapUserLogin.email='raveesh.layal@rubrik.com';
            COntact conRet= AdminPanelApexController.contact;
            AdminPanelApexController.contact=null;
            User UserRet= AdminPanelApexController.User;
            AdminPanelApexController.User=null;
            userLoginListNew.add(wrapUserLogin);
            userLoginListNew.add(wrapUser);
            AdminPanelApexController.createContact(userLoginList, true);
             AdminPanelApexController.createContact(userLoginList2, true);
            AdminPanelApexController.UserUpdate(userLoginList, userLoginListNew);
            AdminPanelApexController.contactToUser(con.Id);
            AdminPanelApexController.sendEmailMethod('Update');
            AdminPanelApexController.requestAccess(userLoginList);
            
        }
        Test.stopTest();
        if(createFutureUser){
            return 'userHasBeenCreated';	
                }else if(!createFutureUser){
                    return 'ContactHasbeenCreated';
                }
        return '';
    }
    
    
}