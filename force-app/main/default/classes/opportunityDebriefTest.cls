@isTest
public class opportunityDebriefTest {
    public static List < Opportunity > opptyList;
    public static List < Opportunity_Debrief__c > defList;
 @testSetup static void createTestData() {
     opptyList = new List < Opportunity >();
     ShGl_TestFactoryHelper.insertCustomSettings();
     ShGl_TestFactoryHelper.WorkflowTriggerBypass();
     Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
     insert act;
     
      //Generate the Contact
        Map < String, Object > cntMap = new Map < String, Object > {
            'AccountId' => act.Id,
                'Email' => 'leademail@hidden.com'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt1; 
     //Generate the Opportunity
        Map < String, Object > oppMap = new Map < String, Object > {
            'AccountId' => act.Id,
                'StageName' => '4 Business Justification'
                };
        
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c();
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        insert sdb;
                    
        opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
        opptyList[0].Lead_Email_Hidden__c = 'leademail123@hidden.com';
        opptyList[0].Converted_From_Lead__c = true;
        opptyList[0].SBQQ__Ordered__c = true;
        opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
        opptyList[0].Primary_Competitor__c = 'Other';
        opptyList[0].ForecastCategoryName = 'Best Case';
        opptyList[0].Other_Competitor_Field__c = 'Testing';
        opptyList[0].Has_Polaris_Product__c = true;
        insert opptyList;
     

 }
    static testMethod void testMethod_CodeCoverage_1() {
     ShGl_DisableBusinessLogic__c modifydfl = new ShGl_DisableBusinessLogic__c();   
     modifydfl.Disable_Opportunity_Validation_Rules__c = false;
     modifydfl.SetupOwnerId = userinfo.getUserId();
     insert modifydfl;
        
     defList = new List < Opportunity_Debrief__c >();   
     Opportunity op = [select Id,StageName, What_did_we_think_would_happen__c, What_really_happened__c, What_was_the_difference__c,What_worked_well__c,What_didn_t_work__c,What_would_we_do_different_next_time__c, Lost_Reason__c, Primary_Competitor__c, Other_Competitor_Field__c, Lost_To_Won_Against__c, Incumbent__c from Opportunity limit 1];   
     Opportunity_Debrief__c def = new Opportunity_Debrief__c();
     def.Area__c = 'Missing Feature';
     def.Area_Detail__c = 'CDM';
     def.Area_Sub_Detail__c = 'Exchange';
     def.Severity__c = 'Blocker';
     def.Opportunity__c = op.Id;
     insert def;
     Opportunity_Debrief__c def1 = new Opportunity_Debrief__c();
     def1.Area__c = 'Missing Feature';
     def1.Area_Detail__c = 'CDM';
     def1.Area_Sub_Detail__c = 'Exchange';
     def1.Severity__c = 'Blocker';
     def1.Opportunity__c = op.Id;
     defList.add(def1);
        PageReference pageRef = Page.opportunityDebrief;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(op.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(op);
        opportunityDebrief defcont = new opportunityDebrief(sc);
        defcont.addContactList = defList;
        defcont.addRow();
        defcont.theOpp = op;
        defcont.save();
    }
    static testMethod void testMethod_CodeCoverage_2() {
     defList = new List < Opportunity_Debrief__c >();
     
     Opportunity op = [select Id,StageName, What_did_we_think_would_happen__c, What_really_happened__c, What_was_the_difference__c,What_worked_well__c,What_didn_t_work__c,What_would_we_do_different_next_time__c, Lost_Reason__c, Primary_Competitor__c, Other_Competitor_Field__c, Lost_To_Won_Against__c, Incumbent__c from Opportunity limit 1];   
     Opportunity_Debrief__c def1 = new Opportunity_Debrief__c();
     def1.Area__c = 'Missing Feature';
     def1.Area_Detail__c = 'CDM';
     def1.Area_Sub_Detail__c = 'Exchange';
     def1.Severity__c = 'Blocker';
     def1.Opportunity__c = op.Id;
     defList.add(def1);
        Test.startTest();
        PageReference pageRef = Page.opportunityDebrief;
        ApexPages.currentPage().getParameters().put('rowIndex','0');
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(op.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(op);
        opportunityDebrief defcont = new opportunityDebrief(sc);
        defcont.addContactList = defList;
        defcont.theOpp = op;
        defcont.addRow();
        defcont.save();
        defcont.contactList = null;
        defcont.addRow();
        Test.stopTest();
        system.assertEquals(def1.Opportunity__c,op.Id);
    }
    static testMethod void testMethod_DeleteRow() {
     defList = new List < Opportunity_Debrief__c >();
     
     Opportunity op = [select Id,StageName, What_did_we_think_would_happen__c, What_really_happened__c, What_was_the_difference__c,What_worked_well__c,What_didn_t_work__c,What_would_we_do_different_next_time__c, Lost_Reason__c, Primary_Competitor__c, Other_Competitor_Field__c, Lost_To_Won_Against__c, Incumbent__c from Opportunity limit 1];   
     Opportunity_Debrief__c def1 = new Opportunity_Debrief__c();
     def1.Area__c = 'Missing Feature';
     def1.Area_Detail__c = 'CDM';
     def1.Area_Sub_Detail__c = 'Exchange';
     def1.Severity__c = 'Blocker';
     def1.Opportunity__c = op.Id;
     defList.add(def1);
        Test.startTest();
        PageReference pageRef = Page.opportunityDebrief;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(op.Id));
        pageRef.getParameters().put('rowIndex', '0');
        ApexPages.StandardController sc = new ApexPages.StandardController(op);
        opportunityDebrief defcont = new opportunityDebrief(sc);
        defcont.addContactList = defList;
        defcont.theOpp = op;
        defcont.addRow();
        defcont.save();
        defcont.addRow();
        defcont.rowIndex = 0;
        defcont.deleteRow();
        Test.stopTest();
        system.assertEquals(def1.Opportunity__c,op.Id);
    }
    //SF-3223 : code coverage for rollup OpportunityDebriefTriggerHandler
    static testMethod void testMethod_CodeCoverage_3() {
         defList = new List < Opportunity_Debrief__c >();
     
         Opportunity op = [select Id ,Incumbent__c from Opportunity limit 1];   
         Opportunity_Debrief__c def1 = new Opportunity_Debrief__c();
         def1.Area__c = 'Missing Feature';
         def1.Area_Detail__c = 'CDM';
         def1.Area_Sub_Detail__c = 'Exchange';
         def1.Severity__c = 'Blocker';
         def1.Opportunity__c = op.Id;
         defList.add(def1);
         insert defList;
         
         Test.startTest();
            delete defList;
         Test.stopTest();
        system.assertEquals(def1.Opportunity__c,op.Id);
    }
}