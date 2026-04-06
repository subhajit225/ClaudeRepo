/**
* @Author : Shubham
* @Created Date : 22 Aug 2022
* @Description : CS21-1167 - Test Class for NodeTriggerHelper
*                
*                
**/
@isTest
private class NodeTriggerHelperTest {

    @testSetup
    static void testSetup() {

        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert acct;

        List<Product2> prodlist = new List<Product2> {
            //startup product
            new Product2(Name = 'X-0001-01',
                ProductCode = 'X-0001-01',
                Category__c = 'Platform',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                Product_Subtype__c = 'Start Up',
                IsActive = true
            ),
            //non-startup product
            new Product2(Name = 'X-0001-01',
                ProductCode = 'X-0001-01',
                Category__c = 'Platform',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };
        insert prodlist;
        
        List<Asset> assetList = new list<Asset> {
            new Asset(Name = 'SN123', SerialNumber = 'SN123', Serial_Number__c = 'SN123', Accountid = acct.Id,Product2id = prodlist[0].id),
            new Asset(Name = 'SN234', SerialNumber = 'SN234', Serial_Number__c = 'SN234',  Accountid = acct.Id,Product2id = prodlist[0].id),
            new Asset(Name = 'SN356', SerialNumber = 'SN356', Serial_Number__c = 'SN356',  Accountid = acct.Id,Product2id = prodlist[1].id)
        };
        insert assetList;
        
        List<Cluster__c> clusterList = new List<Cluster__c> {
            new Cluster__c(UUID__c = 'Test1', Name = 'Test1', Location__c = 'Alamo'),
            new Cluster__c(UUID__c = 'Test2', Name = 'Test2', Location__c = 'Albany'),
            new Cluster__c(UUID__c = 'Test3', Name = 'Test3', Location__c = 'Alhambra')
        };
        insert clusterList;
        
        List<Node__c> NodeList = new List<Node__c> {
            new Node__c(Name = 'RVMHM2', Serial_Number__c = 'RVMHM2',cluster__c = clusterList[0].id,asset__c=assetList[0].id),
            new Node__c(Name = 'RVMHM22', Serial_Number__c = 'RVMHM22',cluster__c = clusterList[1].id,asset__c=assetList[1].id),
            new Node__c(Name = 'RVMHM23', Serial_Number__c = 'RVMHM23',cluster__c = clusterList[2].id,asset__c=assetList[2].id)
        };
 
        insert NodeList;
    }

    public static testMethod void NodeUpdateTest() {
        List<Cluster__c> clusterList = [Select id from Cluster__c];
        Test.startTest();
        Node__c nodeObj = [Select id, cluster__c from Node__c where cluster__c = :clusterList[0].id Limit 1];
        nodeObj.cluster__c = clusterList[1].id ;
        update nodeObj;
        Test.stopTest();
    }

    public static testMethod void NodeUnDeleteTest() {
        List<Cluster__c> clusterList = [Select id from Cluster__c];
        Test.startTest();
        Node__c nodeObj = [Select id, cluster__c from Node__c where cluster__c = :clusterList[2].id Limit 1];
        delete nodeObj;
        Node__c nodeObj1 = [Select id, cluster__c from Node__c where cluster__c = :clusterList[2].id Limit 1 ALL Rows];
        undelete nodeObj1;
        Test.stopTest();
    }

}