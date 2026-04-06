@isTest
class FeatureRecommendationTriggerHelperTest {
    @TestSetup
    static void makeData(){
        ShGl_TestFactoryHelper.insertCustomSettings();
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();

        //create Account
        Account acc1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acc1.Segment_Assignment__c = 'Commercial';
        insert acc1;

        //create feature recommendation 
        List<Feature_Recommendation__c> frs = new List<Feature_Recommendation__c>();
        Feature_Recommendation__c fr1 = new Feature_Recommendation__c();
        Feature_Recommendation__c fr2 = new Feature_Recommendation__c();
        fr1.Account__c = fr2.Account__c = [SELECT Id FROM Account LIMIT 1].Id;
        fr1.Feature_Name__c = 'Sonar';
        fr2.Feature_Name__c = 'Radar';
        fr1.Recommended_Date__c = Date.today();
        fr2.Recommended_Date__c = Date.today();
        fr1.Account_Feature__c = fr1.Account__c+'-'+fr1.Feature_Name__c;
        fr2.Account_Feature__c = fr2.Account__c+'-'+fr2.Feature_Name__c;
        frs.add(fr1);
        frs.add(fr2);
        insert frs;
    }
    @isTest static void testupdateStatusAndCloseDate(){
        List<Feature_Recommendation__c> frs = [SELECT Id, First_Use_Date__c, Status__c FROM Feature_Recommendation__c];
        frs[0].First_Use_Date__c = Date.today();
        frs[1].Status__c = 'Suspended';
        frs[1].Suspended_Reason__c = 'Test suspension';
        Test.startTest();
            update frs;
        Test.stopTest();
    }
}