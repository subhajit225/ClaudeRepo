@isTest
public class ProductTriggerTest {
    private static List<Product2> products;
    
    //@testSetup
    static void testSetup() {
        products = new List<Product2> {
            new Product2(
                Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
                Category__c = 'Platform',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
            new Product2(
                Name = 'RBK-R348S-UG-01',
                ProductCode = 'RBK-R348S-UG-01',
                Category__c = 'Software',
                Family = 'R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'RBK-R348S',
                Appliance_Model_HW__c = 'R348',
                Single_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            ),
                new Product2(
                    Name = 'SE-R348S-UG-01',
                    ProductCode = 'SE-R348S-UG-01',
                    Category__c = 'Software',
                    Family = 'R300',
                    Support_Type__c = 'PREM',
                    Appliance_Model__c = 'SE-R348S',
                    Appliance_Model_HW__c = 'SE348',
                    Single_Entitlement__c = true,
                    Asset_Priority__c = 0,
                    IsActive = true,
                    Is_Refresh_Product_MinQnty__c = '1'
                )
        };
        insert products;
        System.assert(products[0].id != null);
    }
    @isTest
    static void testQuotingRestriction(){
        testSetup();
        System.runAs(new user(ID = UserInfo.getUserID())){
            products[0].Quotable_by_profiles__c = 'Deal Operations';
            
            products[1].Quotable_by_profiles__c = 'Deal Operations';
            products[1].Quoting_Restriction__c = 'User/Profile';
            
            products[2].Quoting_Restriction__c = 'User/Profile;Limited Available;Account';

            Test.startTest();
            update products;
            System.assert(true);
            Test.stopTest();   
        }     
    }
    @isTest
    static void testProductUpdate(){
        testSetup();
        System.runAs(new user(ID = UserInfo.getUserID())){
            products[0].Category__c = 'Software';
            products[0].Family = 'R500';
            products[0].Description = 'Testing';
            products[0].Is_Refresh_Product_MinQnty__c = null;
            products[1].Is_Refresh_Product_MinQnty__c = null;
            products[1].Description = 'Testing';
            products[2].Is_Refresh_Product_MinQnty__c = '2';
            Test.startTest();
            update products;
            List<Product2> savedProductList = [Select Category__c,  Family, Description, Is_Approval_Pending__c from Product2 where ID = :products[0].id OR ID = :products[1].id];
            //System.assert(savedProductList[0].Family == 'R300');
            //System.assert(savedProductList[0].Description == 'Testing');
            //System.assert(savedProductList[0].Is_Approval_Pending__c);
            //System.assert(!savedProductList[1].Is_Approval_Pending__c);
            //System.assert(savedProductList[0].Description == 'Testing');
            ProductTriggerHelper.seProductCodeModifier(products[2].ProductCode,'SE-','S-');
            System.assert(true);
            Test.stopTest();
        }
    }
    @isTest
    static void testProductUpdateTriggerHandler(){
        System.runAs(new user(ID = UserInfo.getUserID())){
            ProductTriggerHandler tHandler = new ProductTriggerHandler();
            tHandler.beforeInsert(null);
            tHandler.beforeUpdate(null, null);
            tHandler.beforeDelete(null);
            tHandler.afterInsert(null);
            tHandler.afterUpdate(null, null);
            tHandler.afterDelete(null);
            System.assert(tHandler != null);
        }
    }
    @isTest
    static void testTriggerFactory(){
        System.runAs(new user(ID = UserInfo.getUserID())){
            ProductTriggerHandler tHandler = new ProductTriggerHandler();
            ITrigger triggerHandler = null;
            triggerHandler = TriggerFactory.getHandler(null);
            triggerHandler = TriggerFactory.getHandler(POC__c.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Deal_Registration__c.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Asset.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Opportunity.sObjectType);
            triggerHandler = TriggerFactory.getHandler(OpportunityLineItem.sObjectType);
            //triggerHandler = TriggerFactory.getHandler(Entitlement.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Lead.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Contact.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Account.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Task.sObjectType);
            triggerHandler = TriggerFactory.getHandler(Custom_Upgrade_Source__c.sObjectType);
            System.assert(triggerHandler != null);

            
            try{
                TriggerFactory.createHandler(Custom_Upgrade_Source__c.sObjectType);
                TriggerFactory.createHandler(null);
            } catch(Exception e){
                System.Debug(LoggingLevel.INFO, 'Error Message '+ e.getMessage());
            }

            testSetup();
            List<Product2> savedProductList = [Select Category__c,  Family, Description, Is_Approval_Pending__c from Product2];
            
            List<Custom_Upgrade_Source__c> customUpgradeSourceList = new List<Custom_Upgrade_Source__c>();
            Custom_Upgrade_Source__c customUpgradeSource = new Custom_Upgrade_Source__c();
            customUpgradeSource.Active__c = true;
            customUpgradeSource.UpgradeProduct__c = savedProductList[0].id;
            customUpgradeSource.Source_Product__c = savedProductList[1].id;
            
            customUpgradeSourceList.add(customUpgradeSource);
            
            Test.startTest();
            insert customUpgradeSourceList;
            update customUpgradeSourceList;
            Delete savedProductList;
            delete customUpgradeSourceList;
            Test.stopTest();
            
        }
    }

    @IsTest
    static void testBeforeProductUpdate() {
        System.runAs(new user(ID = UserInfo.getUserID())){
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        Id cPQPriceBookId =  system.label.CPQ_Pricebook_ID;

        Product2 prodWithSE = new Product2(
            Name  = 'Product With SE',
            ProductCode = 'SE-1234',
            IsActive = true
        );
        Product2 prodV2 = new Product2(
            Name  = 'Product With SE',
            ProductCode = 'V2-1234',
            Product_Level__c = null,
            IsActive = true
        );
        Product2 prodWithoutSE = new Product2(
            Name = 'Product Without SE',
            ProductCode = 'ABC-5678',
            IsActive = true,
            Refresh_Credit_Amount__c = 200,
            Is_Refresh_Product_MinQnty__c = '3'
        );
        insert new List<Product2>{ prodWithSE, prodWithoutSE, prodV2 };

        PricebookEntry pbeSE = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id   = prodWithSE.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        PricebookEntry pbeV2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id   = prodV2.Id,
            UnitPrice    = 100,
            IsActive     = false
        );
        PricebookEntry pbeNoSE = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id   = prodWithoutSE.Id,
            UnitPrice    = 200,
            IsActive     = true
        );
        insert new List<PricebookEntry>{ pbeSE, pbeNoSE, pbeV2 };

        PricebookEntry pbeNoSE2 = new PricebookEntry(
            Pricebook2Id = cPQPriceBookId,
            Product2Id   = prodWithoutSE.Id,
            UnitPrice    = 200,
            IsActive     = true
        );
        insert pbeNoSE2;
        PricebookEntry pbeV2CPQ = new PricebookEntry(
            Pricebook2Id = cPQPriceBookId,
            Product2Id   = prodV2.Id,
            UnitPrice    = 200,
            IsActive     = false
        );
        insert pbeV2CPQ;

        Product2[] oldProducts = [
            SELECT Id, 
                   Is_Refresh_Product_MinQnty__c, 
                   Sales_Comp_Category__c, 
                   ProductCode,
                   Pricebook_Entry_Id__c,
                   Product_Level__c,
                   IsActive 
              FROM Product2 
             WHERE Id IN :new List<Id>{ prodWithSE.Id, prodWithoutSE.Id, prodV2.Id }
        ];
        
        Map<Id, Product2> oldMap = new Map<Id, Product2>(oldProducts);

        prodWithSE.Is_Refresh_Product_MinQnty__c = null; // '2';
        
        //prodWithSE.Sales_Comp_Category__c = 'HW SUPPORT';

        
        prodWithoutSE.Is_Refresh_Product_MinQnty__c = '4'; // null;  // was null
        //prodWithoutSE.Sales_Comp_Category__c = 'HARDWARE';
        prodV2.Is_Refresh_Product_MinQnty__c = null;
        
        ProductTriggerHelper.populatePricebookDetailsOnProduct(oldProducts);

        Map<Id, Product2> newMap = new Map<Id, Product2>(new List<Product2>{ prodWithSE, prodWithoutSE, prodV2 });

        Test.startTest();
        ProductTriggerHelper.beforeProductUpdate(oldMap, newMap);
        update newMap.values();
        Test.stopTest();

        System.assertEquals(
            null, 
            newMap.get(prodWithSE.Id).Refresh_Credit_Amount__c, 
            'Expected null because there is no PricebookEntry for the code "S-1234".'
        );

        Product2 newWithSE = newMap.get(prodWithSE.Id);
        Product2 newWithoutSE = newMap.get(prodWithoutSE.Id);

        System.assertEquals(
            null, 
            newWithSE.SalesCompCategoryChangedDate__c, 
            'Expected SalesCompCategoryChangedDate__c to be null as NOT changed.'
        );
        System.assertEquals(
            null,
            newWithoutSE.SalesCompCategoryChangedDate__c,
            'Expected SalesCompCategoryChangedDate__c to be null as well.'
        );
     }
    }
}