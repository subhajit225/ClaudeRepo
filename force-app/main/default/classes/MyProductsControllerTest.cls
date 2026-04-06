/**
* @description Test Class for MyProductsController 
* @test
* @author Raveesh Layal
* @date 2025-08-26
*/
@IsTest
public class MyProductsControllerTest{
    /**
    * @description Method to cover getCloudAssets.
    */
    @IsTest
    public static  void  getCloudAssetsTest(){
        // Create TriggerControls first
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c>();
        triggerControls.add(new TriggerControl__c(Name = 'Cluster', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true));
        insert triggerControls;

        Account acc = new Account();
        acc.name ='Test Account';
        acc.type = 'Partner';
        insert acc ;
        
        Contact con = new Contact();
        con.Email='testrubrikcs'+System.currentTimeMillis()+'@rubrik.com';
        con.lastName = 'Test Last';
        con.AccountId = acc.Id;
        insert con;
        
        Product2 pd = new Product2();
        pd.IsActive= true;
        pd.name = 'test';
        pd.Release_Product_Types__c = 'Air;Edge';
        pd.ProductCode = 'test-prod';
        pd.Family = 'CLOUT';
        insert pd;
        
        Product2 pd1 = new Product2();
        pd1.IsActive= true;
        pd1.name = 'test1';
        pd1.Release_Product_Types__c = 'Air;Edge';
        pd1.ProductCode = 'test-prod1';
        pd1.Family = 'CLON';
        insert pd1;

        Long timestamp = System.currentTimeMillis();
        
        List<cluster__c> clToInsert = new List<cluster__c>();
        Cluster__c cl = new cluster__c();
        cl.account__c = acc.id;
        cl.name = 'cluster' + timestamp;
        cl.uuid__c = 'cluster' + timestamp;  // Same as name
        cl.software_version__c = null;
        cl.archived__c = false;
        clToInsert.add(cl);
        
        Cluster__c cl1 = new cluster__c();
        cl1.account__c = acc.id;
        cl1.name = 'cluster' + (timestamp + 1);
        cl1.uuid__c = 'cluster' + (timestamp + 1);  // Same as name
        cl1.software_version__c = null;
        cl1.archived__c = false;
        clToInsert.add(cl1);
        
        insert clToInsert;
        
        List<Node__c> nodesToInsert = new List<Node__c>();
        Node__c nd = new Node__c();
        nd.Model__c = 'Edge';  // Only Edge model
        nd.cluster__c = cl.id;
        nodesToInsert .add(nd);
        
        Node__c nd1 = new Node__c();
        nd1.Model__c = 'Edge';  // Only Edge model
        nd1.cluster__c = cl1.id;
        nodesToInsert .add(nd1);

        insert nodesToInsert ;

        Id communityprofileId = [select Id from Profile where name like 'Rubrik Customer Community Super Login User'].id;
        
        User portalAccountOwner = new User(alias = 'test123', email='test123@noemail.com',
                                           emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                           localesidkey='en_US', profileid = communityprofileId, country='United States',IsActive =true,
                                           ContactId = con.Id, FirstName = 'Test First',
                                           timezonesidkey='America/Los_Angeles', username='tester@noemail.com', isAuthorizedUser__c=true);
        
        Database.insert(portalAccountOwner);
        
        Test.startTest();
        System.runAs(portalAccountOwner) {
            MyProductsController.getCloudAssets();
            MyProductsController.clusters();
            MyProductsController.clusters();
            MyProductsController.EdgeNodes();
            MyProductsController.darkNodes();
            MyProductsController.MosaicClusters();
        }
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Name = 'System Administrator', Disable_Entitlement_Validation_Rules__c = TRUE);
        insert disableLogic;
        
        Entitlement cloutEntitlement = new Entitlement();
        cloutEntitlement.name = 'Clout entitlement';
        cloutEntitlement.startdate = system.today();
        cloutEntitlement.enddate = system.today().addDays(60);
        cloutEntitlement.product__c = pd.Id;
        cloutEntitlement.Accountid = acc.id;
        
        Entitlement clonEntitlement = new Entitlement();
        clonEntitlement.name = 'CLON entitlement';
        clonEntitlement.startdate = system.today();
        clonEntitlement.enddate = system.today().addDays(60);
        clonEntitlement.product__c = pd1.Id;
        clonEntitlement.Accountid = acc.id;
        
        insert new List<Entitlement>{cloutEntitlement,clonEntitlement};
            
