/**
*  Name : DealRegExtensionTest
*  Description : Test class for DealRegExtension
*  Revision History : 
*  Version    Author Name      Last Modified Date      Comment
*    1.0     Yogesh Sharma        5/13/2016            Created.
*/
@isTest
private class DealRegExtensionTest {
    @testSetup static void methodName() {
      User u=TestDataFactory.getUser();
      u.LastName = 'TestUser101';
      insert u;
    }
    //method to insert lead with all the values and assigned to the campaign
    static testMethod void positiveScenario1() {
        Account acc=TestDataFactory.getAccount();
        insert acc;

       //System.runAs(u){
        Deal_Registration__c deal=TestDataFactory.getDealRegistration();
        deal.Partner_Rep_Email_Address__c='RK@rubrik.com';
        insert deal;
         
         Account accNew=TestDataFactory.getAccount();
         accNew.Distributor__c=acc.id;
         accNew.Type='Distributor';
         insert accNew;
 
         Contact con=TestDataFactory.getContact(accNew);
         con.email='RK@rubrik.com';
         insert con;
            Deal_Registration__c newDeal=[Select Partner_Rep_Email_Address__c from Deal_Registration__c where id=:deal.id];
            Contact c=[select email from contact where id=:con.id];
            Test.startTest();  
            //usr.AccountId=accNew.id;
            
            
            
            States__c objStates = TestDataFactory.insertStates();
            insert objStates;
            
            Countries__c objCountries = TestDataFactory.insertCountries();
            insert objCountries;
                 
            PageReference ObjDealReg = Page.DealReg;
            Test.setCurrentPage(ObjDealReg);
            ObjDealReg.getParameters().put('id',deal.id);
      ApexPages.StandardController sc = new ApexPages.standardController(deal);
            DealRegExtension objHandler = new DealRegExtension(sc);
            objHandler.fetchPartnerAccount();
                 objHandler.makeStateMandatory();
                 objHandler.makeStateNotMandatory();
                 objHandler.updateStateSelection();
                 objHandler.isItRequired();
                 objHandler.save();
                 objHandler.fetchPartnerAccount();
         
        //}
    }
     static testMethod void negativeScenario1() {

        User ur=[Select userrole.Name from User where lastname='TestUser101'];
             System.runAs(ur){
            Account acc=new Account();
            acc.Name='Test';
            insert acc;
            Account accNew=new Account();
            accNew.Name=acc.Name;
            accNew.Distributor__c=acc.id;
            accNew.Type='MSP';
            insert accNew;
            Contact con=TestDataFactory.getContact(accNew);
            con.email='RK@rubrik.com';
            insert con;
        
            Test.startTest();  
            
            Deal_Registration__c deal=new Deal_Registration__c();
            deal.Partner_Rep_Email_Address__c='RK@rubrik.com';
            insert deal;
            
            States__c objStates = TestDataFactory.insertStates();
            insert objStates;
            
            Countries__c objCountries = TestDataFactory.insertCountries();
            insert objCountries;
                 
            PageReference ObjDealReg = Page.DealReg;
            Test.setCurrentPage(ObjDealReg);
            ObjDealReg.getParameters().put('id',deal.id);
      ApexPages.StandardController sc = new ApexPages.standardController(deal);
            DealRegExtension objHandler = new DealRegExtension(sc);
            objHandler.fetchPartnerAccount();
                 objHandler.makeStateMandatory();
                 objHandler.makeStateNotMandatory();
                 objHandler.updateStateSelection();
                 objHandler.isItRequired();
                 objHandler.save();
                 LeadShare share = objHandler.shares;
        } 
     }
}