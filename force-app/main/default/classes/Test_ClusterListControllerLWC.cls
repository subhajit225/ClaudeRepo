/**
 * Author           :   Parvin Kumar
 * Created Date     :   30-03-2022
 * Description      :   Test class for ClusterListControllerLWC class
 */
@isTest
private class Test_ClusterListControllerLWC { 
    
    /**
     * Author           :   Parvin Kumar
     * Created Date     :   30-03-2022
     * Description      :   Test method for getClusterListLWC()
     */
    static testMethod void testgetClusterListLWC(){
        Account ac = new account(name='test1');
        insert ac; 
        
        Case cs = new Case();
        cs.AccountId = String.ValueOf(ac.id);
        cs.Status='New';
        cs.Origin = 'Pulse';
        cs.Priority = 'P4';
        insert cs;
        
        Cluster__c cl = new Cluster__c();
        cl.Name = '3d04e794-c526-400b-b652-a513a0f07c83';
        cl.tag__c = 'VREC489FBC898';
        cl.software_version__c = '4.0.2-374';
        cl.archived__c = false;
        cl.account__c = cs.AccountId;
        cl.uuid__c = '3d04e794-c526-400b-b652-a513a0f07c83';
        insert cl;   
        
        Test.startTest();
        
        List<ClusterListControllerLWC.ClusterWrapper> clusterList = ClusterListControllerLWC.getClusterListLWC(cs.Id, false);

        Test.stopTest();

        System.assertEquals(clusterList.size()>0, true);
    }
    
    static testMethod void testgetClusterListLWC1(){
        Account ac = new account(name='test2');
        insert ac; 
        
        Case cs = new Case();
        cs.AccountId = String.ValueOf(ac.id);
        cs.Status='New';
        cs.Origin = 'Phone';
        cs.Priority = 'P4';
        insert cs;
        
        Cluster__c cl = new Cluster__c();
        cl.Name = '3d04e794-c526-400b-b652-a513a0f07c83';
        cl.tag__c = 'VREC489FBC898';
        cl.software_version__c = '4.0.2-374';
        cl.archived__c = false;
        cl.account__c = cs.AccountId;
        cl.uuid__c = '3d04e794-c526-400b-b652-a513a0f07c83';
        insert cl;   
        
        Test.startTest();
        
        List<ClusterListControllerLWC.ClusterWrapper> clusterList = ClusterListControllerLWC.getClusterListLWC(cs.Id, true);

        Test.stopTest();

        System.assertEquals(clusterList.size()>0, true);
    }
    
    static testMethod void testgetClusterListLWC2(){
        Account ac = new account(name='test3');
        insert ac; 
        
        Case cs = new Case();
        cs.AccountId = String.ValueOf(ac.id);
        cs.Status='New';
        cs.Origin = 'Phone';
        cs.Priority = 'P4';
        insert cs;
        
        Cluster__c cl = new Cluster__c();
        cl.Name = '3d04e794-c526-400b-b652-a513a0f07c83';
        cl.tag__c = 'VREC489FBC898';
        cl.software_version__c = '4.0.2-374';
        cl.archived__c = false;
        cl.account__c = cs.AccountId;
        cl.uuid__c = '3d04e794-c526-400b-b652-a513a0f07c83';
        insert cl;  
        
         Cluster__c cl2 = new Cluster__c();
        cl2.Name = '3d04e794-c526-400b-b652-a513a0f07c84';
        cl2.tag__c = 'VREC489FBC898';
        cl2.software_version__c = '4.0.2-374';
        cl2.archived__c = false;
        cl2.account__c = cs.AccountId;
        cl2.uuid__c = '3d04e794-c526-400b-b652-a513a0f07c84';
        
        insert cl2;  
        
        list<RSC_Migration_Tasks__c> rscTaskList=new list<RSC_Migration_Tasks__c>();
        for(integer i=0;i<10;i++)
        {
            RSC_Migration_Tasks__c rsc=new RSC_Migration_Tasks__c();
            if(math.mod(i, 2) == 0)
            {
               rsc.Cluster__c=cl.id;  
               rsc.Task_Migration_Status__c='MIGRATED';
            }else{
                rsc.Cluster__c=cl2.id;  
                rsc.Task_Migration_Status__c='IN_PROGRESS';
            }
           
            rsc.Task_Name_Precheck_Name__c='test'+i;
            rsc.No_of_SLAs_migrated__c=5;
            rsc.No_of_SLAs_with_objects__c=6;
            
            rscTaskList.add(rsc);
        }
        
        insert rscTaskList;
        Test.startTest();
        
        List<ClusterListControllerLWC.ClusterWrapper> clusterList = ClusterListControllerLWC.getClusterListLWC(cs.Id, true);

        Test.stopTest();

        System.assertEquals(clusterList.size()>0,true);
    }
}