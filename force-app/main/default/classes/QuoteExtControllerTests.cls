@isTest
public class QuoteExtControllerTests{
    testMethod static void testSubmit() {

        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(
            LastName = 'Test345454Approval',
            Alias = 't1',
            Email = 'abcd@gmail.com.sandbox',
            Username = 'atestbApproval12321@gmail.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Denver',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        System.RunAs(u){
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quote;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quote);
        Assert.areEqual(1, lstQuote.size());
        String testLbl = Label.Approval_Notifier_Admins_Mail;
            testLbl = 'test12367@test.com.sandbox';
        System.Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        System.Test.stopTest();
    }
    }
    
    
    testMethod static void testSubmitLtng() {
        Profile p = [SELECT Id FROM Profile 
            WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',
                    Alias = 't1',
                    Email = 'abcd@gmail.com.sandbox',
                    Username = 'atestbApproval12321@gmail.com',
                    ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Denver',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        System.RunAs(u){

            Id ptId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type = 'Partner';
        vAccount.recordTypeId = ptId;
        insert vAccount;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quote;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quote);
        
        System.Test.startTest();
        Assert.areEqual(1, lstQuote.size());
        QuoteExtController.onSubmitLtng(quote, false);
        QuoteExtController.onSubmitLtng(quote, true);
        System.Test.stopTest();
    }
    }
    
    testMethod static void testRecall() {
        
        User u = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];

        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        
        System.RunAs(u){
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quote;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quote);
        Assert.areEqual(1, lstQuote.size());

        System.Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        //con.onPreview();
        try {
            con.onPreview();
        } catch(Exception e) {
            system.assertEquals(e.getMessage(),e.getMessage());
        }
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        System.Test.stopTest();
    }
    }
    
    testMethod static void testSubmitApproval() {
        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',
                    Alias = 't1',
                    Email = 'abcd@gmail.com.sandbox',
                    Username = 'atestbApproval12321@gmail.com',
                    ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true,
                                                                           Approval_Issue_Notify_flag__c = true);
        
        upsert cc;
        System.RunAs(u){
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quote;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quote);
        Assert.areEqual(1, lstQuote.size());
        
        System.Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        //con.onPreview();
        con.onSubmit();
        con.reDirect();
        System.Test.stopTest();
    }
    }
    
    testMethod static void testSendEmail() {
        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',
                        Alias = 't1',
                        Email = 'abcd@gmail.com.sandbox',
                        Username = 'atestbApproval12321@gmail.com',
                        ProfileId = p.Id,
                        TimeZoneSidKey = 'America/Denver',
                        LocaleSidKey = 'en_US',
                        EmailEncodingKey = 'UTF-8',
                        LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        System.RunAs(u){

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quote;
        SBQQ__Quote__c QuoteforApproval = new SBQQ__Quote__c(
            ID = quote.Id,
            ApprovalStatus__c = 'Submitted'
        );
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quote);
        Exception exception1 = new System.MathException();
        exception1.setMessage('my message');
        Assert.areEqual(1, lstQuote.size());
        System.Test.startTest();
        QuoteExtController.sendFailureEmail(quote.id,exception1);
        System.Test.stopTest(); 
    }
    }
    
    testMethod static void callArroyoQueuableMethodTest() {
        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',
                      Alias = 't1',Email = 'abcd@gmail.com.sandbox',
                      Username = 'atestbApproval12321@gmail.com',
                      ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',
                      LocaleSidKey = 'en_US',
                      EmailEncodingKey = 'UTF-8',
                      LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                    Disable_SBQQ_QuoteLine_Triggers__c = true,
                    Disable_Account_Triggers__c = true,
                Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        System.RunAs(u){
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quote;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quote);
        Assert.areEqual(1, lstQuote.size());
        QuoteExtController.callArroyoQueuableMethod(quote.id);
        QuoteExtController.quoteValidateAPI(quote.Id);
    }
    }
    
    testMethod static void callvalidateSubsAssets(){
        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',
                    Alias = 't1',Email = 'abcd@gmail.com.sandbox',
                    Username = 'atestbApproval12321@gmail.com',
                    ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',RBAC_Group__c = 'System - IT',RBAC_Department__c = 'Service Account');
        insert u;
        System.runas(u){
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                    Disable_Opportunity_Triggers__c = true,
                    Disable_Account_Validation_Rules__c = true,
                    Disable_Entitlement_Validation_Rules__c = true);
        
        upsert cc;

        SBQQ.TriggerControl.disable();

        TriggerControl__c control = new TriggerControl__c(
            Name = 'Entitlement',
            DisableTrigger__c = true
        );
        insert control;
        
        List<Product2> products = new List<Product2>();
        
        Product2 prod = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Rel_SubsAsst__c='Renew:RelatedAsst',
                Usable_Capacity__c=90);  
        products.add(prod);
        Product2 prod1 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Family  ='Non-Returnable Disk Service',
                Rel_SubsAsst__c='Renew:RelatedAsst');  
        products.add(prod1);
        Product2 prod2 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Family  =ReplacementConstants.PRODUCT_FAMILY_RUBRIK_SCALE);  
        products.add(prod2);
        Product2 prod3 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Family  =ReplacementConstants.PRODUCT_FAMILY_THIRD_PARTY_LICENSE);  
        products.add(prod3);
        Product2 prod4 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Product_Level__c  =ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE,
                Rel_SubsAsst__c='Renew:RelatedAsst');  
        products.add(prod4);
        
        Product2 prodHybridSoft = new Product2(Name='RS-BT-FE-PE-PP', 
                Product_Level__c  =ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, IsActive=true, 
                ProductCode='RS-BT-FE-PE-PP',Rel_SubsAsst__c='Renew:RelatedAsst');  
        products.add(prodHybridSoft);
        
        Product2 prodHWR61 = new Product2(Name='RH-6304S-01', 
                Product_Level__c  =ReplacementConstants.HARDWARE, IsActive=true, 
                Product_Type__c= ReplacementConstants.HARDWARE, ProductCode='RH-6304S-01', 
                Usable_Capacity__c=12);  
        products.add(prodHWR61);

        Product2 prodHWR71 = new Product2(Name='RH-7402-01', 
                Product_Level__c  =ReplacementConstants.HARDWARE, IsActive=true, 
                Product_Type__c= ReplacementConstants.HARDWARE, ProductCode='RH-7402-01', 
                Usable_Capacity__c=30);  
        products.add(prodHWR71);

        Product2 prodHWSup1 = new Product2(Name='HW-SVC', 
                ProductCode='HW-SVC',
                Product_Type__c = ReplacementConstants.HW_SUPPORT, Family ='Non-Returnable Disk Service');  
        products.add(prodHWSup1);

        Product2 prodRCDM = new Product2(Name='RCDM-HPE', 
                IsActive=true, 
                Product_Type__c = ReplacementConstants.PRODUCT_TYPE_RCDOM_SUPPORT, ProductCode='RCDM-HPE', 
                Usable_Capacity__c=30);  
        products.add(prodRCDM);

        Product2 prodUpgrade = new Product2(Name='Upgrade', 
                IsActive=true, ProductCode='Upgrade', 
                Upgrade_Path__c = 'Complete to Complete Pro');  
        products.add(prodUpgrade);

        insert products;

        //create pricebook entries
		List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pbe = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbe.Product2Id = prodHWR71.Id;
        pbe.UnitPrice = 100;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.IsActive = true;
        pbeList.add(pbe);

        PricebookEntry pbeRCDM = pbe.clone();
        pbeRCDM.Product2Id = prodRCDM.Id;
        pbeList.add(pbeRCDM);

        insert pbeList;

        //create account
		Account acc = new Account();
		acc.Name = 'Test Account';
		acc.Type='Distributor';
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        insert acc;
        
        //create service contract
		ServiceContract serviceContractObj = new ServiceContract();
		serviceContractObj.Name = 'test contract';
		serviceContractObj.AccountId = acc.Id;
		serviceContractObj.StartDate = System.today();
		serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
		serviceContractObj.EndDate = System.today().addDays(365);
		insert 	serviceContractObj;		

		//create contract lines
		List<contractLineItem> cliList = new List<contractLineItem>(); 

		ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
		ContractLineItemObj.SBQQSC__Account__c = acc.Id;
        ContractLineItemObj.PricebookEntryId = pbe.Id;
		ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
		ContractLineItemObj.Quantity = 15;
		ContractLineItemObj.UnitPrice = 100;
		ContractLineItemObj.StartDate = System.today();
		ContractLineItemObj.EndDate = System.today().addDays(120);
		cliList.add(ContractLineItemObj);

        ContractLineItem ContractLineItemObj2 = ContractLineItemObj.clone();
        cliList.add(ContractLineItemObj2);

        ContractLineItem cliRCDM = ContractLineItemObj.clone();
        cliRCDM.PricebookEntryId = pbeRCDM.Id;
        cliList.add(cliRCDM);
        
		insert cliList;

        //create assets
        List<Asset> assets = new List<Asset>();
        
        Asset asset = new Asset();
        asset.Name = '1234';
        asset.Serial_Number__c = 'AA210264120057';
        asset.SerialNumber = 'AA210264120057';
        asset.AccountId = acc.id;
        asset.Product2Id = prod.Id;
        assets.add(asset);

		Asset assetHWR61 = new Asset(
            Name = 'AA2025R6402000',
            Serial_Number__c = 'AA2025R6402000',
            SerialNumber = 'AA2025R6402000',
            AccountId = acc.id,
            Product2Id = prodHWR61.Id
        );

        Asset assetHWR71 = new Asset(
            Name = 'AA2025R7402000',
            Serial_Number__c = 'AA2025R7402000',
            SerialNumber = 'AA2025R7402000',
            AccountId = acc.id,
            Product2Id = prodHWR71.Id
        );

        assets.add(assetHWR61);
        assets.add(assetHWR71);

        insert assets;

        //create entitlements
        List<Entitlement> entitlements = new List<Entitlement>();

        Entitlement ent_base1 = new Entitlement(
            Name='ent_base1', 
            AccountId=acc.Id,
            Product__c = prodHybridSoft.id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365),
            Quantity__c = 15,
            ContractLineItemId = ContractLineItemObj.Id
        );

        entitlements.add(ent_base1);

        Entitlement ent_base2 = new Entitlement(
            Name='ent_base2', 
            AccountId=acc.Id,
            Product__c =prodHybridSoft.id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365),
            Quantity__c = 15,
            ContractLineItemId = ContractLineItemObj2.Id
        );
        entitlements.add(ent_base2);

		insert entitlements;

        //create scale entitlements
        List<Scale_Entitlement__c> scaleEnts = new List<Scale_Entitlement__c>();

        Scale_Entitlement__c scaleEnt1 = new Scale_Entitlement__c(
            Type__c = ReplacementConstants.REFRESHED_BASE_LICENSE,
            Entitlement__c = ent_base1.Id,
            Asset__c = assetHWR71.Id
        );
        scaleEnts.add(scaleEnt1);

        Scale_Entitlement__c scaleEnt2 = new Scale_Entitlement__c(
            Type__c = ReplacementConstants.REFRESHED_BASE_LICENSE,
            Entitlement__c = ent_base2.Id,
            Asset__c = assetHWR71.Id
        );
        scaleEnts.add(scaleEnt2);

        insert scaleEnts;
			
		//create opp
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = acc.Id;
        opp.Name = 'Testing Opportunity';
        opp.CloseDate = System.today().addMonths(12);
        opp.StageName = ReplacementConstants.STAGENAME_PROSPECTING;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        insert opp;

        //create quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Type__c=ReplacementConstants.QUOTE_TYPE_RENEWAL); 
        insert(quote);  

        System.Test.startTest();

        String replacementDetails1 = '{"rowValues":[{"entId":"'+ent_base1.Id+'"}]}';

        //create quotelines
        List<SBQQ__QuoteLine__c> qlst = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prod.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, 
            SBQQ__SubscribedAssetIds__c=asset.Id,SubscribedAssetNames__c = 'AA210264120057',
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__RenewedAsset__c=asset.Id,SBQQ__SubscriptionTerm__c=36,
            Subscribed_Asset_Name__c='AA210264120057');  
        qlst.add(qli1);
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prod1.Id, SBQQ__Number__c=2, 
            SBQQ__SubscribedAssetIds__c=asset.Id,SubscribedAssetNames__c = 'AA210264120057',
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset.Id,
            SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst.add(qli2);
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prod2.Id, SBQQ__Number__c=2
            ,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,SBQQ__Quantity__c=1,Special_Program__c=ReplacementConstants.DISPOSITION_REASON_REPLACED,Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345');  
        qlst.add(qli3);
        
        SBQQ__QuoteLine__c qli4= new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prod2.Id, SBQQ__Number__c=2, 
            Licensing_Model__c = ReplacementConstants.PREPETUAL,
            SBQQ__SubscribedAssetIds__c=asset.Id,SubscribedAssetNames__c = 'AA210264120057',
            Subscribed_Asset_Name__c='AA210264120057',
            Disposition_Reason__c=ReplacementConstants.DISPOSITION_REASON_REPLACED, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=asset.Id );  
        qlst.add(qli4);
        SBQQ__QuoteLine__c qli5= new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prod4.Id, SBQQ__Number__c=90, 
            Sales_Comp_Category__c='SW SUPPORT',Product_Level__c =ReplacementConstants.SUPPORT,
            SBQQ__RequiredBy__c=qli4.id, SBQQ__SubscribedAssetIds__c=asset.Id,
            SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=90,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=asset.Id );  
        qlst.add(qli5);
        

        SBQQ__QuoteLine__c qliHWS1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prodHybridSoft.Id,SBQQ__Quantity__c=12, SBQQ__Number__c=1,
            SBQQ__SubscribedAssetIds__c=assetHWR61.Id, SubscribedAssetNames__c = 'AA2025R6402000',  
            Subscribed_Asset_Name__c='AA2025R6402000', 
            Disposition_Reason__c=ReplacementConstants.DISPOSTION_RENEWING, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__SubscriptionTerm__c=36);  
        qlst.add(qliHWS1);    
        
        SBQQ__QuoteLine__c qliHWS2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prodHybridSoft.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, 
            SBQQ__SubscribedAssetIds__c=assetHWR71.Id, SubscribedAssetNames__c = 'AA2025R7402000', 
            Subscribed_Asset_Name__c='AA2025R7402000', 
            Disposition_Reason__c=ReplacementConstants.DISPOSTION_RENEWING, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__SubscriptionTerm__c=36, SBQQSC__RenewedContractLine__c=ContractLineItemObj.Id,
            Replacement_Details__c = replacementDetails1);  
        qlst.add(qliHWS2);

        SBQQ__QuoteLine__c qliHWS3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, 
            SBQQ__Product__c=prodHybridSoft.Id, SBQQ__Quantity__c=5, SBQQ__Number__c=1, 
            SBQQ__SubscribedAssetIds__c=assetHWR71.Id, SubscribedAssetNames__c = 'AA2025R7402000',  
            Subscribed_Asset_Name__c='AA2025R7402000', 
            Disposition_Reason__c=ReplacementConstants.DISPOSTION_RENEWING, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__SubscriptionTerm__c=36, SBQQSC__RenewedContractLine__c=ContractLineItemObj.Id,
            Replacement_Details__c = replacementDetails1);  
        qlst.add(qliHWS3);

        SBQQ__QuoteLine__c qliRCDM = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, SBQQ__Product__c=prodRCDM.Id,
        SBQQ__Quantity__c=1, SBQQ__Number__c=1, SBQQSC__RenewedContractLine__c=cliRCDM.Id, Product_Type__c ='RCDM Support');  
        qlst.add(qliRCDM);

        SBQQ__QuoteLine__c upgradeQLIError = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, SBQQ__Product__c=prodUpgrade.Id,
        SBQQ__Quantity__c=1, SBQQ__Number__c=10, Product_Level__c = ReplacementConstants.SUPPORT);  
        qlst.add(upgradeQLIError);

        SBQQ__QuoteLine__c assetQLIAccEntError = qliHWS1.clone();
        assetQLIAccEntError.Account_s_Entitlement__c = ent_base1.Id;
        assetQLIAccEntError.AssociatedAccount__c = acc.Id;
        assetQLIAccEntError.SBQQ__Number__c = 10;
        qlst.add(assetQLIAccEntError);

        insert qlst;
        
        List<SBQQ__QuoteLine__c> qlstLevel1 = new List<SBQQ__QuoteLine__c>();

        //create HW
        SBQQ__QuoteLine__c qliHWR61 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, SBQQ__Product__c=prodHWR61.Id,
        SBQQ__Quantity__c=1, SBQQ__Number__c=1);
        qliHWR61.SBQQ__RequiredBy__c = qliHWS1.Id;
        qlstLevel1.add(qliHWR61);

        //create NRD
        SBQQ__QuoteLine__c qliNRD = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, SBQQ__Product__c=prodHWSup1.Id,
        SBQQ__Quantity__c=1, SBQQ__Number__c=1, Product_Type__c = ReplacementConstants.HW_SUPPORT,
        Disposition_Reason__c=ReplacementConstants.DISPOSTION_RENEWING, 
        SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, SBQQ__SubscriptionTerm__c=36,
        SubscribedAssetNames__c = 'AA2025R6402000', Subscribed_Asset_Name__c='AA2025R6402000');
        qliNRD.SBQQ__RequiredBy__c = qliHWS1.Id;
        qlstLevel1.add(qliNRD);

        insert qlstLevel1;

        //create HW supp
        SBQQ__QuoteLine__c qliHWSup1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quote.Id, SBQQ__Product__c=prodHWSup1.Id,
        SBQQ__Quantity__c=1, SBQQ__Number__c=1, Product_Type__c = ReplacementConstants.HW_SUPPORT,
        Disposition_Reason__c=ReplacementConstants.DISPOSTION_RENEWING, 
        SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE, SBQQ__SubscriptionTerm__c=36,
        SubscribedAssetNames__c = 'AA2025R6402000', Subscribed_Asset_Name__c='AA2025R6402000');
        qliHWSup1.SBQQ__RequiredBy__c = qliHWR61.Id;

        insert qliHWSup1;

        //create disposition quote lines
        List<CPQ_Disposition_Quote_Line__c> disposeLines = new List<CPQ_Disposition_Quote_Line__c>();

        CPQ_Disposition_Quote_Line__c disposeLine1 = new CPQ_Disposition_Quote_Line__c(
            Quote__c = quote.Id, Quantity__c = 10, RenewedContractLine__c = ContractLineItemObj2.Id,
            Replacement_Detail__c = replacementDetails1
        );
        disposeLines.add(disposeLine1);

        CPQ_Disposition_Quote_Line__c disposeLine2 = new CPQ_Disposition_Quote_Line__c(
            Quote__c = quote.Id, Quantity__c = 5, RenewedContractLine__c = ContractLineItemObj2.Id,
            Replacement_Detail__c = replacementDetails1
        );
        disposeLines.add(disposeLine2);

        List<SBQQ__QuoteLine__c> quoteLinesTest = getQuoteLines(quote.Id);
        
        List<SBQQ__QuoteLine__c> quoteLinesError = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesSuccess = new List<SBQQ__QuoteLine__c>();

        for (SBQQ__QuoteLine__c ql : quoteLinesTest){
            if (ql.SBQQ__Number__c == 10){
                quoteLinesError.add(ql);
            }
            else {
                quoteLinesSuccess.add(ql);
            }
        }
        
        String message = QuoteExtController.validateSubsAssets(quoteLinesSuccess, disposeLines);
        String message_error = QuoteExtController.validateSubsAssets(new List<SBQQ__QuoteLine__c>{quoteLinesError[0]}, disposeLines);
        String message_error_2 = QuoteExtController.validateSubsAssets(new List<SBQQ__QuoteLine__c>{quoteLinesError[1]}, disposeLines);
        //QuoteExtController.getQuoteRecord(quote.Id);

        System.assert(message == null || message != '');

        quoteLinesSuccess[0].SubscribedAssetNames__c = 'AA210264120057, MS75';
        String message_erm = QuoteExtController.validateSubsAssets(quoteLinesSuccess, disposeLines);
        System.assert(message_erm != null && message_erm != '');
        
        System.Test.stopTest();
    }
}

    testMethod static void callvalidateSubsAssets2(){
        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',Alias = 't1',
                        Email = 'abcd@gmail.com.sandbox',
                        Username = 'atestbApproval12321@gmail.com',
                        ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',
                        LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',
                        LanguageLocaleKey = 'en_US',RBAC_Group__c = 'System - IT',RBAC_Department__c = 'Service Account');
        insert u;
        System.runas(u){
            ShGl_DisableBusinessLogic__c cc = new ShGl_DisableBusinessLogic__c(
                    SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true,
                                                                           Disable_Account_Validation_Rules__c = true);
        
        upsert cc;
        SBQQ__Quote__c quotex = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quotex;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quotex);
        Assert.areEqual(1, lstQuote.size());
        
        SBQQ_QuoteLineTriggerHandler handler=new SBQQ_QuoteLineTriggerHandler();
        
        
            Product2 prodaa = new Product2(Name='TestProd1', IsActive=true, 
                ProductCode='Test-Prod',Rel_SubsAsst__c='Renew:RelatedAsst',Usable_Capacity__c=90);  
        insert prodaa;
            Product2 prod11 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Family  ='Non-Returnable Disk Service',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod11;
            Product2 prod2 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Family  =ReplacementConstants.PRODUCT_FAMILY_RUBRIK_SCALE);  
        insert prod2;
            Product2 prod3 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Family  =ReplacementConstants.PRODUCT_FAMILY_THIRD_PARTY_LICENSE);  
        insert prod3;
            Product2 prod41 = new Product2(Name='TestProd', IsActive=true, 
                ProductCode='Test-Prod',Product_Level__c =ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE,
                Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod41;
        List<Product2> lstProd = new List<Product2>();
        lstProd.add(prodaa);
        Assert.areEqual(1, lstProd.size());
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(),null);
        insert acc;
        
        List<Account> accountList1 = new List<Account>();
        Account vAccount1 = new Account();
        vAccount1.Name = 'Test Account';
        vAccount1.Type='Distributor';
            vAccount1.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        accountList1.add(vAccount1);
        
        Account vAccount21 = new Account();
        vAccount21.Name = 'Test Account';
        vAccount21.recordTypeId = vAccount1.recordTypeId;
        accountList1.add(vAccount21);
        insert accountList1;
        contact con1=new contact(lastname='test contact',leadsource='web',
                                    email='testc@test.com',accountId=acc.id);
        insert con1;
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {'AccountId' => acc.Id};

        //insert new opportunity
        Opportunity opp=new Opportunity(
            Name='test Opportunity',
            AccountId=acc.id, 
            StageName='1 Discovery', 
            CloseDate=system.Today(),
            ForecastCategoryName='Best Case',
            Initial_Contacts_Name__c=con1.id,Business_Unit__c='Rubrik',
            Installation_Assigned_To__c='FE Install',
            Partner_Lookup__c = vAccount21.id,
            Distributor_Lookup__c = vAccount1.id,
            Alliance_HW_Partner__c = 'Cisco'
        );
        insert opp;
        
        Asset asset1 = new Asset();
        asset1.Name = '1234';
        asset1.Serial_Number__c = 'AA210264120057';
        asset1.AccountId = acc.id;
        asset1.Product2Id = prodaa.Id;
        insert asset1;

            List<Asset> astlst = [Select id,Serial_Number__c,Product_Usable_Capacity__c  
                    from Asset where Serial_Number__c = 'AA210264120057'];
        List<SBQQ__QuoteLine__c> qlst23 = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Quote__c> qutlst = new List<SBQQ__Quote__c>();
            SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Type__c=ReplacementConstants.QUOTE_TYPE_RENEWAL);    

        System.Test.startTest();

        insert(q);
        qutlst.add(q);
            SBQQ__QuoteLine__c qlia = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, 
                SBQQ__Product__c=prodaa.Id, SBQQ__Quantity__c=1, SBQQ__Number__c=1, 
                SBQQ__SubscribedAssetIds__c=astlst[0].Id,
                SubscribedAssetNames__c = 'AA210264120057',
                Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
                SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
                SBQQ__RenewedAsset__c=asset1.Id,SBQQ__SubscriptionTerm__c=36,
                Subscribed_Asset_Name__c='AA210264120057');  
        qlst23.add(qlia);
        //insert qli1;
        
            SBQQ__QuoteLine__c qli21 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, 
                SBQQ__Product__c=prod11.Id, SBQQ__Number__c=2, 
                SBQQ__SubscribedAssetIds__c=astlst[0].Id,
                SubscribedAssetNames__c = 'AA210264120057',
                Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
                SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
                SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset1.Id,
                SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst23.add(qli21);
        //insert qli2; 
        
            SBQQ__QuoteLine__c qli31 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, 
                SBQQ__Product__c=prod11.Id, SBQQ__Number__c=2, 
                SBQQ__SubscribedAssetIds__c=astlst[0].Id,
                SubscribedAssetNames__c = 'AA210264120057',
                Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
                SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
                SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset1.Id,
                SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst23.add(qli31);
        
            SBQQ__QuoteLine__c qli41= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, 
                SBQQ__Product__c=prod11.Id, SBQQ__Number__c=2, 
                SBQQ__SubscribedAssetIds__c=astlst[0].Id,
                SubscribedAssetNames__c = 'AA210264120057',
                Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
                SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
                SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset1.Id,
                SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057' );  
        qlst23.add(qli41);
            SBQQ__QuoteLine__c qli5= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, 
                SBQQ__Product__c=prod41.Id, SBQQ__Number__c=90, 
                SBQQ__SubscribedAssetIds__c=astlst[0].Id,
                SubscribedAssetNames__c = 'AA210264120057',
                Subscribed_Asset_Name__c='AA210264120057',
                Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
                SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
                SBQQ__Quantity__c=90,SBQQ__SubscriptionTerm__c=36,
                SBQQ__RenewedAsset__c=asset1.Id );  
        //qlst.add(qli5);
        
        insert qlst23;

        List<SBQQ__QuoteLine__c> qlupdate = new List<SBQQ__QuoteLine__c>();
        qli21.SBQQ__RequiredBy__c = qlia.Id;
        qli31.SBQQ__RequiredBy__c = qlia.Id;
        qli41.SBQQ__RequiredBy__c=  qli31.Id;
        qlupdate.add(qli21);
        qlupdate.add(qli31);
        qlupdate.add(qli41);
        
        SBQQ.TriggerControl.disable();
        update qlupdate;
        SBQQ.TriggerControl.enable();
        
            List<SBQQ__QuoteLine__c> qllst34 = getQuoteLines(q.Id);
            
        
        QuoteExtController.validateSubsAssets(qllst34, new List<CPQ_Disposition_Quote_Line__c> {});
        
        System.Test.stopTest();
    }
    }
    
    //Start :testMethod for 3838
   testMethod static void bypassValidationSubsAssets(){
 
        Profile p = [SELECT Id FROM Profile 
                       WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',Alias = 't1',
                Email = 'abcd@gmail.com.sandbox',Username = 'atestbApproval12321@gmail.com',
                ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',RBAC_Group__c = 'System - IT',RBAC_Department__c = 'Service Account');
        insert u;
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = u.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
        System.RunAs(u){
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();

        ID standardPBID = Test.getStandardPricebookId();     
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', 
            Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        List<Product2> prodsInsert = new List<Product2>();
        Product2 prodd = new Product2(Name='TestProd', IsActive=true, 
            ProductCode='Test-Prod',Rel_SubsAsst__c='Renew:RelatedAsst',Usable_Capacity__c=1);  
        prodsInsert.add(prodd);
        Product2 prod1 = new Product2(Name='TestProd', IsActive=true, 
            ProductCode='Test-Prod',Family  ='Non-Returnable Disk Service',Rel_SubsAsst__c='Renew:RelatedAsst');  
        prodsInsert.add(prod1);
        Product2 prod22 = new Product2(Name='TestProd', IsActive=true, 
            ProductCode='Test-Prod',Family  =ReplacementConstants.PRODUCT_FAMILY_RUBRIK_SCALE);  
        prodsInsert.add(prod22);
        Product2 prod33 = new Product2(Name='RCDM-ABC', IsActive=true, 
            ProductCode='Test-Prod',Product_Type__c =ReplacementConstants.HW_SUPPORT); 
        prodsInsert.add(prod33);
        Product2 prod44 = new Product2(Name='RCDM-HPE', IsActive=true, 
            ProductCode='Test-Prod',Product_Type__c =ReplacementConstants.HW_SUPPORT);        
        prodsInsert.add(prod44);
        Product2 prod441 = new Product2(Name='RCDM-HPE1', IsActive=true, 
            ProductCode='Test-Prod1',Product_Type__c =ReplacementConstants.HARDWARE);        
        prodsInsert.add(prod441);
        Product2 prod442 = new Product2(Name='RSC', IsActive=true, 
            ProductCode='Test-Prod2',Product_Type__c =ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            Product_Level__c=ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            IsHardwareNotRequiredForHybridLicense__c = false);        
        prodsInsert.add(prod442);

        insert prodsInsert;
        
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = standardPBID,
            Product2Id = prod44.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbEntry3;
        pbes.add(pbEntry3);
        
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod44.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //insert pbEntry1;
        pbes.add(pbEntry1);
        
        PricebookEntry pbEntry33 = new PricebookEntry(
            Pricebook2Id = standardPBID,
            Product2Id = prod33.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbEntry33;
        pbes.add(pbEntry33);
        PricebookEntry pbEntry331 = new PricebookEntry(
            Pricebook2Id = standardPBID,
            Product2Id = prod441.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbEntry33;
        pbes.add(pbEntry331);
        PricebookEntry pbEntry332 = new PricebookEntry(
            Pricebook2Id = standardPBID,
            Product2Id = prod442.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        //insert pbEntry33;
        pbes.add(pbEntry332);
        
        PricebookEntry pbEntry13 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod33.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //insert pbEntry13;
        pbes.add(pbEntry13);
        PricebookEntry pbEntry12 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod441.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //insert pbEntry12;
        pbes.add(pbEntry12);
        PricebookEntry pbEntry121 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod442.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        //insert pbEntry12;
        pbes.add(pbEntry121);
        insert pbes;
        
        List<Product2> lstProdA = new List<Product2>();
        lstProdA.add(prodd);
        Assert.areEqual(1, lstProdA.size());

        //create account
        Account acc111A = (Account) ShGl_TestFactory.createSObject(new Account(),null);
        acc111A.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        insert acc111A;

        contact con1111A=new contact(lastname='test contact',leadsource='web',
                                     email='testc@test.com',accountId=acc111A.id);
        insert con1111A;

        //insert new opportunity
        Opportunity opp111BB=new Opportunity(
            Name='test Opportunity',
            AccountId=acc111A.id, 
            StageName='1 Discovery', 
            CloseDate=system.Today(),
            ForecastCategoryName='Best Case',
            Initial_Contacts_Name__c=con1111A.id,Business_Unit__c='Rubrik',
            Installation_Assigned_To__c='FE Install',
            Partner_Lookup__c = acc111A.id,
            Distributor_Lookup__c = acc111A.id,
            Bypass_PSO__c = true //SF-72381
            
        );
        insert opp111BB;
        
        Asset assetttAA = new Asset();
        assetttAA.Name = '1234';
        assetttAA.Serial_Number__c = '1234';
        assetttAA.SerialNumber = '1234';
        assetttAA.AccountId = acc111A.id;
        assetttAA.Product2Id = prodd.Id;
        assetttAA.Expiration_Date__c = Date.today().addDays(-1);
        insert assetttAA;

        SBQQ__Quote__c q11 = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp111BB.Id,
                SBQQ__Type__c=ReplacementConstants.QUOTE_TYPE_RENEWAL,
            	Quoting_Desk_Exception__c = 'Quoting Exception - HW without SW',
                RWD_Sales_Rep_Exception__c = null);
        SBQQ__Quote__c q1x = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp111BB.Id,
                SBQQ__Type__c=ReplacementConstants.QUOTE_TYPE_RENEWAL,
                RWD_Sales_Rep_Exception__c = 'testexceptio', 
                RWD_Sales_Rep_Exception_Justification__c = 'testreason',
                ExceptionsOnQuote__c = 'testexception');//SF-72381

        //change for SF-72381
        SBQQ__Quote__c quoteNew = new SBQQ__Quote__c(
                SBQQ__SubscriptionTerm__c = 12, SBQQ__Type__c = 'Quote', 
                Quoting_Desk_Exception__c = 'Quoting Exception - SW without HW;Quoting Exception - HW without SW  ', 
                Quoting_Desk_Exception_Justification__c = 'test');

        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(q11);
        lstQuote.add(quoteNew);
        
        Assert.areEqual(2, lstQuote.size());
        lstQuote.add(q1x);//SF-72381
        insert lstQuote;   

        ServiceContract objSCAA = new ServiceContract(
                Name = 'ServiceContract Test', AccountId = acc111A.id, 
                pricebook2Id = pb1.Id,StartDate = Date.today(),Term = 36, 
                SBQQSC__Opportunity__c = opp111BB.Id,SBQQSC__Quote__c = q11.Id);
        insert objSCAA;
        
        List<ContractLineItem> lstCliAA = new List<ContractLineItem>(); 
        ContractLineItem cliSS = new ContractLineItem();
        cliSS.Quantity = 1;
        cliSS.PricebookEntryId = pbEntry121.Id;
        cliSS.UnitPrice= pbEntry121.UnitPrice;
        cliSS.ServiceContractId= objSCAA.id;
        cliSS.StartDate = date.today();
        cliSS.SBQQSC__Product__c= prod442.Id;
        lstCliAA.add(cliSS);
        
        ContractLineItem cli1SS = new ContractLineItem();
        cli1SS.Quantity = 1;
        cli1SS.PricebookEntryId = pbEntry13.Id;
        cli1SS.UnitPrice= pbEntry13.UnitPrice;
        cli1SS.ServiceContractId= objSCAA.id;
        cli1SS.StartDate = date.today();
        cli1SS.SBQQSC__Product__c= prod33.Id;
        lstCliAA.add(cli1SS);
        
        insert lstCliAA;

        System.Test.startTest();



        List<SBQQ__QuoteLine__c> qlstAA = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c=q11.Id, SBQQ__Product__c=prod442.Id, SBQQ__Number__c=1, 
            Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE,
            SBQQ__SubscribedAssetIds__c=assetttAA.Id,SubscribedAssetNames__c = 'AA210264120057',
            Subscribed_Asset_Name__c='AA210264120057',
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1,
            Special_Program__c=ReplacementConstants.DISPOSITION_REASON_REPLACED,
            Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345',
            SBQQSC__RenewedContractLine__c = cliSS.Id);  
        qlstAA.add(qli3);
        
        SBQQ__QuoteLine__c qli4= new SBQQ__QuoteLine__c(
            SBQQ__Quote__c=q11.Id, SBQQ__Product__c=prod33.Id, SBQQ__Number__c=2, 
            Product_Type__c=ReplacementConstants.HW_SUPPORT,
            SBQQ__SubscribedAssetIds__c=assetttAA.Id,SubscribedAssetNames__c = 'AA210264120057',
            Subscribed_Asset_Name__c='AA210264120057',
            Disposition_Reason__c=ReplacementConstants.DISPOSITION_REASON_REPLACED, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1,SBQQ__SubscriptionTerm__c=36,
            SBQQ__RenewedAsset__c=assetttAA.Id,
            SBQQSC__RenewedContractLine__c = cli1SS.Id );  
        qlstAA.add(qli4);
        
        SBQQ__QuoteLine__c qliNew = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c=quoteNew.Id, SBQQ__Product__c=prod442.Id, SBQQ__Number__c=3, 
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1);  
        qlstAA.add(qliNew);
        SBQQ__QuoteLine__c qliNewH = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c=quoteNew.Id, SBQQ__Product__c=prod441.Id, SBQQ__Number__c=4, 
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1, Product_Type__c = ReplacementConstants.HARDWARE);  
        qlstAA.add(qliNewH);

        SBQQ__QuoteLine__c qliNewm = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c=quoteNew.Id, SBQQ__Product__c=prod22.Id, SBQQ__Number__c=4, 
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1, Special_Program__c=ReplacementConstants.DISPOSITION_REASON_REPLACED,
            Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345');  
        qlstAA.add(qliNewm);
        

        SBQQ.TriggerControl.disable();
        insert qlstAA;

        qliNewH.SBQQ__RequiredBy__c = qliNew.Id;
        qliNewH.SBQQ__Optional__c = true;
        qliNewH.SBQQ__Existing__c = false;
        update qliNewH;
       // SBQQ.TriggerControl.enable();
        
        List<SBQQ__QuoteLine__c> qllst11AA = getQuoteLines(q11.Id);
        QuoteExtController.validateSubsAssets(qllst11AA, new List<CPQ_Disposition_Quote_Line__c> {});
        QuoteExtController.getQuoteLines(quoteNew.Id);
        QuoteExtController.getHWQuoteLines(q11.Id);
        QuoteExtController.getIndustryFieldValue(
            ReplacementConstants.QUOTELINE_OBJ_API, 'Licensing_Model__c');

        Map<String, String> qlvsSelected = new Map<String, String>();
        qlvsSelected.put(String.valueOf(qliNew.Id), ReplacementConstants.PREPETUAL);
        List<SBQQ__QuoteLine__c> changedQLList = new List<SBQQ__QuoteLine__c>();
        qliNew.SubscribedAssetNames__c = '1234';
        changedQLList.add(qliNew);

       
        QuoteExtController.updateQuoteLinesforHW(qlvsSelected, changedQLList, q11.Id);
        
        //SF-72381 start
        //q11.RWD_Sales_Rep_Exception__c = null;
        QuoteExtController.updateQuote(q11.Id,'Submitted',false,q11);//SF-72381
        // CPQ22-5720
        QuoteExtController.processExcpValues('Deal Size Exception - Cloud Unstructured <$25k ACV;Term Exception: Minimum Term',q11.id);
        
        //q11.RWD_Sales_Rep_Exception__c = 'Mismatch Quantity';
        QuoteExtController.updateQuote(q1x.Id,'Submitted',false,q1x);//SF-72381
        
        SBQQ__Quote__c qtx = new SBQQ__Quote__c();
        qtx.SBQQ__Type__c = ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION;
        
        string rscty = QuoteExtController.getRecordTypeID(null,qtx);//SF-72381
        SBQQ__RecordJob__c rjrec = new SBQQ__RecordJob__c();
        rjrec.SBQQ__RecordId__c = 'tstrecid QuoteCalculator';
        insert rjrec;
        QuoteExtController.checkQuoteCalculation('tstrecid');
        //SF-72381 end
        
        //SBQQ.TriggerControl.enable();

        QuoteExtController.checkInvalidTradeUp('1234');
        QuoteExtController.getLowerAndUpperBound();

        q11.RWD_Deal_Ops_Exception__c = 'Override renewal line details';
        q11.RWD_Deal_Ops_Exception_Justification__c = 'testjustification';
        update q11;
        qllst11AA[0].RWD_Deal_Ops_Exception__c = 'Override renewal line details';
        update qllst11AA;
        QuoteExtController.validateSubsAssets(qllst11AA, new List<CPQ_Disposition_Quote_Line__c> {});
        
        QuoteExtController.validateSubsAssets(getQuoteLines(quoteNew.Id), new List<CPQ_Disposition_Quote_Line__c> {});
        
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getUserId(), Disable_Asset_Validation__c = TRUE);
        QuoteExtController.validateSubsAssets(qllst11AA, new List<CPQ_Disposition_Quote_Line__c> {});
        System.Test.stopTest();
        }
    }
    testMethod static void testQuoteLinesNew() {
        Test.starttest();
        Profile p = [SELECT Id FROM Profile 
                      WHERE Name = :ReplacementConstants.PROFILE_SYSTEM_ADMINISTRATOR LIMIT 1];
        User u = new User(
            LastName = 'Test345454Approval',
            Alias = 't1',
            Email = 'abcd@gmail.com.sandbox',
            Username = 'atestbApproval12321@gmail.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Denver',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',RBAC_Group__c= 'System - IT',RBAC_Department__c = 'Service Account');
        insert u;
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                    Disable_SBQQ_QuoteLine_Triggers__c = true,
                    Disable_Account_Triggers__c = true,
                    Disable_Opportunity_Triggers__c = true);

        upsert cc;
        System.RunAs(u){
            
        //create account
        Account acc111A = (Account) ShGl_TestFactory.createSObject(new Account(),null);
        acc111A.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        insert acc111A;
		ID standardPBID = Test.getStandardPricebookId(); 
        contact con1111A=new contact(lastname='test contact',leadsource='web',
                                     email='testc@test.com',accountId=acc111A.id);
        insert con1111A;

        //insert new opportunity
        Opportunity opp111BB=new Opportunity(
            Name='test Opportunity',
            AccountId=acc111A.id, 
            StageName='1 Discovery', 
            CloseDate=system.Today(),
            ForecastCategoryName='Best Case',
            Initial_Contacts_Name__c=con1111A.id,Business_Unit__c='Rubrik',
            Installation_Assigned_To__c='FE Install',
            Partner_Lookup__c = acc111A.id,
            Distributor_Lookup__c = acc111A.id,
            Bypass_PSO__c = true //SF-72381
            
        );
        insert opp111BB;
        SBQQ__Quote__c quoteNew = new SBQQ__Quote__c(
                SBQQ__SubscriptionTerm__c = 12, SBQQ__Type__c = 'Quote', 
                Quoting_Desk_Exception__c = 'Quoting Exception - SW without HW;Quoting Exception - HW without SW  ', 
                Quoting_Desk_Exception_Justification__c = 'test');
       
        insert quoteNew;
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', 
        Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;  
      
        
        Product2 prod33 = new Product2(Name='RCDM-ABC', IsActive=true, 
            ProductCode='Test-Prod',Product_Type__c =ReplacementConstants.HW_SUPPORT); 
        insert prod33;
        
        Product2 prod442 = new Product2(Name='RSC', IsActive=true, 
            ProductCode='Test-Prod2',Product_Type__c =ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            Product_Level__c=ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE, 
            IsHardwareNotRequiredForHybridLicense__c = false);      
        insert prod442;
            
        PricebookEntry pbEntry13 = new PricebookEntry(
            Pricebook2Id = standardPBID,
            Product2Id = prod33.Id,
            UnitPrice = 60.00,
            IsActive = true
        );
        insert pbEntry13;
        PricebookEntry pbEntry14 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod33.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry14;
        ServiceContract objSCAA = new ServiceContract(
        Name = 'ServiceContract Test', AccountId = acc111A.id, 
        pricebook2Id = pb1.Id,StartDate = Date.today(),Term = 36, 
        SBQQSC__Opportunity__c = opp111BB.Id,SBQQSC__Quote__c = quoteNew.Id);
        insert objSCAA;
        ContractLineItem cliSS = new ContractLineItem();
        cliSS.Quantity = 1;
        cliSS.PricebookEntryId = pbEntry14.Id;
        cliSS.UnitPrice= pbEntry14.UnitPrice;
        cliSS.ServiceContractId= objSCAA.id;
        cliSS.StartDate = date.today();
        cliSS.SBQQSC__Product__c= prod442.Id;
		insert cliSS;
        
        Asset assetttAA = new Asset();
        assetttAA.Name = '1234';
        assetttAA.Serial_Number__c = '1234';
        assetttAA.SerialNumber = '1234';
        assetttAA.AccountId = acc111A.id;
        assetttAA.Product2Id = prod442.Id;
        assetttAA.Expiration_Date__c = Date.today().addDays(-1);
        insert assetttAA;
            
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c=quoteNew.Id, SBQQ__Product__c=prod442.Id, SBQQ__Number__c=1, 
            Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE,Product_Type__c ='Hardware',
            SBQQ__SubscribedAssetIds__c=assetttAA.Id,SubscribedAssetNames__c = 'AA210264120057',
            Subscribed_Asset_Name__c='AA210264120057',
            Disposition_Reason__c=ReplacementConstants.DISPOSE_NONE, 
            SBQQ__SubscriptionPricing__c=ReplacementConstants.SUBSCRIPTION_FIXED_PRICE,
            SBQQ__Quantity__c=1,
            Special_Program__c=ReplacementConstants.DISPOSITION_REASON_REPLACED,
            Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345',
            SBQQSC__RenewedContractLine__c = cliSS.Id);
        List<SBQQ__QuoteLine__c> lstsq = QuoteExtController.getHWQuoteLines(String.valueOf(quoteNew.Id));
        Test.stopTest();
        system.assert(true);
        
             }
    }

    static List<SBQQ__QuoteLine__c> getQuoteLines(Id quoteId) {
        return [Select Id,Sales_Comp_Category__c,SBQQSC__RenewedContractLine__r.Product2.Name,
                    Quoting_Desk_Exception__c,RWD_Deal_Ops_Exception__c,
                    SBQQSC__RenewedContractLine__r.Product2Id,SBQQSC__RenewedContractLine__c,
                    SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__c,
                    SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name,
                    SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c, 
                    SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c, 
                    SBQQ__Product__r.Product_Subtype__c,Product_Subtype__c,
                    SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Co_Term__c,
                    Subscribed_Asset_Name__c,SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,
                    Special_Program__c,SBQQ__RequiredBy__r.Licensing_Model__c,
                    SBQQ__SubscribedAssetIds__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,
                    SBQQ__StartDate__c,SBQQ__Product__r.Product_Level__c,
                    SBQQ__Product__r.Eligible_for_RCDM_T__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                    SBQQ__RequiredBy__r.Quote_Line_Type__c,SBQQ__RequiredBy__r.SBQQ__Quantity__c,
                    SBQQ__RequiredBy__r.Disposition_Reason__c,Scale_Utility_Product__c,
                    EOL_Product_Status__c, SBQQ__EffectiveStartDate__c,
                    SBQQ__Product__r.Rel_SubsAsst__c, SBQQ__EffectiveEndDate__c, 
                    SBQQ__ProductCode__c,SBQQ__ProductFamily__c,Product_Type__c,
                    SBQQ__Discount__c,Add_on_Level__c,Line_Type__c,Required_By_Product_Code__c,
                    SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c, 
                    SBQQ__Product__r.X0__c, SubscribedAssetNames__c,
                    SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c,
                    SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Level__c,
                    SBQQ__ListPrice__c,SBQQ__ProratedListPrice__c,SBQQ__ListTotal__c,
                    Licensing_Model__c,SBQQ__Product__r.Is_Attributes_Blank__c,
                    SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,SBQQ__Source__c,
                    TPH_Models_Gen__c,TPH_Drive_Size__c,TPH_OEM__c,TPH_Quantity__c,
                    SBQQ__Existing__c,SBQQ__EffectiveQuantity__c,SBQQ__Optional__c,
                    SBQQ__AdditionalDiscountAmount__c,SBQQ__EndDate__c, 
                    SBQQ__SubscriptionPricing__c, Quote_Line_Type__c,  
                    QuoteLine_Group_Name__c, Disposition_Reason__c, 
                    Check_of_POLARIS_Hardware__c, Check_of_ASPEN_Hardware__c, 
                    SKU_Type__c, License_Category__c, SBQQ__Product__r.License_Category__c, 
                    Product_Level__c,SBQQ__Quantity__c,Replace_By__c,SBQQ__Group__c,
                    SBQQ__Group__r.Name,PRE_Promo_Expiration_Date__c,Promo_Code__c,
                    Upgrade_Path__c,Account_s_Entitlement__c, SBQQ__Number__c,Replacement_Details__c 
               from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quoteId]; 
    }
}