@isTest
public class ServiceContractAmend_LtngControllerTest {

    testMethod static void testServiceContractAmendLtng() {
        ServiceContractAmend_LtngController.checkAmendmentPermission();
    }
    @IsTest
    static void validateOppOnCloseDateTest(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        System.runAs(listUser[0]) 
        {
        Id standardPriceBookId =  Test.getStandardPricebookId();
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            IsActive = true,
            SBQQ__SubscriptionTerm__c = 1
        );
        insert new List<Product2>{prod1};
         PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 200.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1,pbEntry1}; 
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity oppr = TestDataFactory.getOpportunity(acc);
        oppr.Opportunity_Sub_Type__c = 'GC Offer';
        insert oppr;
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => acc.Id,'SBQQ__Opportunity2__c' => oppr.Id};
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Amendment';
        qt1.SBQQ__StartDate__c = Date.Today();
        insert qt1;
          Order orderInstanceNew = new Order();
            orderInstanceNew.AccountId = acc.Id;
            orderInstanceNew.OpportunityId = oppr.Id;
            orderInstanceNew.EffectiveDate = system.today();  
            orderInstanceNew.Status = 'Draft';
            orderInstanceNew.Type = 'Revenue';
            orderInstanceNew.Order_Sub_Type__c = 'GC Offer';
            orderInstanceNew.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstanceNew;
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        ServiceContract serviceContractObj1 = new ServiceContract();
        serviceContractObj1.Name = 'EntitlementTriggerHelper ContractA';
        serviceContractObj1.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj1.AccountId = acc.Id;
        serviceContractObj1.SBQQSC__Order__c= orderInstanceNew.Id;
        serviceContractObj1.StartDate = System.today();
        serviceContractObj1.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj1.Term = 36;
        lstServiceContract.add(serviceContractObj1);
        insert lstServiceContract;
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = acc.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
        ServiceContractAmend_LtngController.checkOrderTypeMethod(lstServiceContract[0].id);
  }

}
}