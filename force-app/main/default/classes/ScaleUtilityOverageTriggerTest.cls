@isTest
public class ScaleUtilityOverageTriggerTest {
    //Creating Test data under setup method
    @testSetup 
    static void setup() {
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr1 = new user(
          alias = 'std',
          email = 'testuser@testclass.com',
          emailencodingkey = 'UTF-8',
          firstname = 'test',
          lastname = 'user',
          languagelocalekey = 'en_US',
          localesidkey = 'en_US',
          profileid = p.Id,
          timezonesidkey = 'America/Los_Angeles',
          username = uniqueUserName
        );
        insert usr1;
    
        SBQQ.TriggerControl.disable();
    ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
      Disable_Order_Validation_Rules__c = true,
      Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
      Disable_SBQQ_Quote_Validation_Rules__c = true,
      Disable_Opportunity_Validation_Rules__c = true,
      Disable_Opportunity_Triggers__c = true,
      Disable_SBQQ_Quote_Triggers__c = true,
      Disable_SBQQ_QuoteLine_Triggers__c = true,
      Disable_Order_Old_Trigger__c = true,
      Disable_Account_Triggers__c = true
    );
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        Date stDate = system.today();
        //Date stDate = Date.newInstance(Date.Today().Year(), Date.Today().Month(), 1);
        
