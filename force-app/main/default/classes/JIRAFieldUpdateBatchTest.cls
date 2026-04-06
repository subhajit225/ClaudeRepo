@isTest(seeAllDAta=true)
public class JIRAFieldUpdateBatchTest 
{
    static testMethod  void  testCallout() 
    {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MocResponseGenerator_JIRABatch());
        DataBase.executeBatch(new JIRAFieldUpdateBatch(),20); 
        Test.stopTest();
        
        JIRAFieldUpdateBatch_Schedular sch1 = new JIRAFieldUpdateBatch_Schedular();
        String sch = '0  00 2 4 * ?';
        system.schedule('Test JIRAFieldUpdateBatch', sch, sch1);
    }
    static testMethod void testCallout2() {
        Database.QueryLocator QL;
        Database.BatchableContext BC;
        //Map<String, USer> userMap = new Map<String,User>();
        List<USer> userList = new List<User>();
        JIRAFieldUpdateBatch  AU = new JIRAFieldUpdateBatch ();
        QL = AU.start(bc);
       
        Database.QueryLocatorIterator QIT =  QL.iterator();
        while (QIT.hasNext())
        {
            User user = (User)QIT.next();           
            System.debug(user);
            userList.add(user);
        }  
        
        AU.execute(BC, userList);
        Test.setMock(HttpCalloutMock.class, new MocResponseGenerator_JIRABatch());
        AU.finish(BC);
        JIRAIssueHelper.buildRequest('SOSD-10','APAC', 'Alliance'); 
    }
    
}