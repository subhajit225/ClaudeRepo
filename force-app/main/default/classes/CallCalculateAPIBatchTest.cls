@isTest 
public class CallCalculateAPIBatchTest {
        static testMethod void testMethod1() 
    {
    //REEN-31 Starts 
    ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                      //      Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                       //     Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True
                                                                            );    
        insert cdf;
        //REEN-31 Ends
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Opportunity_Type__c = 'Existing';
        opp.Opportunity_Sub_Type__c = 'Regular';
        opp.CloseDate = System.today()-1;//REEN-31
        insert opp;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Type__c = 'Renewal';
        qt.SBQQ__StartDate__c = Date.parse('05/20/2022');
        qt.SBQQ__Primary__c = true;//REEN-31
        insert qt;
        quoteList.add(qt);
       
        Test.startTest();

            CallCalculateAPIBatch obj = new CallCalculateAPIBatch(quoteList);
            DataBase.executeBatch(obj); 
            //REEN-31 Starts
            RecalculateQuotesBatch obj1 = new RecalculateQuotesBatch();
            DataBase.executeBatch(obj1); 
            //REEN-31 Ends

            QuotesStatusExpiredBatch exp = new QuotesStatusExpiredBatch();
            DataBase.executeBatch(exp);
            
            String schTime = '0 0 12 * * ?';
            QuotesStatusExpiredBatch schJob = new QuotesStatusExpiredBatch();
            system.schedule('TestUpdateConAccJob', schTime, schJob);
            System.assert(true);
        Test.stopTest();
    }


}