            List<Entitlement> cloutResult2 = MyProductsController.getClout();
        MyProductsController.getClon();
        System.assertNotEquals(null, cloutResult2, 'Should return list when clout entitlements exist');
        Test.stopTest();
    }
    
    /**
    * @description Method to cover getPolarisDataProtectionDetails.
    */
    @IsTest
    public static void getPolarisDataProtectionTest(){
        
        User adminUser = createInternalUserWithRole(); 
        
        System.runAs(adminUser) {
            List<TriggerControl__c> triggerControls = new List<TriggerControl__c>();
            triggerControls.add(new TriggerControl__c(Name = 'Cluster', DisableTrigger__c = true));
            triggerControls.add(new TriggerControl__c(Name = 'Account', DisableTrigger__c = true));
            insert triggerControls;
            Account acc = new Account();
            acc.name ='Test Account';
            acc.type = 'Partner';
            insert acc ;
            
            Contact con = new Contact();
            con.FirstName = 'John';
            con.lastName = 'Test Last';
            con.Email='testrubrikcs'+System.currentTimeMillis()+'@rubrik.com';
            con.AccountId = acc.Id;
            insert con;
            
            Contact con1 = new Contact();
            con1.FirstName = 'John1';
            con1.lastName = 'Test Last1';
            con1.Email='testrubrikcs1'+System.currentTimeMillis()+'@rubrik.com';
            con1.AccountId = acc.Id;
            insert con1;
            
            Long timestamp = System.currentTimeMillis();
            Id commProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
            
            User testUser = new User(
                ProfileId = commProfileId,
                LastName = 'Test',
                Email = 'test' + timestamp + '@example.com',
                Username = 'polaris' + timestamp + '@example.com', 
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ContactId = con.Id,
                IsActive = true
            );
            insert testUser;
            Order o = new Order();
            o.Name = 'Test Order';
            o.AccountId = acc.Id;
            o.EffectiveDate = System.today();
            o.Status = 'Draft'; 
            o.Polaris_Contact__c = con.Id;
            o.Polaris_Contact_Email__c = 'order@testuser.com';
            insert o;
            
            Order o1 = new Order();
            o1.Name = 'Test1 Order';
            o1.AccountId = acc.Id;
            o1.EffectiveDate = System.today();
            o1.Status = 'Draft';
            o1.Polaris_Contact__c = con1.Id;
            o1.Polaris_Contact_Email__c = 'order12@testuser.com';
            insert o1;
            
            Test.startTest();
            System.runAs(testUser){
                String result = MyProductsController.getPolarisDataProtectionDetails();
                System.assertNotEquals('', result, 'Should return contact information when orders exist');
                List<InstallBaseDownloadController.InstallBaseWrapper> wrappers = MyProductsController.getInstallWrapper();
                System.assertNotEquals(null, wrappers, 'Wrapper list should not be null');
                /* MyProductsController.bulkUpdateProactiveContactOnClusters(con.Id, acc.Id, new List<Id>(), new List<Id>(), true); */
            }
            Test.stopTest();
        }
    }
    
   /**
 * @description Method to cover DarkNodes entitlement mapping logic
 */
