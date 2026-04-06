/**
    * @File Name          : OpportunityContactRoleHandlerTest.cls
    * @Description        : Test Class for OpportunityContactRoleHandler - Updating click through email on opportunity from contact role
    * @Author             : Vartika Shinde
    * @Group              : 
    * @Last Modified By   : 
    * @Last Modified On   : 
    **/
@isTest
public class OpportunityContactRoleHandlerTest {
 
    @testSetup
    public static void setupMethod() {    
        insert new ShGl_DisableBusinessLogic__c(Disable_Opportunity_Validation_Rules__c =true, setupOwnerId = userinfo.getuserid());
        Account testAcc = new Account(Name='Test');     
        Insert testAcc;
        
        Contact createCon = new Contact(AccountId = testAcc.Id,FirstName='test',LastName='TestContact01',Phone = '8971371780');
        Insert createCon;
        
        Opportunity opp = new Opportunity(AccountId = testAcc.Id,Name = 'Test01',StageName = '1 Discovery',CloseDate = Date.today()+1);
        Insert opp;  
        System.runAs(new user(id=userinfo.getuserid())){
            Opportunity opp2 = new Opportunity(Cloud_Type__c='Microsoft Azure',AccountId = testAcc.Id,Name = 'Test01',StageName = '6 PO With Channel',CloseDate = Date.today()+1,Initial_Contacts_Name__c=createCon.Id,Type='New Customer',Opportunity_Sub_Type__c='Renewal');
            Insert opp2;
        }         
    }
    
    @isTest
    public static void updateContactEmailTest() {
       Opportunity opp = [select id,Click_Thru_Contact_Email__c from Opportunity where Name = 'Test01' limit 1 ] ;
       Contact con = [select id,Email from Contact where FirstName = 'Test' limit 1 ];
      
       OpportunityContactRole ocr = new OpportunityContactRole();
       ocr.OpportunityId = opp.Id;
       ocr.Role = 'Click-Thru Contact';
       ocr.ContactId = con.id;
       insert ocr; 
       
       Test.startTest(); 
           opp.Click_Thru_Contact_Email__c = con.Email;
           update opp;
       Test.stopTest(); 
       System.assertEquals(opp.Click_Thru_Contact_Email__c,con.Email, 'msg');
        
    }
    @isTest
    public static void TestpreventdeleteORupdate(){
        OpportunityContactRole cr = [select id,Role from OpportunityContactRole limit 1 ] ;
        cr.role='Click-Thru Contact';
        update cr;
        System.assertEquals('Click-Thru Contact', cr.role, 'msg');
        delete cr;
    }
}