/**
 * 
 * @description Test class for EscalationApexController to validate escalation request functionality
 * @test
 * @author- Raveesh Layal
 * @date 2025-08-01
 */
@isTest
public class EscalationApexControllerTest {
    
    /**
     * @description Sets up test data including user with Customer Support profile for testing escalation scenarios
     */
    @testsetup
    private static void setup(){
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        List<User>userlist=new List<User>();
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        userlist.add(u);
        insert userlist;
    }
    
    /**
     * @description Tests all methods of EscalationApexController including escalation request creation, contact management, and email functionality
     */
    @istest
    static void testClass() {
        insert new TriggerControl__c(Name='Entitlement');
        
        Account act = new Account(Name='test Account');
        insert act;
        Contact con = new contact(LastName='Test Contact' ,AccountId = act.id,Email='testuser@example.com');
        insert con;
        Escalation_Request__c esc = new Escalation_Request__c();
        esc.Account__c = act.Id;
        esc.Description_of_events__c = 're';
        esc.Desired_outcome_of_escalation__c = 'test';
        esc.Reporting_User__c = Userinfo.getUserId();
        esc.Product_Line_involved_in_the_escalation__c = 'Edge';
        esc.Factors_involved_leading_to_escalation__c = 'Financial loss impacting the customer';
        insert esc;
        
        Escalation_Contact__c esc1=new Escalation_Contact__c();
        esc1.Escalation_Request__c=esc.Id;
        esc1.Contact__c=con.Id;
        esc1.Contact_Type__c='Rubrik contact';
        insert esc1;
        
        Escalation_Contact__c esc2=new Escalation_Contact__c();
        esc2.Escalation_Request__c=esc.Id;
        esc2.Contact__c=con.Id;
        esc2.Contact_Type__c='Primary customer contact';
        insert esc2;
        
        Escalation_Request__c esc3 = [SELECT Id, Name, (SELECT Contact__c, Contact_Type__c FROM Escalation_Contacts__r)FROM Escalation_Request__c WHERE Id = :esc.Id];
        
        Map<String, List<EscalationApexController.picklist>> dummyPicklistMap = new Map<String, List<EscalationApexController.picklist>>();
        dummyPicklistMap.put('DummyField', new List<EscalationApexController.picklist>{
            new EscalationApexController.picklist('Label1', 'Value1')});
        List<EscalationApexController.contactClass> contactClassList = new List<EscalationApexController.contactClass>{
            new EscalationApexController.contactClass(con)};
        
        
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
                    
            EscalationApexController.getDetails(esc.Id,null);
            EscalationApexController.getDetails(null,act.Id);

            // Only one assert added here
            List<EscalationApexController.contactClass> contactList = EscalationApexController.getContactList(act.Id);

            System.assertEquals(1, contactList.size(), 'There should be exactly 1 contact returned for the account.');

            EscalationApexController.getContactDetail(con.Id);
            EscalationApexController.assignMe(esc.Id);
            EscalationApexController.addEscalationContact(esc.Id,new List<Contact>{con},new List<Contact>{con});
            EscalationApexController.copyEmails(esc.Id,'RubrikContact');
            EscalationApexController.copyEmails(esc.Id,'customerContact');
            EscalationApexController.getDetails(null,act.Id);
            EscalationApexController.addEscalationContact(esc.Id,new List<Contact>{con},new List<Contact>{con});
            EscalationApexController.recordWrapper wrapper = new EscalationApexController.recordWrapper(esc3, dummyPicklistMap, contactClassList);
        }
    }
}