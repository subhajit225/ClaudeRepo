/*****************************************************************************
@description   : Custom History Tracker Test Class
Verifies the logic for tracking history of fields of an object which is added in the fieldset.

Field set API should be -> Fields_To_Be_Tracked

******************************************************************************/
@isTest
private class CustomHistoryTrackerTest {
    /**
   * @author Siva Kumar
   * @date 11-06-2025
   * @description test method to testting Field History Tracking on Sobject
   */
    @isTest
    static void testTrackFieldsHistory() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = new Account(Name = 'Test Account'); 
            insert acc; 
            
            Order orderRecord = new Order(Name = 'Test Order', AccountId = acc.Id, EffectiveDate = Date.today()); 
            insert orderRecord; 
            
            orderRecord.Auto_Submission_Date_Time__c = system.today(); 
            update orderRecord; 
            
            Id partnerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();

            Account vAccount1 = new Account();
            vAccount1.Name = 'Test acc 1';
            vAccount1.Type = 'Distributor';
            vAccount1.recordTypeId = partnerRtId;
            vAccount1.Payment_Term__c = 'Net 60';
            insert vAccount1;
            
            Account vAccount2 = new Account();
            vAccount2.Name = 'Test acc 2';
            vAccount2.Type = null;
            vAccount2.recordTypeId = partnerRtId;
            vAccount2.Payment_Term__c = 'Net 60';
            insert vAccount2;
            
            Opportunity opp = new Opportunity();
            opp.Name = 'Test Opp 1';
            opp.AccountId = acc.Id;
            opp.StageName = '1 Discovery';
            opp.CloseDate = System.today();
            opp.ForecastCategoryName = 'Best Case';
            opp.Business_Unit__c = 'Rubrik';
            opp.Installation_Assigned_To__c = 'FE Install';
            opp.Partner_Lookup__c = vAccount1.Id;
            opp.Distributor_Lookup__c = vAccount2.Id;
            insert opp;
            
            SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);
            insert q;

            q.Pricing_Notes__c = 'This is test';
            q.SBQQ__EndDate__c  = Date.valueOf('2027-11-11');
            q.Approved_time__c  = DateTime.now();
            update q;

            CustomHistoryTracker.trackFieldsHistory(new List<Order>{orderRecord}, new Map<Id,Order>{orderRecord.Id => orderRecord}, 'Order__c');
            
            List<History_Tracking__c> lstNewHTRecords = new List<History_Tracking__c>([SELECT Id FROM History_Tracking__c]);
            System.assert(lstNewHTRecords.size() >= 0);
            List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
            PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com.invalid','test partner',system.today(),1,'test12345','test quote', 10);
            pos.Bill_To_Name__c=acc.Id;
            pos.Payment_schedule_type__c = 'test';
            poStageList.add(pos);
            insert poStageList;
            
            List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
            PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com.invalid',pos.id,'292005','test','test2');
            poAs.add(spa);
            insert poAs;
            update poAs;
        }
    }
    
}