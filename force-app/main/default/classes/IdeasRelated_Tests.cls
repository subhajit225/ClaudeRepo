/********************************************************************************************************
* Name              : IdeasRelated_Tests 
* Purpose           : IdeasRelated_Tests is Used for Testing IdeasRelated Class
*********************************************************************************************************/
@isTest
public class IdeasRelated_Tests{
    public static testMethod void test_RelatedIdeas() {

            System.runAs(new User(Id=UserInfo.getUserId())) {
                System.Test.startTest();
                
                //Create Community
                List<Community> c = [select Id from Community where isactive=true limit 1];
                
                //Create Idea
                Idea ideaToCreate = new Idea();
                ideaToCreate.Title = 'TestIdea';
                ideaToCreate.Body = 'TestIdea';
                ideaToCreate.CommunityId = c[0].Id;  
                insert ideaToCreate;

                //Create Idea
                Idea ideaToCreate2 = new Idea();
                ideaToCreate2.Title = 'TestIdeas';
                ideaToCreate2.Body = 'TestIdeas';
                ideaToCreate2.CommunityId = c[0].Id;  
                ideaToCreate2.Related_Ideas__c = 'TestIdea';
                insert ideaToCreate2;
                
                IdeasRelated ri = new IdeasRelated();
                
                ri.limitRecords = 10;
                ri.relatedString = 'Test1,Test2';
                ri.ideaID = ideaToCreate2.id;
                ri.getRelatedIdeas();
                ri.getRelatedIdeas2();
                    

                Test.stoptest();
            }
    
        } 
        
}