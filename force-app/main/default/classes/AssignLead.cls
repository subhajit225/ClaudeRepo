@isTest(seeAllData=true)
private class AssignLead {

    public static List<Lead> leadList;
   
    static void init(){
        leadList = new List<Lead>();
    }

    static testMethod void testLeadAutoAssignWithStateAndCity() {
        init();
        Test.startTest();
     
        // Try to ensure the lead created matches one of our zips.
        // Coverage will drop if it doesn't match
        leadList.add(new Lead(
            LastName = 'test',
            Company = 'test1',
            Deal_Registration__c = true,
            City = 'Alameda',
            State = 'California',
            Country = 'United States'
        ));
        insert leadList;
        Test.stopTest();
    }
    
    static testMethod void testLeadAutoAssignSkipAssignment() {
        init();
        Test.startTest();
     
        // Try to ensure the lead created matches one of our zips.
        // Coverage will drop if it doesn't match
        leadList.add(new Lead(
            LastName = 'test',
            Country = 'United States',
            Company = 'test1'
         ));
        insert leadList;
        Test.stopTest();
    }
    
    static testMethod void testLeadAutoAssign() {
        init();
        Test.startTest();
     
        // Try to ensure the lead created matches one of our zips.
        // Coverage will drop if it doesn't match
        leadList.add(new Lead(
            LastName = 'test',
            Company = 'test1',
            Country = 'United States',
            Deal_Registration__c = true
        ));
        insert leadList;
        Test.stopTest();
    }
}