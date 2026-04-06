@isTest public class OpportunityStageDownGradeBatchTest {
    @isTest
    static void testOpportunityStageDownGradeBatch(){

        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        Opportunity_Stage_Days__c stageDays = new Opportunity_Stage_Days__c(); 
        upsert stageDays;
        stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId()); 
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        listUser[0].LastName = 'Sinha';
        insert listUser;
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        ID oppRecTypeIdSalesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.recordTypeId = oppRecTypeIdSalesOpp;
        oppObject.ownerId = listUser[0].id;
        id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        update new Account(ID=oppObject.accountId, recordTypeId=rId);
        
        Custom_Error_Log__c errors = new Custom_Error_Log__c();
        Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
        CaptureError.Class__c = 'ClassName' ;
        CaptureError.Functionality__c = 'Functionality';
        CaptureError.Exception_Message__c= 'message';
        CaptureError.FailedRecords__c = 'RecIds' ;
        insert CaptureError;
        ShGl_DisableBusinessLogic__c BLSetting = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        BLSetting.Disable_Opportunity_Validation_Rules__c = true;
        insert BLSetting;

        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(cloneOpportunity(oppObject, '0 Nurture'));
        System.debug(oppList[0] + '\n~~~~stageDays: ' + stageDays);
        oppList[0].Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_for_Stage_0__c + 1);
        oppList.add(cloneOpportunity(oppObject, '1 Discovery'));
        oppList[1].Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_for_Stage_1__c + 1);
        oppList.add(cloneOpportunity(oppObject, '2 Consensus'));
        oppList[2].Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_for_Stage_2__c + 1);
        oppList.add(cloneOpportunity(oppObject, '3 Technical Validation'));
        oppList[3].Stage_2_RSM_Validation__c = true;
        oppList[3].Installation_Assigned_To__c = 'FE Install';
        //oppList[0].Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_for_Stage_3__c + 1);
        oppList.add(cloneOpportunity(oppObject, '4 Business Justification'));
        oppList[4].Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_for_Stage_4__c + 1);
        oppList[4].Stage_2_RSM_Validation__c = true;
        oppList[4].Primary_Competitor__c = 'Actifio';
        oppList[4].Installation_Assigned_To__c = 'FE Install';
        
        oppList.add(cloneOpportunity(oppObject, '5 Negotiate & Close'));
        oppList[5].Time_of_Last_Stage_Change__c = System.today() - ((Integer)stageDays.Max_Days_for_Stage_5__c + 1);
        oppList[5].Stage_2_RSM_Validation__c = true;
        oppList[5].Primary_Competitor__c = 'Actifio';
        oppList[5].Technical_Validation_Completed__c = true;
        oppList[5].Installation_Assigned_To__c = 'FE Install';
        
        System.debug('\n\n0~~~~Updated Opportunity: ' + JSON.serialize(oppList));
        insert oppList;
        
        List<Opportunity> oppList1 = [SELECT Name, StageName, Time_of_Last_Stage_Change__c, Opportunity_Type__c, Opportunity_Sub_Type__c, CloseDate, CreatedDate, RecordTypeId, RecordType.Name, 
                   Stage_2_RSM_Validation__c, Technical_Validation_Completed__c, Stage_5_RSM_Validation__c FROM Opportunity where ID in :oppList];
        System.debug('\n\n1~~~~Updated Opportunity: ' + JSON.serialize(oppList1));
        
        System.assert(oppList1[0].Id != null);            
        
        Test.startTest();
        TriggerManager.resetTriggerCounter('Opportunity');
        Datetime dt = Datetime.now().addMinutes(1);
        String jobID = System.Schedule('OpportunityStageDownGradeSchedulerTest', dt.format('s m H d M \'?\' yyyy'), new OpportunityStageDownGradeScheduler());		
        System.debug('\n\n2~~~~Updated Opportunity: OpportunityStageDownGradeSchedulerTest Finished.' );

        Test.stopTest();
        
        List<Opportunity> oppList2 = [SELECT Name, StageName, Time_of_Last_Stage_Change__c, Opportunity_Type__c, Opportunity_Sub_Type__c, CloseDate, CreatedDate, RecordTypeId, RecordType.Name, Stage_2_RSM_Validation__c, Technical_Validation_Completed__c, Stage_5_RSM_Validation__c FROM Opportunity where ID in :oppList];
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>(oppList2);
        System.debug('\n\n2~~~~Updated Opportunity: ' + JSON.serialize(oppList2));

        //System.assert('7 Closed Lost' == oppMap.get(oppList[0].Id).StageName); 
        //System.assert('0 Nurture' == oppMap.get(oppList[1].Id).StageName); 
        //System.assert('1 Discovery' == oppMap.get(oppList[2].Id).StageName); 
        //System.assert('3 Technical Validation' == oppMap.get(oppList[3].Id).StageName); 
        //System.assert('3 Technical Validation' == oppMap.get(oppList[4].Id).StageName); 
        //System.assert('4 Business Justification' == oppMap.get(oppList[5].Id).StageName); 
        
        OpportunityStageDownGradeBatch oppBatch = new OpportunityStageDownGradeBatch();
        oppBatch.sendErrorReport();
    }

    private static Opportunity cloneOpportunity(Opportunity masterOpp, String stageName){
    	Opportunity oppObject = new Opportunity(recordTypeId = masterOpp.recordTypeId);
        oppObject.Name = masterOpp.name + '_' + stageName;
        oppObject.AccountId = masterOpp.AccountId;
        oppObject.StageName = stageName;
        oppObject.Amount = 100;
        oppObject.CloseDate = System.today()+30;
        oppObject.Type = 'New Customer';
        oppObject.Opportunity_Type__c = 'New Customer';
        oppObject.Opportunity_Sub_Type__c = 'Regular';        
        oppObject.Alliance_Partner_Name__c='Amazon';
        oppObject.Alliance_Source_Type__c='Alliance Initiated Deal';
        oppObject.Alliance_Source_Type_SW__c = 'Alliance Initiated Deal';
        oppObject.Partner_Representative__c = 'test';
        oppObject.Deal_Registration_Type__c='Rubrik Sourced';
		oppObject.Identified_Pain__c = 'Test';
        oppObject.OwnerId = masterOpp.OwnerId;
        oppObject.Lead_Email_Hidden__c = masterOpp.Lead_Email_Hidden__c;
        oppObject.Initial_Contacts_Name__c = masterOpp.Initial_Contacts_Name__c;
        
        oppObject.SecondaryOwnerSubmitter__c = masterOpp.OwnerId;
        oppObject.SecondaryOwnerApproved__c = true;
        oppObject.RenewalOwnerSubmitter__c = masterOpp.OwnerId;
        oppObject.RenewalOwnerApproved__c = true;
        oppObject.SE_Misaligned__c = true;
        oppObject.PO_Received_Notification_Sent__c = true;
        oppObject.Include_Datos__c = true;
        oppObject.Alliance_HW_Partner__c = 'Cisco';
        oppObject.Alliance_Source_Type_HW__c = 'Alliance Initiated Deal';
        oppObject.Cloud_Type__c = 'Google';
        oppObject.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        oppObject.Compelling_Bus_Driver__c = 'Instant Recovery';
        oppObject.Current_State__c = 'test';
        oppObject.Negative_Consequences__c = 'test';
        oppObject.Future_State__c = 'test';
        oppObject.Positive_Business_Outcomes__c = 'test';
        oppObject.Distributor_Lookup__c = oppObject.accountId;
        oppObject.Partner_Lookup__c = oppObject.accountId;
        oppObject.Opportunity_Sub_Type__c = 'MSP';
        oppObject.Rubrik_Sales_Engineer__c = UserInfo.getUserId();
        oppObject.Win_Loss_Comments__c = 'test';
        oppObject.Primary_Competitor__c = 'Actifio';
        oppObject.Key_Feature_Needs__c = 'None';
        //oppObject.Deal_Impact__c = 'Deal Blocker';
        oppObject.Valooto_Quote__c = '123123123';
        oppObject.Valooto_Quote_Stage__c = 'Approved';
        oppObject.Help_Needed__c = 'Approved';
        //oppObject.Help_Needed_From__c = masterOpp.OwnerId;
        //oppObject.Technical_Validation_Next_Step__c = 'true'; //commented for SAL26-355 - ,Technical_Validation_Next_Step__c
        oppObject.Escalation_Stage__c = 'Needs Monitoring';
        oppObject.Manager_s_Note__c = 'true';
        oppObject.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppObject.Pricebook2Id = Test.getStandardPricebookId();
        oppObject.Lost_To_Won_Against__c ='Actifio';
        oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
        oppObject.Valooto_Quote__c ='Test';
        return oppObject;
    }

}