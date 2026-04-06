/********************************************************************************************************
* Name              : PartnerOnboardingRequestExtension_Test 
* Purpose           : PartnerOnboardingRequestExtension_Test is Used for Testing PartnerOnboardingRequestExtension Class
*********************************************************************************************************/
@isTest
public class PartnerOnboardingRequestExtension_Test{
    
    static testMethod void createPRRequest(){
        CountryWithCode__c CountrySetting1 = new CountryWithCode__c();
        CountrySetting1.Name = 'United States';
        CountrySetting1.Code__c = 'US';
        insert CountrySetting1;
        CountryWithCode__c countrySetting2 = new CountryWithCode__c();
        countrySetting2.Name = 'Canada';
        countrySetting2.Code__c = 'CA';
        insert CountrySetting2;
        
        StateCodeName__C stateSetting1 = new StateCodeName__C();
        stateSetting1.Name = 'US-AL';
        stateSetting1.State_Name__c = 'Alabama';
        insert stateSetting1;
        StateCodeName__C stateSetting2 = new StateCodeName__C();
        stateSetting2.Name = 'US-CA';
        stateSetting2.State_Name__c = 'California';
        insert stateSetting2;
        PageReference pageRef = Page.PartnerOnboardingForm;
        Test.setCurrentPage(pageRef);
       
        PartnerOnbaordingMapping__c regionSetting = new PartnerOnbaordingMapping__c();
        regionSetting.Name ='NYC/Northeast';
        regionSetting.Channel_Manager_Id__c = UserInfo.getUserId();
        insert regionSetting;
         Partner_Onboarding_Request__c PO_Rec = new Partner_Onboarding_Request__c(First_Name__c='Test',
                                                                                        Last_Name__c = 'Last Name is_Test_class',
                                                                                        Company_Name__c = 'Test Company',
                                                                                        Email__c = 'test@test123.com',
                                                                                        Phone__c = '1234567890',
                                                                                        Address_1__c ='test street',
                                                                                        Address_2__c ='test street',
                                                                                        City__c = 'test City',
                                                                                        
                                                                                        //Country__c = 'USA',
                                                                                        Country__c = 'United States',
                                                                                        StateProvince__c ='CA',
                                                                                        Postal_Code__c ='9350',
                                                                                        Territory__c ='US',
                                                                                        Region__c ='NY NJ',
                                                                                        Distributor__c = 'Promark',
                                                                                        Agreed_Term_Conditions__c = true,
                                                                                        Partner_Onboarding_Status__c = 'Pending',
                                                                                        is_Converted__c = false);
        ApexPages.StandardController sc = new ApexPages.standardController(PO_Rec);
        Test.startTest();
        PartnerOnboardingRequestExtension PRExtn = new PartnerOnboardingRequestExtension(sc);
        List<string> vendors = new List<String>();
        vendors.add('Cisco');
        vendors.add('SAP');
        PRExtn.isSavedBool =false;
        PRExtn.selectedVendors =vendors;
        PRExtn.isitRequired();
        PRExtn.zipLength();
        PRExtn.saveRequest();
        
        PO_Rec.Territory__c='Other';
        PO_Rec.Country__c='India';
        PO_Rec.Postal_Code__c ='93506';
        regionSetting.Region__c='NY NJ';
        update regionSetting;
        
        ApexPages.StandardController sc1 = new ApexPages.standardController(PO_Rec);
        PartnerOnboardingRequestExtension PRExtn1 = new PartnerOnboardingRequestExtension(sc1);
        
        PRExtn1.isItRequired();
        PRExtn1.zipLength();
        PRExtn1.saveRequest();
        Test.stopTest();
   
   } 
        
}