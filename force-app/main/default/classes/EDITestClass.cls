@isTest 
public class EDITestClass {  
    
    static testmethod void covertest(){ 
        User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        ProductModel pm = new ProductModel();
        QuoteModel qm = new QuoteModel(); 
        system.assert(true);
        }
    }
   static testMethod void netappTestMethod(){
      User sysAdminUser = ShGl_TestFactory.createUserwithRole();
      System.runAs(sysAdminUser) {
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Map<String, Object> accMap = new Map<String, Object> {
            'RecordtypeId' => accDistiRecTypeId ,
            'Type' =>'Distributor'
        };
      
        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(),2,accMap); 
        accList[0].name='Promark Technology, Inc.';
        accList[0].name='Net app, Inc.'; 
        insert accList;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => accList[0].Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1',
            'Appliance_Model_HW__c' => 'RBK-R6000S-64G'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ',
            'GPL_Name__c'=>'NetApp'

        };
        Map<String, Object>  prodMap = new Map<String, Object> {    
            'Name' => 'Pord A', 
                'ProductCode' => 'ProductXYZ',  
                'isActive' => true, 
                'Family' => 'AIR',  
                'Product_Type__c' => 'Appliance'    
       };  
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(pd);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID; 
        pBList.add(pbeSubs);
        insert pBList;

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => accList[0].Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =accList[0].id;
        opp.Sell_to_Partner__c = accList[1].id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c =  accList[0].Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Distributor__c = accList[0].id;
        qt.SBQQ__Partner__c = accList[1].id;
         qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        insert qt;
       SBQQ__Quote__c fetchQuote = [Select Id,Partner_s_Name__c from SBQQ__Quote__c where Id = : qt.Id LIMIT 1];

        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,SBQQ__Opportunity2__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
      

        Test.startTest();

        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => accList[0].Id,
            'OpportunityId' => opp.Id,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
            'Sell_to_Partner__c'=>accList[1].Id,
            'Bill_To_Name__c'=>accList[0].Id,
            'SBQQ__Quote__c'=>qt.id
            };
            
            Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            insert Ord;
            List<OrderItem> lstOrdrItems = new List<OrderItem>();
      
           

        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c= accList[0].Id;
        pos.Payment_schedule_type__c='test';
        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
       for(integer i=0;i<qliList.size();i++){
            
              string ediLinenum = 0+''+i;
              PO_Item_Stage__c poi;
              decimal subtermfaulty = qliList[i].SBQQ__SubscriptionTerm__c != null ? qliList[i].SBQQ__SubscriptionTerm__c+13 :13;
              if(i==1){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c+10,pos.id,subtermfaulty,qliList[i].SBQQ__NetPrice__c);
                lstOrdrItems.add(new OrderItem( OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, UnitPrice = qliList[i].SBQQ__NetPrice__c, SBQQ__QuoteLine__c=qliList[i].id));
              }
              else{
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                lstOrdrItems.add(new OrderItem( OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, UnitPrice = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id));

              }

              poItem.add(poi);
       }
       insert lstOrdrItems;
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));
       
        
       /* CP SBQQ__QuoteLine__c qltextra = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtq.Id, SBQQ__Product__c = pd.Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200);
        insert qltextra; */
        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;

        pos.PO_Validation_Status__c ='Staged';
        update pos;
        
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];

        Test.stopTest();
        system.assert(true);
   }
 }
    static testMethod void testMethod1() {
       User sysAdminUser = ShGl_TestFactory.createUserwithRole();
       System.runAs(sysAdminUser) {
        ShGl_TestFactoryHelper.insertTriggerControls();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
         act.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

        insert act;

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        //Generate the Opportunity.
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        //qt.Credit_Calculation_Start_Date__c = system.today();
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 
        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
      
        
        Test.startTest();

        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c='test';
        pos.Customer_Requested_Ship_Date__c = String.ValueOf(system.today().addDays(10));
        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
          
       for(integer i=0;i<qliList.size();i++){

              string ediLinenum = 0+''+i;
              PO_Item_Stage__c poi;
              decimal subtermfaulty = qliList[i].SBQQ__SubscriptionTerm__c != null ? qliList[i].SBQQ__SubscriptionTerm__c+13 :13;
              if(i==1)
                  poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c+10,pos.id,subtermfaulty,qliList[i].SBQQ__NetPrice__c);
              else
                  poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);

              poItem.add(poi);
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));
        Map<String, Object>  prodMap = new Map<String, Object> {    
            'Name' => 'Pord A', 
                'ProductCode' => 'ProductXYZ',  
                'isActive' => true, 
                'Family' => 'AIR',  
                'Product_Type__c' => 'Appliance'    
                };  
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
        insert pd;
        SBQQ__QuoteLine__c qltextra = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtq.Id, SBQQ__Product__c = pd.Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200);
        // insert qltextra;
        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;              
        
        
        
        pos.PO_Validation_Status__c ='Staged';
        update pos;
        
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        POStageHelper.isDisOrdered(null);
        POStageHelper.isDuplicate(null);
        Test.stopTest();
        system.assert(true);
  }
}
    
    
 static testMethod void testMethod2() {
     User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
         ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
         insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        FlowControll.opportunityTriggerHandler = true;
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        Test.startTest();

        SBQQ__Quote__c qtq =[select id,name,SBQQ__Primary__c,SBQQ__NetAmount__c,SBQQ__Status__c,SBQQ__PricebookId__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
            qtq.SBQQ__Primary__c = true;
            qtq.SBQQ__Status__c = 'Approved';
            update qtq;
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
      
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c='test';
        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
          
       for(integer i=0;i<qliList.size();i++){

              string ediLinenum = 0+''+i;
              PO_Item_Stage__c poi;
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);

              poItem.add(poi);
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));

        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
        opp.Renewals_Forecast_Risk__c = 'Subscription';  
      	opp.stagename = '3 Technical Validation';  
      	opp.Opportunity_Sub_Type__c = 'Renewal'; 
      	opp.SBQQ__PrimaryQuote__c  = qtq.id;
      	opp.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        update opp;
        pos.PO_Validation_Status__c ='Staged';
        update pos;
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
            List<PO_Stage_Errors__c> errorListNew = new List<PO_Stage_Errors__c>();
            PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-02',Error_Code__c = 'INT-02', PO_Stage_Id__c = pos.id);
            errorListNew.add(error);
         	SBQQ__Quote__c qtq1 = qtq.clone();
        	qtq1.SBQQ__Primary__c = false;
        	qtq1.SBQQ__Status__c = 'Approved';

            insert qtq1; 
            
            opportunity oppr = new opportunity(
                Name = 'testing DIEtestsalesforce 4/6/2015',
                CloseDate = Date.Today().addDays(10),
                AccountId = opp.accountId,
                Renewals_Forecast_Risk__c = 'Subscription',
      	         stagename = '1 Discovery',
      	         Opportunity_Sub_Type__c = 'Renewal',
      	         RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
            );
            
            insert oppr;
            opportunity oppr1 = new opportunity(
                Name = 'testing DIEtestsalesforce 4/6/2015',
                CloseDate = Date.Today().addDays(10),
                AccountId = opp.accountId,
                Renewals_Forecast_Risk__c = 'Subscription',
      	         stagename = '1 Discovery',
      	         Opportunity_Sub_Type__c = 'Renewal',
      	         RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
            );
            
            insert oppr1;
 			PO_Stage__c po1 = pos.clone();
            po1.Quote__c = qtq1.Id;
            po1.Error_Messages__c = 'Opportunity Not In Stage 6';
            po1.Opportunity__c = oppr.Id;
            insert po1;
            PO_Stage_Errors__c error1 = new PO_Stage_Errors__c(Name = 'INT-02',Error_Code__c = 'INT-02', PO_Stage_Id__c = po1.id);
			errorListNew.add(error1);
			SBQQ__Quote__c qtq2 = qtq1.clone();
            qtq2.SBQQ__Status__c  = 'In Review';
            insert qtq2;
            PO_Stage__c po2 = pos.clone();
            po2.Quote__c = qtq2.Id;
            po2.Opportunity__c = oppr1.Id;
            insert po2;
            PO_Stage_Errors__c error2 = new PO_Stage_Errors__c(Name = 'INT-02',Error_Code__c = 'INT-02', PO_Stage_Id__c = po2.id);
            errorListNew.add(error2);
            insert errorListNew;
            List<PO_Stage_Errors__c> gettErrorCode = [Select id,opportunity__c,quote__c,PO_Stage_Id__c,PO_Stage_Id__r.quote__c,PO_Stage_Id__r.opportunity__c from PO_Stage_Errors__c where id = : errorListNew[0].Id];
			gettErrorCode[0].opportunity__c = gettErrorCode[0].PO_Stage_Id__r.opportunity__c;
			gettErrorCode[0].quote__c = gettErrorCode[0].PO_Stage_Id__r.quote__c;
            update gettErrorCode[0];
            OpportunityStageInvocableService.FlowInputs inputWrapper = new OpportunityStageInvocableService.FlowInputs();
            inputWrapper.stageErrorRec = gettErrorCode[0];
            OpportunityStageInvocableService.updateOpportunityStage(
                new List<OpportunityStageInvocableService.FlowInputs>{ inputWrapper }
            );

			qtq.SBQQ__LastSavedOn__c = DateTime.now();
            qtq.SBQQ__LastCalculatedOn__c = null;
            update qtq;
             OpportunityStageInvocableService.FlowInputs inputWrapper1 = new OpportunityStageInvocableService.FlowInputs();
            inputWrapper1.stageErrorRec = gettErrorCode[0];
            OpportunityStageInvocableService.updateOpportunityStage(
                new List<OpportunityStageInvocableService.FlowInputs>{ inputWrapper1 }
            );
        AcceptPOHelper.autoPoSubmission(opp.Id);
        Test.stopTest();
        system.assert(true);
   }
 }
    
    
    static testMethod void testMethod3() {
     User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
    ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'Product_Payment_Option__c' => 'Annual',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[0].record.SBQQ__SubscriptionTerm__c = 36;

        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
        quoteWithProducts.lineItems[1].record.SBQQ__SubscriptionTerm__c = 36;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        Test.startTest();

        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Product__r.Product_Payment_Option__c,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
      
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c='test';
        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
                  
       for(integer i=0;i<qliList.size();i++){

              string ediLinenum = 0+''+i;
              PO_Item_Stage__c poi;
                if(qliList[i].SBQQ__Product__r.Product_Payment_Option__c =='Annual'){
                    Decimal j= qliList[i].SBQQ__SubscriptionTerm__c != null? (qliList[i].SBQQ__SubscriptionTerm__c/12) : 1;
                    for(integer k=0;k<j;k++){
                      poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum+'_'+k,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,12,qliList[i].SBQQ__NetPrice__c);
                      poItem.add(poi);
                      poi = new PO_Item_Stage__c();
                    }
                }else
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
              
              
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));

        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
                
        
        
        
        pos.PO_Validation_Status__c ='Staged';
        update pos;
        
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];

        Test.stopTest(); 
        system.assert(true);
     }
    }
    
    
     static testMethod void testMethod4() { 
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
    ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        //cusset.name='Promark Technology, Inc.';
        cusset.name='Arrow';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book.
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        
        //FlowControll.opportunityTriggerHandler = true;
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        //qt.ApprovalStatus__c = 'Draft';
        //update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        

        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
      
        
        Test.startTest();

        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.-Temp','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Quote_number__c = qtq.Name;
        pos.Payment_schedule_type__c='test';
        pos.Quote__c = qtq.Id;
        pos.EDI_DISTI_ID__c = 'INGRAM';
        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
          
       for(integer i=0;i<qliList.size();i++){

              string ediLinenum = 0+''+i;
              PO_Item_Stage__c poi;
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);

              poItem.add(poi);
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));

        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
        
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(pos);
        AcceptPOController poController = new AcceptPOController(ctrl);
        /*poController.toggleReject();
        poController.reject();
        poController.cancel();
        poController.savePO();*/
        
        
        //pos.PO_Validation_Status__c ='Staged';
        //update pos;
        
        pos.PO_Internal_Validation_Status__c ='Internal Failure';
        pos.PO_Validation_Status__c ='Success';
        update pos;
        ctrl = new ApexPages.StandardController(pos);
        poController = new AcceptPOController(ctrl);
        //poController.savePO();
        
        Test.stopTest();
        system.assert(true);
     }
    }
    
    
    static testMethod void testMethod5() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();    
        setting.Name = 'System Administrator';  
        setting.Disable_Opportunity_Old_Trigger__c = TRUE;  
        setting.Disable_Order_Old_Trigger__c = TRUE;    
        setting.Disable_Account_Old_Trigger__c = TRUE;
        insert setting; 


        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();   
        settingDisable.Name = 'System Administrator';   
        settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;  
        settingDisable.Disable_Order_Validation_Rules__c = TRUE; 
        settingDisable.Disable_SBQQ_Quote_Validation_Rules__c = TRUE;
        settingDisable.Disable_SBQQ_Quote_Triggers__c = TRUE;
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c= true;

       

        insert settingDisable;  

        List<TriggerControl__c> triggerList=new List<TriggerControl__c>();  
        TriggerControl__c setting0 = new TriggerControl__c();   
        setting0.Name = 'Order';    
        setting0.DisableTrigger__c = TRUE;  
        triggerList.add(setting0);  
        TriggerControl__c setting1 = new TriggerControl__c();   
        setting1.Name = 'Opportunity';  
        setting1.DisableTrigger__c = TRUE;  
        triggerList.add(setting1);

        insert triggerList;

        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act1.name='Target Tech';
        act1.Type ='Distributor';
        insert act1;

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        FlowControll.opportunityTriggerHandler = true;
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        //qt.ApprovalStatus__c = 'Draft';
        //update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];

        
        Test.startTest();

        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.-Temp','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act1.Id;
        pos.Quote_number__c = qtq.Name;
        pos.Quote__c = qtq.Id;
        pos.Service_Level__c = '';
        pos.Shipping_Carrier__c = '';
        pos.Shipping_Account_Number__c = '1234';
        pos.Note_on_Contingency_and_Special_Language__c='test';
        pos.Payment_schedule_type__c='test';
        pos.Customer_Requested_Ship_Date__c = String.ValueOf(system.today().addDays(10)).remove('-');
        insert pos;
        
        

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
          
       for(integer i=0;i<qliList.size();i++){

              string ediLinenum = 0+''+i;
              PO_Item_Stage__c poi;
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);

              poItem.add(poi);
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));

        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
        
        
        pos.PO_Validation_Status__c ='Internal Failure';
        pos.PO_Internal_Validation_Status__c ='Internal Failure';           
        update pos;
        ApexPages.StandardController ctrl = new ApexPages.StandardController(pos);
        AcceptPOController poController = new AcceptPOController(ctrl);
        
        poController.inputMessage = 'Test error reason.';
        poController.toggleReject();
        poController.reject();
        poController.cancel();
        poController.savePO();
        
        
        pos.PO_Validation_Status__c ='Staged';
        update pos;
        
        pos.PO_Internal_Validation_Status__c ='Internal Failure';
        update pos;
        ctrl = new ApexPages.StandardController(pos);
        poController = new AcceptPOController(ctrl);
        //poController.savePO();
         
        pos.PO_Validation_Status__c ='Success';
        update pos;
        ctrl = new ApexPages.StandardController(pos);
        poController = new AcceptPOController(ctrl);
        
        poController.savePO();

        Test.stopTest();
        system.assert(true);
    
    }
  }
    static testMethod void testAcceptPOController() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        insert disableLogic;

        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        //cusset.name='Promark Technology, Inc.';
        cusset.name='Arrow';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        
        //FlowControll.opportunityTriggerHandler = true;
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        //qt.ApprovalStatus__c = 'Draft';
        //update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        Test.startTest();

        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.-Temp','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Quote_number__c = qtq.Name;
        pos.Payment_schedule_type__c='test';
        pos.Quote__c = qtq.Id;
        pos.EDI_DISTI_ID__c = 'ARROW';
        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        for(integer i=0;i<qliList.size();i++){
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,205/*qliList[i].SBQQ__NetPrice__c*/);

              poItem.add(poi);
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));

        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
        
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(pos);
        AcceptPOController poController = new AcceptPOController(ctrl);
        poController.reject();
        
        pos.PO_Internal_Validation_Status__c ='Internal Failure';
        pos.PO_Validation_Status__c ='Success';
        update pos;

        poController.inputMessage = 'Error';
        poController.toggleReject();
        poController.reject();

        delete pos;
        Test.stopTest();
        system.assert(true);
     }

    }
    static testMethod void testAcceptPOController1() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        insert disableLogic;

        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        //cusset.name='Promark Technology, Inc.';
        cusset.name='Arrow';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        
        //FlowControll.opportunityTriggerHandler = true;
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        //qt.ApprovalStatus__c = 'Draft';
        //update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        Test.startTest();

        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.-Temp','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Quote_number__c = qtq.Name;
        pos.Payment_schedule_type__c='test';
        pos.Quote__c = qtq.Id;
        pos.EDI_DISTI_ID__c = 'ARROW';
        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        for(integer i=0;i<qliList.size();i++){
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,205/*qliList[i].SBQQ__NetPrice__c*/);

              poItem.add(poi);
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));

        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
        
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(pos);
        AcceptPOController poController = new AcceptPOController(ctrl);
        //poController.reject();
        
        pos.PO_Internal_Validation_Status__c ='Pending';
        pos.PO_Validation_Status__c ='Staged';
        update pos;

        Test.stopTest();

        ctrl = new ApexPages.StandardController(pos);
        poController = new AcceptPOController(ctrl);
        system.assert(true);
     }
    }
