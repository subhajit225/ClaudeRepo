@isTest
public class MassEmailFieldUpdaterBatchTest{

    
     @testsetup
    public static void setupData(){
    
        Account acc1 = new Account(Name = 'TestAcc1',Primary_Contact_Email__c = 'str@gmail.com');
        
        insert acc1;
    }
    
    @isTest
    public static void testMethod1(){
    
     //setupData();   
    
    //Querey TestData
        list<Account> lstAccsdata = [select id from Account];
        //Use assert statements
        //system.assertEquals(1, lstConsdata.size()) ;
        
            //Use test.startTest() and stopTest() for refreshing governor limits.
            test.startTest();
        		MassEmailFieldUpdaterBatch bch = new MassEmailFieldUpdaterBatch(0);
                bch.objectNameList.add('Opportunity');
                Database.executeBatch(bch);
        	test.stopTest();

   		
     }
    
}