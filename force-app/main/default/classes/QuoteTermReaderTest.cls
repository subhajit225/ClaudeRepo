/*
* Class Name :- QuoteTermReaderTest
* Author :- Mustakim Shaikh
* Created Date :- May 12th, 2025
* @Description : CPQ22-5226 QuoteTermReaderTest
* TestClass   : QuoteTermReaderTest
// ********************Mofification Log *****************************************************************************
*     
* Modified By          Date             Description (Include Jira Details)
* 
*    
* 
// ********************Modification Log *****************************************************************************
*/
@isTest
public class QuoteTermReaderTest {
    @testSetup
    /**
     * @description : Sets up test data for unit tests.
     * This method creates necessary user records and other required data.
     **/
    public static void testSetup() {        
        
        System.runAs(new user(ID = UserInfo.getUserID())) {
        
            ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
            setting.Name = 'System Administrator';
            setting.Disable_Opportunity_Old_Trigger__c = TRUE;
            setting.Disable_Order_Old_Trigger__c = TRUE;
            setting.Disable_Account_Old_Trigger__c = TRUE;
            insert setting;

            ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
            dbl.Disable_Account_Triggers__c = true;
            dbl.Disable_Opportunity_Triggers__c = true;
            dbl.Disable_ServiceContract_Trigger__c = true;
            dbl.Disable_SBQQ_Quote_Triggers__c = true;
            dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
            dbl.Disable_Entitlement_Validation_Rules__c = true;
            dbl.Name = 'System Administrator';
            dbl.Disable_Opportunity_Validation_Rules__c = TRUE;
            dbl.Disable_Order_Validation_Rules__c = TRUE;
            upsert dbl;

            List<TriggerControl__c> triggerList = new List<TriggerControl__c>();

            TriggerControl__c entControl = new TriggerControl__c(
                Name = 'Entitlement',
                DisableTrigger__c = true
            );
            triggerList.add(entControl);
	
            TriggerControl__c setting1 = new TriggerControl__c();
            setting1.Name = 'Opportunity';
            setting1.DisableTrigger__c = TRUE;
            triggerList.add(setting1);

            insert triggerList;
            
            //create quote template
            SBQQ__QuoteTemplate__c objQtTempt = new SBQQ__QuoteTemplate__c(
                    Name = 'MS Quote Document Test',
                    SBQQ__DeploymentStatus__c = 'Deployed'
                );
            insert objQtTempt;

            // Create Template Content linked to Quote Term
            SBQQ__TemplateContent__c templateContent = new SBQQ__TemplateContent__c(
                Name = 'Test Template Content',
                SBQQ__Type__c = 'Quote Terms'
            );
            insert templateContent;


            //create quote template section
            SBQQ__TemplateSection__c objQtTemptSec = new SBQQ__TemplateSection__c(
                    Name = 'MS Quote Document Test Section',
                    SBQQ__Template__c = objQtTempt.Id,
                    SBQQ__Content__c = templateContent.Id
                );
            //insert objQtTemptSec;

             // Create Quote Term
            SBQQ__QuoteTerm__c quoteTerm = new SBQQ__QuoteTerm__c(
                SBQQ__Body__c = 'Test Quote Term',
                SBQQ__Active__c = true,
                SBQQ__PrintOrder__c = 10
            );
            insert quoteTerm;

        
            //create products   
            Product2 hybLicenseprodFE = new Product2(Name='RS-BT-FE-PE-PP',ProductCode = 'RS-BT-FE-PE-PP', IsActive=true, Product_Level__c = 'Hybrid Software', 
                                                    Product_Type__c='FE Edition',Product_Subtype__c='Saas Cloud', X0__c=true,
                                                    Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1');

            //create products   
            Product2 hybLicenseprodEE = new Product2(Name='RS-BT-EE-PE-PP',ProductCode = 'RS-BT-EE-PE-PP', IsActive=true, Product_Level__c = 'Hybrid Software', 
                                                    Product_Type__c='Enterprise Edition',Product_Subtype__c='Saas Cloud', X0__c=true,
                                                    Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1');

            List<Product2> prodList = new List<Product2>(); 
            prodList.add(hybLicenseprodFE);
            prodList.add(hybLicenseprodEE);
            insert prodList;  

            //create pricebook entries
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
            pricebookObj.Product2Id = hybLicenseprodFE.Id;
            pricebookObj.UnitPrice = 100;
            pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
            pricebookObj.IsActive = true;
            pbeList.add(pricebookObj);	
            
            PricebookEntry pricebookObj2 = pricebookObj.clone();
            pricebookObj2.Product2Id = hybLicenseprodEE.Id;
            pbeList.add(pricebookObj2);

            insert pbeList;

            account acct=new account(name='test account',AccountNumber='123456');
            insert acct;
            contact con=new contact(lastname='test contact',leadsource='web',
                                    email='testc@test.com',accountId=acct.id);
            insert con;
            acct.AdvocateHub__Referral_Source__c=con.id;
            update acct;

            //create orderInstance
            Order orderInstance = new Order();
            orderInstance.AccountId = acct.Id;
            orderInstance.EffectiveDate = system.today();  
            orderInstance.Status = 'Draft';
            orderInstance.Type = 'Revenue';
            orderInstance.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstance;
            
            //create order products
            List<OrderItem> orderItemList = new List<OrderItem>();
            OrderItem orderItem1 = new OrderItem();
            orderItem1.OrderId = orderInstance.Id;
            orderItem1.Product2Id = hybLicenseprodFE.Id;
            orderItem1.UnitPrice = pricebookObj.UnitPrice;
            orderItem1.Quantity = 1;
            orderItem1.SerialNumber__c = '09092019APMSP1250';
            orderItem1.Support_Start_Date__c = System.today();
            orderItem1.Support_End_Date__c = System.today().addMonths(36);
            orderItem1.PricebookEntryId = pricebookObj.Id;
            orderItemList.add(orderItem1);
            insert orderItemList;

            //create entitlements
            Entitlement ent = new Entitlement(Name='Testing', 
                AccountId=acct.Id,
                Product__c =hybLicenseprodFE.id,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(365),
                Order_Service_Item__c = orderItem1.Id
            );

            insert ent;

            //create order item extensions
            Order_Item_Extension__c orderItemExtension = new Order_Item_Extension__c(
                Unpaid__c = true, 
                Unbilled__c = true, 
                Invoice_Creation_Date__c = String.valueOf(Date.today()),
                Order_Line_ID__c = orderItem1.Id,
                OI_ExternalID__c = orderItem1.Id
            );
            insert orderItemExtension;
            
            Opportunity oppty=new Opportunity(
                Name='test Opportunity',
                AccountId=acct.id, 
                StageName='1 Discovery', 
                CloseDate=system.Today(),
                ForecastCategoryName='Best Case',
                Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                Installation_Assigned_To__c='FE Install'
            );
            insert oppty;
            
            list<Product2> prodlist2 = new list<Product2>();
            Map<String, Object>  prodMap = new Map<String, Object> {
                'Name' => 'Pord A',
                    'ProductCode' => 'ProductXYZ',
                    'isActive' => true,
                    'Family' => 'AIR',
                    'Product_Type__c' => 'Appliance'
                    };
                        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
            prodlist2.add(pd);
            insert prodlist2;

            Id pricebookId = Test.getStandardPricebookId();
            Map<String, Object>  quoteMap = new Map<String, Object> {
                'SBQQ__Account__c' => acct.Id,
                    'SBQQ__Opportunity2__c' => oppty.Id
                    };
                        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt1.SBQQ__Opportunity2__c = oppty.Id;
            qt1.SBQQ__Primary__c = true;
            qt1.SBQQ__PriceBook__c = pricebookId;
            qt1.ApprovalStatus__c = 'Submitted';
            qt1.SBQQ__QuoteTemplateId__c = objQtTempt.Id;
            qt1.Additional_Terms_Required__c = false;
            insert qt1;

            //create quotelines
            List<SBQQ__QuoteLine__c> lstQuoteLine = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.id,
                                        SBQQ__Product__c = hybLicenseprodFE.Id,
                                        SBQQ__Quantity__c = 1,
                                        SBQQ__ListPrice__c = 100,
                                        SBQQ__NetPrice__c = 100,
                                        SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
                                        SBQQ__SubscriptionPricing__c='Fixed Price', Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB192863040046',
                                    Replacement_Details__c = '{"skuSuppType":null,"skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":null,"skuSelected":null,"skuM365HVal":null,"skuAttlasianVal":null,"seamlessCutover":null,"rowValues":[{"upgradeLines":null,"selectedTerm":12,"selectedRenewalDate":null,"selectedQty":60,"selectedAssetList":{"02i6f00000IrOveAAF":"AA211564080025"},"selectedAsset":"02i6f00000IrOveAAF","rowId":"14.2.0","isAutoDisposition":null,"inactiveLines":null,"entId":"'+ent.Id+'","disposition":"Refreshed","anyToAnyFlag":null}],"renLine":null,"refreshCategoryId":"01t6f00000Oa3G2AAJ","mode":"1to1"}',
                                    Special_Program__c = 'Conversion'
                                        ),
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.id,
                                        SBQQ__Product__c = hybLicenseprodEE.Id,
                                        SBQQ__Quantity__c = 1,
                                        SBQQ__ListPrice__c = 100,
                                        SBQQ__NetPrice__c = 100,
                                        SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
                                        SBQQ__SubscriptionPricing__c='Fixed Price', Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB192863040046'
                                        ),
                new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.id,
                                        SBQQ__Product__c = hybLicenseprodEE.Id,
                                        SBQQ__Quantity__c = 1,
                                        SBQQ__ListPrice__c = 100,
                                        SBQQ__NetPrice__c = 100,
                                        SBQQ__StartDate__c = System.today().addMonths(12).addDays(-1),
                                        SBQQ__SubscriptionPricing__c='Fixed Price', Arroyo_Subsumed_Old_Contract_Line_Items__c = 'BB192863040046'
                                        )
            };

