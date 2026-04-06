/********************************************************************************************************
* Name              : AssetTriggerHelper_Test 
* Purpose           : AssetTriggerHelper_Test is Used for Testing AssetTriggerHelper Class
********************************************************************************************************/
@isTest 
public class AssetTriggerHelper_Test {  
    static List<Asset> assetList;
    static boolean isUpdatedFromSystem =false; 
    static boolean allowFieldChanges= false;
    static boolean allowProductUpgrade = true;
   
    public  static testMethod void testSetFieldsOnAssetInsert(){
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, 
                                                Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                Disable_Account_Triggers__c = true,
                                                Disable_POC_Trigger__c = true,
                                                Disable_Lead_Triggers__c = true,
                                                Disable_Lead_Validation_Rules__c = true,
                                                Disable_OrderItem_Old_Trigger__c = true,
                                                Disable_Opportunity_Triggers__c = true ,
                                                Disable_Opportunity_Validation_Rules__c = true,
                                                Disable_Order_Email_Alerts__c = true, 
                                                Disable_Order_Old_Trigger__c = true, 
                                                Disable_Order_Triggers__c = true, 
                                                Disable_Asset_Triggers__c = false, 
                                                setupOwnerId = userinfo.getuserid()); 
        
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        TriggerControl__c custsetting = new TriggerControl__c(Name='Opportunity',DisableTrigger__c=true);
        TriggerControl__c PortalUserCreation = new TriggerControl__c(Name='PortalUserCreation');
        insert new List<TriggerControl__c>{custsetting,PortalUserCreation};
            
           ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = true;
        //disableFuncCS.DisableJustificationReqForEligibleFreeHW__c = false;
        //disableFuncCS.AssetOverrideFieldsRevertChanges__c = 'Eligible_for_Free_HW__c';
        insert disableFuncCS;
        
        StateNameCode__c custset = new StateNameCode__c(Name='California',Code__c='US-CA');
        insert custset;
        
