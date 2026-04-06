/*  
Test Class For: IdeaDetailController
Developer Name: Grazitti
Created Date: 16/04/2016
*/
@isTest
public class IdeaDetailControllerTest{
    public static testMethod void  createIdeaTest(){
        
        NewIdeaController.getPiklistValues();    
        
        Account acc = new Account();
        acc.name ='Test Account';
        acc.type = 'Partner';
        insert acc ;
        
        Contact con = new Contact();
        con.lastName = 'Test Last';
        con.AccountId = acc.Id;
        insert con;
        
        String networkId = System.Label.CommNetworkId;
        Id IdeaId = NewIdeaController.createIdea('test','testBody', new List<String>{'Other'},networkId );
        IdeaDetailController.getIdeaDetails(IdeaId);
        IdeaDetailController.savecomment(IdeaId,'testComment');
        IdeaDetailController.addVote(IdeaId,'Up');
        
    }
}