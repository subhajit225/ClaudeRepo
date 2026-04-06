/**test class for findRenewedServiceContracts */
@isTest
public class findRenewedServiceContractsTest {
    
    static testMethod void getRenewedServiceContractsTest(){
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<Account> accList = new List<Account>();
        accList.add(acc);
        Assert.areEqual(1, accList.size());
        
        Opportunity opp= new Opportunity(Name = 'Test Opp', OwnerID = UserInfo.getUserId(), AccountId = acc.Id, Stagename ='Approved', 
                                         Amount = 1000, Lead_Email_Hidden__c = 'test@email.com', CloseDate = Date.today());
        insert opp;
        
        Opportunity tempOpp= new Opportunity(Name = 'Temp Opp', OwnerID = UserInfo.getUserId(), AccountId=acc.id, Stagename = 'Approved',
                                             Amount = 1000, Lead_Email_Hidden__c = 'test@email.com', CloseDate = Date.today());
        insert tempOpp;
                            
        ServiceContract testContract = new ServiceContract();
        testContract.AccountId = acc.id;
        testContract.SBQQSC__RenewalOpportunityRecordTypeId__c = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
        testContract.Name = 'Case Instrument Contract Test- Contract';
        testContract.StartDate = System.today()+10;
        testContract.Term = 24;
        testContract.SBQQSC__RenewalTerm__c = 24;
        insert testContract;
        
        Order ordr = new Order(Type='Revenue' ,  AccountId= acc.Id,OpportunityId =tempopp.Id,ShippingStreet ='Test Street',
                               ShippingCity ='Test City', ShippingState ='California', ShippingCountry ='United States',
                               ShippingPostalcode ='94820', EffectiveDate=system.Today(), Order_Status__c = 'Pending');
        insert ordr;
         
        testContract.SBQQSC__RenewalOpportunity__c = tempopp.Id;
        testContract.SBQQSC__Order__c = ordr.Id;
        update testContract;
         
        test.startTest();
        findRenewedServiceContracts className = new findRenewedServiceContracts();
        List<ServiceContract> lstContract = className.getRenewedServiceContracts();
  System.debug(className);
  System.debug(lstContract);
        test.stopTest();
    }
}