@isTest
private class specialistRequestTrigger_Test {
    
    @isTest static void test_method_one() {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;
        insert custsetting; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = true;
        insert disableFuncCS;
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
            'Email'  =>'leademail@hidden.com'
        };
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
            'Initial_Contacts_Name__c' => cnt1.Id,
            'Primary_Competitor__c' => 'Other',
            'Other_Primary_Competitor__c' => 'Other',
            'StageName' => '1 Discovery',
            'Other_Competitor_Field__c' => 'Other',
            'ForecastCategoryName' => 'Best Case'
        };
        Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;

        Specialist_Request__c req = new Specialist_Request__c(
            Account__c = acct.Id,
            Background_on_Primary_Attendees__c = 'Rangers',
            Challenges__c = 'Unavailability', 
            Date_of_Meeting__c = Date.today(), 
            Goal_Of_Meeting__c = 'Specialist Request',
            Location__c = 'Onsite', 
            On_Site_Justification__c = 'NA', 
            Opportunity__c = oppty.Id, 
            Primary_Focus_Area__c = 'Cloud', 
            RecordTypeId = Schema.SObjectType.Specialist_Request__c.getRecordTypeInfosByName().get('Ranger').getRecordTypeId(), 
            Relevant_Areas_Already_Covered__c = 'India', 
            Secondary_Focus_Area__c = 'AWS', 
            Status__c = 'Draft', 
            Type__c = 'Demo'
            );

        insert req;

        req.Status__c = 'Specialist Accepted';
        req.Specialist_Assigned__c = UserInfo.getUserId();
        update req;

        delete req;
    }
}