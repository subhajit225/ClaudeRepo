@IsTest
public class OpportunityStageMovingController_Test {

    @IsTest
    static void updateOpportunityTest(){
        Opportunity op = TestDataFactory.getOpportunity();
        Test.StartTest();
        op.SBQQ__Renewal__c  = true;
        insert op;
        OpportunityStageMovingController.updateOpportunity(op.Id,'StageMoving');
        OpportunityStageMovingController.updateOpportunity(op.Id,'ASPENChange');
        OpportunityStageMovingController.updateOpportunity(op.Id,'RubrikTBD');
        OpportunityStageMovingController.updateOpportunity(op.Id,'DistriMarketplace');
        OpportunityStageMovingController.updateOpportunity(op.Id,'Stage4to5');
        OpportunityStageMovingController.updateOpportunity(op.Id,'StageSkippedTo6');
        Test.StopTest();
        Opportunity opnew = [select id,Accept_Conditions__c,ASPEN_Accept_Conditions__c, Unapproved_Country_Accept_Conditions__c From opportunity where Id =: op.Id];
        System.assert(opnew.Accept_Conditions__c==true, 'Not Found');
        System.assert(opnew.ASPEN_Accept_Conditions__c==true, 'Not Found');
    }
}