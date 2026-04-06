@isTest
public class createRenewalCaseControllerTest {
    static TriggerControl__c getTriggerControl(){
        TriggerControl__c tc= new TriggerControl__c();
        tc.Name='Opportunity';
        tc.DisableTrigger__c = false;
        return tc;
    }
    static testMethod void test1(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        ServiceContract sc = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3, SBQQSC__Opportunity__c = tempOpp.Id);
        insert sc;
        Test.startTest();
        createRenewalCaseController.checkStatus(acc.Id);
        Test.stopTest();
    }
    static testMethod void test2(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        ServiceContract sc = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3, SBQQSC__Opportunity__c = tempOpp.Id);
        insert sc;
        ServiceContract sc2 = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3);
        insert sc2;
        Test.startTest();
        createRenewalCaseController.checkStatus(acc.Id);
        Test.stopTest();
    }
    static testMethod void testOldCs(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        ServiceContract sc = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3, SBQQSC__Opportunity__c = tempOpp.Id);
        insert sc;
        ServiceContract sc2 = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3);
        insert sc2;
        Case cs = new Case(Priority = 'P4', Platform__c = 'Other', Subject = 'Test', Description = 'Testing', AccountId = acc.Id, ServiceContractId = sc.Id);
        insert cs;
        Test.startTest();
        createRenewalCaseController.checkStatus(acc.Id);
        Test.stopTest();
    }
    static testMethod void test3(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        ServiceContract sc = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3, SBQQSC__Opportunity__c = tempOpp.Id);
        insert sc;
        Case cs = new Case(Priority = 'P4', Platform__c = 'Other', Subject = 'Test', Description = 'Testing', AccountId = acc.Id, ServiceContractId = sc.Id);
        insert cs;
        Test.startTest();
        createRenewalCaseController.checkStatus(acc.Id);
        Test.stopTest();
    }
    static testMethod void test4(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        ServiceContract sc = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3, SBQQSC__Opportunity__c = tempOpp.Id);
        insert sc;
        sc = [Select Id,Name,ContractNumber,Status,Account.Name,AccountId,StartDate,EndDate,SBQQSC__Opportunity__c from ServiceContract where Id=:sc.Id];
        createRenewalCaseController.scWrapper wrap = new createRenewalCaseController.scWrapper(sc.Id,sc.Name,sc.ContractNumber,sc.Status,sc.Account.Name,sc.AccountId,sc.StartDate,sc.EndDate,null,sc.SBQQSC__Opportunity__c);
        String seralize = JSON.serialize(wrap);
        Test.startTest();
        createRenewalCaseController.createCase(seralize);
        Test.stopTest();
    }
    static testMethod void test5(){
        TriggerControl__c triggerCntlr= getTriggerControl();
        insert triggerCntlr;
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Opportunity tempOpp= new Opportunity(name='Temp Opp', OwnerID=UserInfo.getUserId(),accountId=acc.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@email.com',closeDate=Date.today());
        insert tempOpp;
        ServiceContract sc = new ServiceContract(Name = 'Test', AccountId = acc.Id, StartDate = System.today(), Term = 3, SBQQSC__Opportunity__c = tempOpp.Id);
        insert sc;
        Case cs = new Case(Priority = 'P4', Platform__c = 'Other', Subject = 'Test', Description = 'Testing', AccountId = acc.Id, ServiceContractId = sc.Id);
        insert cs;
		sc = [Select Id,Name,ContractNumber,Status,Account.Name,AccountId,StartDate,EndDate,SBQQSC__Opportunity__c from ServiceContract where Id=:sc.Id];
        createRenewalCaseController.scWrapper wrap = new createRenewalCaseController.scWrapper(sc.Id,sc.Name,sc.ContractNumber,sc.Status,sc.Account.Name,sc.AccountId,sc.StartDate,sc.EndDate,null,sc.SBQQSC__Opportunity__c);
        String seralize = JSON.serialize(wrap);
        Test.startTest();
        createRenewalCaseController.createCase(seralize);
        Test.stopTest();
    }
}