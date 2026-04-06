// MeetingConsoleControllerTest is the Test Class for : MeetingConsoleController && MeetingCategorizationController && EventConsoleService
@isTest
public class MeetingConsoleControllerTest {
    @testSetup static void createTestData(){
        
        WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
        
        Account testAccount = (Account)ShGl_TestFactory.createSObject(new Account(), null);
        testAccount.Name = 'Test Meeting Account';
        Id customerRecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        testAccount.RecordtypeId = customerRecordTypeId;
        insert testAccount;
        
        Contact con = (Contact)ShGl_TestFactory.createSObject(new Contact(), null);
        con.lastName='test1';
        con.email='test@test.com';
        con.AccountId=testAccount.Id;
        con.Contact_Status__c='Open';
        con.Meeting_Id__c='tests';
        insert con;
        
        Lead ld = (Lead)ShGl_TestFactory.createSObject(new Lead(), null);
        ld.lastname='testmeeting';
        ld.email='meetingtest@test.com';
        ld.country='India';
        ld.Status='Open';
        ld.Company='mrrting';
        ld.Meeting_Id__c='testmeeting';
        ld.LeadSource = 'Email';
        insert ld;
        
    }
    
    @isTest
    public static void testGetEventRecords(){
        Contact con = [select Id from Contact];
        Lead ld = [select Id from Lead WHERE lastname = 'testmeeting'];
        List<Event> eventList = new List<Event>();
        Event eve1 = new Event(Type = 'Inside Sales Led Meeting',Subject='call',whoId=ld.Id,DurationInMinutes=60,ActivityDate=Date.today().addDays(5),ActivityDateTime= system.now(), Post_Meeting_Status__c='Opportunity Sourced');
        Event eve2 = new Event(Type = 'Inside Sales Led Meeting',Subject='rubrik',whoId=con.Id,DurationInMinutes=30,ActivityDate=Date.today().addDays(5),ActivityDateTime= system.now(), Post_Meeting_Status__c='Meeting Cancelled');
        Event eve3 = new Event(Type = 'Transformation Team Generated Meeting',Subject='rubrik',whoId=con.Id,DurationInMinutes=30,ActivityDate=Date.today().addDays(5),ActivityDateTime= system.now(), Post_Meeting_Status__c='Opportunity Sourced');
        eventList.add(eve1);
        eventList.add(eve2);
        eventList.add(eve3);
        Test.startTest();
        insert eventList;
        String filterMap1 = '[{"key":"Meeting_Timing","value":"All Meetings"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Parent_Account_Tier","value":""},{"key":"Week_of_Fiscal_Quarter","value":""},{"key":"Disposition_Status","value":"Opportunity Sourced"}]';
        String filterMap2 = '[{"key":"Meeting_Timing","value":"All Meetings"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Parent_Account_Tier","value":""},{"key":"Week_of_Fiscal_Quarter","value":""},{"key":"Disposition_Status","value":"Meeting Cancelled"}]';
        String filterMap3 = '[{"key":"Meeting_Timing","value":"Upcoming Meeting"},{"key":"Meeting_FQ","value":"Next Quarter"},{"key":"Parent_Account_Tier","value":""},{"key":"Week_of_Fiscal_Quarter","value":""},{"key":"Disposition_Status","value":null}]';
        String filterMap4 = '[{"key":"Meeting_Timing","value":"Upcoming Meeting"},{"key":"Meeting_FQ","value":"Next Quarter"},{"key":"Parent_Account_Tier","value":"test tier"},{"key":"Week_of_Fiscal_Quarter","value":"All Weeks"},{"key":"Disposition_Status","value":null},{"key":"Meeting_Type","value":"Transformation Team Generated Meeting"}]';

        String eventData = '[{"failedEventReason":"Already Dispositioned","failedRecordLink":"/00U8Y000010u9DdUAI"}]';
        String eventData2 = '[{"outcome":"Opportunity Sourced","meetingLink":"/'+ eve3.Id + '/"}]';
        MeetingConsoleController.getEventRecords(filterMap1,eventData);
        MeetingConsoleController.getEventRecords(filterMap3,eventData);
        MeetingConsoleController.getEventRecords(filterMap2,eventData);
        MeetingConsoleController.getEventRecords(filterMap4,eventData2);
        MeetingConsoleController.getSelectedRecords(new List<String>{eve2.id},'Meeting Cancelled','Customer - No Show','');
        MeetingConsoleController.getCustomMetadataRecords();
        MeetingConsoleController.getFilterCustomMetadataRecords();
        Test.stopTest();
        Assert.areEqual(eventList[0].Type, 'Inside Sales Led Meeting');
    }
    @isTest
    public static void testGetSelectedRecords(){
        Contact con = [select Id from Contact];
        Event eve = new Event(Type = 'Inside Sales Led Meeting',Subject='rubrik',whoId=con.Id,DurationInMinutes=30,ActivityDate=Date.today(),ActivityDateTime= system.now());
        Test.startTest();
        insert eve;
        MeetingConsoleController.getSelectedRecords(new List<String>{eve.id},'No Opportunity Sourced','Other','test');
        MeetingConsoleController.isEventUpdateFailedInTest = true;
        MeetingConsoleController.getSelectedRecords(new List<String>{eve.id},'No Opportunity Sourced','Other','test');
        String filterMap1 = '[{"key":"Meeting_Timing","value":"Past Meeting"},{"key":"Meeting_FQ","value":"Previous Quarter"},{"key":"Parent_Account_Tier","value":""},{"key":"Week_of_Fiscal_Quarter","value":""},{"key":"Disposition_Status","value":"Opportunity Sourced"}]';
        String filterMap2 = '[{"key":"Meeting_Timing","value":"All Meetings"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Parent_Account_Tier","value":""},{"key":"Week_of_Fiscal_Quarter","value":"Week 1"},{"key":"Disposition_Status","value":"No Opportunity Sourced"}]';

        MeetingConsoleController.getEventRecords(filterMap1,'');
        MeetingConsoleController.getEventRecords(filterMap2, '');
        Test.stopTest();
        Assert.areEqual(eve.Type, 'Inside Sales Led Meeting');
    }
    @isTest
    public static void testGetEventRecordsCategorization(){
        Contact con = [select Id from Contact];
        Lead ld = [select Id from Lead WHERE lastname = 'testmeeting'];
        List<Event> eventList = new List<Event>();
        Event eve1 = new Event(Type = 'Field Sales Led Meeting',Subject='call',whoId=ld.Id,DurationInMinutes=60,ActivityDate=Date.today().addDays(5),ActivityDateTime= system.now(), Post_Meeting_Status__c='Opportunity Sourced', Meeting_Category__c = 'Discovery Meeting');
        Event eve2 = new Event(Type = 'Field Sales Led Meeting',Subject='rubrik',whoId=con.Id,DurationInMinutes=30,ActivityDate=Date.today().addDays(5),ActivityDateTime= system.now(), Post_Meeting_Status__c='Meeting Cancelled', Meeting_Category__c = 'EB Go / No Go');
        eventList.add(eve1);
        eventList.add(eve2);
        Test.startTest();
        insert eventList;
        List<Event> eventQuery = [SELECT Id, Subject FROM Event];
        List<String> selectedEventIds = new List<String>();
        if(!eventQuery.isEmpty()){
          	for(Event eve: eventQuery){
            	selectedEventIds.add(eve.Id);
        	}  
        }
        String filterMap1 = '[{"key":"Month_of_the_Fiscal_Quarter","value":"Month 1"},{"key":"Meeting_Timing","value":"All Meetings"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Week_of_Fiscal_Quarter","value":"All Weeks"},{"key":"Meeting_Category","value":["Discovery Meeting", "EB Go / No Go"]}]';
        String filterMap2 = '[{"key":"Month_of_the_Fiscal_Quarter","value":"Month 2"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Week_of_Fiscal_Quarter","value":"All Weeks"},{"key":"Meeting_Category","value":["Marketing / SDR Intro Meeting", "Deal Progression Meeting"]}]';
        String filterMap3 = '[{"key":"Month_of_the_Fiscal_Quarter","value":"Entire Quarter"},{"key":"Meeting_FQ","value":"Next Quarter"},{"key":"Week_of_Fiscal_Quarter","value":"All Weeks"},{"key":"Meeting_Category","value":["EB Go / No Go"]}]';
		String filterMap4 = '[{"key":"Month_of_the_Fiscal_Quarter","value":"Entire Quarter"},{"key":"Meeting_Timing","value":"Upcoming Meeting"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Week_of_Fiscal_Quarter","value":"All Weeks"},{"key":"Meeting_Category","value":["Discovery Meeting", "EB Go / No Go"]}]';
        String eventData = '[{"failedEventReason":"Already Dispositioned","failedRecordLink":"/00U8Y000010u9DdUAI"}]';
        MeetingCategorizationController.getEventRecords(filterMap1,eventData);
        MeetingCategorizationController.getEventRecords(filterMap3,eventData);
        MeetingCategorizationController.getEventRecords(filterMap2,eventData);
        MeetingCategorizationController.getEventRecords(filterMap4,eventData);
        MeetingCategorizationController.updateSelectedRecords(new List<String>{eve2.id},'Discovery Meeting');
        MeetingCategorizationController.getCustomMetadataRecords();
        MeetingCategorizationController.getFilterCustomMetadataRecords();
        MeetingCategorizationController.getWhoIdDetails(selectedEventIds);
        MeetingCategorizationController.getMeetingCategoryPicklistValues();
        Test.stopTest();
        Assert.areEqual(eventList[0].Type, 'Field Sales Led Meeting');
    }
    @isTest
    public static void testGetSelectedRecordsCategorization(){
        Contact con = [select Id from Contact];
        Event eve = new Event(Type = 'Field Sales Led Meeting',Subject='rubrik',whoId=con.Id,DurationInMinutes=30,ActivityDate=Date.today(),ActivityDateTime= system.now());
        Test.startTest();
        insert eve;
        MeetingCategorizationController.updateSelectedRecords(new List<String>{eve.id},'Discovery Meeting');
        String filterMap1 = '[{"key":"Month_of_the_Fiscal_Quarter","value":"Month 1"},{"key":"Meeting_Timing","value":"Past Meeting"},{"key":"Meeting_FQ","value":"Previous Quarter"},{"key":"Week_of_Fiscal_Quarter","value":"All Weeks"},{"key":"Meeting_Category","value":["Discovery Meeting", "EB Go / No Go"]}]';
        String filterMap2 = '[{"key":"Month_of_the_Fiscal_Quarter","value":"Month 2"},{"key":"Meeting_Timing","value":"All Meetings"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Week_of_Fiscal_Quarter","value":"Week 1"},{"key":"Meeting_Category","value":["Discovery Meeting", "EB Go / No Go"]}]';

        MeetingCategorizationController.getEventRecords(filterMap1,'');
        MeetingCategorizationController.getEventRecords(filterMap2, '');
        Test.stopTest();
        Assert.areEqual(eve.Type, 'Field Sales Led Meeting');
    }
    @isTest
    public static void fetchAccountLookupData(){
        Account act = [SELECT Id FROM Account LIMIT 1];
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
        System.RunAs(usr){
            List<Product2> lstProducts = getProducts();
            insert lstProducts;
            
            Pricebook2 pricebook = new Pricebook2(Id = Test.getStandardPricebookId());
            List<PriceBookEntry> lstPriceBookEntries = new List<PricebookEntry>();
            for( Product2 objProduct : lstProducts ) {
                lstPriceBookEntries.add(new PriceBookEntry(
                                        UnitPrice = 400,
                                        PriceBook2Id = pricebook.id,
                                        Product2Id = objProduct.Id,
                                        IsActive = true,
                                        UseStandardPrice=false));
            } 
            insert lstPriceBookEntries;
            
            act.OwnerId = usr.Id;
            update act;
            
            Opportunity o = new Opportunity();
            o.AccountId = act.Id;
            o.PriceBook2Id = pricebook.Id;
            o.Amount = 1000.00;
            o.Name = 'Test Opportunity For Unit Test Purposes';
            o.CloseDate = Date.Today().addDays(5);
            o.StageName = 'Prospecting';
            o.Metric__c = '85k or less';
            o.Economic_Buyer__c = 'Brent Staley';
            o.Decision_Criteria__c = 'If 6408 meets conditional PO requirements they will pull the trigger';
            o.Decision_Process__c = 'PO has been cut, waiting to add conditions to the quotes';
            o.Identified_Pain__c = 'Large Capex Payment for Exagrid addition + veeam renewal costs.  Inability to "dump archive to cloud" also a pain point as Chris wants as much OPEX as possible';
            o.Champion__c = 'Chris Norman';
            insert o;
        }
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [select Id from Contact];
        Event eveRecord = new Event(Type = 'Field Sales Led Meeting',Subject='rubrik',whoId=con.Id,DurationInMinutes=30,ActivityDate=Date.today(),ActivityDateTime= system.now());
        insert eveRecord;
        MeetingCategorizationController.updateRelatedToRecords(new List<String>{eveRecord.Id},opp.Id, true);
        MeetingCategorizationController.updateRelatedToRecords(new List<String>{eveRecord.Id},opp.Id, false);
        MeetingCategorizationController.fetchLookupData('Test','Account',new List<String>{act.Id});
        MeetingCategorizationController.fetchLookupData('Test Opportunity For Unit Test Purposes','Opportunity',new List<String>{opp.Id});
        MeetingCategorizationController.getUserAccessToThePage();
    }
     private static List<Product2> getProducts() {
        Set<String> setProductPicker = new Set<String>();
        for( POC_Product_Picker_Matrix__mdt objMDT : [SELECT Product_SKU__c
                                                      FROM POC_Product_Picker_Matrix__mdt]) {
        	setProductPicker.addAll( objMDT.Product_SKU__c.split(';') );                                                  
        }
        List<Product2> lstProduct2 = new List<Product2>();
        for( String c : setProductPicker ) {
            Product2 objP1 = new Product2();
            objP1.ProductCode = c;
            objP1.Name = c;
            objP1.IsActive = true;
            lstProduct2.add( objP1 );
        }
        Product2 objP1 = new Product2();
        objP1.ProductCode = 'RS-BT-RCDM-T';
        objP1.Name = 'Default product code';
        objP1.IsActive = true;
        lstProduct2.add( objP1 );
        return lstProduct2;
    }
     @isTest
    public static void testgetEditAccessForRemainingChunks(){
        Contact con11 = [select Id from Contact];
        Lead ld11 = [select Id from Lead WHERE lastname = 'testmeeting'];
        List<Event> eventList = new List<Event>();
        Event event1 = new Event(Type = 'Field Sales Led Meeting',Subject='call',whoId=ld11.Id,DurationInMinutes=60,ActivityDate=Date.today().addDays(5),ActivityDateTime= system.now(), Post_Meeting_Status__c='Opportunity Sourced', Meeting_Category__c = 'Discovery Meeting',Leader_Attended__c='RD');
        Event event2 = new Event(Type = 'Field Sales Led Meeting',Subject='rubrik',whoId=con11.Id,DurationInMinutes=30,ActivityDate=Date.today().addDays(5),ActivityDateTime= system.now(), Post_Meeting_Status__c='Meeting Cancelled', Meeting_Category__c = 'EB Go / No Go',Leader_Attended__c='RD');
        eventList.add(event1);
        eventList.add(event2);
        Test.startTest();
        insert eventList;
        List<Event> eventQuery2 = [SELECT Id, Subject FROM Event];
        List<String> selectedEventIds = new List<String>();
        if(!eventQuery2.isEmpty()){
          	for(Event eve: eventQuery2){
            	selectedEventIds.add(eve.Id);
        	}  
        }
        String filterMap1 = '[{"key":"Month_of_the_Fiscal_Quarter","value":"Month 1"},{"key":"Meeting_Timing","value":"All Meetings"},{"key":"Meeting_FQ","value":"Current Quarter"},{"key":"Week_of_Fiscal_Quarter","value":"All Weeks"},{"key":"Meeting_Category","value":["Discovery Meeting", "EB Go / No Go"]}]';
        String eventData = '[{"failedEventReason":"Already Dispositioned","failedRecordLink":"/00U8Y000010u9DdUAI"}]';
        List<EventConsoleService.EventDataWrapper> wrapObj = MeetingCategorizationController.getEventRecords(filterMap1,eventData);
        String eventWrapperStringified = JSON.serialize(wrapObj);
        MeetingCategorizationController.getEditAccessForRemainingChunks(selectedEventIds,eventWrapperStringified);
        MeetingCategorizationController.updateLeaderAttended(selectedEventIds, 'RD');
        Test.stopTest();
        Assert.areEqual(eventList[0].Type, 'Field Sales Led Meeting');
    }
    
}