@isTest
public class QuoteAndOrderStaging_Tests {
  //Creating Test data under setup method
  @testSetup
  public static void setup() {
    SBQQ.TriggerControl.disable();
    ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
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
    Date stDate = Date.newInstance(Date.Today().Year(), Date.Today().Month(), 1);
    //stDate = stDate.addMonths(1);
    Date endDate = stDate.addMonths(1).addDays(-1);
    TriggerControl__c objOrderTrigger = new TriggerControl__c(
      Name = 'Entitlement',
      Disable_Trigger__c = true,
      DisableTrigger__c = true,
      SendEmail__c = false
    );
    insert objOrderTrigger;
    Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
    Map<String, Object> accMap = new Map<String, Object>{ 'RecordtypeId' => accDistiRecTypeId, 'Type' => 'Distributor' };

    List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(), 2, accMap);
    accList[0].name = 'Promark Technology, Inc.';
    accList[1].name = 'Net app, Inc.';
    insert accList;

    //accList[0].Id = '0014000001lPJDXAA4';
    //update accList;

    system.debug('accList' + accList);
    //Generate the Contact
    Map<String, Object> cntMap = new Map<String, Object>{ 'AccountId' => accList[0].Id };
    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
    insert cnt;

    system.debug('### cnt:' + cnt);

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
        Name = 'RS-BT-RCDM-T',
        ProductCode = 'RS-BT-RCDM-T',
        License_Category__c = 'On Prem',
        Category__c = 'Software',
        Product_Level__c = 'OnPrem',
        Family = 'OnPrem',
        SBQQSC__EntitlementConversion__c = 'One per quote line',
        SBQQ__SubscriptionPricing__c = 'Fixed Price',
        SBQQ__SubscriptionTerm__c = 1,
        SBQQ__SubscriptionBase__c = 'List',
        SBQQ__SubscriptionType__c = 'One-time',
        IsActive = true,
        Support_Type__c = 'Premium',
        New_CPQ_Product__c = false,
        GPL_Name__c = 'NetApp'
      ),
      // 1
      new Product2(
        Name = 'RS-BT-EE-PE-PP',
        ProductCode = 'RS-BT-EE-PE-PP',
        Category__c = 'Bundle',
        Family = 'Rubrik Licence',
        Product_Type__c = 'Enterprise Edition',
        License_Category__c = 'SaaS',
        Product_Level__c = 'Hybrid Software',
        SBQQ__AssetAmendmentBehavior__c = 'Default',
        SBQQSC__EntitlementConversion__c = 'One per quote line',
        IsActive = true,
        SBQQ__SubscriptionPricing__c = 'Fixed Price',
        SBQQ__SubscriptionTerm__c = 36,
        SBQQ__SubscriptionBase__c = 'List',
        SBQQ__SubscriptionType__c = 'Renewable'
      )
      //3
    };
    insert sampleProducts;

    Id pricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> entries = new List<PricebookEntry>();

    entries.add(
      new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100)
    );
    entries.add(
      new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200)
    );

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
        SBQQ__Quantity__c = 800,
        SBQQ__SubscriptionPricing__c = 'Fixed Price',
        SBQQ__StartDate__c = stDate,
        SBQQ__EndDate__c = endDate,
        SBQQ__DefaultSubscriptionTerm__c = 12,
        SBQQ__ListPrice__c = 0,
        SBQQ__NetPrice__c = 0
      )
    );

    insert lines;

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
          SELECT
            id,
            SBQQ__NetPrice__c,
            SBQQ__NetTotal__c,
            SBQQ__Product__r.productcode,
            SBQQ__Quantity__c,
            SBQQ__SubscriptionTerm__c,
            SBQQ__Product__c,
            SBQQ__PricebookEntryId__c
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

    System.debug('### OI size:' + lstOrdrItems.size());

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
    system.debug('::ServiceContract::' + objSC.pricebook2Id);
    system.debug('::ServiceContract1::' + objSC);
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
        enddate = date.today().addMonths(1).addDays(-1),
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
        enddate = date.today().addMonths(1).addDays(-1),
        ServiceContractId = objSC.Id,
        ContractLineItemId = lstCli[1].Id,
        Order_Service_Item__c = lstOrdrItems[1].id
      )
    };
    insert lstEntitlement;
  }

  public static testMethod void testQuoteAndOrderStageProcessingMethod() {
    List<Quote_and_Order_Staging__c> quoteAndStagingRecordList = new List<Quote_and_Order_Staging__c>();
    List<Account> accList = [SELECT Id FROM account LIMIT 1];
    Quote_and_Order_Staging__c qorderRecord = new Quote_and_Order_Staging__c(
      Account_OM__c = accList[0].Id,
      Process_Type__c = 'Initial RCDM-T Processing',
      EOL_EndDate__c = system.today().addYears(1),
      Processing_Date__c = system.today().addYears(1)
    );
    quoteAndStagingRecordList.add(qorderRecord);
    Quote_and_Order_Staging__c qorderRecordrecord2 = new Quote_and_Order_Staging__c(
      Account_OM__c = accList[0].Id,
      Process_Type__c = 'Initial RCDM-T Processing',
      EOL_EndDate__c = system.today().addYears(1),
      Processing_Date__c = system.today().addYears(1)
    );
    quoteAndStagingRecordList.add(qorderRecordrecord2);
    Test.StartTest();
    insert qorderRecord;
    try {
      insert qorderRecordrecord2;
    } catch (Exception ex) {
      Boolean expectedExceptionThrown = ex.getMessage().contains('Script-thrown exception') ? true : false;
      System.assertEquals(expectedExceptionThrown, false);
    }

    Test.StopTest();
  }
}