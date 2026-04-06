@isTest
private class MilestoneTest {

    @TestSetup
    static void setup() {
        TriggerControl__c setting = new TriggerControl__c();
        setting.Name = 'Entitlement';
        setting.DisableTrigger__c = False;
        upsert setting;
    }

    static testMethod void TestCompleteMilestoneCase(){

    List<Account> acts = new List<Account>();
    Account myAcc = new Account(Name='TestAct', phone='1001231234', Case_Notifications__c=false);
    acts.add(myAcc);

    Account busAcc = new Account(Name = 'TestForMS', phone='4567890999', Case_Notifications__c=false);
    acts.add(busAcc);
    insert acts;
    Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone='4567890999', accountid = busAcc.id);
    insert(cont);

    Id contactId = cont.Id;

    Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=busAcc.Id);
    insert entl;

    String entlId;
    if (entl != null)
    entlId = entl.Id;

    List<Case> cases = new List<Case>{};
    if (entlId != null){
        Case c = TestDataFactory.getCase(busAcc, cont); //new Case(Subject = 'Test Case with Entitlement ', AccountId=busAcc.Id,
        c.EntitlementId = entlId;        
        cases.add(c);
    }
    if (cases.isEmpty()==false){
    insert cases;

    List<Id> caseIds = new List<Id>();
    for (Case cL : cases){
    caseIds.add(cL.Id);
    }
    milestoneUtils.completeMilestone(caseIds, 'First Response', System.now());
    }
    }

    static testMethod void testCompleteMilestoneViaCase(){

    List<Account> acts = new List<Account>();
    Account myAcc = new Account(Name='TestAct', phone='1001231234', Case_Notifications__c=false);
    acts.add(myAcc);

    Account busAcc = new Account(Name = 'TestForMS', phone='4567890999', Case_Notifications__c=false);
    acts.add(busAcc);
    insert acts;
    Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone='4567890999', accountid = busAcc.id);
    insert(cont);

    Id contactId = cont.Id;

    Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=busAcc.Id);
    insert entl;

    String entlId;
    if (entl != null)
    entlId = entl.Id;

    List<Case> cases = new List<Case>{};
    for(Integer i = 0; i < 1; i++){
    Case c = new Case(Subject = 'Test Case ' + i);
    cases.add(c);
    if (entlId != null){
    c = new Case(Subject = 'Test Case with Entitlement ' + i,
    EntitlementId = entlId);
    cases.add(c);
        }
      }
    }
}