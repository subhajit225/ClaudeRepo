/********************************************************************************************************
* Name              : AccountTriggerHandler_Test
* Purpose           : AccountTriggerHandler_Test is Used for Testing AccountTriggerHandler Class
*********************************************************************************************************/
@isTest
public class AccountTriggerHandler_Test{ 
    
    static testMethod void testAccountTriggerHandler(){
        testDataFactoryClass.createCustomSettings();
        
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=false);
        List<Account> actList = new List<Account>();
        Map<Id, Account> actMap = new Map<Id, Account>();
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',type='Customer');
        act.rerun_PatchManager__c =true;
        actList.add(act);
        insert actList;
        
        for(Account acc:actList){
            actMap.put(acc.id,acc);
        }
        
        
        Test.startTest();
        PatchManager.ROUTE_ON_INSERT_ACCOUNT=false;
        AccountTriggerHandler actTrigHandler = new AccountTriggerHandler();
        actTrigHandler.bulkAfter();
        actList[0].rerun_PatchManager__c = false;
        actTrigHandler.beforeInsert(actList[0]); 
        actTrigHandler.beforeUpdate(null,actList[0]);
        actTrigHandler.beforeDelete(null);
        actTrigHandler.afterInsert(null);
        actTrigHandler.afterUpdate(null,null);
        actTrigHandler.afterDelete(null);
        actTrigHandler.andFinally();
        Test.stopTest();
    }
}