@isTest
public class CampaignMemberTriggerHandlerTest{
     @testSetup static void createTestData(){
        
        ShGl_TestFactoryHelper.insertCustomSettings();
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
		
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        Account acct = new Account(Name='testAccount',recordtypeId = partner);
        insert acct;
         
        Lead lead1 = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        lead1.CountryCode = 'IT';
        lead1.L2A_Account__c = acct.Id; 
        lead1.L2A_Confidence_Code__c = 4; 
        lead1.P_0_Response__c=true;  
        insert lead1; 
         
        Lead lead2 = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        lead2.LastName = 'test899';
        lead2.email= 'test@768test.com';
        lead2.CountryCode = 'IT';
        lead2.L2A_Account__c = acct.Id; 
        lead2.L2A_Confidence_Code__c = 4; 
        insert lead2;  

        Contact con = new Contact();
        con.FirstName = 'test';
        con.LastName = 'test';
        con.email = 'test@test.com';
        con.Phone = '4051231234';
        con.AccountId = acct.Id;
        insert con;
        //String CampainRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
        Campaign camp1 = new Campaign(Executed_By__c='Sales',Campaign_Theme__c='Alliances',GTM_Play__c='Azure',Type='Direct Mail',Name = 'Test Campaign 1', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC',Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance', Involvement_by_Customer_Marketing__c='No');
        insert camp1;
         
        Campaign camp2 = new Campaign(Response_MQL_to_AE__c=true,FCRM__FCR_Campaign_Sourced_By__c='Partner',Executed_By__c='Sales',Campaign_Theme__c='Alliances',GTM_Play__c='Azure',Type='Direct Mail',Partner_Campaign_No_SDR_Follow_Up__c=true,Name = 'Test Campaign 2', IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC',Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance', Involvement_by_Customer_Marketing__c = 'No');
        insert camp2;

    }
    
    @isTest
    public static void testMethod1(){
        List<Lead> LdList = [select Id from Lead limit 2];
        Contact con = [select Id from Contact limit 1];
        List<Campaign> cmpList = [select Id from Campaign];
        Test.startTest();
        List<CampaignMember> cmemList = new List<CampaignMember>();
        CampaignMember campMem1 = new CampaignMember(Leadid = LdList[0].Id, CampaignId = cmpList[0].id, Status = 'Responded',FCRM__FCR_QR__c=true);
        CampaignMember campMem11 = new CampaignMember(Leadid = LdList[1].Id, CampaignId = cmpList[0].id, Status = 'Responded',CFCR_PQL__c=true);
        CampaignMember campMem2 = new CampaignMember(CampaignId = cmpList[0].id, Status = 'Responded', contactId= con.Id,FCRM__FCR_QR__c=true);
        CampaignMember campMem3 = new CampaignMember(CampaignId = cmpList[1].id, Status = 'Sent', Leadid = LdList[0].id,FCRM__FCR_QR__c=true); 
        cmemList.add(campMem1);
        cmemList.add(campMem11);
        cmemList.add(campMem2);
        cmemList.add(campMem3);
        insert cmemList;
        
        cmemList[2].status = 'Responded';
        Update cmemList[2];
        
        Delete cmemList[2];
        Test.stopTest();
        System.assertNotEquals(null,cmemList[0].Id);
    }
}