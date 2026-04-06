@istest
public class IdeaPages_Tests {

     public static testMethod void test_IdeasViewAllController() {
          //Create Idea
            Idea idc = new Idea();
            idc.CommunityId = [Select Id from Community limit 1].Id;
            idc.Title = 'Test Idea';
            idc.Categories = 'Web Services';
            idc.Body = 'This is a great Idea!';
            insert idc;
    
            System.assert(idc.categories != null);

            List <Idea> ideasList = new List<Idea>();
            ideasList.add(idc);

            Test.startTest();
            Test.setCurrentPage(Page.IdeasHome);
              
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(ideasList);
            stdSetController.setSelected(ideasList);
              
            IdeasViewController ext = new IdeasViewController();
            ext.getIdeas();
            ext.searchIdeas();
            ext.getCategories();
            ext.refresh();
            
            boolean next = ext.hasNext;
            boolean prev = ext.hasPrevious;
            integer pnum = ext.pageNumber;
            ext.first();
            ext.last();
            ext.previous();
            ext.next();
                        
            Test.stopTest();

      }
  }