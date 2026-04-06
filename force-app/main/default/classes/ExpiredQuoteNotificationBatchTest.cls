@isTest
private class ExpiredQuoteNotificationBatchTest {

    @TestSetup
    static void testSetup(){
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(SetupOwnerId = userInfo.getUserId(),
                                                                             Disable_SBQQ_Quote_Validation_Rules__c = true,
                                                                             Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
                                                                             Disable_Opportunity_Validation_Rules__c = true,
                                                                             Disable_ServiceContract_Trigger__c = true,
                                                                             Disable_Contract_Line_Item_Triggers__c = true);
        insert cdf1;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        TriggerControls.disableCalculateAPIBatch = true;
        SBQQ.TriggerControl.disable();
        
        Account act = (Account) ShGl_TestFactory.createSObject(
            new Account(),
            null
        );
        insert act;
        
        List<Account> actList = new List<Account>();
        Id partnerRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account vAccount1a = getAccount('Disti Account', 'Distributor', partnerRtId);
        actList.add(vAccount1a);
        
        Account vAccount2 = getAccount('Partner Account', null, partnerRtId);
        actList.add(vAccount2);
        
        insert actList;
        
        Opportunity oppty = new Opportunity();
        oppty.Name = 'MS Test Optty';
        oppty.AccountId = act.Id;
        oppty.StageName = '5 Negotiate & Close';
        oppty.Opportunity_Sub_Type__c = 'Regular';
        oppty.CloseDate = System.today();
        oppty.ForecastCategoryName = 'Best Case';
        oppty.Business_Unit__c = 'Rubrik';
        oppty.Installation_Assigned_To__c = 'FE Install';
        oppty.Partner_Lookup__c = vAccount2.Id;
        oppty.Distributor_Lookup__c = vAccount1a.Id;
        insert (oppty);
        
        SBQQ__Quote__c q1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppty.Id,
            SBQQ__Type__c = 'Draft',
            SBQQ__Account__c = act.Id,
            OpportunitySubType__c = 'Regular',
            SBQQ__PricebookId__c = Test.getStandardPricebookId(),
            SBQQ__ExpirationDate__c = System.today().addDays(-1)
        );
        Insert q1;

        
        q1.SBQQ__Primary__c = true;
        q1.ApprovalStatus__c = 'Approved';
        update q1;
    }

    @IsTest
    static void testExecute() {
        List<SBQQ__Quote__c> quoteList = [SELECT Id, SBQQ__Opportunity2__r.StageName, SBQQ__Opportunity2__r.CloseDate, Expiration_Date__c, SBQQ__ExpirationDate__c, ApprovalStatus__c FROM SBQQ__Quote__c];

        Opportunity opp = [SELECT Id, Name, OwnerId, CloseDate, SBQQ__PrimaryQuote__c
                           FROM Opportunity WHERE Name = 'MS Test Optty' LIMIT 1];

        opp.SBQQ__PrimaryQuote__c = quoteList[0].Id;
        update opp;

        Test.startTest();
        System.runAs(new user(ID = UserInfo.getUserID())){
            ExpiredQuoteNotificationBatch batch = new ExpiredQuoteNotificationBatch();
            Database.executeBatch(batch, 200);
            System.Assert(true);
        }
        Test.stopTest();
    }

    static Account getAccount(String name, String type, String rtId) {
        Account vAccount = new Account();
        vAccount.Name = name;
        vAccount.Type = type;
        vAccount.recordTypeId = rtId;
        vAccount.Payment_Term__c = 'Net 60';
        
        return vAccount;
    }
}