        //Generate Account
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.Contract_Status__c = 'Not signed';
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        insert acct;
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Email'  =>'leademail@hidden.com'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                'Other_Competitor_Field__c' => 'Other',
                'Lost_To_Won_Against__c' => 'Other',
                'Polaris_Region__c' => 'US'                 
                };
                    
                    Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        oppty.ForecastCategoryName = 'Best Case';
        oppty.Economic_Buyer__c = 'Test';
        oppty.Metric__c = 'Test';
        oppty.Decision_Process__c = 'Test';
        oppty.Decision_Criteria__c = 'Test';
        oppty.Identified_Pain__c = 'Test';
        oppty.Champion__c = 'Test';
		oppty.Partner_Lookup__c = acct.Id; 
		oppty.Opportunity_Sub_Type__c = 'Renewal'; 
		
        insert oppty;
        
        //Generate POC records
        Map<String, Object>  pocMap = new Map<String, Object> {
            'POC_Duration__c' => '60 Days',
                'Planned_Installation_Date__c' => System.Today()+30,
                'Support_Awareness_needed__c' => 'Yes'
                };
                    Map<String, Object>  pocMap2 = new Map<String, Object> {
                        'POC_Duration__c' => '30 Days',
                            'Planned_Installation_Date__c' => System.Today()+30,
                            'Support_Awareness_needed__c' => 'Yes'
                            };      
                                POC__c poc1 = (POC__c) ShGl_TestFactory.createSObject(new POC__c(), pocMap);
        poc1.POC_Type__c = 'Standard POC';  
        poc1.Planned_Installation_Date__c = System.Today()+40;
        poc1.Account__c = acct.Id;
        poc1.Opportunity__c = oppty.Id;
        POC__c poc2 = (POC__c) ShGl_TestFactory.createSObject(new POC__c(), pocMap2);     
        poc2.POC_Type__c = 'Standard POC';
        poc2.Planned_Installation_Date__c =  System.Today()+40;
        poc2.Account__c = acct.Id;
        poc2.Opportunity__c = oppty.Id;
        insert new List<POC__c>{poc1,poc2}; 
            
            Map<String, Object>  prodMap = new Map<String, Object> {
                'Name' => 'X-0001-01',
                    'ProductCode' => 'ProductXYZ',
                    'isActive' => true,
                    'Family' => 'POLARIS',
                    'Product_Type__c' => 'Appliance'
                    };            
                        Map<String, Object>  prodMap2 = new Map<String, Object> {
                            'Name' => 'X-0001-01',
                                'ProductCode' => 'ProductXYZ',
                                'isActive' => true,
                                'Family' => 'POLARIS',
                                'Product_Type__c' => 'GPS'
                                };                
                                    Map<String, Object>  prodMap3 = new Map<String, Object> {
                                        'Name' => 'X-0001-01',
                                            'ProductCode' => 'ProductXYZ',
                                            'isActive' => true,
                                            'Family' => 'POLARIS',
                                            'Product_Type__c' => 'RADAR'
                                            };
                                                
                                                Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
        Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3); 
        
        insert new List<Product2>{pd, pd2, pd3};
            
            //Generate SBQQ
            Map<String, Object>  quoteMap = new Map<String, Object> {
                'SBQQ__Account__c' => acct.Id,
                    'SBQQ__Opportunity2__c' => oppty.Id
                    };
                        
                        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppty.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = Test.getStandardPricebookId();
		qt1.SBQQ__Account__c = acct.Id;
        insert qt1;
        
        qt1.ApprovalStatus__c = 'Approved';
        update qt1;
        
        //Generate Lead
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.country = 'USA';
        insert led;
        
        oppty.Deal_Registration_Link__c = led.Id;
        oppty.Partner_Lookup__c = acct.Id; 
        oppty.pricebook2Id = Test.getStandardPricebookId();
        oppty.StageName = System.Label.Order_Creation_Stage;
        oppty.Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Installation_Assigned_To__c = 'Partner Install';
        update oppty;
        
        //Generate Order
        Map<String, Object>  orderMap = new Map<String, Object> {
            'Status' => 'Draft',
                'AccountId' => acct.Id,
                'OpportunityId' => oppty.Id,
                'EffectiveDate' => Date.Today(),
                /*'ship_To_Name__c' => acct.Id,*/
                'Type' => 'Revenue',
                'Est_Ship_Date__c' => system.today(),
                'Order_Status__c' => 'Change Needed',
                'Hold_Code__c' => 'Delayed Ship Date',
                'POC_Request__c' => poc2.id,
                'RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId(),
                'Pricebook2Id' => Test.getStandardPricebookId()
                };
                    Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), orderMap);
        ord.Order_Status__c = 'Pending';
        ord.Hold_Code__c = 'End Customer PO# Missing';
        insert ord;
        
        Order ord1 = [ SELECT Id,Pricebook2Id FROM Order where id = :ord.id LIMIT 1 ];
        ord1.Pricebook2Id = Test.getStandardPricebookId();
        update ord1;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = pd.Id, UnitPrice = 100.00, IsActive = true);
        insert pbEntry;
        
        //insert oritem
        OrderItem oitem1 = new OrderItem(product2Id = pd.id,Support_Start_Date__c =System.today(),Support_End_Date__c  =System.today()+2, orderid = ord.id, Quantity = 2, PricebookEntryId = pbEntry.id, UnitPrice = pbEntry.UnitPrice);
        OrderItem oitem2 = new OrderItem(product2Id = pd.id,Support_Start_Date__c =System.today(),Support_End_Date__c  =System.today()+2, orderid = ord.id, Quantity = 2, PricebookEntryId = pbEntry.id, UnitPrice = pbEntry.UnitPrice);
        insert new List<OrderItem>{oitem1, oitem2};
            
            //Generate Assets
            assetList = (List<Asset>) ShGl_TestFactory.createSObjectList(new Asset(), 6, null);
        for(Asset ast : assetList){
            ast.Order_Service_Item__c = oitem1.Id;
            ast.Accountid = acct.Id;
            ast.Product2id = pd.Id; 
        }
        
        Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        assetObj.AccountId =acct.Id;
        assetObj.Name = 'EntitlementTriggerHelperAsset';
        assetObj.Product2Id = pd.Id;
        assetObj.Eligible_for_Free_HW__c = 'True';
        assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
        assetObj.serial_number__c = 'JAY8486304222k4';
        assetList.add(assetObj);
        insert assetList;
        allowFieldChanges= false;
        allowProductUpgrade = true;
        
        
        
        
        
        
        Test.startTest(); 
        /*
AssetTriggerHelper.setFieldsOnAssetInsert(assetList);

for(Asset ast : assetList){
ast.Order_Service_Item__c = null;
ast.Product2id = null;
}
update assetList;
Map<Id, Asset> oldAssetMap = new Map<Id, Asset>();
for(Asset ast : assetList){  
ast.Order_Service_Item__c = oitem1.Id;
ast.Product2id = pd.Id;
update ast;
oldAssetMap.put(ast.id,ast);
}

AssetTriggerHelper.setFieldsOnAssetUpdate(assetList,oldAssetMap);
AssetTriggerHelper.preventChangeFields(assetList);
//AssetTriggerHelper.testA(); 
*/
        
        AssetTriggerHelper.setFieldsOnAssetInsert(assetList);
        
        Map<Id, Asset> oldAssetMap = new Map<Id, Asset>();
        for(Asset ast : assetList){  
            ast.Order_Service_Item__c = oitem1.Id;
            ast.Product2id = pd.Id;
            update ast;
            oldAssetMap.put(ast.Id, ast);
        }
         AssetTriggerHelper.setFieldsOnAssetUpdate(assetList, oldAssetMap);
       Map<Id, Asset> oldAssetMap2 = new Map<Id, Asset>();
        for(Asset ast : assetList){  
            ast.Order_Service_Item__c = oitem2.Id;
            ast.Product2id = pd.Id;
            ast.Program__c = 'Refreshed';
            ast.UsageEndDate = Date.today();
            update ast;
            oldAssetMap2.put(ast.Id, ast);
        }
         AssetTriggerHelper.setFieldsOnAssetUpdate(assetList, oldAssetMap2);
        
       
        
        AssetTriggerHelper.preventChangeFields(assetList);
        
        for(Asset ast : assetList){  
            ast.Product2id = pd2.Id;
        }
        AssetTriggerHelper.preventChangeFields(assetList, oldAssetMap, null, null);
        AssetTriggerHelper.preventChangeFields(assetList, oldAssetMap2, null, null);
        
        AssetTriggerHelper.allowAssetOIUpdates(true);
        AssetTriggerHelper.allowUpdateAsset(true);
        AssetTriggerHelper.allowSupportStartDateUpdate(true);
        /*AssetTriggerHandler.testCoverage();*/
        Test.stopTest();
    }
}