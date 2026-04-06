@isTest
public class PC_ClaimController_Test {
    static testMethod void createIncentiveRec() {
        List<String> lstCCRType= new List<String>();
        lstCCRType.add('Brik_Dollar_Incentive_Claim_Req');
        List<Incentives__c> lstIncentive = ShGl_TestFactory.testMethod_Incentive(1,lstCCRType);
		List<Id> lstIncentiveId = new List<Id>();
        lstIncentiveId.add(lstIncentive[0].Id);
        ShGl_TestFactory.testMethod_Attachment(1,lstIncentiveId);
        PC_ClaimController.getdocs(lstIncentive[0].Id);
    }
}