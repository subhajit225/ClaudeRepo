@isTest
/** Created By : Pavanaja 
 * Purpose : Test class of PC_PartnerOnboardingRequestContoller
**/
public class PC_PartnerOnboardingRequestContollerTest {
    @isTest static void testgetPicklistValues() {
        List<string> picklists = new List<string>();
        picklists = PC_PartnerOnboardingRequestContoller.getPicklistValues('Country__c');
    }
    
    @isTest static void testsavePartnerOnboard1() {
        string result;
        
        PartnerOnbaordingMapping__c regionSetting = new PartnerOnbaordingMapping__c();
        regionSetting.Name ='NYC/Northeast';
        regionSetting.Channel_Manager_Id__c = UserInfo.getUserId();
        insert regionSetting;
        Partner_Onboarding_Request__c PO_Rec = new Partner_Onboarding_Request__c(First_Name__c='Test',
                                                                                 Last_Name__c = 'Last Name is_Test_class',
                                                                                 Company_Name__c = 'Test Company',
                                                                                 Email__c = 'test456546@test123.com',
                                                                                 Phone__c = '1234567890',
                                                                                 Address_1__c ='test street',
                                                                                 Address_2__c ='test street',
                                                                                 City__c = 'test City',
                                                                                 
                                                                                 //Country__c = 'USA',
                                                                                 Country__c = 'United States',
                                                                                 StateProvince__c ='CA',
                                                                                 Postal_Code__c ='93506',
                                                                                // Territory__c ='US',
                                                                                 Region__c ='NY NJ',
                                                                                // Distributor__c = 'Promark',
                                                                                 Agreed_Term_Conditions__c = true,
                                                                                 Partner_Onboarding_Status__c = 'Pending',
                                                                                 is_Converted__c = false);
        
        result = PC_PartnerOnboardingRequestContoller.savePartnerOnboard(PO_Rec);
        
        result = PC_PartnerOnboardingRequestContoller.savePartnerOnboard(PO_Rec);
    }
    @isTest static void testsavePartnerOnboard2() {
        string result;
        PatchManagerSettings__c ps = new PatchManagerSettings__c(Segment_Revenue__c=500000,Route_on_Insert_Deal_Reg__c=true);
        insert ps;
        
        
        Partner_Onboarding_Request__c PO_Rec = new Partner_Onboarding_Request__c(First_Name__c='Test',
                                                                                 Last_Name__c = 'Last Name is_Test_class',
                                                                                 Company_Name__c = 'Test Company',
                                                                                 Email__c = 'test45633546@test123.com',
                                                                                 Phone__c = '1234567890',
                                                                                 Address_1__c ='test street',
                                                                                 Address_2__c ='test street',
                                                                                 City__c = 'test City',
                                                                                 
                                                                                 //Country__c = 'USA',
                                                                                 Country__c = 'United States',
                                                                                 StateProvince__c ='CA',
                                                                                 Postal_Code__c ='93506',
                                                                               //  Territory__c ='US',
                                                                                 Region__c ='NY NJ',
                                                                               //  Distributor__c = 'Promark',
                                                                                 Agreed_Term_Conditions__c = true,
                                                                                 Partner_Onboarding_Status__c = 'Pending',
                                                                                 is_Converted__c = false);
                                                                                 
        
        result = PC_PartnerOnboardingRequestContoller.savePartnerOnboard(PO_Rec);
       
    }
    /*@isTest static void testgetDistributorNames() {
        Account acc = new Account(Name='FedResults, Inc');
        insert acc;
        Contract cont = new Contract(Status='Draft',StartDate=system.today(),ContractTerm=1,Contract_Attached__c='No',Territory_Country__c='United States',Agreement_Type__c='Addendum',Contract_Status__c='Active',accountId=acc.id);
        insert cont;
        
        PC_PartnerOnboardingRequestContoller.getDistributorNames('United States');
        PC_PartnerOnboardingRequestContoller.getUSDistributorNames('Federal');
     }*/
    @isTest static void testgetDependentMap() {
         Map<String,List<String>> objResults = new Map<String,List<String>>();
         objResults = PC_PartnerOnboardingRequestContoller.getDependentMap('Country__c','StateProvince__c');
    }
    @isTest static void testgetPicklistValues1() {
        List<String> fieldApiNamesList = new List<String>();
        fieldApiNamesList.add('Vendors_your_Org_works_with_today__c');
        test.startTest();
        PC_PartnerOnboardingRequestContoller.getPicklistValues(fieldApiNamesList);
        PC_PartnerOnboardingRequestContoller.getDependentPicklistValues();
        test.stopTest();
    }
    @isTest static void testgetUSDistributorNames() {
        test.startTest();
        PC_PartnerOnboardingRequestContoller.getUSDistributorNames('Commercial/Enterprise');
        PC_PartnerOnboardingRequestContoller.getUSDistributorNames('Federal');
        PC_PartnerOnboardingRequestContoller.getUSDistributorNames('SLED');
        PC_PartnerOnboardingRequestContoller.getDistributorNames('United States');
        test.stopTest();
    }
}