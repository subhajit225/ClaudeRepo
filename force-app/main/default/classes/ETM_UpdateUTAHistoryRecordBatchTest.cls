/*******************************************************************************************************
Description : Test Class for ETM_UpdateUTAHistoryRecordBatch
Developer : Natesh
Date : 06/15/2020
**********************************************************************************************************/
@isTest
Private class ETM_UpdateUTAHistoryRecordBatchTest {
    @testSetup 
    static void setup() {
        List<UserTerritoryAssociation_History__c> utaHistories = new List<UserTerritoryAssociation_History__c>();
        for(Integer i=0; i<5;i++){
            UserTerritoryAssociation_History__c utaHist = new UserTerritoryAssociation_History__c();
            
            utaHist.Territory_Model__c = 'Active_Model';
            utaHist.Territory_Model_State__c = 'Planning';
            utaHist.Adaptive_Territory_Id__c = '123455'+i;
            utaHistories.add(utaHist);
        }

        for(Integer i=0; i<5;i++){
            UserTerritoryAssociation_History__c utaHist = new UserTerritoryAssociation_History__c();
            
            utaHist.Territory_Model__c = 'Archived_Model';
            utaHist.Territory_Model_State__c = 'Active';
            utaHist.Adaptive_Territory_Id__c = '123455'+i;
            utaHist.start_Date__c = System.today() - 30;
            if(i==4) {utaHist.End_Date__c = System.today() - 20;}
            utaHistories.add(utaHist);
        }

        insert utaHistories;
    }

    @IsTest
    static void utaHistoryRecordBatchTest(){
        Test.startTest();
        Database.ExecuteBatch(new ETM_UpdateUTAHistoryRecordBatch('Active_Model','Archived_Model'),200);
        Test.stopTest();

        System.assertEquals(5, [Select count() from UserTerritoryAssociation_History__c where Territory_Model_State__c = 'Active']);
        System.assertEquals(5, [Select count() from UserTerritoryAssociation_History__c where Territory_Model_State__c = 'Archived']);
    }
}