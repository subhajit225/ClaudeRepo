/**************************************************************************************************
 * @description       : Stage PO Trigger logic
 * @author            : Chaitra
 * @last modified on  : 03-12-2025
 * @last modified by  : Siva Kumar
 * Covers following Apex Classes
 * POItemStageHelperClass
 * POValidateAmount
 ******************************************************************************/
@isTest 
public class EDINetAppTestClass {
    @TestSetup
    static void makeData(){
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';                    
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];  
        User usr=new user(alias = 'std', email='testuser@testclass.com',
                          emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = p.Id,
                          timezonesidkey='America/Los_Angeles', username=uniqueUserName); 
        insert new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_QuoteLine_Triggers__c=true, Disable_Opportunity_Triggers__c =true, Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true,setupOwnerId = usr.id,  Disable_SBQQ_QuoteLine_Validation_Rules__c= true);
        System.runAs(usr){
            FlowControll.opportunityTriggerHandler = false;
            Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Map<String, Object> accMap = new Map<String, Object> {
                'RecordtypeId' => accDistiRecTypeId ,
                    'Type' =>'Distributor'
                    }; 
                        
                        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(),2,accMap); 
            accList[0].name='Promark Technology, Inc.';
            accList[1].name='Net app, Inc.';
            
            insert accList;
            
            Sfdc_Disti_Mapping__mdt distiPromarkRec = Sfdc_Disti_Mapping__mdt.getInstance('Promark_Technology_Inc');
            accList[0].Id = distiPromarkRec.Sfdc_Id__c;   
            update accList;  
            
            //Generate the Contact
            Map<String, Object> cntMap = new Map<String, Object> {
                'AccountId' => accList[0].Id
                    };
                        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
            insert cnt;
            
            Map<String, Object> annualprdMap = new Map<String, Object> {
                'Name' => 'annualProduct',
                    'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                    'SBQQ__SubscriptionTerm__c' => 12, 
                    'SBQQ__SubscriptionType__c' => 'Renewable',
                    'Product_Payment_Option__c' => 'Annual',
                    'ProductCode' => 'ProductAnnual',
                    'Product_Type__c' => 'Spares'
                    };
                        
                        Map<String, Object> subprdMap1 = new Map<String, Object> {
                            'Name' => 'Subscription', 
                                'IsActive' => true, 
                                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                'SBQQ__SubscriptionTerm__c' => 12, 
                                'SBQQ__SubscriptionType__c' => 'Renewable',
                                'ProductCode' => 'ProductXYZ',
                                'GPL_Name__c'=>'NetApp',
                                'Product_Type__c' => 'Spares'
                                };
                                    Map<String, Object>  prodMap = new Map<String, Object> {    
                                        'Name' => 'Pord A', 
                                            'ProductCode' => 'ProductXYZ',  
                                            'isActive' => true, 
                                            'Family' => 'AIR',  
                                            'Product_Type__c' => 'Appliance'    
                                            };  
                                                Map<String, Object> stdprdMap = new Map<String, Object> {
                                                    'Name' => 'Standalone',
                                                        'IsActive' => true,
                                                        'SBQQ__AssetConversion__c' => 'One per unit',
                                                        'ProductCode' => 'ProductXYZ1'
                                                        };
                                                            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), annualprdMap);
            Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), subprdMap1);
            Product2 prdApp = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
            List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, stdprdMap);
            prdList.add(prdHW);
            prdList.add(prdSubs);
            prdList.add(prdApp);
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
            
            PricebookEntry pbeAppstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeAppstd.Product2Id = prdApp.Id;
            pbeAppstd.UnitPrice = 1500;
            pbeAppstd.Pricebook2id = pricebookId;
            pBList.add(pbeAppstd);
            
            PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeHW.Product2Id = prdHW.Id;
            pbeHw.UnitPrice = 1000;
            pbeHW.Pricebook2id = system.label.CPQPricebookID;
            pBList.add(pbeHW);
            
            PricebookEntry pbeApp = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null); 
            pbeApp.Product2Id = prdApp.Id;
            pbeApp.UnitPrice = 1000;
            pbeApp.Pricebook2id = system.label.CPQPricebookID;
            pBList.add(pbeApp);
            
            PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pbeSubs.Product2Id = prdSubs.Id;
            pbeSubs.UnitPrice = 1000;
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
            opp.Partner_Lookup__c = accList[0].id;
            opp.Sell_to_Partner__c = accList[1].id;
            opp.Pricebook2id = system.label.CPQPricebookID;
            insert opp;
            
            
            
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
            qt.SBQQ__Account__c =  accList[0].Id;
            qt.SBQQ__Opportunity2__c = opp.Id;
            qt.SBQQ__Primary__c = true;
            qt.SBQQ__SubscriptionTerm__c = 36;
            qt.SBQQ__PaymentTerms__c = 'Net 45';  
            qt.SBQQ__ExpirationDate__c = Date.newInstance(2022, 09, 9);
            insert qt;
            
            
            
            
            //the JSON formatted String representing the quote model to add a product to
            String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
            String currencyCode = 'USD';
            //the JSON formatted String representing the product to be added to the quote
            String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
            String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
            String productModel3 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdApp.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
            
            
            List<ProductModel> productModels = new List<ProductModel>();
            productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
            productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
            productModels.add((ProductModel) JSON.deserialize(productModel3, ProductModel.class));
            
            ProductAdder adder = new ProductAdder();
            QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
            quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
            quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 2; 
            quoteWithProducts.lineItems[2].record.SBQQ__Quantity__c = 20; 
            quoteWithProducts.lineItems[0].record.SBQQ__SubscriptionTerm__c = 12;
            quoteWithProducts.lineItems[1].record.SBQQ__SubscriptionTerm__c = 36 ;
            quoteWithProducts.lineItems[2].record.SBQQ__SubscriptionTerm__c = 12 ;
            String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
            
            
            QuoteCalculator calculator = new QuoteCalculator();
            calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
            
            qt.ApprovalStatus__c = 'Approved';
            update qt;
            
            //opp.StageName ='6 PO With Channel';
            opp.SBQQ__PrimaryQuote__c = qt.id;
            opp.Lost_To_Won_Against__c = 'Actifio';
            opp.Opportunity_Sub_Type__c='Regular';
            opp.Partner_Level_Of_Involvement__c='1.Rubrik initiated, Partner was fulfillment only';
            opp.Installation_Assigned_To__c='FE Install';
            opp.Primary_Competitor__c = 'Actifio';
            opp.ForecastCategoryName='Best Case';    
            opp.Initial_Contacts_Name__c=cnt.id ;
            opp.Cloud_Type__c = 'Google';
            update opp;
            
            //FlowControll.opportunityTriggerHandler = true;
            
            SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:qt.id ];
            
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
            PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Suzuki Access','test123',system.today().addDays(10),1,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qtq.SBQQ__NetAmount__c);
            pos.Bill_To_Name__c= accList[0].Id;
            pos.Payment_schedule_type__c='test';
            insert pos;
            
            List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
            for(integer i=0;i<qliList.size();i++){
                
                string ediLinenum = 0+''+i;
                PO_Item_Stage__c poi;
                decimal subtermfaulty = qliList[i].SBQQ__SubscriptionTerm__c != null ? qliList[i].SBQQ__SubscriptionTerm__c+13 :13;
                if(i==1){
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                    lstOrdrItems.add(new OrderItem( OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c,unitprice =qliList[i].SBQQ__NetPrice__c, Sales_Price__c = qliList[i].SBQQ__NetPrice__c, SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
                }
                else{
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                    lstOrdrItems.add(new OrderItem( OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
                    
                }
                
                poItem.add(poi);
            }
            insert lstOrdrItems;
            insert poItem;
            
            PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
            insert spa;
        }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to Stage PO trigger logic
    */
    static testMethod void netappTestMethod(){
        User usr =[select id,alias from user order by createddate desc limit 1];
        System.runAs(usr){
            PO_Stage__c stgPO = [select id,PO_Validation_Status__c,Quote__c,(select id from PO_Item_Stage__r ) from PO_Stage__c limit 1];
            SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__Opportunity2__c,SBQQ__ExpirationDate__c from SBQQ__Quote__c where Id =: stgPO.Quote__c];
            List<Account> acctList = [select Id from Account where Name = 'Net app, Inc.'];
            Account accPro = [select Id, Name from Account where Name = 'Promark Technology, Inc.' limit 1];
            Assert.areEqual('Promark Technology, Inc.', accPro.Name);
            qtq.SBQQ__ExpirationDate__c = system.today().addDays(-2);
            update qtq;
            Opportunity opp = [select Id, Hold_Code__c, Distributor_Lookup__c from Opportunity where Id =: qtq.SBQQ__Opportunity2__c];
            opp.Hold_Code__c = 'Contingency with order';
            update opp;
            
            stgPO.PO_Validation_Status__c ='Staged';
            stgPO.Bill_To_Name__c = acctList[0].Id;
            update stgPO;
            
            test.startTest();
            TriggerHandler.bypass('OrderHandler');
            for(PO_Item_Stage__c poItm : stgPO.PO_Item_Stage__r){
                poItm.UnitPrice__c = 1.0;
                poItm.SubscriptionTerm__c = 1.0;  
                poItm.Quantity__c = 1.0;
            }
            update stgPO.PO_Item_Stage__r;
            stgPO.PO_Validation_Status__c ='Staged';
            stgPO.PO_Internal_Validation_Status__c ='Pending';
            stgPO.TotalAmount__c = 1.0;
            update stgPO;
            Test.stopTest();
        } 
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to Stage PO trigger logic
    */
    static testMethod void netappOrdValidationTestMethod(){
        User usr =[select id,alias from user order by createddate desc limit 1];
        System.runAs(usr){
            test.startTest();
            TriggerHandler.bypass('OrderHandler');
            PO_Stage__c stgPO = [select id,PO_Validation_Status__c,(select id from PO_Item_Stage__r ) from PO_Stage__c limit 1];
            Order ord1 = [select id,Sell_to_Partner__c,Bill_To_Name__c,SBQQ__Quote__c,Status,EffectiveDate,OpportunityId,AccountId,Type from order];
            Order cloneOrd = ord1.clone(false,true,false, false);
            insert cloneOrd;
            
            stgPO.PO_Validation_Status__c ='Staged';
            update stgPO;
            Assert.areEqual(true, stgPO != null);
            Test.stopTest();  
        } 
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to Stage PO trigger logic
    */
    static testMethod void stagePOInternalValidation(){
        User usr =[select id,alias from user order by createddate desc limit 1];
        System.runAs(usr){
            PO_Stage__c stgPO = [select id,PO_Validation_Status__c,Quote__c,(select id from PO_Item_Stage__r ) from PO_Stage__c limit 1];
            SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__Opportunity2__c,SBQQ__ExpirationDate__c from SBQQ__Quote__c where Id =: stgPO.Quote__c];
            List<Account> acctList = [select Id from Account where Name = 'Net app, Inc.'];
            Account accPro = [select Id,Name from Account where Name = 'Promark Technology, Inc.' limit 1];
            Assert.areEqual('Promark Technology, Inc.', accPro.Name);
            qtq.SBQQ__ExpirationDate__c = system.today().addDays(2);
            qtq.ApprovalStatus__c = 'Approved';
			qtq.SBQQ__Status__c = 'Approved';
            update qtq;
            Opportunity opp = [select Id, Hold_Code__c, Distributor_Lookup__c from Opportunity where Id =: qtq.SBQQ__Opportunity2__c];
            opp.StageName = '6 PO With Channel';
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c ='Regular';
            opp.Cloud_Partner_Impact__c = 'Partner gets a well-qualified meeting with key decision-makers';
            update opp;
            
            stgPO.PO_Validation_Status__c ='Staged';
            stgPO.Bill_To_Name__c = accPro.Id;
            stgPO.Payment_schedule_type__c = null;
            stgPO.Shipping_Account_Number__c = null;
            stgPO.Shipping_Carrier__c = 'No Shipping Required';
            stgPO.Service_Level__c = 'N/A';
            stgPO.Note_on_Contingency_and_Special_Language__c = null;
            stgPO.Account_Name__c = accPro.Name;
            update stgPO;
            
            test.startTest();
            TriggerHandler.bypass('OrderHandler');
            for(PO_Item_Stage__c poItm : stgPO.PO_Item_Stage__r){
                poItm.UnitPrice__c = 1.0;
                poItm.SubscriptionTerm__c = 1.0;  
                poItm.Quantity__c = 1.0;
            }
            update stgPO.PO_Item_Stage__r;
            stgPO.PO_Validation_Status__c ='Staged';
            stgPO.PO_Internal_Validation_Status__c ='Pending';
            stgPO.TotalAmount__c = 1.0;
            update stgPO;
            Test.stopTest();
        } 
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to Stage PO trigger logic
    */
    static testMethod void stagePOInternalErrorsTest(){
        User usr =[select id,alias from user order by createddate desc limit 1];
        System.runAs(usr){
            POValidateAmount.isTestRunning = true;
            PO_Stage__c stgPO = [select id,PO_Validation_Status__c,Quote__c,(select id,Product__r.Appliance_Model_HW__c, Product__r.Product_Type__c from PO_Item_Stage__r ) from PO_Stage__c limit 1];
            SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__Opportunity2__c,SBQQ__ExpirationDate__c from SBQQ__Quote__c where Id =: stgPO.Quote__c];
            List<Account> acctList = [select Id from Account where Name = 'Net app, Inc.'];
            Account accPro = [select Id,Name from Account where Name = 'Promark Technology, Inc.' limit 1];
            Assert.areEqual('Promark Technology, Inc.', accPro.Name);
            qtq.SBQQ__ExpirationDate__c = system.today().addDays(-2);
            update qtq;
            Opportunity opp = [select Id, Hold_Code__c, Distributor_Lookup__c from Opportunity where Id =: qtq.SBQQ__Opportunity2__c];
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c ='Regular';
            opp.Cloud_Partner_Impact__c = 'Partner gets a well-qualified meeting with key decision-makers';
            update opp;
            
            stgPO.PO_Validation_Status__c ='Staged';
            stgPO.Bill_To_Name__c = accPro.Id;
            stgPO.Shipping_Account_Number__c = null;
            stgPO.Shipping_Carrier__c = 'Watchpoint';
            stgPO.Service_Level__c = null;
            stgPO.Note_on_Contingency_and_Special_Language__c = 'Test Note';
            stgPO.Account_Name__c = accPro.Name;
            update stgPO;
            test.startTest();
            qtq.SBQQ__Primary__c = false;
            update qtq;
            stgPO.PO_Validation_Status__c ='Staged';
            stgPO.PO_Internal_Validation_Status__c ='Pending';
            stgPO.TotalAmount__c = 1.0;
            update stgPO;
            Test.stopTest();
        } 
    }
}