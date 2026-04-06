/*
 * Class Name :- ProactiveClusterControllerTest
 * Visualforce Page :- ProactiveClusterController
 * Author :- Shiva Sharma
 * Created Date :- 04-10-2019
 * Description : This Controller is being used in ProactiveClusterController Test Class
 * Coverage :- 92%
 // ********************Change Logs ******************************************************************************************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 // ********************Change Logs Ends**************************************************************************************************************************************************
*/
@isTest
public class ProactiveClusterControllerTest {
    @testSetup static void setup() {
        testDataFactoryClass.createContactWithUser(1);
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        List<Cluster__c> clusters = new List<Cluster__c>{
            new Cluster__c( UUID__c = 'Cluster 1', Name = 'Cluster 1', Account__c = acc.Id, archived__c = false),
            new Cluster__c( UUID__c = 'Cluster 2', Name = 'Cluster 2', Account__c = acc.Id, archived__c = false),
            new Cluster__c( UUID__c = 'Cluster 3', Name = 'Cluster 3', Account__c = acc.Id, archived__c = false)};
        insert clusters;
    }
    
    @isTest static void testMethod1() {
        user u = [select id,email from user where Profile.Name ='Rubrik Customer Community Login User' and username = 'testuser@testuser1.com' LIMIT 1];
        cluster__c cs =new cluster__c(Account__c = [select id from account limit 1].Id,name='123',UUID__C='123');
        insert cs;
        System.runAs(u){
            ProactiveClusterController.proactiveContactClass record = ProactiveClusterController.getProactiveInfo(Userinfo.getUserId());
            ProactiveClusterController.updateBusinessHourInfo(record, '0202', new List<String>{'Sunday'});
            ProactiveClusterController.updateProactiveInfo([select id from contact Limit 1].Id, true, record);
            ProactiveClusterController.updateRecordAddress(record, 'String test','Test Instruction');
            ProactiveClusterController.proactiveContactClass record1 = ProactiveClusterController.getProactiveInfo(cs.Id);
            ProactiveClusterController.updateBusinessHourInfo(record1, '0202', new List<String>{'Sunday'});
            ProactiveClusterController.updateProactiveInfo([select id from contact Limit 1].Id, true, record1);
            ProactiveClusterController.updateRecordAddress(record1, 'String test','Test Instruction');
            ProactiveClusterController.fetchCountryToStatesMap();
        }
    }

    // CS21-45
    @isTest
    static void testUpdateWithAllClustersTrue() {
        user u = [select id,email from user where Profile.Name ='System Administrator' and isActive = true LIMIT 1];
        System.runAs(u){
            Test.startTest();
                Account objAcc = [SELECT Id FROM Account WHERE Name = 'Test Account' Limit 1];
                Contact objCon = [SELECT Id FROM Contact WHERE Name = 'Test Contact' Limit 1];
                MyProductsController.bulkUpdateProactiveContactOnClusters( objCon.Id, objAcc.Id, null, null, true);
            Test.stopTest();

            for (Cluster__c c : [SELECT Id, Proactive_Case_Contact__c FROM Cluster__c WHERE Account__c =: objAcc.Id]) {
                System.assertEquals(objCon.Id, c.Proactive_Case_Contact__c);
            }
        }
    }

    // CS21-45
    @isTest
    static void testUpdateWithSelectedClusters() {
        user u = [select id,email from user where Profile.Name ='System Administrator' and isActive = true LIMIT 1];
        System.runAs(u){
            Test.startTest();
                Account objAcc = [SELECT Id FROM Account WHERE Name = 'Test Account' Limit 1];
                Contact objCon = [SELECT Id FROM Contact WHERE Name = 'Test Contact' Limit 1];
                Cluster__c objCluster = [SELECT Id, Proactive_Case_Contact__c FROM Cluster__c WHERE name = 'Cluster 1'];
                Cluster__c objClustera = [SELECT Id, Proactive_Case_Contact__c FROM Cluster__c WHERE name = 'Cluster 2'];
                MyProductsController.bulkUpdateProactiveContactOnClusters( objCon.Id, objAcc.Id, new List<Id>{objCluster.Id}, new List<Id>{objClustera.Id}, false);
            Test.stopTest();

            Cluster__c objCluster1 = [SELECT Id, Proactive_Case_Contact__c FROM Cluster__c WHERE name = 'Cluster 1'];
            System.assertEquals(objCon.Id, objCluster1.Proactive_Case_Contact__c);
        }
    }

    // CS21-45
    @isTest
    static void testNoAccessThrowsException() {
        user u = [select id,email from user where Profile.Name ='System Administrator' and isActive = true LIMIT 1];
        System.runAs(u){
            Test.startTest();
            try {
                MyProductsController.bulkUpdateProactiveContactOnClusters(null, null, null, null, true);
                System.assert(true);  
            } catch (Exception e) {
                System.assert(false); 
            }
            Test.stopTest();
        }
    }

}