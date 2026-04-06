@isTest public class OpportunityStage1ToClosedLostBatchTest {
    @isTest
    static void testOpportunityStage1ToClosedLostBatch() {
        Opportunity_Stage_Days__c stageDays = new Opportunity_Stage_Days__c(); 
        upsert stageDays;
        stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId()); 
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        sdb.Disable_Opportunity_Triggers__c = true;
        upsert sdb;
        ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.recordTypeId = oppRecTypeIdSalesOpp;
        oppObject.StageName = '1 Discovery';
        oppObject.Type = 'New Customer';
        oppObject.Opportunity_Type__c = 'New Customer';
        oppObject.Opportunity_Sub_Type__c = 'Regular';
        oppObject.Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_To_Move_Stg1_To_Closed_Lost__c + 1);
        oppObject.peopleai__LastTouched__c = System.today() - ((Integer)stageDays.Max_Days_To_Move_Stg1_To_Closed_Lost__c + 1);
        oppList.add(oppObject);
        Opportunity oppObject1 = TestDataFactory.getOpportunity();
        oppObject1.recordTypeId = oppRecTypeIdSalesOpp;
        oppObject1.StageName = '1 Discovery';
        oppObject.Type = 'New Customer';
        oppObject.Opportunity_Type__c = 'New Customer';
        oppObject.Opportunity_Sub_Type__c = 'Regular';
        oppObject1.Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_To_Send_Email__c - 1);
        oppObject1.peopleai__LastTouched__c = System.today() - ((Integer)stageDays.Max_Days_To_Send_Email__c - 1);
        oppList.add(oppObject1);
        upsert oppList;

        //SplitOppty
        List<Opportunity> spliOppList = new List<Opportunity>();
        Opportunity splitOpp1 = TestDataFactory.getOpportunity();
        splitOpp1.recordTypeId = oppRecTypeIdSalesOpp;
        splitOpp1.StageName = '1 Discovery';
        splitOpp1.Pricebook2Id = test.getStandardPricebookId();
        splitOpp1.Split_percentage__c=25;
        splitOpp1.split__c = true;
        splitOpp1.Opportunity_Split_Parent__c = oppObject.id; 
        spliOppList.add(splitOpp1);
        Opportunity splitOpp2 = TestDataFactory.getOpportunity();
        splitOpp2.recordTypeId = oppRecTypeIdSalesOpp;
        splitOpp2.StageName = '1 Discovery';
        splitOpp2.Pricebook2Id = test.getStandardPricebookId();
        splitOpp2.Split_percentage__c=25;
        splitOpp2.split__c = true;
        splitOpp2.Opportunity_Split_Parent__c = oppObject1.id; 
        spliOppList.add(splitOpp2);
        upsert spliOppList;

        Test.startTest();
        TriggerManager.resetTriggerCounter('Opportunity');
        Datetime dt = Datetime.now().addMinutes(1);
        String jobID = System.Schedule('OpportunityStage1ToClosedLostBatchTest', dt.format('s m H d M \'?\' yyyy'), new OpportunityStage1ToClosedLostBatch(null));      
        String queryStrStart = 'SELECT Id, StageName, Days_in_Current_Stage__c, Next_Step_date_time__c, RD_Notes_Timestamp__c, peopleai__LastTouched__c, manager_note_date_time__c, CloseDate, CreatedDate, OwnerId, Owner.ManagerId ' +
                                ' FROM Opportunity where Opportunity_Split_Parent__c = null';
        Database.executeBatch(new OpportunityStage1ToClosedLostBatch(queryStrStart), (Integer)stageDays.OpportunityStageDownGradeBatch_Size__c);
        Test.stopTest();
        List<Opportunity> oppList2 = [select Id, StageName from Opportunity where StageName = '7 Closed Lost'];
        System.assert(!oppList2.isEmpty());
    }
}