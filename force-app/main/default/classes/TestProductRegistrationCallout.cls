@isTest
private class  TestProductRegistrationCallout {


 private static testMethod void Test_ProductRegistrationCallout() {
     RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
    
      req.requestURI = '/services/apexrest/register';  //Request URL
      req.httpMethod = 'POST';//HTTP Request Type
      RestContext.request = req;
      RestContext.response= res;
      ProductRegistrationCallout.processRegRequest('acctid:12345','nodename:RVM12345','uuid:1234-1234-1234',true);
      
  }
  

   private static testMethod void Test_ProductRegistrationPortalCallout() {
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();

      req.requestURI = '/services/apexrest/register';  //Request URL
      req.httpMethod = 'POST';
      RestContext.request = req;
      RestContext.response= res;
      String manufactredTime = String.valueOf(Datetime.now());
      Account acc = new Account(Name = 'Rubrik-Test',Type = 'Prospect',Partner_Agreement_Status__c = 'Signed - Inactive');
      INSERT acc;
      ProductRegistrationPortalCallout.processRegRequest('uuid:1234-1234-1234','nodename:RVM12345',manufactredTime,'testtoken',true);
  }
  //CS21-3227
  
  // private static testMethod void Test_ProductRegistrationController() {
  
  //       ProductRegistrationController pr = new ProductRegistrationController();

  //       pr.uuid = '1234-1234-1234';
  //       pr.nodename = 'RVM12345';
  //       pr.regMessage = 'test';
  //       pr.regString = 'tedgry6354654';
  
  //       pr.init();
  //       pr.validate();
  //       pr.callout();
  // }
}