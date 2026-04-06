/********************************************************************************************************
* Name              : UpdateL3opportunityBatch_Test
* Purpose           : UpdateL3opportunityBatch_Test is Used for Testing UpdateL3opportunityBatch Class
*********************************************************************************************************/

@isTest
public class UpdateL3opportunityBatch_Test {
    
    public static void disbaletriggers(){
        boolean tempFlag = flowControll.opportunityTriggerHandler;
                boolean tempFlag1 = flowControll.opportunityLineItemHandler;
                flowControll.opportunityTriggerHandler = false;
                flowControll.opportunityLineItemHandler = false;
                SBQQ.TriggerControl.disable();
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                TriggerControls.disableCalculateAPIBatch = true;
                TriggerControl.stopOrderItemTrigger = true;
                TriggerControl.stopOrderTrigger = true;
                TriggerControl.stopSCTrigger = true;
                TriggerControl.stopCLITrigger = true;
                TriggerControl.stopEntitlementTrigger = true;
    }
    
    
    @testSetup
    static void setupDataForAccountTriggerHandler(){
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Triggers__c = TRUE);
        
    } 
    static void setupDataForAccountTriggerHandler1(){
        
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Opportunity_Old_Trigger__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Opportunity_Triggers__c = TRUE);
        
        
    } 
    
    @isTest
    static void testBatchExecution() {
        //ShGl_DisableBusinessLogic__c
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
        
        Set<Id> AccId = New Set<Id>();
        
                        // Create test data
                        
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Account testAccount1 = new Account(Name = 'Test Account2');
        insert testAccount1;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = '1 Discovery',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            Opportunity_Type__c = 'Existing Customer'
            
        );
        
        disbaletriggers();    
        insert testOpportunity;
     
        
        
        Opportunity testOpportunity1 = new Opportunity(
            Name = 'Test Opportunity1',
            StageName = '1 Discovery',
            CloseDate = Date.today(),
            AccountId = testAccount1.Id,
            Opportunity_Type__c = 'Existing Customer'
            
        );
        disbaletriggers();
        insert testOpportunity1;
     
        
        
        testAccount.Is_L3_Eligible_Account__c=true;
        update testAccount;
        testAccount1.Is_L3_Eligible_Account__c=false;
        update testAccount1;
        AccId.add(testAccount.Id);
        AccId.add(testAccount1.Id);
        
        Test.startTest();
        UpdateL3opportunityBatch obj = new UpdateL3opportunityBatch(AccId);
        DataBase.executeBatch(obj); 
                
        Test.stopTest();
        System.assertEquals(false, testAccount1.Is_L3_Eligible_Account__c);
    }

}