            insert lstQuoteLine;
        }

    }
    
     @isTest
    static void testLoadNull() {
        User admin = [SELECT Id FROM USER WHERE Profile.Name='System Administrator' AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(new user(ID = UserInfo.getUserID())){
            QuoteTermReader reader = new QuoteTermReader();
            List<QuoteTermModel> terms = reader.load(null, null, null);
            System.assertEquals(0, terms.size());
        }
    }

    @IsTest
    static void testEvaluateCondition() {
        User admin = [SELECT Id FROM USER WHERE Profile.Name='System Administrator' AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(new user(ID = UserInfo.getUserID())){
            Boolean result;
            Object fieldValue = 'Test';
            // Test '=' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, '=', 'Test');
            System.assertEquals(true, result);

            // Test '!=' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, '!=', 'Test2');
            System.assertEquals(true, result);

            // Test 'contains' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, 'contains', 'est');
            System.assertEquals(true, result);

            // Test 'startsWith' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, 'startsWith', 'Test');
            System.assertEquals(true, result);

            // Test 'endsWith' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, 'endsWith', 'est');
            System.assertEquals(true, result);

            // Test 'notContains' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, 'notContains', 'xyz');
            System.assertEquals(true, result);

            // Test null fieldValue
            result = QuoteTermReader.evaluateCondition(null, '=', 'Test');
            System.assertEquals(false, result);

            // Test invalid operator
            result = QuoteTermReader.evaluateCondition(fieldValue, 'invalid', 'Test');
            System.assertEquals(false, result);

            fieldValue = '10';

            // Test '>' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, '>', '5');
            System.assertEquals(true, result);

            // Test '<' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, '<', '20');
            System.assertEquals(true, result);

            // Test '>=' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, '>=', '10');
            System.assertEquals(true, result);

            // Test '<=' operator
            result = QuoteTermReader.evaluateCondition(fieldValue, '<=', '10');
            System.assertEquals(true, result);
        }
    }

    @isTest
    public static void testLoadWithQt() {

        SBQQ__Quote__c quoteObj = [select id from sbqq__quote__c limit 1];
        
        Test.startTest();
        System.runAs(new user(ID = UserInfo.getUserID())){
            quoteObj.ApprovalStatus__c = 'Approved';
            Update quoteObj;

            QuoteTermReader reader = new QuoteTermReader();
            List<QuoteTermModel> terms = reader.load(quoteObj.Id, null, null);
            System.assertEquals(0, terms.size());
        }
        Test.stopTest();
    }

    @isTest
    public static void testGcOffer() {

        SBQQ__Quote__c quoteObj = [select id from sbqq__quote__c limit 1];
        Opportunity oppty = [select id from Opportunity limit 1];
        
        Test.startTest();
        System.runAs(new user(ID = UserInfo.getUserID())){

            oppty.Opportunity_Type__c = 'GC Offer';
            Update oppty;

            quoteObj.ApprovalStatus__c = 'Approved';
            Update quoteObj;

            QuoteTermReader reader = new QuoteTermReader();
            List<QuoteTermModel> terms = reader.load(quoteObj.Id, null, null);
            System.assertEquals(0, terms.size());
        }
        Test.stopTest();
    }


    @IsTest
    public static void testAddnlTerm() {

        Test.startTest();
        System.runAs(new user(ID = UserInfo.getUserID())){

            List<Addnl_TnC_Query_Clause__mdt> clauseLst = Addnl_TnC_Query_Clause__mdt.getAll().values();
            Set<String> quoteFields = new Set<String>{'OpportunitySubType__c', 'SBQQ__QuoteTemplateId__c'};
            Set<String> quoteLineFields = new Set<String>{'Disposition_Reason__c', 'Special_Program__c', 'Replacement_Details__c'};

            for (Addnl_TnC_Query_Clause__mdt mdt : clauseLst){
                if (mdt.Object_Scope__c == 'Quote' && mdt.FieldName__c != null){
                    quoteFields.add(mdt.FieldName__c);
                }
                else if (mdt.Object_Scope__c == 'QuoteLine' && mdt.FieldName__c != null){
                    quoteLineFields.add(mdt.FieldName__c);
                }
            }

            String query = 'SELECT '+ String.join(quoteFields, ', ');
            query += ' , (SELECT '+String.join(quoteLineFields, ', ')+' FROM SBQQ__LineItems__r)';
            query += ' FROM SBQQ__Quote__c LIMIT 1';

            SBQQ__Quote__c quoteObj = Database.query(query.trim());

            Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>();
            for (SBQQ__QuoteLine__c ql : quoteObj.SBQQ__LineItems__r){
                quoteLineMap.put(ql.Id, ql);
            }

            quoteObj.ApprovalStatus__c = 'Approved';
            quoteObj.Additional_Terms_Required__c = true;
            Update quoteObj;

            SBQQ__QuoteTerm__c quoteTerm = new SBQQ__QuoteTerm__c(
                SBQQ__Body__c = 'Test Quote Term',
                SBQQ__Active__c = true,
                SBQQ__PrintOrder__c = 10,
                SBQQ__Quote__c = quoteObj.Id,
                Additional_Term__c = true
            );
            insert quoteTerm;

            QuoteTermReader reader = new QuoteTermReader();
            List<QuoteTermModel> terms = reader.load(quoteObj.Id, null, null);
            System.assertEquals(0, terms.size());

            QuoteTermReader.setAdditionalTnCFlag(quoteObj, quoteLineMap);
        }
        Test.stopTest();
    }
}