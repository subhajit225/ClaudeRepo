/**
* @File Name : RateCardProductsController_Test.cls
* @description : Test Class for RateCardProductsController.cls
* @Modification Log :
********************Change Logs ********************************************
* User Story            Modified By          Date               Description
* CS21-3905             Shailesh Kumar	    January 29,2026		Added methods for coverage
********************Change Logs Ends****************************************
**/
@IsTest
public class RateCardProductsController_Test {
    private static User getSysAdminUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = true
            LIMIT 1
        ];
    }

    @IsTest
    static void testGetProducts() {
        User adminUser = getSysAdminUser();
        RateCardProductsController controller = new RateCardProductsController();
        System.runAs(adminUser) {
            insert new Rate_Card_Product__c(
                Product_Name__c = 'Alpha',
                Product_Description__c = 'test Desciption',
                Sort_Order__c = 'desc'
            );

            Test.startTest();
            List<Rate_Card_Product__c> products =
                RateCardProductsController.getProducts();
            controller.ordId = products[0]?.Id;//fake order Id
            Test.stopTest();
            System.assert(products.size() > 0, 'Products should be returned');
            System.assertEquals('Alpha', products[0].Product_Name__c);
        }
    }

    @IsTest
    static void testSaveProducts() {
        User adminUser = getSysAdminUser();

        System.runAs(adminUser) {
            Rate_Card_Product__c prod = new Rate_Card_Product__c(
                Product_Name__c = 'Old Name',
                Product_Description__c = 'Old Desc',
                Sort_Order__c = 'asc'
            );
            insert prod;

            prod.Product_Name__c = 'Updated Name';

            Test.startTest();
            RateCardProductsController.saveProducts(
                new List<Rate_Card_Product__c>{ prod }
            );
            Test.stopTest();

            Rate_Card_Product__c updated =
                [SELECT Product_Name__c FROM Rate_Card_Product__c WHERE Id = :prod.Id];

            System.assertEquals(
                'Updated Name',
                updated.Product_Name__c,
                'Product name should be updated'
            );
        }
    }

    @IsTest
    static void testAddProduct() {
        User adminUser = getSysAdminUser();
        Product2 prod1 = new Product2();
        prod1.Name = 'Prduct A Test';
        prod1.ProductCode = 'ProductXYZ123';
        prod1.isActive = true;
        prod1.Family ='POLARIS';
        prod1.Product_Type__c = 'Appliance';
        insert prod1;
        System.runAs(adminUser) {
            Test.startTest();
            RateCardProductsController.ProductWrapper prod =
                RateCardProductsController.addRateCardProduct(
                    String.valueOf(prod1.Id),
                    'desc'
                );
            Test.stopTest();
            System.assertNotEquals(null, prod.recId, 'Product should be inserted');
        }
    }

    @IsTest
    static void testDeleteProducts() {
        User adminUser = getSysAdminUser();

        System.runAs(adminUser) {
            Rate_Card_Product__c prod = new Rate_Card_Product__c(
                Product_Name__c = 'To Delete',
                Product_Description__c = 'Delete Me',
                Sort_Order__c = 'asc'
            );
            insert prod;

            Test.startTest();
            RateCardProductsController.deleteProducts(
                new List<Id>{ prod.Id }
            );
            Test.stopTest();

            Integer countRecords = [
                SELECT COUNT()
                FROM Rate_Card_Product__c
                WHERE Id = :prod.Id
            ];

            System.assertEquals(0, countRecords, 'Product should be deleted');
        }
    }

    @IsTest
    static void testUpdateSortOrder() {
        User adminUser = getSysAdminUser();

        System.runAs(adminUser) {
            insert new Rate_Card_Product__c(
                Product_Name__c = 'Prod Sort',
                Product_Description__c = 'Sort Desc',
                Sort_Order__c = 'asc'
            );

            Test.startTest();
            RateCardProductsController.updateSortOrder('desc');
            Test.stopTest();

            Rate_Card_Product__c updated =
                [SELECT Sort_Order__c FROM Rate_Card_Product__c LIMIT 1];

            System.assertEquals('desc',updated.Sort_Order__c,'Sort order should be updated to desc');
        }
    }

    @IsTest
    static void testGuardClauses() {
        User adminUser = getSysAdminUser();

        System.runAs(adminUser) {
            // Should not throw exception
            RateCardProductsController.saveProducts(null);
            RateCardProductsController.deleteProducts(null);
            RateCardProductsController.updateSortOrder('invalid');

            System.assert(true, 'Guard clauses executed safely');
        }
    }
    
    @IsTest
    static void testDuplicateProduct() {
        User adminUser = getSysAdminUser();
        Product2 prod1 = new Product2();
        prod1.Name = 'Prduct A Test';
        prod1.ProductCode = 'ProductXYZ123';
        prod1.isActive = true;
        prod1.Family ='POLARIS';
        prod1.Product_Type__c = 'Appliance';
        insert prod1;
        
        insert new Rate_Card_Product__c(
            Product_Name__c = prod1.Name,
            Product_Description__c = 'Existing Desc',
            Sort_Order__c = 'asc'
        );
        
        System.runAs(adminUser) {
            Test.startTest();
            RateCardProductsController.ProductWrapper result =
                RateCardProductsController.addRateCardProduct(
                    String.valueOf(prod1.Id),
                    'desc'
                );
            Test.stopTest();
            System.assertEquals(true,result.isDuplicate,'Duplicate flag should be true');
        }
    }
}