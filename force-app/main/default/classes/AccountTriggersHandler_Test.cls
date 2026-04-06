/********************************************************************************************************
* Name              : AccountTriggersHandler_Test
* Purpose           : AccountTriggersHandler_Test is Used for Testing AccountTriggersHandler Class
*********************************************************************************************************/
@isTest
public class AccountTriggersHandler_Test{

    @testSetup
    static void setupDataForAccountTriggerHandler(){
        insert new SOX_Objects_Delete_Access__c(SetupOwnerId=UserInfo.getUserId(), Allow_Account_Delete__c=true);
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        PatchManagerSettings__c settingDisable2 = new PatchManagerSettings__c();
        settingDisable2.Name = 'Test Setting';
        settingDisable2.Route_on_Insert_Account__c = true;
        //settingDisable2.Segment_Revenue__c = 50000;
        settingDisable2.Default_Account_User__c = '0051W000003q27P';
        insert settingDisable2;
    }

    static testMethod void testMethod_AccountOwnerUpdate(){

        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
		Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.type = 'Customer';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.ParentId = act1.id;
        act.RSC_G_Eligible__c = true;
        act.Account_Preference__c = 'Strategic Account';
        act.U_S_citizen_service__c = 'Exception approval';
        system.debug('act :: '+act);
        insert act;

        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(2, actList.size());
        insert new AccountShare(AccountAccessLevel = 'Edit',AccountId =act.Id, RowCause = 'Manual', UserOrGroupId = usr.Id,OpportunityAccessLevel = 'Read');

        Test.startTest();
        System.RunAs(usr){
            act.OwnerId = usr.Id;
            act.U_S_citizen_service__c = 'Exception approval';
            act.Pooled_SE_Override__c = true;
            act.Account_Deal_Desk_Notes__c = 'dummy note';
            update act;
            try{
                act.OwnerId = usr.Id;
                act.U_S_citizen_service__c = 'Purchased';
                act.Type = 'Prospect';
                act.Pooled_SE_Override__c = false;
                act.Account_Preference__c = '';
                act.Account_Deal_Desk_Notes__c = 'Changed dummy note';
                update act;
            }catch(Exception e){
                System.debug(System.LoggingLevel.DEBUG, 'account update failed');
            }
        }
        Test.stopTest();

        Account actUpd = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :act.Id];
        System.assertEquals(act.Name, actUpd.Name);
        System.assertEquals(usr.Id, actUpd.OwnerId);
    }
    
    static testMethod void testMethod_updateSalesEngineer(){

        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
		Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.ParentId = act1.id;
        act.RSC_G_Eligible__c = true;
		act.U_S_citizen_service__c = 'Exception approval';        
        system.debug('act :: '+act);
        insert act;

        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(2, actList.size());
        insert new AccountShare(AccountAccessLevel = 'Edit',AccountId =act.Id, RowCause = 'Manual', UserOrGroupId = usr.Id,OpportunityAccessLevel = 'Read');

        Test.startTest();
        System.RunAs(usr){
            act.OwnerId = usr.Id;
            act.Type = 'FSI';
            act.Rubrik_Sales_Engineer__c = usr.Id;
            act.Pooled_SE_Override__c = true;
            act.U_S_citizen_service__c = '';
            act.Account_Preference__c = 'Strategic Account';
            update act;
        }
        
        System.runAS(new User(Id=UserInfo.getUserId())){
            act.Adaptive_Territory_Id__c = 'test';
            update act;
        }
        Test.stopTest();

        Account actUpd = [SELECT Id,Type,Rubrik_Sales_Engineer__c,Adaptive_Territory_Id__c, Name, OwnerId FROM Account WHERE Id = :act.Id];
        System.assertEquals(act.Type, actUpd.Type);
        System.assertEquals(act.Rubrik_Sales_Engineer__c, actUpd.Rubrik_Sales_Engineer__c);
        System.assertEquals(act.Adaptive_Territory_Id__c, actUpd.Adaptive_Territory_Id__c);
    }

    static testMethod void testMethod_AccountOwnerCEMUpdate(){

        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;

        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act :: '+act);
        insert act;

        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(1, actList.size());
        insert new AccountShare(AccountAccessLevel = 'Edit',AccountId =act.Id, RowCause = 'Manual', UserOrGroupId = usr.Id,OpportunityAccessLevel = 'Read');

        Test.startTest();
        System.RunAs(usr){
            act.OwnerId = usr.Id;
            act.Account_SAM__c = usr.Id;
            update act;
        }
        Test.stopTest();

        Account actUpd = [SELECT Id, Name, OwnerId, Account_SAM__c FROM Account WHERE Id = :act.Id];
        System.assertEquals(act.Name, actUpd.Name);
        System.assertEquals(usr.Id, actUpd.OwnerId);
        System.assertEquals(usr.Id, actUpd.Account_SAM__c);
    }

    static testMethod void testMethod_CEMUpdate(){

        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;

        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act :: '+act);
        insert act;

        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(1, actList.size());
        insert new AccountShare(AccountAccessLevel = 'Edit',AccountId =act.Id, RowCause = 'Manual', UserOrGroupId = usr.Id,OpportunityAccessLevel = 'Read');

        Test.startTest();
        System.RunAs(usr){
            act.Account_SAM__c = usr.Id;
            update act;
        }
        Test.stopTest();

        Account actUpd = [SELECT Id, Name, Account_SAM__c FROM Account WHERE Id = :act.Id];
        System.assertEquals(act.Name, actUpd.Name);
        System.assertEquals(usr.Id, actUpd.Account_SAM__c);
    }

    static testMethod void testDelete(){
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        //Account acc = [Select id from Account limit 1];
        act.ParentId = act1.id;
        act.RSC_G_Eligible__c = true;
        act.Type = 'Prospect';
        update act;
	    if(act != null){
            delete act;
            undelete act;
        }
        /*AccountTriggersHandler  handler = new AccountTriggersHandler();
        handler.beforeDelete();
        handler.afterDelete();
        handler.afterUndelete();*/

    }

    // CS21-1550: [FedRAMP] Disable proactive cases: FedRAMP Customer
    @IsTest
    static void disableProactiveCaseCreationFedRamptest(){
        
        Account objAcc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        Test.startTest();
            objAcc.RSC_G_Support__c = 'RSC-G';
            INSERT objAcc;
        Test.stopTest();
        Account actUpdt = [SELECT Id, Snooze_Alerts_Until__c FROM Account WHERE Id =: objAcc.Id];
        System.assertNotEquals(actUpdt.Snooze_Alerts_Until__c, null);
    }

    // CS21-1550: [FedRAMP] Disable proactive cases: Non FedRAMP Customer
    @IsTest
    static void disableProactiveCaseCreationNonFedRamptest(){
        User u = [Select id from user where Profile.Name = 'System Administrator' and isActive = true limit 1];
        System.runAs(u){
            Account objAcc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            objAcc.RSC_G_Support__c = 'RSC-G';
            INSERT objAcc;
            Test.startTest();
            objAcc.RSC_G_Support__c = 'RSC-G;RSC/CDM';
            objAcc.Is_Customer_Fully_Transitioned__c = true;
            objAcc.Disable_Auto_OwnerAssignment__c = true;
            objAcc.Contract_Negotiation__c = true;
            objAcc.EULA_revision_Required__c = true;
            UPDATE objAcc;
            objAcc.EULA_revision_Required__c = false;
            objAcc.Disable_Auto_OwnerAssignment__c = false;
            objAcc.Deactivate_Smart_Hands__c = true;
            objAcc.Customer_Type_Without_RCV__c = 'Cloud Customer w/o RCV';
            UPDATE objAcc;
            Test.stopTest();
            Account actUpdt = [SELECT Id, Snooze_Alerts_Until__c FROM Account WHERE Id =: objAcc.Id];
            System.assertEquals(actUpdt.Snooze_Alerts_Until__c, null);
        }
    }
}