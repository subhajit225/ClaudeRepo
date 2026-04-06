@isTest(SeeAllData=false)
public class IntegrationLogMainTest {

    public static testMethod void testLogs() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(
            setupownerid = userinfo.getuserid(),
            Disable_Integration_Error_Log_Trigger__c = false,
            TriggerMaxLoopCount__c = 6
        );
        insert cdf;

        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = False;
        insert setting1;
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='tAccount', RecordTypeId = partnerRecordTypeId);
        insert acct;
         Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        Date closeDt = System.Today()+30;
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' , Initial_Contacts_Name__c = cnt.Id, AccountId= acct.Id,StageName = '4 Business Justification',
                                            CloseDate = closeDt, Lead_Email_Hidden__c='', partner_lookup__c=acct.id, Alliance_Partner_Name__c='Amazon', 
                                            Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c='FE Install');
        insert oppr;

        Order od = new Order();
        od.AccountId = acct.Id;
        od.OpportunityId =oppr.Id;
        od.EffectiveDate = Date.Today();
        od.Order_Status__c = 'PO Received';
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        insert od;

        List<Error_Logs__C> logs = new List<Error_Logs__C>();
        logs.add(new Error_Logs__C(Related_Order__c=od.Id,Success__c =true));
        logs.add(new Error_Logs__C(Related_Order__c=od.Id, Type__c = 'Integration', Error_Type__c = 'Restricted Party Screening', Success__c =false));
        logs.add(new Error_Logs__C(Related_Order__c=od.Id, Type__c = 'Integration', Error_Type__c = 'Order Fulfillment', Success__c =false));
        logs.add(new Error_Logs__C(Account__c=acct.Id,Success__c =false));
        logs.add(new Error_Logs__C(Account__c=acct.Id,Success__c =true));
		IntegrationLogMainTriggerHelper.updateFieldsOnInsert(logs);
        insert logs;

        update logs[0];
    }
}