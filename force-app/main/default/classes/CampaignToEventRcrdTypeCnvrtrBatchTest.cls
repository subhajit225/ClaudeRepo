@isTest
class CampaignToEventRcrdTypeCnvrtrBatchTest {
    @TestSetup
    static void makeData(){
        ShGl_TestFactoryHelper.insertCustomSettings();
        ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disFuncCS.Allow_Contact_Transfer__c = true;
        update disFuncCS;

        ShGl_DisableBusinessLogic__c disBusCS = ShGl_DisableBusinessLogic__c.getInstance();
        disBusCS.Disable_Campaign_Trigger__C = true;
        insert disBusCS;

        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
                
        Account acc1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acc1.Segment_Assignment__c = 'Commercial';
        insert acc1;
        Lead lead1 = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        lead1.CountryCode = 'IT';
        lead1.Winning_L2A_Account__c = acc1.Id;
        insert lead1;

        // Create a Campaign with a specific type that has associated CampaignMemberStatus records
        // Ensure the Campaign has a RecordType that is not 'Event' and is active
        Campaign camp1 = new Campaign(Executed_By__c='Sales',Planned_MQL__c = 1,Involvement_by_Customer_Marketing__c='Yes',Campaign_Theme__c='Cloud',Name = 'Test Campaign 1',type='Advertising', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance',RecordTypeId=Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId(),GTM_Play__c='Cloud Native Protection');
        insert camp1;

        Campaign camp2 = new Campaign(Executed_By__c='Sales',Planned_MQL__c = 1,Involvement_by_Customer_Marketing__c='Yes',Campaign_Theme__c='Cloud',Name = 'Test Campaign 2',type='Direct Mail', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance',RecordTypeId=Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId(),GTM_Play__c='Cloud Native Protection');
        insert camp2;
    }

    @isTest
    static void testMethod1() {
        // This is a placeholder for the actual test logic.
        // You would typically create test data, execute the batch, and assert the expected outcomes.

        //Disable campaign trigger for the current context
        ShGl_DisableBusinessLogic__c disBusCS = ShGl_DisableBusinessLogic__c.getInstance();
        disBusCS.Disable_Campaign_Trigger__C = true;
        update disBusCS;
        // Execute the batch
        CampaignToEventRecordTypeConverterBatch batch = new CampaignToEventRecordTypeConverterBatch();
        Test.startTest();
        // Run as System Administrator to ensure the batch has the necessary permissions
        // to update Campaign records
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            Database.executeBatch(batch, 200); //
            // Execute the batch with a batch size of 200
        }
        Test.stopTest();    
        // Verify that the Campaign records were updated correctly
        List<Campaign> updatedCampaigns = [SELECT Id, RecordTypeId FROM Campaign WHERE Name IN ('Test Campaign 1', 'Test Campaign 2')];
        //find the Event Record Type ID for Campaign
        for (Campaign camp : updatedCampaigns) {
            System.assertEquals(Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Global').getRecordTypeId(), camp.RecordTypeId, 'Campaign Record Type should be updated to Event.');
        }
    }
}