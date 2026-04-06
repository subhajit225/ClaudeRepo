@isTest
public with sharing class DsaasConversionControllerTest {
    /***********************************************************************************************************
    * Method Name          : testVerbDisp
    * Date Created/Modified: 31/07/2025
    * @description         : Test conversion
    /**********************************************************************************************************/
    
    public static testMethod void testVerbDisp(){
        /*User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;*/
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User usr1 = new User(LastName = 'Test345454Approval',Alias = 't1',Email = 'abcd@gmail.com',Username = 'atestbApproval12321@gmail.com',ProfileId = p.Id,TimeZoneSidKey = 'America/Denver',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US');
        insert usr1;

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        disableLogic.Name = 'System Administrator';   
        disableLogic.Disable_Opportunity_Validation_Rules__c = TRUE; 

        insert disableLogic;
        System.runAs(usr1)  {
        //insert Account
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='TestAccount', RecordTypeId = partnerRecordTypeId);
        insert acct;
        
//insert Opportunity
        Date closeDt = System.Today()+30;
        opportunity oppr = new opportunity(Name='Test Dsaas conversion' , Sell_to_Partner__c = acct.Id,  AccountId= acct.Id, StageName = '1 Discovery',
                                            CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon', 
                                            Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                            Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                            Identified_Pain__c = 'Test', Champion__c = 'Test', Why_Rubrik__c = 'Why_Rubrik',
                                            Why_do_anything__c = 'Why_do_anything', Why_now__c = 'Why_now', //Alliance_HW_Partner__c = 'Cisco', 
                                            Partner_Representative__c = 'Test');
        insert oppr;
//      

        Id standardPriceBookId = Test.getStandardPricebookId();//pb2Standard.Id;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> lstProducts = new List<Product2>{
            new Product2(Name = 'Product XY', ProductCode = 'Pro-XY', isActive = true,Custom_Renewal_Type__c = 'DSAAS'),
            new Product2(Name = 'Product XX', ProductCode = 'Pro-XX', isActive = true),
            new Product2(Name = 'Product RCV', ProductCode = 'Pro-RCV', isActive = true, Product_Type__c = 'Cloud Vault Backup') ,
            new Product2(Name ='Product RCVTest',ProductCode ='Pro-RCVTest',isActive = true, Custom_Renewal_Type__c = 'DSAAS', Product_Type__c ='Cloud Vault Backup', Is_Split_in_Polaris_2_0__c =true )
        };

        insert lstProducts;

        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true) ,
            new PricebookEntry(Pricebook2Id =pricebookId, Product2Id =lstProducts[3].Id, UnitPrice = 100.00, IsActive = true)
        };
        
        insert lstPricebooks;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppr.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Renewal',
            Quoting_Desk_Exception_Justification__c = 'DSAAS conversion',
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
              
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = acct.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        renewServiceContractObj.SBQQSC__Quote__c = quote.Id;
        renewServiceContractObj.EndDate = System.today().addDays(360);
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = acct.Id;
        ContractLineItemObj.SBQQSC__Product__c = lstProducts[0].Id;
        ContractLineItemObj.PricebookEntryId = lstPricebooks[0].Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj;

        ContractLineItem ContractLineItemObj1 =(ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c =acct.Id;
        ContractLineItemObj1.SBQQSC__Product__c =lstProducts[3].Id;
        ContractLineItemObj1.PricebookEntryId =lstPricebooks[3].Id;
        ContractLineItemObj1.ServiceContractId =lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity =10;
        ContractLineItemObj1.UnitPrice =100;
        ContractLineItemObj1.StartDate =Date.Today().addmonths(-29);
        ContractLineItemObj1.EndDate =Date.Today().addmonths(6);
        ContractLineItemObj1.SBQQSC__RenewalQuantity__c =1;
        ContractLineItemObj1.SBQQSC__RootId__c =lstServiceContract[0].Id;
        insert ContractLineItemObj1 ;
        
                
        test.startTest();

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, Product_Type__c = 'Enterprise Edition',SubscribedAssetNames__c='testAsset', Usable_Capacity__c = 30, SBQQ__Product__c = lstProducts[1].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, GPL__c='NetApp',SBQQ__SubscriptionTerm__c=12, Disposition_Reason__c = 'Renew Now',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, Product_Type__c = 'Cloud Vault Backup',SBQQ__RequiredBy__c = lines[0].id, SubscribedAssetNames__c='testAsset', Usable_Capacity__c = 30, SBQQ__Product__c = lstProducts[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, GPL__c='NetApp',SBQQ__SubscriptionTerm__c=12, Disposition_Reason__c = 'Renew Now',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id));
        lines.add( new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, Product_Type__c ='Cloud Vault Backup', SubscribedAssetNames__c='testAsset', Usable_Capacity__c = 30, SBQQ__Product__c = lstProducts[3].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price',SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, GPL__c='NetApp',SBQQ__SubscriptionTerm__c=12, Disposition_Reason__c = 'Renew Now',SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id ));
        
        upsert lines;
        System.assert(lines.size()>0);

        ApexPages.currentPage().getParameters().put('qid',quote.Id);
        DsaasConversionController   inst = new DsaasConversionController();
        inst.init();
        Test.stopTest();
     } // run as end
     } //method end
}