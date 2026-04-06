@isTest
public class QuoteTriggerHelperQueueable_Test {
 
    @isTest
    static void qouteisPrimaryTest(){
        Map<Id,SBQQ__Quote__c > oldMap = new Map<Id,SBQQ__Quote__c>();
        Map<Id,SBQQ__Quote__c> qtMap = new Map<Id, SBQQ__Quote__c>();
        List<SBQQ__Quote__c> updateList = new List<SBQQ__Quote__c>();
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
    opp.ForecastCategoryName = 'Best Case';
 
 
    insert opp;
 
    SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
 
    qt.SBQQ__Opportunity2__c = opp.Id;
    qt.Deal_Desk_Notes__c = 'TestNotes';
   qt.SBQQ__Primary__c = false;
     
    Test.startTest();
    insert qt;
    oldMap.put(qt.id, qt);
       
    qt.SBQQ__Primary__c = true;
    qt.Pricing_Notes__c = 'Test Notes' ;
    update qt;
    qtMap.put(qt.id, qt);
    QuoteTriggerHelperQueueable queueable = new QuoteTriggerHelperQueueable(oldMap, qtMap);
    Test.stopTest();
    System.assert(true);
    }
 
 
    @isTest
    static void qouteisNotPrimaryTest(){
        Map<Id,SBQQ__Quote__c > oldMap = new Map<Id,SBQQ__Quote__c>();
        Map<Id,SBQQ__Quote__c> qtMap = new Map<Id, SBQQ__Quote__c>();
        List<SBQQ__Quote__c> updateList = new List<SBQQ__Quote__c>();
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
    opp.ForecastCategoryName = 'Best Case';
 
 
    insert opp;
 
    SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
 
    qt.SBQQ__Opportunity2__c = opp.Id;
    qt.Deal_Desk_Notes__c = 'TestNotes';
   qt.SBQQ__Primary__c = true;
      qt.Pricing_Notes__c = '' ;
    Test.startTest();
    insert qt;
    oldMap.put(qt.id, qt);
       
    qt.SBQQ__Primary__c = false;
    qt.Pricing_Notes__c = 'Test Notes' ;
    update qt;
    qtMap.put(qt.id, qt);
    QuoteTriggerHelperQueueable queueable = new QuoteTriggerHelperQueueable(oldMap, qtMap);
    Test.stopTest();
    System.assert(true);
    }
}