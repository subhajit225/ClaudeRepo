/**
  * @description Test Class for InstallBaseDownloadController 
  * @test
  * @author Raveesh Layal
  * @date 2025-08-26
*/
@IsTest
public class InstallBaseDownloadController_Tests{
    
    /**
       * @description method to cover GetibWrapperObj
    */
    @isTest static void testGetibWrapperObj() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true
        );
        insert u;
        System.runAs(u){
            Account acc1= new Account(Name='Test Account1');
            insert acc1;
            Account acc2= new Account(Name='Test Account2');
            insert acc2;
            Account acc3 =new Account(Name='Test Account3');
            insert acc3;
            
            Product2 product = new Product2(Name = 'Test Product', ProductCode = 'TP123', Family = 'RBK-CLOUT');
            insert product;
            
            Product2 productCloudOut = new Product2(Name = 'Cloud Out Product', ProductCode = 'CLOUDOUT1', Family = 'RBK-CLOUT');
            insert productCloudOut;
            
            Product2 productCloudOn = new Product2(Name = 'Cloud On Product', ProductCode = 'CLOUDON1', Family = 'RBK-CLON');
            insert productCloudOn;
            
            Product2 productCloudCluster = new Product2(Name = 'Cloud Cluster Product', ProductCode = 'CLOUDCL1', Family = 'RBK-RCDM');
            insert productCloudCluster;
            
            // Create parent Asset record with required Product2
            Asset parentAsset = new Asset(
                Name = 'Parent Asset',
                Product2Id = product.Id,
                SerialNumber = 'PARENTASSET123',
                AccountId=acc1.Id
            );
            insert parentAsset;
            
            // Create child Asset record with Product2 and ParentId
            Asset childAsset = new Asset(
                Name = 'Child Asset',
                AccountId=acc2.Id,
                Product2Id = product.Id,
                ParentId = parentAsset.Id,
                SerialNumber = 'CHILDASSET123',
                Support_Start_Date__c = Date.today().addMonths(-1),
                Support_End_Date__c = Date.today().addMonths(11),
                Premium_Support_End_Date__c = Date.today().addMonths(6)
            );
            insert childAsset;
            
            // Create chassis asset 
            Asset chassisAsset = new Asset(
                Name = 'Chassis Asset',
                AccountID=acc3.Id,
                Product2Id = product.Id,
                SerialNumber = 'CHASSIS123'
            );
            insert chassisAsset;
            
            // Create Cluster record
            Cluster__c cluster = new Cluster__c(Name = 'UUID12345', uuid__c = 'UUID12345');
            insert cluster;
            
            chassis__c c=new chassis__c(Name='ChassisSerial123',serial_number__c='ChassisSerial123',asset__c=chassisAsset.Id);
            insert c;
            
            
            TriggerControl__c tc = new TriggerControl__c(
                Name = 'Entitlement',
                DisableTrigger__c = true, 
                SetupOwnerId = UserInfo.getOrganizationId()
            );
            insert tc;
            ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
                Name = 'Default',
                Disable_Entitlement_Validation_Rules__c = true,
                SetupOwnerId = UserInfo.getOrganizationId()
            );
            insert disableLogic;
            
            Entitlement childAssetEntitlement = new Entitlement(
                Name = 'Child Asset Entitlement',
                AssetId = childAsset.Id,
                StartDate = Date.today().addDays(-10),
                EndDate = Date.today().addDays(365),
                AccountId = acc2.Id
                
            );
            insert childAssetEntitlement;
            
            // Create Node record under cluster - CHANGE Model__c to something OTHER than 'Edge'
            Node__c node = new Node__c(
                Name = 'SERIAL123',
                cluster__c = cluster.Id,
                asset__c = childAsset.Id,
                chassis__c = c.Id,
                serial_number__c = 'SERIAL123',
                model__c = 'Edge', 
                software_version__c = 'v1.0',
                bios_version__c = 'Bios1',
                board_serial__c = 'BOARD123',
                ipmi_mac_address__c = '00:00:5E:00:53:AF',
                mac_address_0__c = '00:00:5E:00:53:B0',
                mac_address_1__c = '00:00:5E:00:53:B1',
                manufactured_date__c = Date.today(),
                OwnerId = UserInfo.getUserId()
            );
            insert node;
            
            // Create Assets for different product families
            Asset cloudOutAsset = new Asset(
                Name = 'Cloud Out Asset',
                AccountId = acc2.Id,
                Product2Id = productCloudOut.Id,
                SerialNumber = 'CLOUDOUTASSET123'
            );
            insert cloudOutAsset;
            
            Asset cloudOnAsset = new Asset(
                Name = 'Cloud On Asset',
                AccountId = acc2.Id,
                Product2Id = productCloudOn.Id,
                SerialNumber = 'CLOUDONASSET123'
            );
            insert cloudOnAsset;
            
            Asset cloudClusterAsset = new Asset(
                Name = 'Cloud Cluster Asset',
                AccountId = acc2.Id,
                Product2Id = productCloudCluster.Id,
                SerialNumber = 'CLOUDCLUSTERASSET123'
            );
            insert cloudClusterAsset;
            
            // Create Entitlements for different product families
            Entitlement entCloudOut = new Entitlement(
                Name = 'Entitlement Cloud Out',
                AssetId = cloudOutAsset.Id,
                Product__c = productCloudOut.Id,  
                StartDate = Date.today().addDays(-10),
                EndDate = Date.today().addDays(10),
                AccountId = acc2.Id
                
            );
            insert entCloudOut;
            
            Entitlement entCloudOn = new Entitlement(
                Name = 'Entitlement Cloud On',
                AssetId = cloudOnAsset.Id,
                Product__c = productCloudOn.Id,  
                StartDate = Date.today().addDays(-20),
                EndDate = Date.today().addDays(20),
                AccountId = acc2.Id
                
            );
            insert entCloudOn;
            
            Entitlement entCloudCluster = new Entitlement(
                Name = 'Entitlement Cloud Cluster',
                AssetId = cloudClusterAsset.Id,
                Product__c = productCloudCluster.Id, 
                StartDate = Date.today().addDays(-30),
                EndDate = Date.today().addDays(30),
                AccountId = acc2.Id
                
            );
            insert entCloudCluster;
            
            Test.startTest();
            InstallBaseDownloadController controller = new InstallBaseDownloadController();
            List<InstallBaseDownloadController.InstallBaseWrapper> wrappers = controller.getibWrapperObj();
            Test.stopTest();
            
            System.assertNotEquals(null, wrappers, 'Wrapper list should not be null');
            
            
            Boolean hasNode = false;
            Boolean hasCloudOut = false;
            Boolean hasCloudOn = false;
            Boolean hasCloudCluster = false;
            
            for (InstallBaseDownloadController.InstallBaseWrapper wrap : wrappers) {
                if (wrap.ibtype == 'Node') {
                    hasNode = true;
                    
                    System.assertEquals('SERIAL123', wrap.ibname, 'Node name should match');
                }
                if (wrap.ibtype == 'Cloud Out') {
                    hasCloudOut = true;
                    
                    System.assertEquals('Entitlement Cloud Out', wrap.ibname, 'Cloud Out name should match');
                    System.assertEquals('Cloud Out Asset', wrap.uuid, 'UUID should be asset name for Cloud Out');
                }
                if (wrap.ibtype == 'Cloud On') {
                    hasCloudOn = true;
                    
                    System.assertEquals('Entitlement Cloud On', wrap.ibname, 'Cloud On name should match');
                    System.assertEquals('Cloud On Asset', wrap.uuid, 'UUID should be asset name for Cloud On');
                }
                if (wrap.ibtype == 'Cloud Cluster') {
                    hasCloudCluster = true;
                    
                    System.assertEquals('Entitlement Cloud Cluster', wrap.ibname, 'Cloud Cluster name should match');
                    System.assertEquals('Cloud Cluster Asset', wrap.uuid, 'UUID should be asset name for Cloud Cluster');
                }
            }
        }
        
    }
    
    
}