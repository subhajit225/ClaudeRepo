@isTest
/**  
 * Purpose : Test class of PC_PartnerOnboardingRequestContoller
**/
public class PC_PartnerOnboardingRequestCntrl_Test {
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
            List<Partner_Onboarding_Request__c> PO_Rec = ShGl_TestFactory.testMethod_PartnerOnBoarding(1);
            PO_Rec[0].First_Name__c='Test';
            PO_Rec[0].Last_Name__c = 'Last Name is_Test_class';
            PO_Rec[0].Company_Name__c = 'Test Company';
            PO_Rec[0].Email__c = 'test456546@test123.com';
            PO_Rec[0].Phone__c = '1234567890';
            PO_Rec[0].Address_1__c ='test street';
            PO_Rec[0].Address_2__c ='test street';
            PO_Rec[0].City__c = 'test City';
            
            //Country__c = 'USA',
            PO_Rec[0].Country__c = 'United States';
            PO_Rec[0].StateProvince__c ='CA';
            PO_Rec[0].Postal_Code__c ='93506';
            //PO_Rec[0].Territory__c ='US';
            PO_Rec[0].Region__c ='NY NJ';
            PO_Rec[0].Distributor__c = ''; 
            PO_Rec[0].Agreed_Term_Conditions__c = true;
            PO_Rec[0].Partner_Onboarding_Status__c = 'Pending';
            PO_Rec[0].is_Converted__c = false;
            //update PO_Rec;            
        result = PC_PartnerOnboardingRequestContoller.savePartnerOnboard(PO_Rec[0],'US');
        System.debug('result**'+result);
    }
    @isTest static void testsavePartnerOnboard2() {
        string result;        
        List<Partner_Onboarding_Request__c> PO_Rec = ShGl_TestFactory.testMethod_PartnerOnBoardingWithoutInsert(1);
            PO_Rec[0].First_Name__c='Test';
            PO_Rec[0].Last_Name__c = 'Last Name is_Test_class';
            PO_Rec[0].Company_Name__c = 'Test Company';
            PO_Rec[0].Email__c = 'test456546@test123.com';
            PO_Rec[0].Phone__c = '1234567890';
            PO_Rec[0].Address_1__c ='test street';
            PO_Rec[0].Address_2__c ='test street';
            PO_Rec[0].City__c = 'test City';
            
            //Country__c = 'USA',
            PO_Rec[0].Country__c = 'United States';
            PO_Rec[0].StateProvince__c ='CA';
            PO_Rec[0].Postal_Code__c ='93506';
            //PO_Rec[0].Territory__c ='US';
            PO_Rec[0].Region__c ='NY NJ';
            PO_Rec[0].Distributor__c = '';
            PO_Rec[0].Agreed_Term_Conditions__c = true;
            PO_Rec[0].Partner_Onboarding_Status__c = 'Pending';
            PO_Rec[0].is_Converted__c = false;
        	result = PC_PartnerOnboardingRequestContoller.savePartnerOnboard(PO_Rec[0],'US');
        
       
    }
    @isTest static void testgetDependentMap() {
         Map<String,List<String>> objResults = new Map<String,List<String>>();
         objResults = PC_PartnerOnboardingRequestContoller.getDependentMap('Country__c','StateProvince__c');
    }
    @isTest static void testMethodGetDistributorValues() {
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account AccRecord = new Account();
        AccRecord.Name = 'test';
        AccRecord.BillingStreet = 'street'; 
        AccRecord.BillingCity = 'city';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '456789';
        AccRecord.RecordTypeId= devRecordTypeId;
        AccRecord.Type = 'Distributor';
        AccRecord.Partner_Agreement_Status__c = 'Signed - Active';
        AccRecord.Territory__c = 'US;';
        insert AccRecord;
        List<String> territory=new List<String>();
        territory.add('US');
        PC_PartnerOnboardingRequestContoller.getDistributorValues(territory);
    }
}