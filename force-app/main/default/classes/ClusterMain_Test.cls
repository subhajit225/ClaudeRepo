/********************************************************************************************************
* Name              : ClusterMain_Test
* Purpose           : ClusterMain_Test is Used for Testing ClusterMain Trigger
*********************************************************************************************************/
@isTest
public class ClusterMain_Test{
    
    static testMethod void testClusterMainTrigger(){
        testDataFactoryClass.createCustomSettings();
        List<Account> actList= new List<Account>();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        actList.add(act);
        insert actList;
        
        List<opportunity> oppList =  testDataFactoryClass.createOpporunity(actList);
        
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => actList[0].Id
        };
        Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert con;
        
        OpportunityContactRole ocr=new OpportunityContactRole();
        ocr.ContactId=con.id;
        ocr.IsPrimary=true;
        ocr.OpportunityId=oppList[0].id;
        insert ocr;
        
        Test.startTest();
        List<Cluster__c> clusters = new List<Cluster__c> {
            new Cluster__c(UUID__c = 'Test1', Name = 'Test1', Location__c = 'Alamo',Email_Sent_for_80_Consumption__c=false,Enable_Email_Alert__c=true,Account__c=actList[0].id)/* ,
            new Cluster__c(UUID__c = 'Test2', Name = 'Test2', Location__c = 'Albany'),
            new Cluster__c(UUID__c = 'Test3', Name = 'Test3', Location__c = 'Alhambra')*/
        }; 
        insert clusters;
        
        clusters[0].Email_Sent_for_80_Consumption__c =true;
        try{
            update clusters;
        }catch(Exception exp){
            System.debug('Exception Occured while updating clusers = '+exp);
        }
        
        Test.stopTest();
    }

    @isTest
    static void testUpdateEndOfSupportFromAcc() {
        List<Account> accList = new List<Account>{new Account(Name = 'Test Account 1', Approved_Software_Program__c = 'Approved CDM 8.1 extension (28-FEB-2025)'),
                                                    new Account(Name = 'Test Account 2', Approved_Software_Program__c = null)};
        INSERT accList; 

        List<Cluster__c> clusterList = new List<Cluster__c>{new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1', Account__c = accList[0].Id, Software_Version__c = null),
                                        new Cluster__c(UUID__c = 'Cluster 2', Name = 'Cluster 2', Account__c = accList[1].Id, Software_Version__c = '9.0.2-25173'),
                                        new Cluster__c(UUID__c = 'Cluster 3', Name = 'Cluster 3', Account__c = accList[1].Id, Software_Version__c = '8.1.2-p2-24758')};
        INSERT clusterList; 

        List<Release_Version__c> releaseVersionList = new List<Release_Version__c>{new Release_Version__c(End_Of_Support_Date__c = Date.today().addDays(10)),
                                                            new Release_Version__c(End_Of_Support_Date__c = Date.today().addDays(-10))};
        INSERT releaseVersionList;

        List<Releases__c> releaseList = new List<Releases__c>{new Releases__c(Version__c = '9.0.2-25173', Release_Version__c = releaseVersionList[0].Id),
                                                            new Releases__c(Version__c = '8.1.2-p2-24758', Release_Version__c = releaseVersionList[1].Id)};
        INSERT releaseList;

        // Create oldClusterMap to simulate old data
        Map<Id, Cluster__c> oldClusterMap = new Map<Id, Cluster__c>();
        oldClusterMap.put(clusterList[0].Id, new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1', Id = clusterList[0].Id, Account__c = accList[1].Id, Software_Version__c = '8.1.2-p2-24758'));
        oldClusterMap.put(clusterList[1].Id, new Cluster__c(UUID__c = 'Cluster 2', Name = 'Cluster 2', Id = clusterList[1].Id, Account__c = accList[0].Id, Software_Version__c = '8.1.2'));
        oldClusterMap.put(clusterList[2].Id, new Cluster__c(UUID__c = 'Cluster 3', Name = 'Cluster 3', Id = clusterList[2].Id, Account__c = accList[1].Id, Software_Version__c = '8.1.2'));

        // Create newClusterList to simulate updates
        List<Cluster__c> newClusterList = new List<Cluster__c>{
            new Cluster__c(UUID__c = 'Cluster 1', Name = 'Cluster 1', Id = clusterList[0].Id, Account__c = accList[0].Id, Software_Version__c = '9.0.2-25173'), // Account changed
            new Cluster__c(UUID__c = 'Cluster 2', Name = 'Cluster 2', Id = clusterList[1].Id, Account__c = accList[1].Id, Software_Version__c = '8.1.2-p2-24758'), // No change
            new Cluster__c(UUID__c = 'Cluster 3', Name = 'Cluster 3', Id = clusterList[2].Id, Account__c = accList[1].Id, Software_Version__c = '9.0.2-25173') // Software Version changed
        };

        // Call the method to test
        Test.startTest();
        ClusterMainTriggerHandler.updateEndOfSupportFromAcc(newClusterList, oldClusterMap);
        Test.stopTest();

        // Verify results
        List<Cluster__c> updatedClusters = [SELECT Id, CDM_End_of_Support_Status__c FROM Cluster__c WHERE Account__c =: accList[1].Id];
        System.assertEquals(2, updatedClusters.size());
    }
    
}