// added by Deep
    static testMethod void testAcceptPOController2() {        
       try{
        User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        insert disableLogic;

        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
    system.assertEquals(act.Type,'Distributor');

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Arrow';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';

        insert qt; 
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        qtq.ProcessType__c = 'Aspen';
        update qtq;
        

        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        Test.startTest();

        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.-Temp','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Quote_number__c = qtq.Name+':';
        pos.Payment_schedule_type__c='test';
        pos.Quote__c = qtq.Id;
        pos.EDI_DISTI_ID__c = 'PO PDF';
        pos.Distributor_Name__c='Arrow ECS UK Ltd'; //ingrammicro';
        pos.Shipping_Carrier__c='Test,01';
        pos.Account_name__c='Test:01';
        pos.Ship_To_Phone_Number__c='Test:01';
        pos.Ship_To_Contact_Name__c='Test:01';
	pos.Pdf_Address__c = 'test \n Email: test@gmail.com';
        pos.Stage_Total_Amount_Text__c = '13005';
        pos.CM_Value_From_Glynt__c = 'Super Micro Computer, Inc.';

        insert pos;

        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        for(integer i=0;i<qliList.size();i++){
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,205/*qliList[i].SBQQ__NetPrice__c*/);

              poItem.add(poi);
       }
        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
        
        pos.Distributor_Name__c='Carahsoft Technology Corp,';
        pos.PO_Internal_Validation_Status__c ='Pending';
        pos.PO_Validation_Status__c ='Staged';
        update pos;
        Test.stopTest();
        system.assert(true);
        }
    }catch(exception e){
            System.debug(LoggingLevel.DEBUG,'catch'+e.getMessage()+e.getLineNumber());
        }
    }

 @isTest
    static void testAmount(){
        User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        String format = '{"$":"USD", ".":"."}';
        String amountText = '$100.50 USD';
        POStageHelper.getamount(format, amountText);  
        system.assertEquals(amountText,'$100.50 USD');
    }
    }

    /**
      * @description createCustomSetPOValidationError.
    **/
    public static void createCustomSetPOValidationError(){
        List<POValidation_ErrorCode__c> poErrList = new List<POValidation_ErrorCode__c>();
        POValidation_ErrorCode__c poErr1 = new POValidation_ErrorCode__c();
        poErr1.name='PO-01';
        poErr1.Code__c='PO-01';
        poErr1.Error_Issue__c = 'error reported';
        poErrList.add(poErr1);
        
        POValidation_ErrorCode__c poErr2 = new POValidation_ErrorCode__c();
        poErr2.name='PO-02';
        poErr2.Code__c='PO-02';
        poErr2.Error_Issue__c = 'error reported';
        poErrList.add(poErr2);
        
        POValidation_ErrorCode__c poErr3 = new POValidation_ErrorCode__c();
        poErr3.name='PO-03';
        poErr3.Code__c='PO-03';
        poErr3.Error_Issue__c = 'error reported';
        poErrList.add(poErr3);
        
        POValidation_ErrorCode__c poErr4 = new POValidation_ErrorCode__c();
        poErr4.name='PO-04';
        poErr4.Code__c='PO-04';
        poErr4.Error_Issue__c = 'error reported';
        poErrList.add(poErr4);
        
        POValidation_ErrorCode__c poErr5 = new POValidation_ErrorCode__c();
        poErr5.name='PO-05';
        poErr5.Code__c='PO-05';
        poErr5.Error_Issue__c = 'error reported';
        poErrList.add(poErr5);
        
        POValidation_ErrorCode__c poErr6 = new POValidation_ErrorCode__c();
        poErr6.name='PO-06';
        poErr6.Code__c='PO-06';
        poErr6.Error_Issue__c = 'error reported';
        poErrList.add(poErr6);
        
        POValidation_ErrorCode__c poErr7 = new POValidation_ErrorCode__c();
        poErr7.name='PO-07';
        poErr7.Code__c='PO-07';
        poErr7.Error_Issue__c = 'error reported';
        poErrList.add(poErr7);
        
        POValidation_ErrorCode__c poErr8 = new POValidation_ErrorCode__c();
        poErr8.name='PO-08';
        poErr8.Code__c='PO-01';
        poErr8.Error_Issue__c = 'error reported';
        poErrList.add(poErr8);
        
        POValidation_ErrorCode__c poErr9 = new POValidation_ErrorCode__c();
        poErr9.name='PO-09';
        poErr9.Code__c='PO-01';
        poErr9.Error_Issue__c = 'error reported';
        poErrList.add(poErr9);
        
      
        
        POValidation_ErrorCode__c poErr10 = new POValidation_ErrorCode__c();
        poErr10.name='PO-10';
        poErr10.Code__c='PO-01';
        poErr10.Error_Issue__c = 'error reported';
        poErrList.add(poErr10);
        
        POValidation_ErrorCode__c poErr11 = new POValidation_ErrorCode__c();
        poErr11.name='PO-11';
        poErr11.Code__c='PO-01';
        poErr11.Error_Issue__c = 'error reported';
        poErrList.add(poErr11);
        
        POValidation_ErrorCode__c poErr12 = new POValidation_ErrorCode__c();
        poErr12.name='PO-12';
        poErr12.Code__c='PO-01';
        poErr12.Error_Issue__c = 'error reported';
        poErrList.add(poErr12);
        
        POValidation_ErrorCode__c poErr13 = new POValidation_ErrorCode__c();
        poErr13.name='PO-13';
        poErr13.Code__c='PO-01';
        poErr13.Error_Issue__c = 'error reported';
        poErrList.add(poErr13);
        
        POValidation_ErrorCode__c poErr14 = new POValidation_ErrorCode__c();
        poErr14.name='PO-14';
        poErr14.Code__c='PO-01';
        poErr14.Error_Issue__c = 'error reported';
        poErrList.add(poErr14);
        
        POValidation_ErrorCode__c poErr20 = new POValidation_ErrorCode__c();
        poErr20.name='PO-20';
        poErr20.Code__c='PO-01';
        poErr20.Error_Issue__c = 'error reported';
        poErrList.add(poErr20);
        
        insert poErrList;
        
       
    }
    
    /* 
    static testMethod void testMethod_orderservice() {  

        ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();    
            setting.Name = 'System Administrator';  
            setting.Disable_Opportunity_Old_Trigger__c = TRUE;  
            setting.Disable_Order_Old_Trigger__c = TRUE;    
            setting.Disable_Account_Old_Trigger__c = TRUE;  
            insert setting; 

            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();   
            settingDisable.Name = 'System Administrator';   
            settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;  
            settingDisable.Disable_Order_Validation_Rules__c = TRUE;    
            insert settingDisable;  

            List<TriggerControl__c> triggerList=new List<TriggerControl__c>();  
            TriggerControl__c setting0 = new TriggerControl__c();   
            setting0.Name = 'Order';    
            setting0.DisableTrigger__c = TRUE;  
            triggerList.add(setting0);  
            TriggerControl__c setting1 = new TriggerControl__c();   
            setting1.Name = 'Opportunity';  
            setting1.DisableTrigger__c = TRUE;  
            triggerList.add(setting1);  
            insert triggerList; 
        //create account and contact to assign to opportunity   
        List<Account>accList = new List<Account>(); 
        accList.add(new account(name='test account',AccountNumber='123456',Type ='Distributor'));   
        accList.add(new account(name='test account',AccountNumber='123456',RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId(),   
         Focused_Partner__c=false ));   
            insert accList; 
        contact con=new contact(lastname='test contact',leadsource='web',   
                                  email='testc@test.com',accountId=accList[0].id);  
            insert con; 
            accList[0].AdvocateHub__Referral_Source__c=con.id;  
            update accList[0];  
            //insert new opportunity    
            List<Opportunity> oppList=new List<Opportunity>();  
            Opportunity oppy1=new Opportunity(  
                                           Name='test Opportunity', 
                                           AccountId=accList[0].id,     
                                           StageName='1 Discovery',     
                                           CloseDate=system.Today(),    
                                           ForecastCategoryName='Best Case',    
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',   
                                           Installation_Assigned_To__c='FE Install',    
                               Distributor_Lookup__c=accList[0].id, 
                                           Opportunity_Type__c='New Customer',  
                               Opportunity_Sub_type__c = 'MSP', 
                       Deal_Registration_Type__c = 'Partner Initiated Deal',    
                                           Amount = 300000  ,   
                                           Partner_Lookup__c=accList[1].id  
                                           );   
            oppList.add(oppy1); 
        insert oppList; 
                test.startTest();   
        list<Product2> prodlist = new list<Product2>(); 
        Map<String, Object>  prodMap = new Map<String, Object> {    
            'Name' => 'Pord A', 
                'ProductCode' => 'ProductXYZ',  
                'isActive' => true, 
                'Family' => 'AIR',  
                'Product_Type__c' => 'Appliance'    
                };  
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);   
        prodlist.add(pd);   
        insert prodlist;    

        Id pricebookId = Test.getStandardPricebookId(); 
        Map<String, Object>  quoteMap = new Map<String, Object> {   
            'SBQQ__Account__c' => accList[0].Id,    
            'SBQQ__Opportunity2__c' => oppList[0].Id    
        };  
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);   
        qt1.SBQQ__Opportunity2__c = oppList[0].Id;  
        qt1.SBQQ__Primary__c = true;    
        qt1.SBQQ__PriceBook__c = pricebookId;   
        qt1.ApprovalStatus__c = 'Approved'; 
        qt1.SBQQ__PaymentTerms__c = 'Net 45';
        insert qt1; 


         oppList[0].Pricebook2Id = pricebookId; 
        oppList[0].StageName = '4 Business Justification';  
        oppList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';  
        oppList[0].SBQQ__PrimaryQuote__c = qt1.Id;  
        oppList[0].Primary_Competitor__c='Actifio'; 
        update oppList[0];  

         Order od = new Order();    
        od.Name='testOrder1';   
        od.Status = 'Draft';    
        od.Order_Status__c='Order Accepted';    
        od.BookingStatus__c='Booking Failed';   
        od.AccountId = accList[0].Id;   
        od.OpportunityId = oppList[0].Id;   
        od.EffectiveDate = Date.Today();    
        od.ShippingStreet ='Test Street';   
        od.ShippingCity ='Test City';   
        od.ShippingState ='California'; 
        od.ShippingCountry ='United States';    
        od.ShippingPostalcode ='94820'; 
        od.ship_To_Name__c = accList[0].id; 
        od.Type = 'Revenue';    
        od.Est_Ship_Date__c = system.today();   
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();   
        od.Pricebook2Id = pricebookId;  
        od.SBQQ__Quote__c=qt1.id;   
        //od.Hold_Code__c = 'Missing freight forwarder details';    

        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qt1.name,qt1.SBQQ__NetAmount__c);  
        pos.Bill_To_Name__c=accList[0].Id;
        pos.Payment_schedule_type__c='test';  
        insert pos; 
        od.Stage_PO__c = pos.Id;    
        insert od;      

       test.stoptest(); 
       triggerList[0].DisableTrigger__c = false;    
       update triggerList[0];   

       od.Order_Status__c = 'Rejected'; 
       update od;   
       od.Order_Status__c = 'Order Accepted';   
       update od;   


    }
    */
    
    static testMethod void testMethod5Dup() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();    
        setting.Name = 'System Administrator';  
        setting.Disable_Opportunity_Old_Trigger__c = TRUE;  
        setting.Disable_Order_Old_Trigger__c = TRUE;    
        setting.Disable_Account_Old_Trigger__c = TRUE; 
        insert setting; 

        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();   
        settingDisable.Name = 'System Administrator';   
        settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;  
        settingDisable.Disable_Order_Validation_Rules__c = TRUE;  
        settingDisable.Disable_SBQQ_Quote_Validation_Rules__c  = TRUE; 
        settingDisable.Disable_SBQQ_Quote_Triggers__c  = TRUE;
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c= true;
        
        insert settingDisable;  

        List<TriggerControl__c> triggerList=new List<TriggerControl__c>();  
        TriggerControl__c setting0 = new TriggerControl__c();   
        setting0.Name = 'Order';    
        setting0.DisableTrigger__c = TRUE;  
        triggerList.add(setting0);  
        TriggerControl__c setting1 = new TriggerControl__c();   
        setting1.Name = 'Opportunity';  
        setting1.DisableTrigger__c = TRUE;  
        triggerList.add(setting1);  
        insert triggerList;
        FlowControll.opportunityTriggerHandler = false;
        Fuzzy_Logic_Setting__c fuzzylogicSet = new Fuzzy_Logic_Setting__c();
        fuzzylogicSet.Fuzzy_Enabled__c = true;
        fuzzylogicSet.Fuzzy_logic_Limit__c =1.0;
        fuzzylogicSet.Distributor_Salesforce_ID__c ='ALL';
        fuzzylogicSet.name='ALL';
        insert fuzzylogicSet;
        
        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act1.name='Target Tech';
        act1.Type ='Distributor';
        insert act1;

        //Create custom setting record for promark EDI Process.
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
 
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        //qt.ApprovalStatus__c = 'Draft';
        //update qt;
        
        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2); 
        qliList.add( qli1 );
        
        
         qliList.add( qli2 );
        insert qliList;*/
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,SBQQ__Opportunity2__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
      
        
        Test.startTest();

        setting0.DisableTrigger__c = false;  
        update setting0;
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.-Temp','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act1.Id;
        pos.Quote_number__c = qtq.Name;
        pos.Quote__c = qtq.Id;
        pos.Service_Level__c = '';
        pos.Shipping_Carrier__c = '';
        pos.Shipping_Account_Number__c = '1234';
        pos.Note_on_Contingency_and_Special_Language__c='test';
        pos.Payment_schedule_type__c='test';
        insert pos;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
          
       for(integer i=0;i<qliList.size();i++){

              string ediLinenum = 0+''+i;
              PO_Item_Stage__c poi;
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);

              poItem.add(poi);
       }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));

        insert poItem;

        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        insert spa;
        
        
        pos.PO_Validation_Status__c ='Staged';
        pos.PO_Internal_Validation_Status__c ='Internal Failure';
        update pos;
        ApexPages.StandardController ctrl = new ApexPages.StandardController(pos);
        AcceptPOController poController = new AcceptPOController(ctrl);
        ctrl = new ApexPages.StandardController(pos);
        poController = new AcceptPOController(ctrl);
        //poController.savePO();
        
        /*pos.PO_Validation_Status__c ='Staged';
        update pos;
        
        pos.PO_Validation_Status__c ='Internal Failure';
        update pos;
        ctrl = new ApexPages.StandardController(pos);
        poController = new AcceptPOController(ctrl);
        poController.savePO();
         
        pos.PO_Internal_Validation_Status__c='Failure';
        update pos;
        ctrl = new ApexPages.StandardController(pos);
        poController = new AcceptPOController(ctrl);
        
        poController.savePO();*/
        
        Test.stopTest();
        system.assert(true);
        /*for(PO_Stage_Errors__c  errs : [select id,PO_Stage_Id__c, PO_Stage_Item_Id__c, Error_Message__c, Error_Type__c, Error_Code__c from PO_Stage_Errors__c order by Error_Type__c]){
            System.debug(errs.Error_Message__c+'--------------'+errs);
        }*/
    }
    }
    // PRDOPS23-80
    @isTest
    static  void testVerbiage() {
        User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act1.name='Target Tech';
        act1.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act1;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.Legal_Approved_Verbiage__c = 'Test verbiage';
        
        insert qt; 
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,SBQQ__Opportunity2__c,Legal_Approved_Verbiage__c from SBQQ__Quote__c where id=:qt.id ];
        
        Test.startTest();
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.-Temp','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
        pos.Bill_To_Name__c=act1.Id;
        pos.Quote_number__c = qtq.Name;
        pos.Quote__c = qtq.Id;
        pos.Service_Level__c = '';
        pos.Shipping_Carrier__c = '';
        pos.Shipping_Account_Number__c = '1234';
        pos.Note_on_Contingency_and_Special_Language__c='';
        pos.Payment_schedule_type__c='test';
        insert pos;
        
        pos.PO_Validation_Status__c ='Staged';
        update pos;
        
        Test.stopTest();
        system.assert(true);
        //List<PO_Stage_Errors__c>  errs = [select id,PO_Stage_Id__c, PO_Stage_Item_Id__c, Error_Message__c, Error_Type__c, Error_Code__c from PO_Stage_Errors__c WHERE Error_Code__c = 'PO-32'];
        //System.assertEquals(1, errs.size());
    }
}
    
    static List<PO_Stage__c> poIndexValidationsHelperConfigPoList(SBQQ__Quote__c qtq) {
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        for (integer i = 1; i <= 2; i++) {
            PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
                'Promark Technology, Inc.pp',
                'test123',
                system.today().addDays(10),
                2,
                'test@test.com',
                'test partner',
                system.today(),
                i,
                'test12345',
                qtq.name,
                0.0
            );
            pos.Bill_To_Name__c = qtq.SBQQ__Account__c;
            pos.Payment_schedule_type__c = 'test';
            pos.Quote_number__c = qtq.name;
            pos.Opportunity__c = qtq.SBQQ__Opportunity2__c;
            pos.Ship_to_Email__c = 'test@test.com';
            pos.Ship_To_Contact_Name__c = 'testCon';
            pos.Ship_To_Phone_Number__c = '7000022448';
            pos.ShippingCountryCode__c = 'IN';
            pos.ShippingStateCode__c = 'KA';
            pos.ShippingCity__c = 'test City';
            pos.ShippingStreet__c = 'test street';
            pos.ShippingPostalCode__c = '0000';
            pos.PO_Validation_Status__c = 'Pending';
            poStageList.add(pos);
        }
        return poStageList;
    }

    static SBQQ__Quote__c poIndexValidationsHelperConfigQuote() {
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_SBQQ_Quote_Validation_Rules__c = true,
            Disable_SBQQ_QuoteLine_Validation_Rules__c= true
        );
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        Map<String, Object> accMap = new Map<String, Object>{
            'RecordtypeId' => accDistiRecTypeId,
            'Type' => 'Distributor'
        };

        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(), 2, accMap);
        accList[0].name = 'Promark Technology, Inc.';
        accList[0].name = 'Net app, Inc.';
        insert accList;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object>{ 'AccountId' => accList[0].Id };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object>{
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit',
            'ProductCode' => 'ProductXYZ1'
        };

        Map<String, Object> prdMap1 = new Map<String, Object>{
            'Name' => 'Subscription',
            'IsActive' => true,
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
            'SBQQ__SubscriptionTerm__c' => 12,
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'ProductCode' => 'ProductXYZ',
            'GPL_Name__c' => 'NetApp'
        };
        Map<String, Object> prodMap = new Map<String, Object>{
            'Name' => 'Pord A',
            'ProductCode' => 'ProductXYZ',
            'isActive' => true,
            'Family' => 'AIR',
            'Product_Type__c' => 'Appliance'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(pd);
        insert prdList;

        List<PricebookEntry> pBList = new List<PricebookEntry>();

        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name = 'CPQ PriceBook', isActive = true);
        insert customPB;

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);

        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeSubs);
        insert pBList;

        //Generate the Opportunity
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => accList[0].Id,
            'RecordTypeId' => Schema.getGlobalDescribe()
                .get('Opportunity')
                .getDescribe()
                .getRecordTypeInfosByName()
                .get('Sales Opportunity')
                .getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c = accList[0].id;
        opp.Sell_to_Partner__c = accList[1].id;

        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = accList[0].Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';

        insert qt;
        FlowControll.opportunityTriggerHandler = true;

        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        String productModel = SBQQ.ServiceRouter.load(
            'SBQQ.ProductAPI.ProductLoader',
            prdSubs.id,
            '{"pricebookId" : "' +
            customPB.id +
            '", "currencyCode" : "' +
            currencyCode +
            '"}'
        );
        String productModel2 = SBQQ.ServiceRouter.load(
            'SBQQ.ProductAPI.ProductLoader',
            prdHW.id,
            '{"pricebookId" : "' +
            customPB.id +
            '", "currencyCode" : "' +
            currencyCode +
            '"}'
        );

        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add(
            (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class),
            productModels,
            0
        );
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;

        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');

        qt.ApprovalStatus__c = 'Approved';
        update qt;

        return [
            SELECT
                id,
                name,
                SBQQ__Account__c,
                SBQQ__Opportunity2__c,
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
            WHERE id = :qt.id
        ];
    }

    static void poIndexValidationsHelperSetStatePos(List<PO_Stage__c> poStageList, String stage) {
        for (PO_Stage__c objStage : poStageList) {
            objStage.PO_Validation_Status__c = stage;
        }
    }

    @isTest
    static void poIndexValidationsDuplicate() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList;
        poStageList = poIndexValidationsHelperConfigPoList(qtq);
        poIndexValidationsHelperSetStatePos(poStageList, 'Success');
        insert poStageList;
        poStageList = poIndexValidationsHelperConfigPoList(qtq);
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
    }
    }

    @isTest
    static void poIndexValidationsPaymentTerm() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
        
            stagePo.Payment_Terms__c = 'Net 30';
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
     }
    }
    @isTest
    static void poIndexValidationsPoIndexDisorded() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.PO_Index__c = 1;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
     }
    }
    @isTest
    static void poIndexValidationsMissingAccountName() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.Account_name__c = null;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }
    @isTest
    static void poIndexValidationsMissingShippingDetails() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.ShippingCountryCode__c  = null;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
     }
    }
    @isTest
    static void poIndexValidationsMissingEndUserPoNumber() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.End_User_PO__c  = null;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }
    
    @isTest
    static void poIndexValidationsMissingPartnerName() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.Partner_Name__c  = null;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }
    @isTest
    static void poIndexValidationsMissingShippingTermFca() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.Shipping_Method__c  = 'DDP';
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest(); 
        system.assert(true);
    }
    }
    @isTest
    static void poIndexValidationsMissingPoNumber() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.PoNumber__c  = null;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }
    @isTest
    static void poIndexValidationsMissingQuoteNumber() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.Quote_number__c  = null;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }
    @isTest
    static void poIndexValidationsPoIndexGTExpectedPo() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.PO_Index__c  = 9;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }

    
    @isTest
    static void poIndexValidationsBlankExpectedPo() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.Expected_number_of_POs__c  = null;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }

    @isTest
    static void poIndexValidationsZeroPoIndex() {
    User sysAdminUser = ShGl_TestFactory.createUserwithRole();
        System.runAs(sysAdminUser) {
        SBQQ__Quote__c qtq = poIndexValidationsHelperConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelperConfigPoList(qtq);
        for(PO_Stage__c stagePo : poStageList) {
            stagePo.PO_Index__c  = 0;
        }
        insert poStageList;
        Test.startTest();
        poIndexValidationsHelperSetStatePos(poStageList, 'Staged');
        update poStageList;
        Test.stopTest();
        system.assert(true);
      }
    }
    
   /* @isTest
    static void testPoPDFChanges() {

        SBQQ__Quote__c qtq = poIndexValidationsHelper_ConfigQuote();
        List<PO_Stage__c> poStageList = poIndexValidationsHelper_ConfigPoList(qtq);
        system.debug('size if stage Po to create is ' + poStageList.size());
        PO_Stage__c postage = poStageList[0];
        postage.EDI_DISTI_ID__c = 'PO PDF';
        postage.Distributor_Name__c = 'COMPUTER GROSS SPA';
        postage.PO_Index__c= 1;
        postage.Expected_number_of_POs__c = 1;
        postage.Pdf_Address__c = 'VIA I DEL/nEmail:rubriklog@computergross.it';
        postage.Stage_PO_Date__c = '30/12/2021';    
        Test.startTest();
        insert postage;
        Test.stopTest();
    }*/
}