@isTest
//(seeAllDAta=true)
public class OpportunityRenewalStatusBatch_Test
{
    @isTest
    static void testMethodforBatch()
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
        Opportunity opp = TestDataFactory.getOpportunity(acc);
        opp.closeDate=Date.today();
        opp.SBQQ__QuotePricebookId__c =cpqpriceBook.id;
        opp.Opportunity_Type__c='Existing Customer';
        opp.Opportunity_Sub_Type__c ='Renewal';
        opp.stageName='7 Closed Won';
        //insert opp;
        Opportunity tempOpp = TestDataFactory.getOpportunity(acc);
        tempOpp.accountId=acc.id;
        tempOpp.stagename='Approved';
        tempOpp.closeDate=Date.today();
        tempOpp.SBQQ__QuotePricebookId__c =cpqpriceBook.id;
        insert new List<Opportunity> {opp, tempOpp};

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
            OpportunityRenewalStatusBatch obj = new OpportunityRenewalStatusBatch();
            DataBase.executeBatch(obj,20);
            OpportunityRenewalStatusBatchSchedular  sch1 = new OpportunityRenewalStatusBatchSchedular ();
            Datetime dt = Datetime.now().addMinutes(1);
            String jobID = System.Schedule('OpportunityRenewalStatusBatchSchedularTest', dt.format('s m H d M \'?\' yyyy'), sch1);	
            
        Test.stopTest();
    }
}