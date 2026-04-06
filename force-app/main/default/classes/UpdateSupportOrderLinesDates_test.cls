/**************************************************************
* @description       : UpdateSupport Dates TestClass 
* @author            : Prashant
* @last modified on  : 17-09-2023

************************************************************/
@isTest
public class UpdateSupportOrderLinesDates_test {
    
   static testMethod void testscaleUtility(){
       Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

       Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        
        insert act;
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' , Opportunity_Sub_Type__c = 'Regular', Distributor_Lookup__c = act.Id, Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Mosaic_Customer_Environment__c='AWS', CloseDate = Date.Today().addDays(10), Lead_Email_Hidden__c='', AccountId = act.Id, StageName = '1 Discovery',
                                           Rubrik_Sales_Engineer__c = UserInfo.getUserId(), Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Alliance_Source_Type_SW__c ='Rubrik Initiated Alliance Deal',Identified_Pain__c = 'Test', Champion__c = 'Test', ForecastCategoryName = 'Best Case',Override__c=false,Aspen_Eligibility__c='Actual Aspen');
        
        insert oppr;

        insert new RPS__c(SetupOwnerId = Userinfo.getOrganizationId(), Is_RPS_Required__c =false, Screening_Source__c ='Internal', Valid_HoldCodes__c ='Global Trade Compliance screening failed;Credit Check Failed');
        
        testDataFactoryClass.createCustomSettings();
        
        System.runAs(new User(Id=UserInfo.getUserId())) {
            
            Account acct16 = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];
            Opportunity oppr16 = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId =: acct16.Id LIMIT 1];
            
            Id pricebookId = Test.getStandardPricebookId();
            oppr16.pricebook2Id = pricebookId;
            oppr16.Opportunity_Sub_Type__c='GC Offer';
            update oppr16;
            
            List<Product2> lstProds16 = new List<Product2>{
                new Product2(
                    Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-TR',Family='ASE', Appliance_Model_HW__c = 'RBK-R6408F',
                    Capacity__c='12TB',isActive = true),
                    new Product2(
                        Name='RBK-SVC-PREM-R3441',ProductCode='RBK-SVC-TR1',Family='ASE1', Appliance_Model_HW__c = 'RBK-R6408F1',
                        Capacity__c='36TB',isActive = true)
                    };
                        
                        insert lstProds16;
            
            List<PricebookEntry> lstPbEntry16 =new List<PricebookEntry>{
                new PricebookEntry(
                    Pricebook2Id = oppr16.pricebook2Id,
                    Product2Id = lstProds16[0].Id,
                    UnitPrice = 100.00,
                    IsActive = true
                )
                    };
                        
                        insert lstPbEntry16;
            
            List<OpportunityLineItem> lstOlis16 = new List<OpportunityLineItem>{
                new OpportunityLineItem(
                    OpportunityId = oppr16.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry16[0].Id,
                    TotalPrice = 5 *  lstPbEntry16[0].UnitPrice
                )
                    };
                        
                        insert lstOlis16;
            
            test.startTest();
            
            
            Map<String, Object>  OrderMap16 = new Map<String, Object> {
                'Type' => 'Revenue',
                   'Order_Sub_Type__c' => 'GC Offer', 
                    'AccountId' => acct16.Id,
                    'OpportunityId' => oppr16.Id,
                    'Sync_to_NetSuite__c' => true,
                    'EffectiveDate' => system.today(),
                    'Status' => 'Pending',
                    'ShippingCountryCode' => 'US',
                    'Polaris_Fulfillment_Status__c' => 'Completed'
                    };
                        
                        Order ord16 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap16);
            insert Ord16;
            
            List<OrderItem> lstOrdrItems16 = new List<OrderItem>{
                new OrderItem(
                    OrderId = Ord16.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry16[0].Id,
                    UnitPrice = lstPbEntry16[0].UnitPrice,
                    Support_End_Date__c = System.Today().addYears(1),
                    Support_Start_Date__c = System.Today()
                ),
                    new OrderItem(
                        OrderId = Ord16.Id,
                        Quantity = 5,
                        PricebookEntryId = lstPbEntry16[0].Id,
                        UnitPrice = lstPbEntry16[0].UnitPrice,
                        Support_End_Date__c = System.Today().addYears(1),
                        Support_Start_Date__c = System.Today()
                    )
                    };
                        
                        insert lstOrdrItems16;
            
            System.enqueueJob(new UpdateSupportOrderLinesDatesForCSUClass(lstOrdrItems16));

            test.stopTest();
            
        }
    }   


}