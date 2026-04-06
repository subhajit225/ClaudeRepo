@isTest(seealldata =true)
public class ServiceContractMain_Test {
    
    static TriggerControl__c getTriggerControl(){
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c=true;
        return tc;
    }
    
    static testMethod void testSCcreation(){
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr1 = new user(
            alias = 'std',
            email = 'testuser@testclass.com.invalid',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName
        );
        insert usr1;
        System.runAs(usr1) {
            
            TriggerControl__c triggerCntlr= getTriggerControl();
            //insert triggerCntlr;
            Account acc= [select id , name from Account LIMIT 1];
            //insert Acc;
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            
            Account ACCT = new Account(Name='Test Account', RecordTypeId = partnerRecordTypeId ,Phone='123-456-7890', AccountNumber='Test',
                                       BillingStreet = '123 street', BillingCity = 'Santa Clara', BillingState = 'California', BillingPostalCode = '95050', BillingCountry = 'United States');
            insert ACCT;
            
            Opportunity opp= new Opportunity(name='Test Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today(),Partner_Lookup__c =ACCT.Id,Distributor_Lookup__c= ACCT.Id);
            insert opp;
            Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
            insert tempOpp;
            
            SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,SBQQ__Primary__c = true);
            insert quote;
            
            ServiceContract testContract = new ServiceContract();
            testContract.AccountId = Acc.id;
            testContract.SBQQSC__RenewalOpportunityRecordTypeId__c = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
            testContract.Name = 'Case Instrument Contract Test- Contract';
            testContract.StartDate = System.today()+10;
            testContract.Term = 24;
            testContract.SBQQSC__RenewalTerm__c = 24;
            testContract.SBQQSC__Quote__c = quote.Id;
            insert testContract;
            
            TriggerControl.stopOrderTrigger = true;
            Order ordr = new Order(
                AccountId = acc.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                OpportunityId = opp.Id,
                SBQQ__Quote__c = quote.Id,
                EffectiveDate = System.today(),
                Status = 'Draft',
                Type = 'Revenue',
                Order_Status__c = 'Pending',
                Is_RWD_Polaris_Quote__c = true,
                Order_Sub_Type__c = null
            );
            insert ordr;
            TriggerControl.stopOrderTrigger = false;
            
            testContract.SBQQSC__RenewalOpportunity__c = tempopp.Id;
            testContract.SBQQSC__Order__c = ordr.Id;
            update testContract;
			
			system.assertEquals(12,[SELECT Id,SBQQSC__RenewalTerm__c FROM ServiceContract WHERE Id =: testContract.Id].SBQQSC__RenewalTerm__c);
            
            /*Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
insert newProd;

Pricebook2 pricebook= new Pricebook2(name='Test Price Book',isActive=true);
insert priceBook;

Id standardPBId = test.getStandardPricebookId();
PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = newProd.Id, UnitPrice = 300, IsActive = true);
insert standardPBE;

PriceBookEntry pbEntry = new PriceBookEntry(
UnitPrice = 300,
PriceBook2Id = pricebook.id,
Product2Id = newProd.Id,
IsActive = true,
UseStandardPrice=false);
insert pbEntry ;

OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000,Quantity = 2,OpportunityID = opp.Id);
insert oppLine;
system.debug('Opportunity Line items:'+opp.OpportunityLineItems);

test.startTest();
OpportunitySplitHelper.createOptySplitLineItem(opp,2);
OpportunitySplitHelper.CopyOpportunity(tempOpp,opp);
test.stopTest();*/
        }
    }

}