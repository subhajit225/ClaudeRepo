@isTest
public class CustomEmailTemplateControllerTest {
    @TestSetup 
    static void setupData() { 
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = False;
 
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Contact';
        setting2.DisableTrigger__c = False;

        TriggerControl__c setting3 = new TriggerControl__c();
        setting3.Name = 'Entitlement';
        setting3.DisableTrigger__c = False;
        insert new List<TriggerControl__c>{setting1, setting2, setting3};
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='testAccount', RecordTypeId = partnerRecordTypeId, Account_Deal_Desk_Notes__c = 'Test Notes');
        Account acc = new Account(Name='testAccount1');
        insert new List<Account>{acct, acc};

        Contact con = new Contact(FirstName='john', LastName='doe', Email='john@doe.com', AccountId=acct.Id);
        insert con;

        Date closeDt = System.Today()+30;

        Opportunity oppr = TestDataFactory.getOpportunity(acct);
        insert oppr;
 
        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true);
        pd.IsActive = true;
        insert pd;

        Id standardPriceBookId =  Test.getStandardPricebookId();

        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;

        PricebookEntry pbestandard = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pb1.id, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert new List<PricebookEntry>{pbestandard, pbe};


        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
            'SBQQ__Opportunity2__c' => oppr.Id
        };
            
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        insert qt1;
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = pd.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, 
                                                        SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
        lines.add(ql1);
        insert lines;
    } 
    
    @isTest
    public static void testgetLines() {
        SBQQ__Quote__c quoteRec = [SELECT Id, Account_Deal_Desk_Notes__c, SBQQ__Account__c FROM SBQQ__Quote__c];

        Test.startTest();
        //CPQ22-836 starts
        CustomEmailTemplateController controller = new CustomEmailTemplateController();
        controller.getLines();
        //CPQ22-836 ends
        Test.stopTest();
    }

}