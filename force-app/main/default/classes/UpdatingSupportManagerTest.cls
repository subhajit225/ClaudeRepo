@isTest
public class UpdatingSupportManagerTest {
    
    static testMethod void testData() {
        Id p = [select id from profile where name='Rubrik Customer Support User'].id;
        Id pm = [select id from profile where name='Rubrik Customer Support Manager'].id;
        Account ac = new Account(name ='Grazitti') ;
        Insert ac; 
        User userManager = new User(alias = 'test123', email='test123@noemail.com', Username = 'test321@test321.test',
                             emailencodingkey='UTF-8', lastname='Testing@123', languagelocalekey='en_US',
                             localesidkey='en_US', profileid = pm , country='United States',IsActive =true, 
                             timezonesidkey='America/Los_Angeles');
        Insert userManager; 
        User user = new User(alias = 'test123', email='test123@noemail.com', Username = 'test321@test.test',
                             emailencodingkey='UTF-8', lastname='Testing@123', languagelocalekey='en_US' , ManagerId=userManager.id,
                             localesidkey='en_US', profileid = p, country='United States',IsActive =true,
                             timezonesidkey='America/Los_Angeles');
        Insert user; 
        
        Case cs1 = new Case(Subject='Test case dup',JIRA_References_URL__c='ALERT-11112abc',Jira_Reference_urls__c= 'ALERT-11112abc',
                            Description='testing',Origin = 'Portal', Status ='In Progress', Accountid = ac.id ,
                            Resolution__c='Product defect',  Priority = 'P1');
        insert cs1;
        
        Tasks__c t = new Tasks__c( Case__c = cs1.id);
        insert t;
        t.Owner_ID__c = user.id;
        update t;
        
    }
    
}