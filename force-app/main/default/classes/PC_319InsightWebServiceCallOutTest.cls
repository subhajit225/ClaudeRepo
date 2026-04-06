@isTest
public class PC_319InsightWebServiceCallOutTest {
    @isTest static void testPartnerOnboard1() {
	 PartnerOnbaordingMapping__c regionSetting = new PartnerOnbaordingMapping__c();
        regionSetting.Name ='NYC/Northeast';
        regionSetting.Channel_Manager_Id__c = UserInfo.getUserId();
        insert regionSetting;
        Country_Code_319_API__c cc = new Country_Code_319_API__c(Name='United States',Country_code__c='US');
        insert cc;
        Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test Company';
            acc1.Type = 'OEM';
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.OEM_Subtype__c = 'Revshare';
        insert acc1;
        Partner_Onboarding_Request__c PO_Rec = new Partner_Onboarding_Request__c(First_Name__c='Test',
                                                                                 Last_Name__c = 'Last Name is_Test_class',
                                                                                 Company_Name__c = 'Test Company',
                                                                                 Email__c = 'test456546@test123.com',
                                                                                 Phone__c = '1234567890',
                                                                                 Address_1__c ='test street',
                                                                                 Address_2__c ='test street',
                                                                                 City__c = 'test City',
                                                                                 Country__c = 'United States',
                                                                                 StateProvince__c ='CA',
                                                                                 Postal_Code__c ='93506',
                                                                                 Region__c ='NY NJ',
                                                                                 Agreed_Term_Conditions__c = true,
                                                                                 is_Converted__c = false,
                                                                                 Partner_Selling_Countries__c ='Albania;Algeria',
                                                                                 Account__c = acc1.Id);
        insert PO_Rec;
        PO_Rec.Partner_Onboarding_Status__c = 'L1 Approved';
        update PO_Rec;
        
        
        PC_319InsightWebService.additionalField af = new PC_319InsightWebService.additionalField();
        PC_319InsightWebService.company comp = new PC_319InsightWebService.company();
        PC_319InsightWebService.contact cont = new PC_319InsightWebService.contact();
        PC_319InsightWebService.dataBuilderData data = new PC_319InsightWebService.dataBuilderData();
        PC_319InsightWebService.dataBuilderFieldConfig conf = new PC_319InsightWebService.dataBuilderFieldConfig();
        PC_319InsightWebService.getDataBuilderFields gf = new PC_319InsightWebService.getDataBuilderFields();
        PC_319InsightWebService.searchResult sr = new PC_319InsightWebService.searchResult();
        PC_319InsightWebService.stageStatus sg = new PC_319InsightWebService.stageStatus();
        PC_319InsightWebService.updateDataBuilder ub = new PC_319InsightWebService.updateDataBuilder();
        PC_319InsightWebService.getDataBuilderFieldValues gv = new PC_319InsightWebService.getDataBuilderFieldValues();
        PC_319InsightWebService.getDataBuilders gb = new PC_319InsightWebService.getDataBuilders();
        PC_319InsightWebService.deployDataBuilder db = new PC_319InsightWebService.deployDataBuilder();
        PC_319InsightWebService.deployDataBuilderResponse dr = new PC_319InsightWebService.deployDataBuilderResponse();
        PC_319InsightWebService.deployDataBuilderResult dres = new PC_319InsightWebService.deployDataBuilderResult();
        PC_319InsightWebService.getDataBuilderFieldValuesResponse dvres = new PC_319InsightWebService.getDataBuilderFieldValuesResponse();
        PC_319InsightWebService.getDataBuildersResponse bres = new PC_319InsightWebService.getDataBuildersResponse();
        PC_319InsightWebService.updateDataBuilderResponse ures= new PC_319InsightWebService.updateDataBuilderResponse();
        PC_319InsightWebService.requestDataBuilderResponse rres = new PC_319InsightWebService.requestDataBuilderResponse();
        PC_319InsightWebService.riskGroup rg = new PC_319InsightWebService.riskGroup();
        PC_319InsightWebService.getDataBuilderFieldsResponse fres= new PC_319InsightWebService.getDataBuilderFieldsResponse();
        PC_319InsightWebService.companyData cd = new PC_319InsightWebService.companyData();
        PC_319InsightWebService.AuthHeader ah = new PC_319InsightWebService.AuthHeader();
        PC_319InsightWebService.contactName cn = new PC_319InsightWebService.contactName();
        PC_319InsightWebService.requestDataBuilder rdb = new PC_319InsightWebService.requestDataBuilder();
		PC_319InsightWebService.contactData cdata = new PC_319InsightWebService.contactData();
        
        
    }
     @isTest static void testPartnerOnboard2() {
        PC_319InsightWebService.DataBuilderWebServicePort cons = new PC_319InsightWebService.DataBuilderWebServicePort();
        Test.setMock(WebServiceMock.class, new PC_319InsightWebServiceMock());
        
        PC_319InsightWebService.deployDataBuilderResponse resp = cons.deployDataBuilder('3434', 76,null,null,null,null);
     }
    @isTest static void testPartnerOnboard3() {
        PC_319InsightWebService.DataBuilderWebServicePort cons = new PC_319InsightWebService.DataBuilderWebServicePort();
        Test.setMock(WebServiceMock.class, new PC_319InsightWebServiceMock2());
        
        PC_319InsightWebService.requestDataBuilderResponse response = cons.requestDataBuilder('3434',null);
     }
    
    @isTest static void testPArtnerOnboard4(){
        Country_Code_319_API__c cc = new Country_Code_319_API__c(Name='United States',Country_code__c='US');
        insert cc;
        Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test Company';
            acc1.Type = 'OEM';
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.OEM_Subtype__c = 'Revshare';
        insert acc1;
        Partner_Onboarding_Request__c PO_Rec = new Partner_Onboarding_Request__c(First_Name__c='Test',
                                                                                 Last_Name__c = 'Last Name is_Test_class',
                                                                                 Company_Name__c = 'Test Company',
                                                                                 Email__c = 'test456546@test123.com',
                                                                                 Phone__c = '1234567890',
                                                                                 Address_1__c ='test street',
                                                                                 Address_2__c ='test street',
                                                                                 City__c = 'test City',
                                                                                 Country__c = 'United States',
                                                                                 StateProvince__c ='CA',
                                                                                 Postal_Code__c ='93506',
                                                                                 Region__c ='NY NJ',
                                                                                 Agreed_Term_Conditions__c = true,
                                                                                 is_Converted__c = false,
                                                                                 Partner_Selling_Countries__c ='Albania;Algeria',
                                                                                 Account__c = acc1.Id);
        insert PO_Rec;
        PC_319InsightWebService.DataBuilderWebServicePort cons = new PC_319InsightWebService.DataBuilderWebServicePort();
        Test.setMock(WebServiceMock.class, new PC_319InsightWebServiceMock2());
        
        Test.startTest();
        PO_Rec.Partner_Onboarding_Status__c = 'L2 Approved';
        update PO_Rec;
        Test.stopTest();
    }
}