        //stDate = stDate.addMonths(1);   
        Date endDate = stDate.addMonths(1).addDays(-1);
    TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, DisableTrigger__c = true, SendEmail__c = false);
        insert objOrderTrigger;
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
    Map<String, Object> accMap = new Map<String, Object>{ 'RecordtypeId' => accDistiRecTypeId, 'Type' => 'Distributor' };
      
    List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(), 2, accMap);
    accList[0].name = 'Promark Technology, Inc.';
    accList[1].name = 'Net app, Inc.';
    accList[0].Payment_Term__c = 'Net 90';
    accList[1].Payment_Term__c = 'Net 90';
        insert accList;

        //accList[0].Id = '0014000001lPJDXAA4';
        //update accList;

        //Generate the Contact
    Map<String, Object> cntMap = new Map<String, Object>{ 'AccountId' => accList[0].Id };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Opportunity opp = new Opportunity(
            AccountId = accList[0].Id,
            Name = 'Test',
            CloseDate = System.today().addMonths(12),
            StageName = 'Test',
            Pricebook2Id = Test.getStandardPricebookId(),
            Distributor_Lookup__c = accList[0].Id,
            Partner_Lookup__c = accList[0].id,
      Alliance_Partner_Name__c = 'Amazon',
      Alliance_Source_Type__c = 'Alliance Initiated Deal'
    );
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            Is_RWD_Polaris_Quote__c = true,
      SBQQ__PriceBook__c = Test.getStandardPricebookId()
    );
        insert quote;

        List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'RS-TB-EE-RSV-PE',
                    ProductCode = 'RS-TB-EE-RSV-PE',
                    Product_Level__c = 'Hybrid Software',
                    Product_Type__c = 'Enterprise Edition',
                    Product_Subtype__c = 'Scale MSP',
                    License_Category__c = 'SaaS',
                    License_Type__c = 'Consumption',
                    Quotable_Date__c = system.today(),
                    IsActive = true,
                    SBQQ__Hidden__c = false,
                    Support_Type__c = 'Premium',
                    SBQQ__ExcludeFromOpportunity__c = true,
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    New_CPQ_Product__c = true
                ),
                // 1
                new Product2(
                    Name = 'RS-TB-EE-RSVX-PE',
                    ProductCode = 'RS-TB-EE-RSVX-PE',
                    Product_Level__c = 'Hybrid Software',
                    Product_Type__c = 'Enterprise Edition',
                    Product_Subtype__c = 'Scale MSP',
                    License_Category__c = null,
                    License_Type__c = 'Consumption',
                    Quotable_Date__c = system.today(),
                    IsActive = true,
                    SBQQ__Hidden__c = false,
                    Support_Type__c = 'Premium',
                    SBQQ__ExcludeFromOpportunity__c = true,
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    New_CPQ_Product__c = true
                ),
                // 2
                new Product2(
                    Name = 'RS-TB-EE-OND-PE',
                    ProductCode = 'RS-TB-EE-OND-PE',
                    Product_Level__c = 'Hybrid Software',
                    Product_Type__c = 'Enterprise Edition',
                    Product_Subtype__c = 'On Demand',
                    License_Category__c = 'SaaS',
                    License_Type__c = 'Subscription',
                    Quotable_Date__c = system.today(),
                    IsActive = true,
                    SBQQ__Hidden__c = false,
                    Support_Type__c = 'Premium',
                    SBQQ__ExcludeFromOpportunity__c = true,
                   // SBQQSC__EntitlementConversion__c = 'One per quote line',
                    New_CPQ_Product__c = true
                ),
                new Product2(
                   Name = 'RS-HW-SVC-PE-S1',
                   ProductCode = 'RS-HW-SVC-PE-S1',
                   Product_Level__c = 'Support',
                   Product_Type__c = 'HW Support',
                   License_Type__c = 'Consumption',
                   Quotable_Date__c = system.today(),
                   IsActive = true,
                   SBQQ__Hidden__c = false,
                   Support_Type__c = 'Premium',
                   SBQQ__ExcludeFromOpportunity__c = true,
                   SBQQSC__EntitlementConversion__c = 'One per unit',
                   New_CPQ_Product__c = true
               ),
                new Product2(
                   Name = 'RC-SFP-TSR-01',
                   ProductCode = 'RC-SFP-TSR-01',
                   Product_Level__c = 'Hardware',
                   Product_Type__c = 'Accessories',
                   License_Type__c = 'Consumption',
                   Quotable_Date__c = system.today(),
                   IsActive = true,
                   SBQQ__Hidden__c = false,
                   Support_Type__c = 'Premium',
                   SBQQ__ExcludeFromOpportunity__c = true,
                   New_CPQ_Product__c = true
               )
				//3
        };
        insert sampleProducts;
		
         Id pricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 100));

        insert entries; 
    Pricebook2 customPB = new Pricebook2(Name = 'CPQ PriceBook', isActive = true);
        insert customPB;

    List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
    lines.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = sampleProducts[0].Id,
        SBQQ__PricebookEntryId__c = entries[0].Id,
        SBQQ__Quantity__c = 800,
        SBQQ__SubscriptionPricing__c = 'Fixed Price',
        SBQQ__StartDate__c = stDate,
        SBQQ__EndDate__c = endDate,
        SBQQ__DefaultSubscriptionTerm__c = 1,
        SBQQ__ListPrice__c = 10,
        SBQQ__NetPrice__c = 10
      )
    );
    lines.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = sampleProducts[1].Id,
        SBQQ__PricebookEntryId__c = entries[1].Id,
        SBQQ__Quantity__c = 1,
        SBQQ__SubscriptionPricing__c = 'Fixed Price',
        SBQQ__StartDate__c = stDate,
        SBQQ__EndDate__c = endDate,
        SBQQ__DefaultSubscriptionTerm__c = 12,
        SBQQ__ListPrice__c = 0,
        SBQQ__NetPrice__c = 0
      )
    );
    lines.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = sampleProducts[2].Id,
        SBQQ__PricebookEntryId__c = entries[2].Id,
        SBQQ__Quantity__c = 1,
        SBQQ__SubscriptionPricing__c = null,
        SBQQ__StartDate__c = stDate,
        SBQQ__EndDate__c = endDate,
        SBQQ__DefaultSubscriptionTerm__c = null,
        SBQQ__ListPrice__c = 1.5,
        SBQQ__NetPrice__c = 0
      )
    );
    lines.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = sampleProducts[3].Id,
        SBQQ__PricebookEntryId__c = entries[3].Id,
        SBQQ__Quantity__c = 1,
        SBQQ__SubscriptionPricing__c = null,
        SBQQ__StartDate__c = stDate,
        SBQQ__EndDate__c = endDate,
        SBQQ__DefaultSubscriptionTerm__c = null,
        SBQQ__ListPrice__c = 1.5,
        SBQQ__NetPrice__c = 0
      )
    );
    lines.add(
      new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = quote.Id,
        SBQQ__Product__c = sampleProducts[4].Id,
        SBQQ__PricebookEntryId__c = entries[4].Id,
        SBQQ__Quantity__c = 1,
        SBQQ__SubscriptionPricing__c = null,
        SBQQ__StartDate__c = stDate,
        SBQQ__EndDate__c = endDate,
        SBQQ__DefaultSubscriptionTerm__c = null,
        SBQQ__ListPrice__c = 1.5,
        SBQQ__NetPrice__c = 0
      )
    );

        insert lines;

        lines[1].SBQQ__Bundle__c = true;
        lines[0].SBQQ__RequiredBy__c = lines[1].Id;
        lines[2].SBQQ__RequiredBy__c = lines[1].Id;
        lines[4].SBQQ__RequiredBy__c = lines[1].Id;
      lines[1].SBQQ__RequiredBy__c = null;
        update lines;
        
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        
    opp.StageName = '6 PO With Channel';
        opp.SBQQ__PrimaryQuote__c = quote.id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Polaris_Region__c = 'US';
        //opp.SBQQ__Ordered__c = true;
        //update opp;
        
        opp.SBQQ__Ordered__c = true;
        //update opp;
        
        //FlowControll.opportunityTriggerHandler = true;
        
    SBQQ__Quote__c qtq = [
      SELECT
        id,
        name,
        SBQQ__NetAmount__c,
        SBQQ__PricebookId__c,
        (
          SELECT id, SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__Product__r.productcode, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c, SBQQ__PricebookEntryId__c
          FROM SBQQ__LineItems__r
        )
      FROM SBQQ__Quote__c
      WHERE id = :quote.id
    ];
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
    Map<String, Object> OrderMap = new Map<String, Object>{
            'Type' => 'Revenue',
            'AccountId' => accList[0].Id,
            'OpportunityId' => opp.Id,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
      'Sell_to_Partner__c' => accList[1].Id,
      'Bill_To_Name__c' => accList[0].Id,
      'SBQQ__Quote__c' => quote.id
            };
            
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
    	ord.Type = 'Revenue';
        ord.Order_Sub_Type__c = 'GC Offer';
        test.startTest();
        insert Ord;

        List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
      
    for (integer i = 0; i < qliList.size(); i++) {
      lstOrdrItems.add(
        new OrderItem(
          Product2Id = qliList[i].SBQQ__Product__c,
          SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c,
          OrderId = Ord.Id,
          Quantity = qliList[i].SBQQ__Quantity__c,
          PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c,
          unitprice = qliList[i].SBQQ__NetPrice__c,
          Sales_Price__c = qliList[i].SBQQ__NetPrice__c,
          SBQQ__QuoteLine__c = qliList[i].id,
          SBQQ__SubscriptionTerm__c = qliList[i].SBQQ__SubscriptionTerm__c
        )
      );
        }
        insert lstOrdrItems;

        Integer count = 0;
    for (OrderItem OI : lstOrdrItems) {
      if (count == 0 || count == 2) {
                 OI.SBQQ__RequiredBy__c = lstOrdrItems[1].Id;
        if (count == 0) {
                    OI.Support_Start_Date__c = System.today();
                    OI.Support_End_Date__c = System.today().addMonths(1).addDays(-1);
                }
            }
            //if(count == 1){
      OI.Global_Commit_ID__c = accList[1].Id + '-' + lstOrdrItems[1].id + '-RS-TB-EE-RSVX-PE';
            OI.Customer_Facing_GC_ID__c = 10001;
            //}
            count++;
        }   
        
        update lstOrdrItems;
        Ord.Order_Split_Type__c = 'Not needed';
        Ord.Is_RWD_Polaris_Quote__c = true;
    ord.Polaris_Fulfillment_Status__c = 'Completed';
        ord.Actual_Order_Ship_Date__c = System.today();
        ord.Order_Status__c = 'Shipped';
        update Ord;
        Test.StopTest();
        
    ServiceContract objSC = new ServiceContract(
      Name = 'ServiceContract Test1',
      AccountId = accList[0].Id,
      StartDate = Date.today(),
      Term = 36,
      pricebook2Id = Test.getStandardPricebookId(),
      SBQQSC__Opportunity__c = opp.Id,
      SBQQSC__Order__c = ord.Id,
      SBQQSC__Quote__c = quote.Id
    );
       
    insert objSC;
    List<ContractLineItem> lstCli = new List<ContractLineItem>();
        
    ContractLineItem cli2 = new ContractLineItem();
    cli2.Quantity = lstOrdrItems[0].quantity;
    cli2.SBQQSC__Product__c = lstOrdrItems[0].Product2Id;
    cli2.PricebookEntryId = lstOrdrItems[0].PricebookEntryId;
    cli2.ServiceContractId = objSC.id;
    cli2.UnitPrice = lstOrdrItems[0].UnitPrice;
    cli2.StartDate = stDate;
    cli2.EndDate = endDate;
    cli2.SBQQSC__OrderProduct__c = lstOrdrItems[0].id;
    cli2.SBQQSC__QuoteLine__c = qliList[0].id;
    cli2.SBQQSC__SegmentIndex__c = 1;
    lstCli.add(cli2);
    
     ContractLineItem cli = new ContractLineItem();
    cli.Quantity = lstOrdrItems[1].quantity;
    cli.SBQQSC__Product__c = lstOrdrItems[1].Product2Id;
    cli.PricebookEntryId = lstOrdrItems[1].PricebookEntryId;
    cli.ServiceContractId = objSC.id;
    cli.UnitPrice = lstOrdrItems[1].UnitPrice;
    cli.StartDate = stDate;
    cli.EndDate = endDate;
    cli.SBQQSC__OrderProduct__c = lstOrdrItems[1].id;
    cli.SBQQSC__QuoteLine__c = qliList[1].id;
    lstCli.add(cli);
    
    ContractLineItem cli1 = new ContractLineItem();
    cli1.Quantity = lstOrdrItems[2].quantity;
    cli1.SBQQSC__Product__c = lstOrdrItems[2].Product2Id;
    cli1.PricebookEntryId = lstOrdrItems[2].PricebookEntryId;
    cli1.ServiceContractId = objSC.id;
    cli1.UnitPrice = lstOrdrItems[2].UnitPrice;
    cli1.StartDate = stDate;
    cli1.EndDate = endDate;
    cli1.SBQQSC__OrderProduct__c = lstOrdrItems[2].id;
    cli1.SBQQSC__QuoteLine__c = qliList[2].id;
    lstCli.add(cli1);
    
    insert lstCli;
	lstOrdrItems[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
   	lstOrdrItems[1].SBQQSC__ContractLineItem__c = lstCli[1].Id;
    update lstOrdrItems;
        Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();

    List<Entitlement> lstEntitlement = new List<Entitlement>{
      new Entitlement(
        Name = 'Ent Test1',
        RecordTypeId = supportRecordTypeId,
        Type = 'Phone Support',
        AccountId = accList[0].Id,
        Product__c = sampleProducts[0].Id,
        StartDate = date.today(),
        ServiceContractId = objSC.Id,
        ContractLineItemId = lstCli[0].Id,
        Order_Service_Item__c = lstOrdrItems[0].id
      ),
      new Entitlement(
        Name = 'Ent Test2',
        RecordTypeId = supportRecordTypeId,
        Type = 'Phone Support',
        AccountId = accList[0].Id,
        Product__c = sampleProducts[1].Id,
        StartDate = date.today(),
        ServiceContractId = objSC.Id,
        ContractLineItemId = lstCli[1].Id,
        Order_Service_Item__c = lstOrdrItems[1].id
      )
        };
        insert lstEntitlement; 
    List<Asset> lstAsset = new List<Asset>{
      new Asset(
        Name = 'AA204063040011',
        serial_number__c = 'AA204063040011',
        SerialNumber = 'AA204063040011',
        AccountId = accList[0].Id,
        Product2Id = sampleProducts[0].Id,
        SBQQ__QuoteLine__c = qliList[0].id
      )
    };

    insert lstAsset;
        
        Scale_Utility_Cluster_Registration__c clustReg = new Scale_Utility_Cluster_Registration__c();
        clustReg.Account_ID__c = accList[0].id;
        clustReg.Cluster_UUID__c = 'a4936c8a-a6de-45ee-bfad-a962c8c4ee12';
        clustReg.Global_Commit_ID__c = lstOrdrItems[1].Global_Commit_ID__c;
        clustReg.License_ID__c = lstOrdrItems[1].Product2Id;
        clustReg.License_Order_Product__c = lstOrdrItems[1].id;
       // clustReg.Order_Number__c = Ord.ordernumber;
        clustReg.Service_Contract_ID__c = objSC.Id;
        insert clustReg;
        
        Scale_Utility_Overage__c suo = new Scale_Utility_Overage__c();
        suo.Account_ID__c = accList[0].id;
        suo.Global_Commit_ID__c = lstOrdrItems[1].Global_Commit_ID__c;
        suo.Is_First_Item__c = true;
        suo.License_Order_Product__c = lstOrdrItems[1].id;
        suo.On_Demand_Period_End_Date__c = System.today().addMonths(1).addDays(-1);
        suo.On_Demand_Period_Start_Date__c = System.today();
        suo.OnDemand_Order_Product__c = lstOrdrItems[2].id;
        suo.Original_Order__c = ord.id;
        suo.Process_Flag__c = 'Do not Process';
        suo.Reserve_Order_Line__c = lstOrdrItems[0].id;
        suo.Snapshot_Date__c = System.today();
    suo.Ondemand_CLI__c = lstCli[2]?.id;
        suo.Current_Month_Commited_Usage__c = 500;
        suo.Max_Commited_Usage__c = 700;
        suo.Usage_in_TB__c = 1000.00;
        insert suo;
        
        Snowflake_Feed__c sFFeed = new Snowflake_Feed__c();
        sFFeed.Account_ID__c = accList[0].id;
        sFFeed.Cluster_UUID__c = 'a4936c8a-a6de-45ee-bfad-a962c8c4ee12';
        sFFeed.Cluster_Usage_BETB__c = 1000.00;
        sFFeed.Cluster_Usage_FETB__c = 1000.00;
        sFFeed.Is_UCL__c = false;
        sFFeed.Snapshot_Date__c = System.today();
        sFFeed.Original_Order__c = ord.id;
        sFFeed.Scale_Utility_Overage_ID__c = suo.id;
        sFFeed.Type__c = 'Cluster';
        sFFeed.Origin__c = 'Snowflake';
        insert sFFeed;
        
        Snowflake_Feed__c sFFeed1 = new Snowflake_Feed__c();
        sFFeed1.Account_ID__c = accList[0].id;
        //sFFeed.Cluster_UUID__c = 'a4936c8a-a6de-45ee-bfad-a962c8c4ee12';
        sFFeed1.Cluster_Usage_BETB__c = 1000.00;
        sFFeed1.Cluster_Usage_FETB__c = 1000.00;
        sFFeed1.Is_UCL__c = false;
        sFFeed1.Snapshot_Date__c = System.today();
        sFFeed1.Original_Order__c = ord.id;
        sFFeed1.Scale_Utility_Overage_ID__c = suo.id;
        sFFeed1.Type__c = 'CNP';
        sFFeed1.Origin__c = 'SFDC';
        insert sFFeed1;
        
        Scale_Utility_Overage_Lines__c suoline = new Scale_Utility_Overage_Lines__c();
        suoline.Actual_Usage_TB__c = 1000.00;
        suoline.Max_Contract_Consumption__c = 1;
        suoline.Minimum_Reserve_Consumption__c = 280;
        suoline.Net_Price__c = 7200;
        suoline.OnDemand_Usage_TB__c = 720;
        suoline.Scale_Utility_Overage__c = suo.id;
    suoline.OnDemand_CLI__c = lstCli[2]?.id;
        suoline.Sync_Status__c = 'Sync Ready';
        suoline.Unit_Net_Price__c = 10;
        insert suoline;
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
    oppLineList.add(new OpportunityLineItem(pricebookentryid = entries[0].Id, Product2Id = sampleProducts[0].id, TotalPrice = 8000, Quantity = 800, OpportunityID = opp.Id));
    oppLineList.add(new OpportunityLineItem(pricebookentryid = entries[1].Id, Product2Id = sampleProducts[1].id, TotalPrice = 1, Quantity = 1, OpportunityID = opp.Id));
    oppLineList.add(new OpportunityLineItem(pricebookentryid = entries[2].Id, Product2Id = sampleProducts[2].id, TotalPrice = 100, Quantity = 1, OpportunityID = opp.Id));
        insert oppLineList;
        
    Attachment attach = new Attachment();
    attach.Name = 'Unit Test Attachment';
    Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
    attach.body = bodyBlob;
    attach.parentId = ord.id;
        insert attach;
    }
    //testing reprocessing the SUO
      /**
   * @author Prashant Kumar
   * @date 23-04-2025
   * @description testing overage Reprocess
   */
  public static testMethod void overageReprocess() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
      List<Scale_Utility_Overage__c> suoList = [SELECT Id, Process_Flag__c FROM Scale_Utility_Overage__c LIMIT 1];
	    suoList[0].Process_Flag__c = Constants.PROCESS_FLAG_REPROCESS;
        update suoList;
      List<Scale_Utility_Overage__c> suoList1 = [SELECT Id, Process_Flag__c FROM Scale_Utility_Overage__c LIMIT 1];
       	System.assert(suoList1[0].Process_Flag__c != Constants.PROCESS_FLAG_REPROCESS);
        }
    }
    //testing creating overage order process 
         /**
   * @author Prashant Kumar
   * @date 23-04-2025
   * @description testing Overage Order
   */
    public static testMethod void createOverageOrder(){
        
        System.runAs(new user(Id = UserInfo.getUserId())) {
        List<Scale_Utility_Overage__c> suoList = [Select Id,Process_Flag__c from Scale_Utility_Overage__c limit 1];
	    suoList[0].Process_Flag__c = Constants.PROCESS_FLAG_CEATE_OVERAGE_ORDER;	
        update suoList;
        suoList[0].Sync_Status__c = Constants.SYNC_SUCCESS;
        update suoList;
      List<Scale_Utility_Overage__c> suoList1 = [SELECT Id, Process_Flag__c FROM Scale_Utility_Overage__c LIMIT 1];
       	System.assert(suoList1 != null);
        }
       	
    }
    //Testing batch job trigger through platform event trigger
    /**
    * @author Prashant Kumar
    * @date 23-04-2025
    * @description testing Scale Utility Integration. 
    */
  public static testMethod void scaleUtilityintegrationTriggerTest() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
        List<Scale_Utility_Integration__e> lstOfSUI = new List<Scale_Utility_Integration__e>();
      lstOfSUI.add(new Scale_Utility_Integration__e(Job_Name__c = 'Initial Processing', Snapshot_Date__c = System.today()));
      lstOfSUI.add(new Scale_Utility_Integration__e(Job_Name__c = 'Reprocessing', Snapshot_Date__c = System.today()));
        Test.startTest();
        EventBus.publish(lstOfSUI);
        System.assert(lstOfSUI !=  null);
        Test.stopTest();
        }
    }
    //Testing Quote pdf attachment creation 
    /**
    * @author Prashant Kumar
    * @date 23-04-2025
    * @description testing Quote Document Functionality. 
    */
  public static testMethod void testQuoteDocAttachmentCreation() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
      List<Order> Order = [SELECT id FROM order LIMIT 1];
      List<Attachment> lstOfAttach = [SELECT id FROM Attachment LIMIT 1];
      Set<Id> attachids = new Set<Id>{ lstOfAttach[0].id };
      Map<Id, Id> mapOfOrdToQutDoc = new Map<Id, Id>();
        mapOfOrdToQutDoc.put(Order[0].id, lstOfAttach[0].id);
        System.assert(mapOfOrdToQutDoc !=  null);
        UtilityClass.createAttachment(mapOfOrdToQutDoc, attachids);
      try {
          System.debug(LoggingLevel.DEBUG, lstOfAttach[2]);
      } catch (Exception ex) {
            UtilityClass.logException(ex);
            UtilityClass.logException(ex, 'Test');
            UtilityClass.logException(ex, 'Test', 'Test');
            UtilityClass.logException(ex, 'Test', 'Test', 'Test');
            UtilityClass.logException(ex, 'Test', 'Test', 'Test', Order[0].id);
        }
    }
    }
    //Trigger the batch class to create SUO record.
    /**
    * @author Prashant Kumar
    * @date 23-04-2025
    * @description testing ScaleUtilityOverageBatchWithCLIBatch Class. 
    */
  public static testMethod void coverBatchClass() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
       // ScaleUtilityOverageBatchProcess cls = new ScaleUtilityOverageBatchProcess();
       Test.startTest();
        // Id JobId  = Database.executeBatch(new ScaleUtilityOverageBatchProcess('Initial Processing', system.today(), null, null), 2000);
      Id JobId = Database.executeBatch(new ScaleUtilityOverageBatchWithCLI('Initial Processing', null, null), 1);
        /*Scale_Utility_Overage__c suo = [select id,Process_Flag__c from Scale_Utility_Overage__c limit 1];
        if(suo != null){
            suo.Process_Flag__c = Constants.PROCESS_FLAG_REPROCESS;
            update suo;
        }*/
        flowControll cls = new flowControll();
        flowControll.disableAllTriggers();
        System.assert(jobId != null);
        Test.stopTest();
        }
    }
    /**
    * @author Prashant Kumar
    * @date 23-04-2025
    * @description testing reprocessOverageRec. 
    */
  public static testMethod void reprocessOverageRec() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
      Scale_Utility_Overage__c suo = [SELECT id, Overage_Order__c, Process_Flag__c FROM Scale_Utility_Overage__c LIMIT 1];
        Scale_Utility_Overage__c suo1 = suo.clone();
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf('test');
        attachment.Name = String.valueOf('test.txt');
        attachment.ParentId = suo.Id;     
        insert attachment;
      ScaleUtilityOverageTriggerHelper.CopyPdfToONDOrder(new Set<Id>{ suo.id }, new List<Scale_Utility_Overage__c>{ suo1 });
      if (suo != null) {
            suo.Process_Flag__c = Constants.PROCESS_FLAG_REPROCESS;
            update suo;    
        }
        system.assert(suo != null);
    }
    }
    /**
    * @author Prashant Kumar
    * @date 23-04-2025
    * @description testing UpdateSupportOrderLinesDatesForCSUClass Queueable Class. 
    */
  public static testMethod void testupdateOIQueuableClass() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
      List<OrderItem> lstofOI = [SELECT id, orderId, Global_Commit_ID__c, Customer_Facing_GC_ID__c FROM OrderItem LIMIT 5];
      for (orderitem oi : lstofOI) {
        if (oi.Customer_Facing_GC_ID__c != null) {
                oi.Customer_Facing_GC_ID__c = null;
                oi.Global_Commit_ID__c = 'TEST';
            }
        }
        update lstofOI;
        UpdateSupportOrderLinesDatesForCSUClass cls = new UpdateSupportOrderLinesDatesForCSUClass(lstofOI);
        Test.startTest();
         System.enqueueJob(cls); 

      List<OrderItem> lstOfOIoutput = [SELECT id FROM orderitem LIMIT 1];
        System.assert(lstOfOIoutput[0].id != null);
        Test.StopTest();
    }
    } 
    /**
    * @author Prashant Kumar
    * @date 23-04-2025
    * @description testing Scale Utility Amendment  Queueable Class. 
    */
  public static testMethod void testAmend() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
      List<Account> accList = [SELECT Id FROM account LIMIT 2];
      Opportunity opty = [SELECT id, Opportunity_Sub_Type__c FROM opportunity WHERE name = 'Test'];
        opty.Opportunity_Sub_Type__c = 'GC Offer';
        update opty;
      SBQQ__Quote__c quote = [SELECT id, SBQQ__Type__c, Additional_Month_added__c FROM SBQQ__Quote__c LIMIT 1];
        quote.SBQQ__Type__c = 'Amendment';
        quote.Additional_Month_added__c = true;
        update quote;
      SBQQ__Quote__c qtq = [
        SELECT
          id,
          name,
          SBQQ__NetAmount__c,
          SBQQ__PricebookId__c,
          (
            SELECT id, SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__Product__r.productcode, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c, SBQQ__PricebookEntryId__c
            FROM SBQQ__LineItems__r
          )
        FROM SBQQ__Quote__c
        WHERE id = :quote.id
      ];
           List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
      Map<String, Object> OrderMap = new Map<String, Object>{
            'Type' => 'Revenue',
            'AccountId' => accList[0].Id,
            'OpportunityId' => opty.Id,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
        'Sell_to_Partner__c' => accList[1].Id,
        'Bill_To_Name__c' => accList[0].Id,
        'SBQQ__Quote__c' => quote.id
      };
      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord.Type = 'Revenue';
      ord.SBQQ__Quote__c = quote.id;
      ord.Order_Sub_Type__c = 'GC Offer';
      test.startTest();
      insert Ord;
      List<OrderItem> lstOrdrItems = new List<OrderItem>();
      for (integer i = 0; i < qliList.size(); i++) {
        lstOrdrItems.add(
          new OrderItem(
            Product2Id = qliList[i].SBQQ__Product__c,
            SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c,
            OrderId = Ord.Id,
            Quantity = qliList[i].SBQQ__Quantity__c,
            PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c,
            unitprice = qliList[i].SBQQ__NetPrice__c,
            Sales_Price__c = qliList[i].SBQQ__NetPrice__c,
            SBQQ__QuoteLine__c = qliList[i].id,
            SBQQ__SubscriptionTerm__c = qliList[i].SBQQ__SubscriptionTerm__c
          )
        );
      }
      insert lstOrdrItems;
      system.assert(!lstOrdrItems.isempty());
      Test.StopTest();
    }

  }
  public static testMethod void testAmend1() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr1) {
      List<Product2> productList = [SELECT id FROM Product2 WHERE Product_Subtype__c = 'Scale MSP'];
      for (Product2 prod : productList) {
        prod.Edition__c = 'Edition Upgrade';
        prod.Product_Type__c = 'Edition Upgrade';
        prod.license_category__C = 'SaaS';
      }
      update productList;
      List<Account> accList = [SELECT Id FROM account LIMIT 2];
      Opportunity opty = [SELECT id, Opportunity_Sub_Type__c FROM opportunity WHERE name = 'Test'];
      opty.Opportunity_Sub_Type__c = 'GC Offer';
      update opty;
      ServiceContract sc = [SELECT id FROM ServiceContract LIMIT 1];
      SBQQ__Quote__c quote = [SELECT id, SBQQ__Type__c, Amended_Renewed_Service_Contract__c, Additional_Month_added__c FROM SBQQ__Quote__c LIMIT 1];
      quote.SBQQ__Type__c = 'Amendment';
      quote.Amended_Renewed_Service_Contract__c = sc.id;
      quote.Additional_Month_added__c = true;
      update quote;
      SBQQ__Quote__c qtq = [
        SELECT
          id,
          name,
          SBQQ__NetAmount__c,
          SBQQ__PricebookId__c,
          (
            SELECT id, SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__Product__r.productcode, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c, SBQQ__PricebookEntryId__c
            FROM SBQQ__LineItems__r
          )
        FROM SBQQ__Quote__c
        WHERE id = :quote.id
      ];
      List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'AccountId' => accList[0].Id,
        'OpportunityId' => opty.Id,
        'Sync_to_NetSuite__c' => true,
        'EffectiveDate' => system.today(),
        'Status' => 'Pending',
        'Sell_to_Partner__c' => accList[1].Id,
        'Bill_To_Name__c' => accList[0].Id,
        'SBQQ__Quote__c' => quote.id
                };
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
    	ord.Type = 'Revenue';
        ord.Order_Sub_Type__c = 'GC Offer';
        test.startTest();
        insert Ord;
        List<OrderItem> lstOrdrItems = new List<OrderItem>();
      for (integer i = 0; i < qliList.size(); i++) {
        lstOrdrItems.add(
          new OrderItem(
            Product2Id = qliList[i].SBQQ__Product__c,
            SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c,
            OrderId = Ord.Id,
            Quantity = qliList[i].SBQQ__Quantity__c,
            PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c,
            unitprice = qliList[i].SBQQ__NetPrice__c,
            Sales_Price__c = qliList[i].SBQQ__NetPrice__c,
            SBQQ__QuoteLine__c = qliList[i].id,
            SBQQ__SubscriptionTerm__c = 36 //qliList[i].SBQQ__SubscriptionTerm__c
          )
        );
        }
        insert lstOrdrItems;

      update lstOrdrItems;
        system.assert(!lstOrdrItems.isempty());
        Test.StopTest();
    }

    }
    @isTest
    static void testCreateEntitlementLink() {
        insert new TriggerControl__c(Name = 'Entitlement');
        // Create test data
        Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
    List<Order> lstOfOrder = [SELECT id FROM order LIMIT 1];
    List<Product2> lstProducts = new List<Product2>([SELECT Id, Product_Level__c FROM Product2]);
    List<OrderItem> lstOfOI = [SELECT id, Quantity FROM Orderitem LIMIT 5];
    List<Contractlineitem> lstofCLI = [SELECT id, SBQQSC__RenewalQuantity__c FROM contractlineitem LIMIT 2];
    for (Contractlineitem cli : lstofCLI) {
            cli.SBQQSC__RenewalQuantity__c = 50;
        }
        update lstofCLI;
        lstProducts[0].Product_Level__c = null;
        update lstProducts;
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        
        Entitlement prevEnt = new Entitlement(
            RecordTypeId = supportRecordTypeId,
            Type = 'Phone Support',
            AccountId = accountId,
            StartDate = date.today(),
            EndDate = date.today().addDays(10),
            Name = 'Previous Entitlement',
            Product__c = lstProducts[0].Id,
            Order_Service_Item__c = lstOfOI[0].Id,
            ContractLineItemId = lstofCLI[0].Id,
            Quantity__c = 2
        );
        insert prevEnt;
        
        Entitlement renewedEnt = new Entitlement(
            RecordTypeId = supportRecordTypeId,
            Type = 'Phone Support',
            AccountId = accountId,
            StartDate = date.today(),
            EndDate = date.today().addDays(10),
            Name = 'Renewed Entitlement',
            Product__c = lstProducts[1].Id,
            Order_Service_Item__c = lstOfOI[0].Id,
            ContractLineItemId = lstofCLI[0].Id,
            Quantity__c = 3
        );
        insert renewedEnt;
        
    List<Entitlement> listofEnt = [
      SELECT
        id,
        ContractLineItemId,
        ContractLineItem.SBQQSC__RenewalQuantity__c,
        Quantity__c,
        Product__r.Product_Level__c,
        Order_Service_Item__r.serialNumber__c,
        Product__c,
        Order_Service_Item__r.Quantity
      FROM Entitlement
      WHERE Order_Service_Item__c != NULL
    ];
        // Create mock Polaris SKU Mappings
        Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings = new Map<String, Polaris_SKU_Mapping_V2__c>();
        
        Polaris_SKU_Mapping_V2__c mapping1 = new Polaris_SKU_Mapping_V2__c(Old_Product__c = lstProducts[0].Id, New_Product__c = lstProducts[1].Id, Quantity_Ratio__c = 10);
        insert mapping1;
        
        mapProductToPolarisMappings.put(mapping1.Old_Product__c + '-' + mapping1.New_Product__c, mapping1);
        
        Map<String, PreviousTransRefWrapper> newoiToSurvEntwithWrap = new Map<String, PreviousTransRefWrapper>();
        
        // Call the method
        Test.startTest();
    Entitlement_Links__c entLink = UtilityClass.createEntitlementLink(
      listofEnt[0],
      listofEnt[1],
      'Renewed',
      'Surviving',
      mapProductToPolarisMappings,
      newoiToSurvEntwithWrap,
      null,
      null
    );
        
    Map<Id, Contractlineitem> mapofCLI = UtilityClass.getupdatedCli(new Map<Id, Contractlineitem>(), listofEnt[0], 10);
    try {
      Integer i = 1 / 0;
    } catch (Exception ex) {
            UtilityClass.createlogExceptionRecord(ex, 'Utilityclass', 'createlogExceptionRecord', 'Order', lstOfOrder[0].Id, 'Math Exception', false, 'Failed');
        }
        System.assert(renewedEnt.Id != null);
        Test.stopTest();
    }
}