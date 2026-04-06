@isTest
private class AssetSWVersionUpdateTest {

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

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
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
        insert products;

        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', SW_Version__c = '0.1', SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN2', SW_Version__c = '0.2', SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN3', SW_Version__c = '0.3', SerialNumber = 'SN3', Serial_Number__c = 'SN3', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN4', SW_Version__c = '0.4', SerialNumber = 'SN4', Serial_Number__c = 'SN4', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN5', SW_Version__c = '0.5', SerialNumber = 'SN5', Serial_Number__c = 'SN5', Product2Id = products[0].Id, Accountid = acct.Id),
            new Asset(Name = 'SN6', SW_Version__c = '0.6', SerialNumber = 'SN6', Serial_Number__c = 'SN6', Product2Id = products[0].Id, Accountid = acct.Id)
        };
        insert assets;

        List<Cluster__c> clusters = new List<Cluster__c> {
            new Cluster__c(UUID__c = 'Test1', Name = 'Test1'),
            new Cluster__c(UUID__c = 'Test2', Name = 'Test2')
        };
        insert clusters;

        List<Node__c> nodes = new List<Node__c> {
            //SN-1
            new Node__c(
                Cluster__c = clusters.get(0).Id,
                Asset__c = assets.get(0).Id,
                Serial_Number__c = 'SNN-1-1',
                software_version__c = '1.0.1',
                Name = 'SNN-1-1'
            ),
            new Node__c(
                Cluster__c = clusters.get(0).Id,
                Asset__c = assets.get(0).Id,
                Serial_Number__c = 'SNN-1-2',
                software_version__c = '1.0.1',
                Name = 'SNN-1-2'
            ),
            //SN-2
            new Node__c(
                Cluster__c = clusters.get(0).Id,
                Asset__c = assets.get(1).Id,
                Serial_Number__c = 'SNN-2-1',
                software_version__c = '2.0.1',
                Name = 'SNN-2-1'
            ),
            //SN-3
            new Node__c(
                Cluster__c = clusters.get(1).Id,
                Asset__c = assets.get(2).Id,
                Serial_Number__c = 'SNN-3-1',
                software_version__c = '3.0.1',
                Name = 'SNN-3-1'
            ),
            new Node__c(
                Cluster__c = clusters.get(1).Id,
                Asset__c = assets.get(2).Id,
                Serial_Number__c = 'SNN-3-2',
                software_version__c = '3.0.2',
                Name = 'SNN-3-2'
            ),
            //SN-4
            new Node__c(
                Cluster__c = clusters.get(1).Id,
                Asset__c = assets.get(3).Id,
                Serial_Number__c = 'SNN-4-1',
                software_version__c = '4.0.1',
                Name = 'SNN-4-1'
            ),
            new Node__c(
                Cluster__c = clusters.get(1).Id,
                Asset__c = assets.get(3).Id,
                Serial_Number__c = 'SNN-4-2',
                software_version__c = null,
                Name = 'SNN-4-2'
            ),
            //SN-5
            new Node__c(
                Cluster__c = clusters.get(1).Id,
                Asset__c = assets.get(4).Id,
                Serial_Number__c = 'SNN-5-1',
                software_version__c = null,
                Name = 'SNN-5-1'
            )
        };
        insert nodes;

    }

    @isTest
	static void testUpdateAssetSWVersions() {

        List<Asset> assetsBefore = [SELECT Name, SW_Version__c FROM Asset WHERE Name IN ('SN1','SN2','SN3','SN4','SN5','SN6')];
        System.assertEquals(6, assetsBefore.size());

        for(Asset asset : assetsBefore) {
            if('SN1' == asset.Name) {
                System.assertEquals('0.1', asset.SW_Version__c);
            }
            else if('SN2' == asset.Name) {
                System.assertEquals('0.2', asset.SW_Version__c);
            }
            else if('SN3' == asset.Name) {
                System.assertEquals('0.3', asset.SW_Version__c);
            }
            else if('SN4' == asset.Name) {
                System.assertEquals('0.4', asset.SW_Version__c);
            }
            else if('SN5' == asset.Name) {
                System.assertEquals('0.5', asset.SW_Version__c);
            }
            else if('SN6' == asset.Name) {
                System.assertEquals('0.6', asset.SW_Version__c);
            }
        }

        Test.startTest();
            AssetSWVersionUpdate bInstance = new AssetSWVersionUpdate();
            DataBase.executeBatch(bInstance);
        Test.stopTest();

        List<Asset> assets = [SELECT Name, SW_Version__c FROM Asset WHERE Name IN ('SN1','SN2','SN3','SN4','SN5','SN6')];
        System.assertEquals(6, assets.size());

        for(Asset asset : assets) {
            if('SN1' == asset.Name) {
                System.assertEquals('1.0.1', asset.SW_Version__c);
            }
            else if('SN2' == asset.Name) {
                System.assertEquals('2.0.1', asset.SW_Version__c);
            }
            else if('SN3' == asset.Name) {
                System.assertEquals('0.3', asset.SW_Version__c);
            }
            else if('SN4' == asset.Name) {
                System.assertEquals('0.4', asset.SW_Version__c);
            }
            else if('SN5' == asset.Name) {
                System.assertEquals('0.5', asset.SW_Version__c);
            }
            else if('SN6' == asset.Name) {
                System.assertEquals('0.6', asset.SW_Version__c);
            }
        }

	}

    @isTest
    static void testUpdateAssetSWVersionsScheduler() {
        List<Asset> assetsBefore = [SELECT Name, SW_Version__c FROM Asset WHERE Name IN ('SN1','SN2','SN3','SN4','SN5','SN6')];
        System.assertEquals(6, assetsBefore.size());

        for(Asset asset : assetsBefore) {
            if('SN1' == asset.Name) {
                System.assertEquals('0.1', asset.SW_Version__c);
            }
            else if('SN2' == asset.Name) {
                System.assertEquals('0.2', asset.SW_Version__c);
            }
            else if('SN3' == asset.Name) {
                System.assertEquals('0.3', asset.SW_Version__c);
            }
            else if('SN4' == asset.Name) {
                System.assertEquals('0.4', asset.SW_Version__c);
            }
            else if('SN5' == asset.Name) {
                System.assertEquals('0.5', asset.SW_Version__c);
            }
            else if('SN6' == asset.Name) {
                System.assertEquals('0.6', asset.SW_Version__c);
            }
        }

        Test.startTest();
            AssetSWVersionUpdate bInstance = new AssetSWVersionUpdate();
            String cronExpr = '0 0 0 15 3 ? 2022';
            String jobId = System.schedule('AssetSWVersionUpdate', cronExpr, bInstance);
            bInstance.execute(null);
        Test.stopTest();

        List<Asset> assets = [SELECT Name, SW_Version__c FROM Asset WHERE Name IN ('SN1','SN2','SN3','SN4','SN5','SN6')];
        System.assertEquals(6, assets.size());

        for(Asset asset : assets) {
            if('SN1' == asset.Name) {
                System.assertEquals('1.0.1', asset.SW_Version__c);
            }
            else if('SN2' == asset.Name) {
                System.assertEquals('2.0.1', asset.SW_Version__c);
            }
            else if('SN3' == asset.Name) {
                System.assertEquals('0.3', asset.SW_Version__c);
            }
            else if('SN4' == asset.Name) {
                System.assertEquals('0.4', asset.SW_Version__c);
            }
            else if('SN5' == asset.Name) {
                System.assertEquals('0.5', asset.SW_Version__c);
            }
            else if('SN6' == asset.Name) {
                System.assertEquals('0.6', asset.SW_Version__c);
            }
        }
    }
}