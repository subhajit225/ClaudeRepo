/*******************************************************************************
* @description       : Apex Test Class for PreviousTransRefWrapper
* @created on        : 03-04-2025
* @created by        : Naveen Selvaraj / Ravi
* *****************************************************************************
* History
* Date                Modification           Author
* 03-04-2025          FY25SR-1212             naveenkumar.selvaraj@rubrik.com
*******************************************************************************
*/ 
@isTest
public class PreviousTransRefWrapperTest {
    /**
* @description method to create test data
*/
    @testSetup
    static void createData(){
        Test.startTest();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        
        insert new TriggerControl__c(Name = 'Order', DisableTrigger__c = false);
        
        insert new ShGl_DisableBusinessLogic__c(
            Disable_POC_Validation_Rules__c = true,
            Disable_Entitlement_Validation_Rules__c = true,
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_SBQQ_QuoteLine_Triggers__c = true,
            Disable_Opportunity_Validation_Rules__c = true,
            Disable_Opportunity_Triggers__c = true,
            Disable_Order_Email_Alerts__c = true,
            Disable_Order_Old_Trigger__c = true,
            Disable_Order_Triggers__c = true,
            Disable_Contact_Triggers__c = true,
            setupOwnerId = userinfo.getuserid(),
            Disable_POC_Trigger__c = true
        );
        insert new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true, setupOwnerId = userinfo.getuserid());
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account acct = new Account(
            BillingCountryCode = 'US',
            Is_Refreshed__c = false,
            Name = 'Test',
            Sync_to_NetSuite__c = false,
            RecordTypeId = devRecordTypeId,
            Website = 'www.test3.com',
            OwnerId = userinfo.getUserId(),
            type = 'Customer'
        );
        
        insert acct;
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prodRec = new Product2(
            Name = 'RBK-SVC-PREM-R345',
            ProductCode = 'RBK-SVC-PREM-R345',
            Family = 'POLARIS',
            Appliance_Model_HW__c = 'RBK-R6408E',
            isActive = true,
            Bundle_Features__c = 'Polaris',
            Allow_PSO_Task_Creation__c = true,
            usable_Capacity__c = 60,
            Product_Level__c = 'OnPrem'
        );
        insert prodRec;
        
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodRec.Id, UnitPrice = 100.00, IsActive = true);
        insert pbEntry;
        Map<String, Object> OrderMap = new Map<String, Object>{
            'Type' => 'Revenue',
                'Send_for_Polaris_Fulfilment__c' => true,
                'AccountId' => acct.Id,
                'EffectiveDate' => system.today(),
                'Status' => 'Pending',
                'Sync_to_NetSuite__c' => true,
                'ShippingCountryCode' => 'US',
                'ShippingStateCode' => 'CA',
                'ShippingStreet' => 'Test Street',
                'ShippingCity' => 'Test City',
                'ShippingState' => 'California',
                'ShippingCountry' => 'United States',
                'ShippingPostalcode' => '94820',
                'ship_To_Name__c' => acct.id,
                'ShipToContactName__c' => 'Test',
                'Pricebook2Id' => pricebookId,
                'Have_Polaris_Products__c' => false,
                'Polaris_Fulfillment_Status__c' => 'Completed',
                'Original_Est_Ship_Date__c' => Date.today().addDays(30),
                'Est_Ship_Date__c' => null,
                'Order_Splitted__c' => true,
                'Order_Sub_Type__c' => 'Renewal'
                };
                    
                    Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        insert Ord;
        
        OrderItem ordItemRec = new OrderItem(
            OrderId = Ord.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = pbEntry.UnitPrice,
            SerialNumber__c = 'SN123,SN456',
            Failed_Serial_Number__c = 'S3F4NXM416324',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today(),
            Is_Hardware_Line__c = true,
            Is_Refresh__c = true
        );
        insert ordItemRec;
        Test.stopTest();
    }
    /**
* @description method to cover PreviousTransRefWrapper
*/
    @isTest
    static void testDeserializeJSON() {
        System.runAs(new User(Id = UserInfo.getUserId())){
            
            
            // Step 1: Prepare the test data - Create instances of PreviousTransRefWrapper
            Id testOItmId = [SELECT Id FROM OrderItem LIMIT 1].Id;  // Replace with a valid Id or mock Id
            Decimal testOIleftQty = 100.50;
            Id testEntId = null;  // Replace with a valid Id or mock Id
            Decimal testUsedEntQty = 50.25;
            Id testPhtmOid = [SELECT Id FROM Order LIMIT 1].Id;  // Replace with a valid Id or mock Id
            
            // Create a wrapper object
            PreviousTransRefWrapper wrapper = new PreviousTransRefWrapper(
                testOItmId, testOIleftQty, testEntId, testUsedEntQty, testPhtmOid, null, null, false
            );
            
            // Step 2: Serialize the wrapper to JSON
            List<PreviousTransRefWrapper> wrapperList = new List<PreviousTransRefWrapper>{wrapper};
                String jsonString = JSON.serialize(wrapperList);
            
            // Step 3: Test the deserializeJSON method
            Test.startTest();
            List<PreviousTransRefWrapper> deserializedList = PreviousTransRefWrapper.deserializeJSON(jsonString);
            Test.stopTest();
            
            // Step 4: Verify the deserialization works as expected
            System.assertEquals(1, deserializedList.size(), 'Deserialized list size should be 1');
            PreviousTransRefWrapper deserializedWrapper = deserializedList[0];
            System.assertEquals(testOItmId, deserializedWrapper.orderItemId, 'OItmId should match');
            System.assertEquals(testOIleftQty, deserializedWrapper.orderItemRemainingQuantity, 'OIleftQty should match');
            System.assertEquals(testEntId, deserializedWrapper.entId, 'entId should match');
            System.assertEquals(testUsedEntQty, deserializedWrapper.usedEntitlementQuantity, 'usedEntQty should match');
            System.assertEquals(testPhtmOid, deserializedWrapper.phantomOrderItemId, 'phtmOid should match');
        }
    }
}