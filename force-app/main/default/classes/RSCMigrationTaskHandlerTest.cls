/** 
* @Author      : Raveesh Layal
* @CreatedDate : 5th October 2023
* @Description : Updates the repective RSC Migration Task records and related records.
* @TstClass FOR: RSCMigrationTaskHandler
* @Jira		   : CS21-1939 

* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1939        		           
* --------------------------------------------------------------------------------------------------------------------------------
*/

@isTest() 
public class RSCMigrationTaskHandlerTest {
    /**
* @description To test the updateClusterId() and updateTotalCountOnCluster()
* @return void
*/
    @isTest
    public static void method1(){
        
        Account acc = new Account(name='testAcc');
        insert acc;
        Account accRbk = new Account(name='Rubrik');
        insert accRbk;
        list<cluster__c> clusterList=new list<cluster__c>();
        list<RSC_Migration_Tasks__c> taskList=new list<RSC_Migration_Tasks__c>();
        for(integer i=0;i<2;i++)
        {
            cluster__c c=new cluster__c();
            c.Name='ci'+i;
            c.uuid__c='ci'+i;
            if(i==0)
            {
                  c.account__c=accRbk.id;
            }
            else{
                 c.account__c=acc.id;
            }
           
            clusterList.add(c);
            
        }
        insert clusterList;
        system.assertEquals(clusterList.size(),2);
        system.assert(clusterList.size()==2);
        for(integer i=0;i<20;i++)
        {
            RSC_Migration_Tasks__c rsc=new RSC_Migration_Tasks__c();
            rsc.cluster_UUID__c='ci'+i;
            rsc.Task_Name_Precheck_Name__c='test'+i;
            
            if(math.mod(i, 2) == 0)
            {
                rsc.Task_Migration_Status__c='IN_PROGRESS';
                rsc.Cluster__c=clusterList[0].id;
            }
            else 
            {
                rsc.Task_Migration_Status__c='MIGRATED';
                rsc.Cluster__c=clusterList[1].id;
            }
            taskList.add(rsc);
        }
        test.startTest();
        insert taskList;
        delete taskList;
        test.stopTest();
        System.assertEquals(tasklist.size(),20);
        system.assert(tasklist.size()==20);
        
    }
    
    
}