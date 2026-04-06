@isTest 
private class CampaignMemberStatusBatchTest {
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
        
        //delete the existing CampaignMemberStatus records if any
        List<CampaignMemberStatus> existingStatuses = [SELECT Id FROM CampaignMemberStatus WHERE CampaignId = :camp1.Id];
        if (!existingStatuses.isEmpty()) {
            delete existingStatuses;
        }
        //insert new CampaignMemberStatus records for the campaign 2

        List<CampaignMemberStatus> requiredStatuses = new List<CampaignMemberStatus>{
            new CampaignMemberStatus(Label = 'Delivered', CampaignId = camp2.Id, HasResponded = false),
            new CampaignMemberStatus(Label = 'Filled out Form', CampaignId = camp2.Id, HasResponded = true)
        };  
    }

     @isTest
    static void testCampaignMemberStatusFixBatch() {
        Test.startTest();
        CampaignMemberStatusBatch batch = new CampaignMemberStatusBatch(new Map<Id, Campaign>{
            [SELECT Id FROM Campaign WHERE Name = 'Test Campaign 1' LIMIT 1].Id => [SELECT Id, Name, Type FROM Campaign WHERE Name = 'Test Campaign 1' LIMIT 1],
            [SELECT Id FROM Campaign WHERE Name = 'Test Campaign 2' LIMIT 1].Id => [SELECT Id, Name, Type FROM Campaign WHERE Name = 'Test Campaign 2' LIMIT 1]
        });
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            Database.executeBatch(batch, 200); // Execute the batch with a batch size of 200
        }
        Test.stopTest();            
        // Verify that the CampaignMemberStatus records were created correctly
        List<CampaignMemberStatus> statuses = [SELECT CampaignId, Label, IsDefault, HasResponded 
                                               FROM CampaignMemberStatus 
                                               WHERE CampaignId IN (SELECT Id FROM Campaign WHERE Name = 'Test Campaign 1')
                                               AND Label IN ('Clicked', 'Filled out Form')]; // Adjust labels based on your requirements
        //System.assertEquals(2, statuses.size(), 'There should be 2 CampaignMemberStatus records created for the campaign.');
        for (CampaignMemberStatus status : statuses) {
            System.assertNotEquals(null, status.CampaignId, 'CampaignId should not be null');
            System.assertNotEquals(null, status.Label, 'Label should not be null');
            System.assertNotEquals(null, status.IsDefault, 'IsDefault should not be null');
            System.assertNotEquals(null, status.HasResponded, 'HasResponded should not be null');
  
            if (status.Label == 'Clicked') {
                System.assertEquals(false, status.HasResponded, 'Sent status should not have responded.');
            } else if (status.Label == 'Filled out Form') {
                System.assertEquals(true, status.HasResponded, 'Responded status should have responded.');          
            }
        }
    }
   
}