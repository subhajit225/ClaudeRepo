/********************************************************************************************************
* Name              : PartnerCommunityHomeController_Test 
* Purpose           : PartnerCommunityHomeController_Test is Used for Testing PartnerCommunityHomeController Class
*********************************************************************************************************/
@IsTest
public class PartnerCommunityHomeController_Test{
    public static testMethod void testGetWebinars(){
        Test.startTest();
        PartnerCommunityHomeController  controller = new PartnerCommunityHomeController();
        controller.getWebinars();
        Test.stopTest();
    }
    
    public static testMethod void testGetCampaigns(){
        Test.startTest();
        PartnerCommunityHomeController  controller = new PartnerCommunityHomeController();
        controller.getCampaigns();
        Test.stopTest();
    }
    
    public static testMethod void testGetIncentives(){
        Test.startTest();
        PartnerCommunityHomeController  controller = new PartnerCommunityHomeController();
        controller.getIncentives();
        
        Incentives__c incent = new Incentives__c();
        incent.Name='Test Incentives';
        incent.Start__c=System.today();
        incent.End__c=System.today()+5;
        insert incent;
        controller.getIncentives();
        Test.stopTest();
    }
}