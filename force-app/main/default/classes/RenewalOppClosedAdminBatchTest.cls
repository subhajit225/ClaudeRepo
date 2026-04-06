/**
* @description Test class for RenewalOppClosedAdminBatch
**/
@isTest
public class RenewalOppClosedAdminBatchTest {
    @testSetup static void methodName() {
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        FlowControll.opportunityTriggerHandler = false;
        FlowControll.accountTrigger = false;
        FlowControll.opportunityLineItemHandler = false;
        
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
         
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        oppr.RecordtypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        insert oppr;
        
        Opportunity oppr1 = TestDataFactory.getOpportunity(accObj);
        oppr.RecordtypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        oppr1.Closed_Admin_Opporutinty__c='Partial Replacement';
        insert oppr1;
        
        Product2 productObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productObj.ProductCode = 'RBH-SVC-test-product';
        productObj.Product_Subtype__c = 'GO';
        productObj.Name = 'RBH-SVC-test-product';
        productObj.IsActive = true;
        insert productObj;
        
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = productObj.Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        insert pricebookObj;
        
        Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        assetObj.AccountId = accObj.Id;
        assetObj.Name = 'EntitlementTriggerHelperAsset';
        assetObj.Product2Id = productObj.Id;
        assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
        assetObj.serial_number__c = 'JAY8486304222k4';
        insert assetObj;
        
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper ContractA';
        serviceContractObj1.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj1.AccountId = accObj.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        insert serviceContractObj1;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(
          new ContractLineItem(),
          null
        );
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.AssetId = assetObj.Id;
        ContractLineItemObj.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj1.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        
        oppr.SBQQSC__RenewedServiceContract__c = serviceContractObj1.Id;
        update oppr;
        oppr1.SBQQSC__RenewedServiceContract__c = serviceContractObj1.Id;
        update oppr1;

        OpportunityLineItem oppProduct = new OpportunityLineItem();
        oppProduct.OpportunityId = oppr1.Id;
        oppProduct.Quantity = 100;
        oppProduct.Product2Id= productObj.Id;
        oppProduct.Amended_Service_Contract_Id_Text__c =serviceContractObj1.Id;
        oppProduct.ContractLine_Id__c =  ContractLineItemObj.Id;
        oppProduct.pricebookentryid=pricebookObj.Id;
        oppProduct.TotalPrice=100*200;
        Insert oppProduct;
  }
    static testMethod void testmethod1(){
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
        Test.startTest();
        Database.executebatch(new RenewalOppClosedAdminBatch());
        Test.stopTest();
        List<opportunity>oppr=[select id,name from opportunity LIMIT 20];
            system.assertNotEquals(oppr[0].Id, null);
        }
    }
    static testMethod void testmethod2(){
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            ShGl_DisableBusinessLogic__c sdbl = new ShGl_DisableBusinessLogic__c(
                setupownerid = usr1.Id,
                Disable_Opportunity_Validation_Rules__c = false,
                Enable_Logs__c = true
            );
            insert sdbl;    
            
            Test.startTest();
            Database.executebatch(new RenewalOppClosedAdminBatch());
            Test.stopTest();
            List<opportunity> oppr=[select id,name from opportunity LIMIT 20];
            system.debug(LoggingLevel.DEBUG, oppr);
            system.assertNotEquals(oppr[0].Id, null);
        }
    }
}