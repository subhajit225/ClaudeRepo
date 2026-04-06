@isTest
public class CreateUCLSnowflakeFeedsHelper_Test{      

    static testMethod void testInsertOder(){
     insert new TriggerControl__c(name = 'Order', DisableTrigger__c = false);
        
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true ,Disable_Order_Email_Alerts__c = false, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = false, setupOwnerId = userinfo.getuserid());

          Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

               Account acct =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        
        insert acct;
             opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' , Opportunity_Sub_Type__c = 'Regular', Distributor_Lookup__c = acct.Id, Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Mosaic_Customer_Environment__c='AWS', CloseDate = Date.Today().addDays(10), Lead_Email_Hidden__c='', AccountId = acct.Id, StageName = '1 Discovery',
                                           Rubrik_Sales_Engineer__c = UserInfo.getUserId(), Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Alliance_Source_Type_SW__c ='Rubrik Initiated Alliance Deal', Identified_Pain__c = 'Test', Champion__c = 'Test', ForecastCategoryName = 'Best Case');
        
        insert oppr;
            insert new Hold_Off_Tracking__c (Hold_Code__c = 'OM Internal Review', Release_Date_Time__c = datetime.newInstance(2021, 9, 15, 12, 30, 0), Related_Opportunity__c = oppr.Id, Is_Released__c = false);
            
            Id pricebookId = Test.getStandardPricebookId();
            oppr.pricebook2Id = pricebookId;
            oppr.Opportunity_Sub_Type__c = 'Renewal';
            
            update oppr;
            
            List<Product2> lstProds = new List<Product2>{
                new Product2(
                    Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344',Family='ASE', Appliance_Model_HW__c = 'RBK-R6408F',
                    isActive = true,Product_Level__c = 'Support'
                ),
                    new Product2(
                        Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344', Appliance_Model_HW__c = 'RBK-R640F',
                        isActive = true ,Product_Level__c = 'Support', Bundle_Features__c = 'Cloud Native Protection', Family ='POLARIS'
                    ),
                     new Product2(
                        Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344',Product_Type__c='MSP', Appliance_Model_HW__c = 'RBK-R640F',
                        isActive = true , Bundle_Features__c = 'Cloud Native Protection', Family ='RCDM',
                         MSP_Std_Actual__c=null,Product_Level__c = 'Support'
                    )
                    };
                        
                        insert lstProds;
            
            List<PricebookEntry> lstPbEntry =new List<PricebookEntry>{
                new PricebookEntry(
                    Pricebook2Id = oppr.pricebook2Id,
                    Product2Id = lstProds[0].Id,
                    UnitPrice = 100.00,
                    IsActive = true
                ),
                    new PricebookEntry(
                        Pricebook2Id = oppr.pricebook2Id,
                        Product2Id = lstProds[1].Id,
                        UnitPrice = 100.00,
                        IsActive = true
                    ),
                     new PricebookEntry(
                        Pricebook2Id = oppr.pricebook2Id,
                        Product2Id = lstProds[2].Id,
                        UnitPrice = 100.00,
                        IsActive = true
                    )
                    };
                        
                        insert lstPbEntry;
            
            List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
                new OpportunityLineItem(
                    OpportunityId = oppr.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry[0].Id,
                    TotalPrice = 5 *  lstPbEntry[0].UnitPrice
                ),
                    new OpportunityLineItem(
                        OpportunityId = oppr.Id,
                        Quantity = 5,
                        PricebookEntryId = lstPbEntry[1].Id,
                        TotalPrice = 5 *  lstPbEntry[1].UnitPrice
                    )
                    };
                        
                        insert lstOlis;
            
            test.startTest();
            
            Map<String, Object>  OrderMap = new Map<String, Object> {
                'Type' => 'Revenue',
                    'AccountId' => acct.Id,
                    'OpportunityId' => oppr.Id,
                    'Sync_to_NetSuite__c' => true,
                    'EffectiveDate' => system.today(),
                    'Status' => 'Pending',
                    'Mosaic_SKUs__c' => 'RBK-MOSAIC',
                    'ShippingCountryCode' => 'US',
                    'Polaris_Fulfillment_Status__c' => 'Completed',
                    'Is_RWD_Polaris_Quote__c' => true 
                    };
                        
                        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            insert Ord;
            
            List<OrderItem> lstOrdrItems = new List<OrderItem>{
                new OrderItem(
                    OrderId = Ord.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry[0].Id,
                    UnitPrice = lstPbEntry[0].UnitPrice,
                    SerialNumber__c = 'S3F4NXMM416324',
                    Failed_Serial_Number__c = 'S3F4NXM416324',
                    Support_End_Date__c = System.Today().addYears(1),
                    Support_Start_Date__c = System.Today(),
                    Global_Commit_ID__c='23456789'
                    
                )
                   
                    };
                        
                        insert lstOrdrItems;
                         Scale_Utility_Overage__c suo = new Scale_Utility_Overage__c();
                        suo.Account_ID__c = acct.id;
                        suo.Global_Commit_ID__c = lstOrdrItems[0].Global_Commit_ID__c;
                        suo.Is_First_Item__c = true;
                        suo.License_Order_Product__c = lstOrdrItems[0].id;
                        suo.On_Demand_Period_End_Date__c = System.today().addMonths(1).addDays(-1);
                        suo.On_Demand_Period_Start_Date__c = System.today();
                        suo.OnDemand_Order_Product__c = lstOrdrItems[0].id;
                        suo.Original_Order__c = ord.id;
                        suo.Process_Flag__c = 'Do not Process';
                        suo.Reserve_Order_Line__c = lstOrdrItems[0].id;
                        suo.Snapshot_Date__c = System.today();
                        suo.Usage_in_TB__c = 1000.00;
                        insert suo;
        Map<String,String> createSnowFlakeMap = new Map<String,String>();
        createSnowFlakeMap.put('Global_Commit_ID__c',lstOrdrItems[0].Global_Commit_ID__c);
        createSnowFlakeMap.put('Account_ID__c',acct.id);
        createSnowFlakeMap.put('recordId',suo.id);
        createSnowFlakeMap.put('Cluster_UUID__c','test_112');
        createSnowFlakeMap.put('Cluster_Usage_FETB__c','112.23');

           String snowFlakeId =   CreateUCLSnowflakeFeedsHelper.createSnowFlakeFeed(createSnowFlakeMap); 
             System.assert(snowFlakeId != null);
            test.stopTest(); 
            
         
    
    }
}