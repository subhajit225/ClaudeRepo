/**
* @description Test Class for SalesOppChurnUtility.cls
*/
@isTest 
class SalesOppChurnUtilityTest { 
    /**
* @description Test method to check helptext data for churn with Access to Metadata.
*/
    @isTest
    static void helpTextPresentTest() { 
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<Opportunity> opps = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_CPQ_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        System.runAs(listUser[0]){
            SalesOppChurnUtility salesChurnUtility = new SalesOppChurnUtility();
            Assert.isTrue(salesChurnUtility.getChurnReasonInfo().size()>0,'Mapping Data should be present');     
        }
    }
        /**
* @description Test method to check helptext data for churn without Metadata Access.
*/
    @isTest
    static void helpTextPresentNegativeTest() { 
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Inside Sales'];
        List<Opportunity> opps = new List<Opportunity>();
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        System.runAs(listUser[0]){
            SalesOppChurnUtility salesChurnUtility = new SalesOppChurnUtility();
            Assert.isTrue(salesChurnUtility.getChurnReasonInfo()==null,'Access Exception');     
        }
    }
}