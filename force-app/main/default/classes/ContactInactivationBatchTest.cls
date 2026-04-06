/****************** ContactInactivationBatchTest is the Test Class for ContactInactivationBatch Class *************************/
@isTest
public class ContactInactivationBatchTest {
    /*Perpare the Setup Data*/
    @TestSetup
    public static void prepareCommonData(){
        WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
            
        List<Account> accountRecs = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 2, 'AccountDefaults', null);
        accountRecs[0].Type = 'Marketplace'; 
        //accountRecs[0].RCIE_Certified__c=3;
        accountRecs[0].AWS_GCP_Cloud_Alliance_BDM__c = UserInfo.getUserId(); //Added as part of SAL26-105
        accountRecs[0].MSFT_OCI_Cloud_Alliance_BDM__c = UserInfo.getUserId(); //Added as part of SAL26-105
        //accountRecs[0].Account_Alliance_BDM_Lookup__c = UserInfo.getUserId(); //Commented as part of SAL26-101
        accountRecs[1].ETM_Area__c = 'MM-APAC-A'; 
        
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser) {
            insert accountRecs;
            List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 3, null);
            conList[0].AccountId=AccountRecs[0].Id;
            conList[0].Latest_UTM_Term__c = 'msft';
            conList[0].Last_UTM_Term_Date__c=system.today()-1;     
            conList[1].AccountId=AccountRecs[1].Id;         
            conList[1].Campaign_Sourced_By__c='Marketing'; 
            conList[1].Contact_Status__c='Nurture';
            conList[0].Campaign_Sourced_By__c='Marketing';
            conList[0].MQL__c = true;
            conList[2].AccountId=AccountRecs[1].Id;         
            conList[2].Campaign_Sourced_By__c='Marketing';
            conList[2].Last_Applied_Routing_Modifier__c = 'Route to Partner';
            conList[2].Contact_Status__c='Nurture';
            insert conList;
        }
    }
    /*Test the Batch Class*/
    @isTest static void testBatch(){
        List<Contact> conQuery = [SELECT Id, Contact_Status__c, MQL__c, Last_MQL_Date__c, MeetingDate__c, LastActivityDate, ContactRejectReason__c FROM Contact LIMIT 100];
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Allow_Contact_Transfer__c = true);
            conQuery[0].Contact_Status__c='Open';
            conQuery[0].Last_MQL_Date__c = Date.today()-31;
            update conQuery;
        }
        Test.startTest();
            Database.executeBatch(new ContactInactivationBatch(),100);
            System.AssertEquals(conQuery[0].Contact_Status__c, 'Open');
        Test.stopTest();
    }
    /*Test the Schedule Job*/
    @isTest static void testScheduler(){
        List<Contact> contactQuery = [SELECT Id, Name, MQL__c FROM Contact LIMIT 1];
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser) {
            contactQuery[0].Contact_Status__c='Working';
            contactQuery[0].Last_MQL_Date__c = Date.today()-31;
            update contactQuery;
        }
        Test.startTest();
            String sch = '0 0 3 * * ?'; 
            system.schedule('Test Lead Inactivation Check', sch, new ContactInactivationBatch(contactQuery[0].Id));
            System.AssertEquals(contactQuery[0].Contact_Status__c, 'Working');
        Test.stopTest(); 
    }
}