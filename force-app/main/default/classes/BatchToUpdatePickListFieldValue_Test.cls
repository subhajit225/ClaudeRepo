@isTest
public class BatchToUpdatePickListFieldValue_Test {
    @testSetup static void dataSetup() {
        //Creating Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.Account_Preference__c = 'Advisory Account; Critical Account; CSM Account';
        act.Heads_Up_to_Support_Team__c = 'Hello';
        act.Strategic_Account__c =  true;
        insert act;

        //Creating Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert con;

        ////Creating Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id
                };

                    List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 6, oppMap);

        integer i=0;
        for(Opportunity opp: opptyList){
            opp.Idea_References__c = 'GRZWRKSPCE-I-51; GRZWRKSPCE-I-5; GRZWRKSPCE-I-25; GRZWRKSPCE-I-50';
            opp.ACV_Amount__c = 121;
            if(i==0){
                opp.Next_Step__c='c-co';
            }
            if(i==1){
                opp.Next_Step__c='TEST Cohesity';
            }
            if(i==2){
                opp.Primary_Competitor__c = 'Cohesity';
            }
            if(i==3){
                opp.Other_Primary_Competitor__c = 'Testing Cohesity Test';
            }
            if(i==4){
                opp.Win_Loss_Comments__c = 'Cohesity Test';
            }
            /*if(i==5){
                opp.Cohesity_Deal__c = true;
            }*/ //SAL26-704: Commented
            i++;
        }
        insert opptyList;

        ////Creating Case
        List<Case>  caseList= New List<Case>();
        Map<String, Object> caseMap = new Map<String, Object> {
            'Subject' => 'testing one more',
                'ContactId' => con.Id,
                'Jira_Reference_urls__c' => 'test',
                'Last_Case_Status__c' => 'Customer requested close',
                'Priority' => 'P2',
                'close_survey_triggered__c' => false,
                'Resolution__c' => 'Hardware problem',
                'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
                'AccountId' => act.Id

                };
                    Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
        caseList.add(caseTest);

        Map<String, Object> caseMap1 = new Map<String, Object> {
            'Subject' => 'testing one more 1',
                'ContactId' => con.Id,
                'Jira_Reference_urls__c' => 'test',
                'Last_Case_Status__c' => 'Customer requested close',
                'Priority' => 'P2',
                'close_survey_triggered__c' => false,
                'Resolution__c' => 'Hardware problem',
                'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
                'AccountId' => act.Id

                };
                    Case caseTest1 = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap1);
        caseList.add(caseTest1);
        insert caseList;

        //Creating Aha Idea
        List<Aha_Ideas__c> ahaIdeaList = New List<Aha_Ideas__c>();
        Aha_Ideas__c ai1 = new Aha_Ideas__c();
        ai1.name = 'Idea Parent Test Record';
        ai1.Aha_Idea_Number__c = '7271210190138657159';
        ai1.Aha_Unique_ID__c = 'GRZWRKSPCE-I-80';
        ai1.Idea_Description__c = 'Account 1 idea 2 (Case)';
        ai1.Status__c = 'TestCase';
        ai1.Escalation__c = 'TestCase';
        ai1.For_Workspace__c = 'TestCase';
        ai1.Product_Area__c  = 'TestCase';
        ai1.Idea_Category__c  = 'TestCase';
        ai1.Idea_Tags__c  = 'TestCase';
        ai1.Product_Component__c  = 'TestCase';
        ahaIdeaList.Add(ai1);

        INSERT ahaIdeaList;
    }
    @isTest
    static void BatchToUpdatePickListFieldValueTestMethod(){
        Aha_Ideas__c ai = [SELECT Id,Duplicate_of__c,Escalation__c,For_Workspace__c,Product_Area__c,Idea_Category__c,
                           Idea_Tags__c,Product_Component__c,Aha_Unique_ID__c,Business_Case_Value__c,Status__c
                             FROM Aha_Ideas__c WHERE Aha_Unique_ID__c =: 'GRZWRKSPCE-I-80'];

        Test.startTest();
        BatchToUpdatePickListFieldValue obj = new BatchToUpdatePickListFieldValue();
        DataBase.executeBatch(obj);
        Test.stopTest();

    }
}