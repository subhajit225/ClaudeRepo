//Gaurav Jain: Test Data to be created later.
@isTest(SeeAllData=true)
public class EntitlementUsageTest {
	public static testMethod void test_EntitlementUsage () {
        Entitlement_Use__c entitlementUse = [select Id, Name, Account__c, activation_date__c, actual_usage__c, archived__c, cluster__c, contact__c, entitlement__c, notes__c, serial_number__c, usage_limit__c, node__c from Entitlement_Use__c LIMIT 1];
        
		Entitlement_Use__c entitlementUseClone = entitlementUse.clone(false, true, false, false);
        
        entitlementUseClone.serial_number__c += '-1';
        entitlementUseClone.Name += '-1';
        
        insert entitlementUseClone;
        
        delete entitlementUseClone;
        
        undelete entitlementUseClone;
        
        update entitlementUseClone;
    }
}