@IsTest
static void testDarkNodesMethod() {
    User adminUser = createInternalUserWithRole();

    System.runAs(adminUser) {
        insert new List<TriggerControl__c>{
            new TriggerControl__c(Name = 'Cluster', DisableTrigger__c = true),
            new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true)
        };

        Account acc = new Account(Name = 'Test Account', Type = 'Partner');
        insert acc;

        Contact con = new Contact(LastName = 'Test Last', AccountId = acc.Id,Email='testrubrikcs'+System.currentTimeMillis()+'@rubrik.com');
        insert con;

        Id communityProfileId = [
            SELECT Id FROM Profile
            WHERE Name LIKE 'Rubrik Customer Community Super Login User'
            LIMIT 1
        ].Id;

        User portalUser = new User(
            Alias = 'test123',
            Email = 'test123@noemail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = communityProfileId,
            Country = 'United States',
            IsActive = true,
            ContactId = con.Id,
            FirstName = 'Test First',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'darktester' + System.currentTimeMillis() + '@noemail.com'
        );
        insert portalUser;

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'test-prod',
            IsActive = true
        );
        insert prod;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            Product2Id = prod.Id,
            Status = 'Installed'
        );
        insert testAsset;

        Node__c darkNode = new Node__c(
            Name = 'DarkNode001',
            serial_number__c = 'DarkNode001',
            asset__c = testAsset.Id
        );
        insert darkNode;

        Node__c edgeNode = new Node__c(
            Name = 'EdgeNode001',
            serial_number__c = 'EdgeNode001',
            Model__c = 'Edge',
            asset__c = testAsset.Id
        );
        insert edgeNode;

        Test.startTest();
        System.runAs(portalUser) {
            List<Node__c> result = MyProductsController.DarkNodes();

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(!result.isEmpty(), 'Should return at least one node');

            Boolean darkNodeFound = false;
            Boolean edgeNodeFound = false;

            for (Node__c node : result) {
                darkNodeFound |= node.Id == darkNode.Id;
                edgeNodeFound |= node.Id == edgeNode.Id;
            }

            System.assert(darkNodeFound, 'Dark node should be returned');
            System.assert(!edgeNodeFound, 'Edge node should NOT be returned');
        }
        Test.stopTest();
    }
}
    
    /**
    * @description Method to cover clusters entitlement mapping
    */
    @IsTest
    static void testClustersEntitlementMapping() {
        // Disable ALL validation rules and triggers
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
            Name = 'Default',
            Disable_Account_Triggers__c = true,
            Disable_Entitlement_Validation_Rules__c = true,  
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert disableLogic;
        
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c>();
        triggerControls.add(new TriggerControl__c(Name = 'Cluster', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Asset', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Node', DisableTrigger__c = true));
        insert triggerControls;
        
        Account acc = new Account();
        acc.name = 'Test Account';
        acc.type = 'Partner';
        insert acc;
        
        Contact con = new Contact();
        con.lastName = 'Test Last';
        con.AccountId = acc.Id;
        con.Email='testrubrikcs'+System.currentTimeMillis()+'@rubrik.com';
        insert con;
        
        Id sysAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User sysAdminUser = new User(
            alias = 'testadm', 
            email = 'testadmin@noemail.com',
            emailencodingkey = 'UTF-8', 
            lastname = 'TestAdmin', 
            languagelocalekey = 'en_US',
            localesidkey = 'en_US', 
            profileid = sysAdminProfileId, 
            country = 'United States',
            IsActive = true,
            FirstName = 'Test Admin',
            timezonesidkey = 'America/Los_Angeles', 
            username = 'testadmin@noemail.com'
        );
        insert sysAdminUser;
        
        System.runAs(sysAdminUser) {
            Product2 prod = new Product2();
            prod.IsActive = true;
            prod.name = 'Test Product';
            prod.ProductCode = 'TEST-PROD';
            insert prod;
            
            Asset testAsset = new Asset();
            testAsset.Name = 'Test Asset';
            testAsset.AccountId = acc.Id;
            testAsset.Product2Id = prod.Id;
            testAsset.Status = 'Installed';
            insert testAsset;
            
            Long timestamp = System.currentTimeMillis();
            
            Cluster__c testCluster = new Cluster__c();
            testCluster.account__c = acc.id;
            testCluster.name = 'TestCluster' + timestamp;
            testCluster.uuid__c = 'TestCluster' + timestamp;
            testCluster.archived__c = false;
            testCluster.software_version__c = null;
            insert testCluster;
            
            Node__c node = new Node__c();
            node.Name = 'Test Node';
            node.Model__c = null;
            node.serial_number__c='Test Node';
            node.cluster__c = testCluster.id;
            node.asset__c = testAsset.Id;
            insert node;
            
            try {
                Entitlement ent = new Entitlement();
                ent.Name = 'Test Entitlement';
                ent.AccountId = acc.Id;
                ent.AssetId = testAsset.Id;
                ent.Product__c = prod.Id;
                ent.Terminated_Date__c = Date.today().addDays(30);
                ent.StartDate = Date.today();
                ent.EndDate = Date.today().addDays(365);
                insert ent;
              
            } catch(Exception e) {
                //removed debug statement
            }
            
            
            Test.startTest();
            List<MyProductsController.ProductWrapper> result = MyProductsController.clusters();
            MyProductsController.ProductWrapper testWrapper = new MyProductsController.ProductWrapper(testCluster, new List<Node__c>{node});
            System.assertNotEquals(null, testWrapper.clustr, 'Cluster should be set in wrapper');
            System.assertNotEquals(null, testWrapper.nodes, 'Nodes list should be set in wrapper');
            
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }
    /**
    * @description Method to cover complete clusters() method including all SOQL queries and entitlement mapping
    */
    @IsTest
    public static void testCompleteClustersCoverage(){

    User adminUser = createInternalUserWithRole(); 
    
    System.runAs(adminUser) {
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c>();
        triggerControls.add(new TriggerControl__c(Name = 'Cluster', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Node', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Asset', DisableTrigger__c = true));
        triggerControls.add(new TriggerControl__c(Name = 'Account', DisableTrigger__c = true));
        insert triggerControls;
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
            Name = 'Default',
            Disable_Entitlement_Validation_Rules__c = true,
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert disableLogic;
        
        Account acc = new Account(Name = 'Test Account', Type = 'Partner');
        insert acc;
        
        Contact con = new Contact(LastName = 'Test Last', AccountId = acc.Id,Email='testrubrikcs'+System.currentTimeMillis()+'@rubrik.com');
        insert con;
        
        List<Product2> productsToInsert = new List<Product2>();
        productsToInsert.add(new Product2(IsActive = true, Name = 'Prod 1', ProductCode = 'P1', Family = 'CLOUT'));
        productsToInsert.add(new Product2(IsActive = true, Name = 'Prod 2', ProductCode = 'P2', Family = 'CLON'));
        insert productsToInsert;
        
        List<Asset> assetsToInsert = new List<Asset>();
        assetsToInsert.add(new Asset(Name = 'A1', AccountId = acc.Id, Product2Id = productsToInsert[0].Id, Status = 'Installed'));
        assetsToInsert.add(new Asset(Name = 'A2', AccountId = acc.Id, Product2Id = productsToInsert[1].Id, Status = 'Installed'));
        assetsToInsert.add(new Asset(Name = 'A3', AccountId = acc.Id, Product2Id = productsToInsert[0].Id, Status = 'Installed'));
        insert assetsToInsert;
        
        RSCInstance__c rsc = new RSCInstance__c(
            RSCAccountName__c = 'Rubrik Cloud', 
            AccountId__c = acc.Id, 
            SDPEndUser__c = acc.Id 
        );
        insert rsc;

        Long timestamp = System.currentTimeMillis();
        
        List<Cluster__c> clustersToInsert = new List<Cluster__c>();
        Cluster__c edgeCluster = new Cluster__c(Account__c = acc.Id, Name = 'Edge' + timestamp, uuid__c = 'Edge' + timestamp);
        Cluster__c nonEdgeCluster1 = new Cluster__c(Account__c = acc.Id, Name = 'NonEdge1' + timestamp, uuid__c = 'NonEdge1' + timestamp);
        Cluster__c nonEdgeCluster2 = new Cluster__c(Account__c = acc.Id, Name = 'NonEdge2' + timestamp, uuid__c = 'NonEdge2' + timestamp);
        clustersToInsert.add(edgeCluster);
        clustersToInsert.add(nonEdgeCluster1);
        clustersToInsert.add(nonEdgeCluster2);
        insert clustersToInsert;
        
        List<Node__c> nodesToInsert = new List<Node__c>();

        nodesToInsert.add(new Node__c(
            Name = 'EdgeNode1', serial_number__c = 'EdgeNode1', 
            Model__c = 'Edge', cluster__c = edgeCluster.Id, asset__c = assetsToInsert[0].Id
        ));

        nodesToInsert.add(new Node__c(
            Name = 'EdgeNode2', serial_number__c = 'EdgeNode2', 
            Model__c = 'Edge', cluster__c = edgeCluster.Id, asset__c = assetsToInsert[1].Id
        ));

        nodesToInsert.add(new Node__c(
            Name = 'AirNode1', serial_number__c = 'AirNode1', 
            Model__c = null, cluster__c = nonEdgeCluster1.Id, asset__c = assetsToInsert[2].Id
        ));

        nodesToInsert.add(new Node__c(
            Name = 'NullModelNode', serial_number__c = 'NullModelNode', 
            Model__c = null, cluster__c = nonEdgeCluster2.Id, asset__c = assetsToInsert[0].Id
        ));

        nodesToInsert.add(new Node__c(
            Name = 'NoAssetNode', serial_number__c = 'NoAssetNode', 
            Model__c = 'Edge', cluster__c = nonEdgeCluster1.Id, asset__c = null
        ));

        insert nodesToInsert;
        
        Entitlement ent = new Entitlement(
            Name = 'Test Ent', AccountId = acc.Id, AssetId = assetsToInsert[0].Id, 
            Product__c = productsToInsert[0].Id, StartDate = Date.today().addDays(-1), EndDate = Date.today().addDays(365)
        );
        insert ent;
        
        Id communityProfileId = [SELECT Id FROM Profile WHERE Name LIKE 'Rubrik Customer Community Super Login User' LIMIT 1].Id;
        User portalUser = new User(
            alias = 'test' + String.valueOf(timestamp).right(4), 
            email = 'test' + timestamp + '@noemail.com',
            lastname = 'Testing', profileid = communityProfileId, ContactId = con.Id,
            username = 'tester' + timestamp + '@noemail.com',
            TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', IsActive = true
        );
        insert portalUser;
        Test.startTest();
        System.runAs(portalUser) {
            List<MyProductsController.ProductWrapper> result = MyProductsController.clusters();
            System.assertNotEquals(null, result, 'Result should not be null');
        }
        Test.stopTest();
    }
    }
	
    /**
    * @description Method to cover getRSCInstances.
    */
    @IsTest
    public static void testGetRSCInstancesService() {
        User admin = createInternalUserWithRole();
        System.runAs(admin) {
            Account acc = new Account(Name = 'Service Test Acc', Type = 'Partner');
            insert acc;
    
            Contact con = new Contact(LastName = 'ServiceContact', AccountId = acc.Id,Email='testrubrikcs'+System.currentTimeMillis()+'@rubrik.com');
            insert con;
    
            List<RSCInstance__c> instances = new List<RSCInstance__c>{
                new RSCInstance__c(RSCAccountName__c = 'Inst 1', AccountId__c = acc.Id,RSCUrl__c = 'https://test1.com'),
                new RSCInstance__c(RSCAccountName__c = 'Inst 2',SDPEndUser__c = acc.Id,RSCUrl__c = 'https://test2.com')
            };
            insert instances;
    
            User portalUser = createPortalUser(con, 'svc');
    
            Test.startTest();
            System.runAs(portalUser) {
                RSCInstanceService.TableWrapper result = MyProductsController.getRSCInstances();    
                System.assertNotEquals(null,result,'Result wrapper should not be null');
            }
            Test.stopTest();
        }
    }
    
    /**
     * @description Method to cover MosaicClusters.
     */
    @IsTest
    public static void testMosaicClusters() {
        User admin = createInternalUserWithRole();
        
        System.runAs(admin) {
            List<TriggerControl__c> triggerControls = new List<TriggerControl__c>();
            triggerControls.add(new TriggerControl__c(Name = 'Cluster', DisableTrigger__c = true));
            triggerControls.add(new TriggerControl__c(Name = 'Node', DisableTrigger__c = true));
            insert triggerControls;

            Account acc = new Account(Name = 'Mosaic Account', Type = 'Customer');
            insert acc;

            Long timestamp = System.currentTimeMillis();
            Cluster__c mosCluster = new Cluster__c(
                Name = 'MosaicCluster' + timestamp,
                Account__c = acc.Id,
                archived__c = false,
                tag__c = 'Datos', 
                uuid__c = 'MosaicCluster' + timestamp
            );
            insert mosCluster;

            Node__c nd = new Node__c(
                Name = 'MOS-NODE-001',
                serial_number__c = 'MOS-NODE-001',
                cluster__c = mosCluster.Id,
                Model__c = null 
            );
            insert nd;

            Test.startTest();
            List<MyProductsController.ProductWrapper> results = MyProductsController.MosaicClusters();
            Test.stopTest();

            System.assertNotEquals(0, results.size(), 'MosaicClusters should return at least one record');
            
            System.assertEquals(mosCluster.Id, results[0].clustr.Id, 'The returned cluster ID should match the one inserted');
            System.assertNotEquals(0, results[0].nodes.size(), 'The wrapper should contain the child node');
        }
    }
    /**
     * @description Helper method to create an internal user with a role (required for portal user creation).
     * @return User Internal Admin User.
     */
    private static User createInternalUserWithRole() {
        List<User> usersList=[Select id from User where username='myproductscontrollertestuser123@rubrik.com'];

        if(usersList.size() > 0) {
          return usersList[0];  
        }
        UserRole ur = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User u = new User(
            LastName = 'IntAdmin',
            Alias = 'iadm',
            Email = 'admin' + DateTime.now().getTime() + '@test.com',
            Username = 'myproductscontrollertestuser123@rubrik.com',
            ProfileId = p.Id,
            UserRoleId = ur.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }

    /**
     * @description Helper method to create a portal user.
     * @param con Contact associated with portal account.
     * @param suffix Unique suffix for username.
     * @return User Portal User.
     */
    private static User createPortalUser(Contact con, String suffix) {
        List<User> usersList=[Select id from User where username='myproductscontrollertestportaluser123@rubrik.com'];

        if(usersList.size() > 0) {
          return usersList[0];  
        }

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User' LIMIT 1];
        
        User u = new User(
            LastName = 'PortalUser',
            Alias = 'p' + suffix,
            Email = 'portal' + suffix + '@test.com',
            Username = 'myproductscontrollertestportaluser123@rubrik.com',
            ProfileId = p.Id,
            ContactId = con.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert u;
        return u;
    }
}