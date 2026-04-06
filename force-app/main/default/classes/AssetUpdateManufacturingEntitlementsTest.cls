//Gaurav Jain: Test Data to be created later.
@isTest(SeeAllData = true)
public class AssetUpdateManufacturingEntitlementsTest {
	public static testMethod void test_Batch () {
        AssetUpdateManufacturingEntitlements scheduler = new AssetUpdateManufacturingEntitlements();
        
        String sch = '0 0 0 3 9 ? 2022';
        
        String jobId = System.schedule('BatchSchedulerTest - Everyday at 1pm', sch, scheduler);
        
        Database.executeBatch(new AssetUpdateManufacturingEntitlements());
    }
}