/****************
* Coverage Class-IdeaListController
* Created By - Grazitti Team
* Date - 16th April 2019
* 
**************/

@isTest
public class IdeaListController_Test {
     public static testmethod void IdeaListControllerTestMethod() 
    {        
        
        Id userLicenseId = [ select Id from UserLicense where NAME LIKE '%Customer Community%' LIMIT 1].id;
        Id communityprofileId = [select Id from Profile where name like '%Customer Community%' and UserLicenseId=:userLicenseId].id;
        
        Account a = new Account(name ='Test Account') ;
        Database.insert(a); 
        List<Contact> conList= new List<Contact>();
        Contact con = new Contact(LastName ='test', FirstName = 'Test First', AccountId = a.Id,  Email = System.now().millisecond() + 'testfirst@test.com');
        insert con;
        List<User> userList = new List<User>();
        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
        
        userList.add(portalAccountOwner);
        insert userList;
        Test.startTest();
        List<String> categoriesList= new List<String>();
        categoriesList = IdeaListController.getCategories();
        Id communityId = [ Select Name, IsActive, Id From Community c where IsActive=true and NAME LIKE '%Ideas Community%' LIMIT 1].id;
        Idea myIdea = new Idea(CommunityId = communityId);
        myIdea.title = ' Test Idea';
        myIdea.body = ' In order for LEX to appeal to our users, it needs to react more quickly or at least be perceived to be faster - right now Lightning is a misnomer. We see a landing page while the screen loads, which shows the release logo, animated - it is distracting and appears to be much slower than Salesforce Classic, perhaps up to a couple of seconds. An embarrassed silence while I am trying to show clients how much better LEX can be, but all they see is the equivalent of the loading page stopwatch or clock that you used to see in the 90. The reality might be that page loads are similar speed, but taking us to another screen while new new page is loading just makes it look slower. Go faster, please!';
        if(categoriesList != null && !categoriesList.IsEmpty()){
            myIdea.Categories=categoriesList[0];
        }else{
            myIdea.Categories='Cloud/Archive';
            
        }
        insert myIdea;
        IdeaListController.getIdeas(communityId,'Browse All Ideas','All');
        IdeaListController.getFilteredIdeas(communityId,'All');   
        IdeaListController.getFilteredIdeas(communityId,'Cloud/Archive'); 
        IdeaListController.addVote(myIdea.Id, 'UP' , communityId);
        IdeaListController.getIdeas(communityId,'Popular Ideas','All');
        IdeaListController.getIdeas(communityId,'Recent Ideas','All');
        IdeaListController.getIdeas(communityId,'Recent Comments','All');
        IdeaListController.getIdeas(communityId,'Top Ideas','All');
        IdeaListController.getIdeas(communityId,'My Ideas','All');
        IdeaListController.getIdeas(communityId,'My Votes','All');
        system.runAs(portalAccountOwner) {
            IdeaListController.addVote(myIdea.Id, 'UP' , communityId);
            IdeaListController.addVote(myIdea.Id, 'Down' , communityId);
        }
        Test.stopTest();       
    }
    
}