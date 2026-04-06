@istest
public class IdeaComUtils_Test {

     public static testMethod void testSendIdeaCommentMail() {
          //Create Idea
            Idea idc = new Idea();
            idc.CommunityId = [Select Id from Community limit 1].Id;
            idc.Title = 'Test Idea';
            idc.Categories = 'Web Services';
            idc.Body = 'This is a great Idea!';
            insert idc;
    
            System.assert(idc.categories != null);
            
           //Create Idea Comment
           
                   
            IdeaComment icom = new IdeaComment();
            icom.IdeaId = idc.Id;
            icom.CommentBody = 'my comment';
            insert icom;
            
            //Change Idea title
            idc.Title = 'NewTitle';
            idc.Categories = 'Web Services';
            update idc;
            
            System.assert(idc.categories != null);
      }
  
  
   public static testMethod void testSendIdeaCommentDownVote() {
          //Create Idea
            Idea idc = new Idea();
            idc.CommunityId = [Select Id from Community limit 1].Id;
            idc.Title = 'Test Idea';
            idc.Categories = 'Web Services';
            idc.Body = 'This is a great Idea!';
            insert idc;
    
            System.assert(idc.categories != null);
            
           // Vote downvote = new Vote();
            //downvote.ParentID = idc.id;
           // downvote.Type='Down';
           // insert downvote;
           
           Test.startTest();
           
            IdeaComment icom = new IdeaComment();
            icom.IdeaId = idc.Id;
            icom.CommentBody = 'my comment';
            insert icom;

            Integer invocations = Limits.getEmailInvocations();
            Test.stopTest();
            
      }
  
  

     @IsTest(SeeAllData=true) static void test_CommunityIdeaExtension_save() {
            //Create Idea
            Idea idc = new Idea();
            idc.CommunityId = [Select Id from Community limit 1].Id;
            idc.Title = 'Test Idea';
            idc.Categories = 'Web Services';
            idc.Body = 'This is a great Idea!';
            insert idc;
    
            System.assert(idc.categories != null);
            
           //Create Idea Comment
                   
            IdeaComment icom = new IdeaComment();
            icom.IdeaId = idc.Id;
            icom.CommentBody = 'my comment';
            insert icom;
            
            //Change Idea title
            idc.Title = 'NewTitle';
            idc.Categories = 'Web Services';
            update idc;
            
            Test.StartTest();
             IdeaComments testIdeaComments = new IdeaComments();
             
             testIdeaComments.ideaID=idc.id;
             testIdeaComments.limitRecords =1;
      
              testIdeaComments.getIdeaComments();
             Test.StopTest();
            
        
            }  
      
  
}