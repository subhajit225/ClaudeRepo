@isTest 
class L2AServiceTest {
    //MKT23-634 Deployment
    @isTest static void testcallService(){
        L2AService service = new L2AService();
        List<Lead> leadList = new List<Lead>();
            Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='AMER-MM',BillingCountry ='United States',BillingCountryCode ='US');
            insert act;
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'Test Lead FN1';
        led.lastName = 'Test Lead LN1';
        led.Status = 'Open';
        led.Email='test@nassconorfolk.com';
        led.Campaign_Sourced_By__c='Sales';
        led.Deal_Registration__c = false;
        led.rerun_PatchManager__c = false;
        led.Industry = 'Industry';
        led.Country = 'United States';
        led.CountryCode = 'US';
        led.postalCode = '589526';
        led.L2A_Confidence_Code__c=4.0;
        led.L2A_Account__c=act.Id;
        led.ReassignLead__c=true;
        
        insert led;
        leadList.add(led);
        //insert leadList;
        Map<String,Object> payload = service.getPayload(leadList);
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        service.callService(payload);
    }
}