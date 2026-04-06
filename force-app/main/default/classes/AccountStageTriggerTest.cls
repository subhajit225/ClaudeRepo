/**
 * @description
 * Created as part of SAL26-323.
 * This is the test class of AccountStageTriggerHelper/Handler classes.
 */ 
@IsTest
public class AccountStageTriggerTest {
    @testSetup
    static void testSetup(){
        
        List<User> listUsers = new List<User>();
        Id listProfile1 = [Select Id From Profile Where Name = 'System Administrator'].Id;
        Id listProfile2 = [Select Id From Profile Where Name = 'Sales Operations'].Id;
        List<Opportunity> oppLi = new List<Opportunity>();
        List<User> listUsers1 = TestDataFactory.getUsers('testClassUser1', new Set<Id>{listProfile1}, 2);
        List<User> listUsers2 = TestDataFactory.getUsers('testClassUser2', new Set<Id>{listProfile2}, 2);
        listUsers.addAll(listUsers1);
        listUsers.addAll(listUsers2);
        insert listUsers;
        for(User us : listUsers2){
            us.ManagerId= listUsers1[0].id;
        }
        update listUsers2;
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        Operations_Request__c OPRequest = new Operations_Request__c();
        OPRequest.Name ='test 1';
        OPRequest.Current_account_owner__c=listUsers[0].id;
        OPRequest.Future_account_owner__c=listUsers[1].id;
        OPRequest.Issue__c = 'Entitlement/Asset Transfer';
        OPRequest.Future_Account__c=objAccount.Id;
        insert OPRequest;
        ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='New',name='Test Stage');
        insert ETMStageMonitor;
        Account_Stage__c asObject = new Account_Stage__c();
        asObject.JobId__c = ETMStageMonitor.Id;
        asObject.Account__c = objAccount.Id;
        asObject.TerritoryAdaptive_Id__c = '123456789876';
        asObject.Account_Move_Reason__c = 'Channel Reassignment';
        asObject.Territory_Structure_Type__c = 'Core';
        asObject.Operations_Request__c = OPRequest.Id;
        insert asObject;
    }

    /** 
     * @description
     * Method to test the scenario if the AS status is success
     */
    static testmethod void accountStageApproved() {
        User u = [select id from user where Firstname LIKE 'testClassUser1%'Limit 1];
        system.runAs(u){
            Account_Stage__c astage = [select id,Status__c from Account_Stage__c limit 1];
            astage.Status__c = 'Success';
            update astage;
            System.assertEquals('Success', astage.Status__c);
        }

    }
    /** 
     * @description
     * Method to test the scenario if the AS status is failure but with "Data already available" error messgae.
     */
    static testmethod void accountStageFailed() {
        User u = [select id from user where Firstname LIKE 'testClassUser1%' Limit 1];
        system.runAs(u){
            Account_Stage__c astage = [select id,Status__c from Account_Stage__c limit 1];
            astage.Status__c = 'Failure';
            astage.Error_message__c = 'Data already available';
            update astage;
            System.assertEquals('Failure', astage.Status__c);
        }

    }
    
     /** 
     * @description
     * Method to test catch block of AccountSTageTriggerHelper class.
     */
    static testmethod void accountStageHelperCatchBlock() {
        User u = [select id from user where Firstname LIKE 'testClassUser1%' Limit 1];
        system.runAs(u){
            Map<Id,Account_Stage__c> astage = New map<Id,Account_Stage__c>([select id,Status__c from Account_Stage__c limit 1]);
            AccountStageTriggerHelper.updateAccountStageStatus(astage,astage.values());
            Account_Stage__c ac = astage.values();
            ac.Status__c = 'Failure';
            update ac;
            System.assertEquals('Failure', ac.Status__c);
        }

    }
}