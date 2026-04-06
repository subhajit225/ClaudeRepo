/*********************************************************************************
  *@description  : Test Class for RollupSummaryUtility
**********************************************************************************/
@isTest
public class RollupSummaryUtilityTest {
    /**
       *@description Test Method of Rollup Test Class
    */
    public static testmethod void rollUpSummaryUtility(){
        System.runAs(new User(Id = UserInfo.getUserId())){
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            sdb.Disable_Opportunity_Validation_Rules__c = true;
            sdb.Disable_Account_Validation_Rules__c = true;
            insert sdb;
            List<case> caseList = new List<Case>();
            Case newCase1 = new Case(AccountId = acc.id, Subject = 'Test', Priority = 'P1');
            Case newCase2 = new Case(AccountId = acc.id, Subject = 'Test', Priority = 'P2');
            Case newCase3 = new Case(AccountId = acc.id, Subject = 'Test', Priority = 'P3');
            caseList.add(newCase1);
            caseList.add(newCase2);
            caseList.add(newCase3);
            insert caseList;
            
            
            List<TriggerControl__c> settings = new List<TriggerControl__c>();
            TriggerControl__c customSetting = new TriggerControl__c(Name = 'Opportunity',SetupOwnerId=UserInfo.getOrganizationId(),DisableTrigger__c = false);
            settings.add(customSetting);
            insert settings;
            
            Opportunity opp = new Opportunity(Name = 'Test Opp',Accountid = acc.Id, Stagename = '1 Discovery',CloseDate = system.today());
            insert opp;
            
            List<Opportunity_Debrief__c> oppDebList = new List<Opportunity_Debrief__c>();
            Opportunity_Debrief__c oppDeb = new Opportunity_Debrief__c(Area__c = 'Rubrik',Opportunity__c = opp.Id);
            oppDebList.add(oppDeb);
            Insert oppDebList;
            
            
            Map<Id,Opportunity_Debrief__c> oppDebIdToOppDeb = new Map<Id,Opportunity_Debrief__c>();
            oppDebIdToOppDeb.put(oppDeb.Id, oppDeb);
            RollupSummaryUtility.rollupIssueTrackerOnOppty(oppDebList, null);
            
            Test.starttest();
            RollupSummaryUtility.rollupCasesOnAccount(caseList, null);
            CaseTriggerHandler.isRepeat = false;
            newCase3.Priority = 'P4';
            update newCase3;
            Map<Id,Case> oldCase = new Map<Id,Case>([SELECT id,Priority,IsClosed FROM Case]);
            RollupSummaryUtility.rollupCasesOnAccount(caseList, oldCase);

            Test.stopTest();
            List<Account> accounts = [SELECT Id, Cases_Count__c, No_Of_Open_Support_Cases__c, Cases_Open_P1__c, Cases_Open_P2__c 
                                    FROM Account Where Id = :acc.Id LIMIT 1];
            
            system.assertEquals(3, accounts[0].Cases_Count__c);
            system.assertEquals(3, accounts[0].No_Of_Open_Support_Cases__c);
            system.assertEquals(1, accounts[0].Cases_Open_P1__c);
            system.assertEquals(1, accounts[0].Cases_Open_P2__c);

        }
        
    }
}