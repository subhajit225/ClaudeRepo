@isTest
private class POnboarding_Request_Service_isTest {
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
                                                                                        Postal_Code__c ='93506',
                                                                                       // Territory__c ='US',
                                                                                        Region__c ='NY NJ',
                                                                                        Distributor__c = 'Promark',
                                                                                        Agreed_Term_Conditions__c = true,
                                                                                        Partner_Onboarding_Status__c = 'Pending',
                                                                                        is_Converted__c = false);
        ApexPages.StandardController sc = new ApexPages.standardController(PO_Rec);
        
        PartnerOnboardingRequestExtension PRExtn = new PartnerOnboardingRequestExtension(sc);
        List<string> vendors = new List<String>();
        vendors.add('Cisco');
        vendors.add('SAP');
        PRExtn.selectedVendors =vendors;
        PRExtn.isitRequired();
        PRExtn.zipLength();
        PRExtn.saveRequest();
   
   }
   static testMethod void convertPR_RequestToContact() { 
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
      Partner_Onboarding_Request__c prTestRecord = new Partner_Onboarding_Request__c(First_Name__c='Test',
                                                                                        Last_Name__c = 'Last Name is_Test_class 2',
                                                                                        Company_Name__c = 'Test Company',
                                                                                        Email__c = 'test23456@test123.com',
                                                                                        Phone__c = '1234567890',
                                                                                        Address_1__c ='test street',
                                                                                        Address_2__c ='test street',
                                                                                        City__c = 'test City',
                                                                                        //StateProvince__c ='CA',
                                                                                        //Country__c = 'USA',
                                                                                        Country__c = 'United States',
                                                                                        StateProvince__c ='CA',
                                                                                       // Territory__c ='US',
                                                                                        Region__c ='NY NJ',
                                                                                        //Distributor__c = 'Promark',
                                                                                        Agreed_Term_Conditions__c = true,
                                                                                        Partner_Onboarding_Status__c = 'Pending',
                                                                                        is_Converted__c = false);
    insert prTestRecord;
    Partner_Onboarding_Request__c queryRecord=[select id,Last_Name__c,First_Name__c,Partner_Onboarding_Status__c ,is_Converted__c,StateProvince__c,
                                    Country__c,Region__c from Partner_Onboarding_Request__c
                                                where Last_Name__c='Last Name is_Test_class 2' LIMIT 1];
    system.assertEquals(queryRecord.Last_Name__c, 'Last Name is_Test_class 2');
    system.assertEquals(queryRecord.Partner_Onboarding_Status__c, 'Pending');
    system.assertEquals(queryRecord.is_Converted__c, false);
    queryRecord.Partner_Onboarding_Status__c = 'Approved';
    TriggerControl__c setting = new TriggerControl__c();
    setting.Name = 'Contact';
    setting.DisableTrigger__c = False;
    insert setting;
    Account acc= new Account(Name='Promark', Type='Reseller');
    insert acc;
    PartnerOnbaordingDistyMapping__c distySetting = new PartnerOnbaordingDistyMapping__c();
    distySetting.Name ='Promark';
    distySetting.Disty_ID__c =acc.id;
    insert distySetting;
    update queryRecord;
    Partner_Onboarding_Request__c queryRecordAfterUpdate =[select id,Last_Name__c,First_Name__c,Partner_Onboarding_Status__c ,is_Converted__c from Partner_Onboarding_Request__c
                                                where Last_Name__c='Last Name is_Test_class 2' LIMIT 1];
    system.assertEquals(queryRecordAfterUpdate.Partner_Onboarding_Status__c, 'Approved');
    //system.assertEquals(queryRecordAfterUpdate.is_Converted__c, true);
   
   }


}