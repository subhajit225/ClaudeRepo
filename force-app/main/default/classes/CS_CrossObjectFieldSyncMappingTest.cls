@isTest
public class CS_CrossObjectFieldSyncMappingTest {
    
    static void executeSyncProcess() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.Risk_Status__c = 'New';
        update testCase;
        
        Cross_Object_Fields_Sync_Mapping__mdt mapping = new Cross_Object_Fields_Sync_Mapping__mdt(
            Sync_Name__c = 'Test Sync Name',
            Source_Object__c = 'Case',
            Destination_Object__c = 'Risk_Profile__c',
            Source_FieldAPIName__c = 'Risk_Status__c',
            Destination_FieldAPIName__c = 'Risk_Status__c',
            Destination_Object_Id_Field__c = 'Risk_Profile__c'
        );
        
        CS_CrossObjectFieldSyncMapping syncInstance = new CS_CrossObjectFieldSyncMapping('Test Sync');
        CS_CrossObjectFieldSyncMapping.testMockFieldMappings = new List<Cross_Object_Fields_Sync_Mapping__mdt>{ mapping };
        syncInstance.setSourceRecordIds(new Set<Id>{testCase.Id});
        
        CS_CrossObjectFieldSyncMapping.execute(syncInstance, new Map<String, String>{'Id' => testCase.Id});
    }

    private static void verifySyncResults() {
        Case testCase = [SELECT Id, Risk_Profile__r.Risk_Status__c, Risk_Status__c FROM Case LIMIT 1];
        System.assertEquals(testCase.Risk_Status__c, testCase.Risk_Profile__r.Risk_Status__c, 
                            'The Risk Status field on the Risk Profile should match the Risk Status field on the Case.');
    }
	
    @future
    static void insertRiskGrovernanceMember(){
         Group riskGovernanceGroup = [SELECT Id FROM Group WHERE DeveloperName = 'Risk_Governance_Team' LIMIT 1];
        
        GroupMember groupMember = new GroupMember(
            GroupId = riskGovernanceGroup.Id,
            UserOrGroupId = UserInfo.getUserId()
        );
        insert groupMember;
    }
    @testSetup
    static void setupTestData() {       
        insertRiskGrovernanceMember();
        Risk_Profile_Assignment__c customSetting = new Risk_Profile_Assignment__c(
            Last_Assigned_Index__c = 0
        );
        insert customSetting;       
               
        Account testAccount = new Account(Name = 'Test Account New');
        insert testAccount;

        Risk_Profile__c testRiskProfile = new Risk_Profile__c(
            Risk_Type__c = 'Account Risk',
            Primary_Risk_Reason__c = 'Support issues',
            Secondary_Risk_Reason__c = 'Support issues',
            Risk_Validation_Status__c = 'Invalid'
        );
        insert testRiskProfile;
        
        testRiskProfile.Risk_Validation_Status__c = 'Valid';
        update testRiskProfile;        
    }

    @isTest
    static void testSyncExecution() {
        Test.startTest();
        	executeSyncProcess();  
        Test.stopTest();
        verifySyncResults();
    }

    @isTest
    static void testAsyncExecution() {
        Test.startTest();
        	runAsyncProcess();
        Test.stopTest();
        
        verifySyncResults();
    }

    @future
    static void runAsyncProcess() {
        executeSyncProcess();
    }
}