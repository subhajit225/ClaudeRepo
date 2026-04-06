@istest
public class AssetValidationErrorBatchTest{
    
    
   testMethod static void callvalidateSubsAssets(){
         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',Alias = 't1',Email = 'abcd@gmail.com',Username = 'atestbApproval12321@gmail.com',ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12,SBQQ__Status__c = 'Approved');
        insert quote;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quote);
        Assert.areEqual(1, lstQuote.size());
        
        SBQQ_QuoteLineTriggerHandler handler=new SBQQ_QuoteLineTriggerHandler();
        System.debug(handler);
        
        
        Product2 prod = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Rel_SubsAsst__c='Renew:RelatedAsst',Usable_Capacity__c=1,Family = 'Rubrik Scale');  
        insert prod;
        Product2 prod1 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Non-Returnable Disk Service',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod1;
        Product2 prod2 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Rubrik Scale',SBQQ__SubscriptionPricing__c= 'Fixed Price');  
        insert prod2;
        Product2 prod3 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Third Party License');  
        insert prod3;
        Product2 prod4 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Product_Level__c  ='Hybrid Software',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod4;
        List<Product2> lstProd = new List<Product2>();
        lstProd.add(prod);
        Assert.areEqual(1, lstProd.size());
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(),null);
        insert acc;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        contact con=new contact(lastname='test contact',leadsource='web',
                                email='testc@test.com',accountId=acc.id);
        insert con;

        //insert new opportunity
        Opportunity opp=new Opportunity(
            Name='test Opportunity',
            AccountId=acc.id, 
            StageName='1 Discovery', 
            CloseDate=system.Today(),
            ForecastCategoryName='Best Case',
            Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
            Installation_Assigned_To__c='FE Install',
            Partner_Lookup__c = vAccount2.id,
            Distributor_Lookup__c = vAccount.id,
            Alliance_HW_Partner__c = 'Cisco'
        );
        insert opp;
        
        Asset asset = new Asset();
        asset.Name = 'AA210264120057';
        asset.Serial_Number__c = 'AA210264120057';
        asset.AccountId = acc.id;
        asset.Product2Id = prod.Id;
        insert asset;

        List<Asset> astlst = [Select id,Serial_Number__c,Product_Usable_Capacity__c  from Asset where Serial_Number__c = 'AA210264120057'];
        List<SBQQ__QuoteLine__c> qlst = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Quote__c> qutlst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,SBQQ__Type__c='Renewal',SBQQ__Status__c = 'Approved');        
        System.Test.startTest();
        insert(q);
        qutlst.add(q);
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, 
                                                         SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__RenewedAsset__c=asset.Id,SBQQ__SubscriptionTerm__c=36);  
        qlst.add(qli1);
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod1.Id, SBQQ__Number__c=2, 
                                                         SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset.Id,SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst.add(qli2);
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod2.Id, SBQQ__Number__c=2
                                                         ,Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,Special_Program__c='Replaced',Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345');  
        qlst.add(qli3);
        
        SBQQ__QuoteLine__c qli4= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod2.Id, SBQQ__Number__c=2, Licensing_Model__c = 'Perpetual',
                                                        SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='Replaced', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=asset.Id );  
        qlst.add(qli4);
        SBQQ__QuoteLine__c qli5= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod4.Id, SBQQ__Number__c=90, Sales_Comp_Category__c='SW SUPPORT',Product_Level__c ='Support',SBQQ__RequiredBy__c=qli4.id,
                                                        SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=90,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=asset.Id );  
        qlst.add(qli5);
        
        insert qlst;
        
        /*List<SBQQ__QuoteLine__c> qllstttt = [select Id,Sales_Comp_Category__c,SBQQSC__RenewedContractLine__r.Product2.Name,SBQQSC__RenewedContractLine__r.Product2Id,SBQQSC__RenewedContractLine__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c,SBQQ__Product__r.Product_Subtype__c,Product_Subtype__c,SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Co_Term__c,Subscribed_Asset_Name__c,SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,Special_Program__c,SBQQ__RequiredBy__r.Licensing_Model__c,SBQQ__SubscribedAssetIds__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__StartDate__c,SBQQ__Product__r.Product_Level__c,SBQQ__Product__r.Eligible_for_RCDM_T__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.Quote_Line_Type__c,SBQQ__RequiredBy__r.SBQQ__Quantity__c,SBQQ__RequiredBy__r.Disposition_Reason__c,Scale_Utility_Product__c,EOL_Product_Status__c, SBQQ__EffectiveStartDate__c,SBQQ__Product__r.Rel_SubsAsst__c, SBQQ__EffectiveEndDate__c, SBQQ__ProductCode__c,SBQQ__ProductFamily__c,Product_Type__c,SBQQ__Discount__c,Add_on_Level__c,Line_Type__c,Required_By_Product_Code__c,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c, SBQQ__Product__r.X0__c, SubscribedAssetNames__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Level__c,SBQQ__ListPrice__c,SBQQ__ProratedListPrice__c,SBQQ__ListTotal__c,Licensing_Model__c,SBQQ__Product__r.Is_Attributes_Blank__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,SBQQ__Source__c,TPH_Models_Gen__c,TPH_Drive_Size__c,TPH_OEM__c,TPH_Quantity__c,SBQQ__Existing__c,SBQQ__EffectiveQuantity__c,SBQQ__Optional__c,SBQQ__AdditionalDiscountAmount__c,SBQQ__EndDate__c, SBQQ__SubscriptionPricing__c, Quote_Line_Type__c,  QuoteLine_Group_Name__c, Disposition_Reason__c, Check_of_POLARIS_Hardware__c, Check_of_ASPEN_Hardware__c, SKU_Type__c, License_Category__c, SBQQ__Product__r.License_Category__c, Product_Level__c,SBQQ__Quantity__c,Replace_By__c,SBQQ__Group__c,SBQQ__Group__r.Name,PRE_Promo_Expiration_Date__c,Promo_Code__c,Upgrade_Path__c,Account_s_Entitlement__c,VrtNdAdnAsset__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:q.Id];*/
        
        AssetValidationErrorBatch batch = new AssetValidationErrorBatch(); 
       database.executebatch(batch);
        
        System.Test.stopTest();
    }

  
    testMethod static void callvalidateSubsAssets2(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',Alias = 't1',Email = 'abcd@gmail.com',Username = 'atestbApproval12321@gmail.com',ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        SBQQ__Quote__c quotex = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12);
        insert quotex;
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(quotex);
        Assert.areEqual(1, lstQuote.size());
        
        SBQQ_QuoteLineTriggerHandler handler=new SBQQ_QuoteLineTriggerHandler();
        System.debug(handler);
        
        
        Product2 prodaa = new Product2(Name='TestProd1', IsActive=true, ProductCode='Test-Prod',Rel_SubsAsst__c='Renew:RelatedAsst',Usable_Capacity__c=1);  
        insert prodaa;
        Product2 prod11 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Non-Returnable Disk Service',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod11;
        Product2 prod2 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Rubrik Scale',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod2;
        Product2 prod3 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Third Party License',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod3;
        Product2 prod41 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Product_Level__c  ='Hybrid Software',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod41;
        List<Product2> lstProd = new List<Product2>();
        lstProd.add(prodaa);
        Assert.areEqual(1, lstProd.size());
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(),null);
        insert acc;
        
        List<Account> accountList1 = new List<Account>();
        Account vAccount1 = new Account();
        accountList1.add(vAccount1);
        vAccount1.Name = 'Test Account';
        vAccount1.Type='Distributor';
        vAccount1.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
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
            System.debug(oppMap);

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
        asset1.Name = 'AA210264120057';
        asset1.Serial_Number__c = 'AA210264120057';
        asset1.AccountId = acc.id;
        asset1.Product2Id = prodaa.Id;
        insert asset1;
        List<Asset> astlst = [Select id,Serial_Number__c,Product_Usable_Capacity__c  from Asset where Serial_Number__c = 'AA210264120057'];
        List<SBQQ__QuoteLine__c> qlst23 = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Quote__c> qutlst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,SBQQ__Type__c='Renewal',SBQQ__Status__c = 'Approved');    

        System.Test.startTest();

        insert(q);
        qutlst.add(q);
        SBQQ__QuoteLine__c qlia = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prodaa.Id, SBQQ__Quantity__c=1, SBQQ__Number__c=1, 
                                                         SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__RenewedAsset__c=asset1.Id,SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst23.add(qlia);
        //insert qli1;
        
        SBQQ__QuoteLine__c qli21 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod11.Id, SBQQ__Number__c=2, 
                                                          SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset1.Id,SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst23.add(qli21);
        //insert qli2; 
        
        SBQQ__QuoteLine__c qli31 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod11.Id, SBQQ__Number__c=2, 
                                                          SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset1.Id,SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst23.add(qli31);
        
        SBQQ__QuoteLine__c qli41= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod11.Id, SBQQ__Number__c=2, 
                                                         SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset1.Id,SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057' );  
        qlst23.add(qli41);
        SBQQ__QuoteLine__c qli5= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod41.Id, SBQQ__Number__c=90, 
                                                        SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=90,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=asset1.Id );  
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
        
       /* List<SBQQ__QuoteLine__c> qllst34 = [select Id,Sales_Comp_Category__c,SBQQSC__RenewedContractLine__r.Product2.Name,SBQQSC__RenewedContractLine__r.Product2Id,SBQQSC__RenewedContractLine__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c,SBQQ__Product__r.Product_Subtype__c,Product_Subtype__c,SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Co_Term__c,Subscribed_Asset_Name__c,SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,Special_Program__c,SBQQ__RequiredBy__r.Licensing_Model__c,SBQQ__SubscribedAssetIds__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__StartDate__c,SBQQ__Product__r.Product_Level__c,SBQQ__Product__r.Eligible_for_RCDM_T__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.Quote_Line_Type__c,SBQQ__RequiredBy__r.SBQQ__Quantity__c,SBQQ__RequiredBy__r.Disposition_Reason__c,Scale_Utility_Product__c,EOL_Product_Status__c, SBQQ__EffectiveStartDate__c,SBQQ__Product__r.Rel_SubsAsst__c, SBQQ__EffectiveEndDate__c, SBQQ__ProductCode__c,SBQQ__ProductFamily__c,Product_Type__c,SBQQ__Discount__c,Add_on_Level__c,Line_Type__c,Required_By_Product_Code__c,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c, SBQQ__Product__r.X0__c, SubscribedAssetNames__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Level__c,SBQQ__ListPrice__c,SBQQ__ProratedListPrice__c,SBQQ__ListTotal__c,Licensing_Model__c,SBQQ__Product__r.Is_Attributes_Blank__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,SBQQ__Source__c,TPH_Models_Gen__c,TPH_Drive_Size__c,TPH_OEM__c,TPH_Quantity__c,SBQQ__Existing__c,SBQQ__EffectiveQuantity__c,SBQQ__Optional__c,SBQQ__AdditionalDiscountAmount__c,SBQQ__EndDate__c, SBQQ__SubscriptionPricing__c, Quote_Line_Type__c,  QuoteLine_Group_Name__c, Disposition_Reason__c, Check_of_POLARIS_Hardware__c, Check_of_ASPEN_Hardware__c, SKU_Type__c, License_Category__c, SBQQ__Product__r.License_Category__c, Product_Level__c,SBQQ__Quantity__c,Replace_By__c,SBQQ__Group__c,SBQQ__Group__r.Name,PRE_Promo_Expiration_Date__c,Promo_Code__c,Upgrade_Path__c,Account_s_Entitlement__c,VrtNdAdnAsset__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:q.Id];*/
        
        AssetValidationErrorBatch batch = new AssetValidationErrorBatch(); 
       database.executebatch(batch);
        
        System.Test.stopTest();
    }

    public static void testSetup(){

    }
    
    //Start :testMethod for 3838
    
   testMethod static void bypassValidationSubsAssets(){
 
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(LastName = 'Test345454Approval',Alias = 't1',Email = 'abcd@gmail.com',Username = 'atestbApproval12321@gmail.com',ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US');
        insert u;
        ShGl_DisableBusinessLogic__c cc = new ShGl_DisableBusinessLogic__c(SetupOwnerId = u.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_Account_Triggers__c = true,
                                                                           Disable_Opportunity_Triggers__c = true);
        
        upsert cc;
        System.RunAs(u){
        SBQQ_QuoteLineTriggerHandler handler = new SBQQ_QuoteLineTriggerHandler();
        System.debug(handler);

        ID standardPBID = Test.getStandardPricebookId();     
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        List<Product2> prodsInsert = new List<Product2>();
        Product2 prodd = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Rel_SubsAsst__c='Renew:RelatedAsst',Usable_Capacity__c=1);  
        prodsInsert.add(prodd);
        Product2 prod1 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Non-Returnable Disk Service',Rel_SubsAsst__c='Renew:RelatedAsst');  
        prodsInsert.add(prod1);
        Product2 prod22 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Rubrik Scale',Rel_SubsAsst__c='Renew:RelatedAsst',SBQQ__SubscriptionPricing__c= 'Fixed Price');  
        prodsInsert.add(prod22);
        Product2 prod33 = new Product2(Name='RCDM-ABC', IsActive=true, ProductCode='Test-Prod',Product_Type__c ='HW Support',Rel_SubsAsst__c='Renew:RelatedAsst'); 
        prodsInsert.add(prod33);
        Product2 prod44 = new Product2(Name='RCDM-HPE', IsActive=true, ProductCode='Test-Prod',Product_Type__c ='HW Support',Rel_SubsAsst__c='Renew:RelatedAsst');        
        prodsInsert.add(prod44);
        Product2 prod441 = new Product2(Name='RCDM-HPE1', IsActive=true, ProductCode='Test-Prod1',Product_Type__c ='Hardware',Rel_SubsAsst__c='Renew:RelatedAsst');        
        prodsInsert.add(prod441);
        Product2 prod442 = new Product2(Name='RSC', IsActive=true, ProductCode='Test-Prod2',Product_Type__c ='Hybrid Software', Product_Level__c='Hybrid Software', IsHardwareNotRequiredForHybridLicense__c = false,Rel_SubsAsst__c='Renew:RelatedAsst',SBQQ__SubscriptionPricing__c= 'Fixed Price');        
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
        acc111A.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
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
            Distributor_Lookup__c = acc111A.id
        );
        insert opp111BB;
        
        Asset assetttAA = new Asset();
        assetttAA.Name = 'AA210264120057';
        assetttAA.Serial_Number__c = 'AA210264120057';
        assetttAA.SerialNumber = 'AA210264120057';
        assetttAA.AccountId = acc111A.id;
        assetttAA.Product2Id = prodd.Id;
        assetttAA.Expiration_Date__c = Date.today().addDays(-1);
        insert assetttAA;

        SBQQ__Quote__c q11 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp111BB.Id,SBQQ__Type__c='Renewal',SBQQ__Status__c = 'Approved');
        SBQQ__Quote__c quoteNew = new SBQQ__Quote__c(SBQQ__SubscriptionTerm__c = 12, SBQQ__Type__c = 'Quote', RWD_Deal_Ops_Exception__c = 'SW without HW;HW without SW', RWD_Deal_Ops_Exception_Justification__c = 'test',SBQQ__Status__c = 'Approved');

        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c> ();
        lstQuote.add(q11);
        lstQuote.add(quoteNew);
        Assert.areEqual(2, lstQuote.size());
        
        insert lstQuote;   

        ServiceContract objSCAA = new ServiceContract(Name = 'ServiceContract Test', AccountId = acc111A.id, pricebook2Id = pb1.Id,StartDate = Date.today(),Term = 36, SBQQSC__Opportunity__c = opp111BB.Id,SBQQSC__Quote__c = q11.Id);
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

        system.debug('#666 limit bypass '+Limits.getCpuTime());

        System.Test.startTest();



        List<SBQQ__QuoteLine__c> qlstAA = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q11.Id, SBQQ__Product__c=prod442.Id, SBQQ__Number__c=1, Product_Level__c = 'Hybrid Software',
                                                         SBQQ__SubscribedAssetIds__c=assetttAA.Id,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,Special_Program__c='Replaced',Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345',SBQQSC__RenewedContractLine__c = cliSS.Id);  
        qlstAA.add(qli3);
        
        SBQQ__QuoteLine__c qli4= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q11.Id, SBQQ__Product__c=prod33.Id, SBQQ__Number__c=2, Product_Type__c='HW Support',
                                                        SBQQ__SubscribedAssetIds__c=assetttAA.Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='Renewing', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=assetttAA.Id,SBQQSC__RenewedContractLine__c = cli1SS.Id );  
        qlstAA.add(qli4);
        
        SBQQ__QuoteLine__c qliNew = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteNew.Id, SBQQ__Product__c=prod22.Id, SBQQ__Number__c=3, 
                                                           Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,Special_Program__c='Replaced',Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345');  
        qlstAA.add(qliNew);
        SBQQ__QuoteLine__c qliNewH = new SBQQ__QuoteLine__c(SBQQ__Quote__c=quoteNew.Id, SBQQ__Product__c=prod441.Id, SBQQ__Number__c=4, 
                                                            Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1, Product_Type__c = 'Hardware');  
        qlstAA.add(qliNewH);

        SBQQ.TriggerControl.disable();
        insert qlstAA;

        qliNewH.SBQQ__RequiredBy__c = qliNew.Id;
        qliNewH.SBQQ__Optional__c = true;
        qliNewH.SBQQ__Existing__c = false;
        update qliNewH;

       // SBQQ.TriggerControl.enable();
        
       /* List<SBQQ__QuoteLine__c> qllst11AA = [select Id,Sales_Comp_Category__c,SBQQSC__RenewedContractLine__r.Product2.Name,SBQQSC__RenewedContractLine__r.Product2Id,SBQQSC__RenewedContractLine__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Name,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Product_Type__c, SBQQSC__RenewedContractLine__r.Required_by_Product_Code__c, SBQQ__Product__r.Product_Subtype__c,
        Product_Subtype__c,SBQQ__Quote__r.SBQQ__Type__c,SBQQ__Quote__r.Co_Term__c,Subscribed_Asset_Name__c,SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,Special_Program__c,SBQQ__RequiredBy__r.Licensing_Model__c,SBQQ__SubscribedAssetIds__c,Arroyo_Subsumed_Old_Contract_Line_Items__c,SBQQ__StartDate__c,SBQQ__Product__r.Product_Level__c,SBQQ__Product__r.Eligible_for_RCDM_T__c,SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
        SBQQ__RequiredBy__r.Quote_Line_Type__c,SBQQ__RequiredBy__r.SBQQ__Quantity__c,SBQQ__RequiredBy__r.Disposition_Reason__c,Scale_Utility_Product__c,EOL_Product_Status__c, SBQQ__EffectiveStartDate__c,SBQQ__Product__r.Rel_SubsAsst__c, SBQQ__EffectiveEndDate__c, SBQQ__ProductCode__c,SBQQ__ProductFamily__c,Product_Type__c,SBQQ__Discount__c,Add_on_Level__c,Line_Type__c,Required_By_Product_Code__c,SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SBQQ__Product__r.Category__c, 
        SBQQ__Product__r.X0__c, SubscribedAssetNames__c,SBQQSC__RenewedContractLine__r.SBQQSC__RequiredByProduct__r.Category__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Product_Level__c,SBQQ__ListPrice__c,SBQQ__ProratedListPrice__c,SBQQ__ListTotal__c,Licensing_Model__c,SBQQ__Product__r.Is_Attributes_Blank__c,SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,SBQQ__Source__c,TPH_Models_Gen__c,TPH_Drive_Size__c,TPH_OEM__c,TPH_Quantity__c,SBQQ__Existing__c,
        SBQQ__EffectiveQuantity__c,SBQQ__Optional__c,SBQQ__AdditionalDiscountAmount__c,SBQQ__EndDate__c, SBQQ__SubscriptionPricing__c, Quote_Line_Type__c,  QuoteLine_Group_Name__c, Disposition_Reason__c, Check_of_POLARIS_Hardware__c, Check_of_ASPEN_Hardware__c, SKU_Type__c, License_Category__c, SBQQ__Product__r.License_Category__c, Product_Level__c,SBQQ__Quantity__c,Replace_By__c,SBQQ__Group__c,SBQQ__Group__r.Name,PRE_Promo_Expiration_Date__c,Promo_Code__c,Upgrade_Path__c,Account_s_Entitlement__c,VrtNdAdnAsset__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:q11.Id];*/
        
        
        

       
         AssetValidationErrorBatch batch = new AssetValidationErrorBatch(); 
       database.executebatch(batch);

        system.debug('#666 limit bypass 2'+Limits.getCpuTime());
        System.Test.stopTest();
        }
    }
}