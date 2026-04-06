@isTest
public class MyCasesControllerTest {
    static testMethod void SubmitCaseController(){

    UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'CEO' Limit 1];
    User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' AND isActive = true Limit 1];
    adminUser.UserRoleId = userRole.Id;
    update adminUser;

    System.runAs(adminUser){
    Account acc =new Account(Name='TestAcc1');
    insert acc;
    Contact con=new Contact(lastname='TestContact');
        con.AccountId=acc.id;
        insert con;
        
    Profile prof=[Select Id,Name from Profile where name=:'Rubrik Customer Community Login User (No Cases)' Limit 1];
    User u = new User(Alias = 'standt', email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = prof.Id, 
                          TimeZoneSidKey='America/Los_Angeles', username='standarduser@testorg121saurv.com');
        u.ContactId=con.Id;
        insert u;
        System.runAs(u){ 
            
            MyCasesController.getCasesrecords();   
            MyCasesController.getCasesByViews('test');   
            MyCasesController.getCasefilter();   
            MyCasesController.OpportunityController_AC cont = new MyCasesController.OpportunityController_AC();
            cont.getCases();
            cont.getByName('Test');
            MyCasesController.getCasesByViews('My Open Cases (P1/P2/P3)');
            MyCasesController.getCasesByViews('My Open Cases (P4)');
            MyCasesController.getCasesByViews('My Open Cases');
            MyCasesController.getCasesByViews('Recently Viewed Cases');
            MyCasesController.getCasesByViews('My Closed Cases');
            MyCasesController.getCasesByViews('Customer Cases');
        }
    }
    }
}