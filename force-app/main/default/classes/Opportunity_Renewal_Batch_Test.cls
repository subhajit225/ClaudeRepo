@isTest
//(seeAllDAta=true)
public class Opportunity_Renewal_Batch_Test
{
    static testMethod void testMethodforBatch()
    {
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c=true;
        insert tc;

        insert new PatchManagerSettings__c(Default_User_Id__c = UserInfo.getUserId(), Default_Account_User__c = UserInfo.getUserId());

        Account acc= new Account(name='Test Account');
        insert Acc;

        Pricebook2 cpqpriceBook= new Pricebook2(name='CPQ PriceBook',isActive=true);
        insert cpqpriceBook;

        Opportunity opp= new Opportunity(name='Test Opp',accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today(), SBQQ__QuotePricebookId__c =cpqpriceBook.id);
        insert opp;
        Opportunity tempOpp= new Opportunity(name='Temp Opp',accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today(), SBQQ__QuotePricebookId__c =cpqpriceBook.id);
        insert tempOpp;

        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd;

        Pricebook2 pricebook= new Pricebook2(name='Test Price Book',isActive=true);
        insert priceBook;



        Id standardPBId = test.getStandardPricebookId();
        PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = newProd.Id, UnitPrice = 300, IsActive = true);
        insert standardPBE;

        PriceBookEntry cpqpbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = cpqpriceBook.id,//pricebook.id,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert cpqpbEntry ;

        Test.startTest();
            Opportunity_Renewal_Batch obj = new Opportunity_Renewal_Batch();
            DataBase.executeBatch(obj,20);
            OpportunityRenewal_BatchSchedular sch1 = new OpportunityRenewal_BatchSchedular();
            String sch = '0  00 3 4 * ?';
            system.schedule('Test', sch, sch1);
            
        Test.stopTest();
    }
    
}