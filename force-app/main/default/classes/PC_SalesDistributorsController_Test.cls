/** 
* Purpose : Test class of PC_SalesDistributorsController
**/
@isTest
public class PC_SalesDistributorsController_Test {
    public static testmethod void testGetCountryOptions(){
        Test.startTest();
        PC_SalesDistributorsController.getCountryOptions();
        //PC_SalesDistributorsController.getTerritoryOptions();
        Test.stopTest(); 
    }
    private static testmethod void testGetDistributorsList(){
        Test.startTest();
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        accRec.Type = 'Distributor';
        accRec.BillingCountryCode = 'US';
        accRec.BillingCountry = 'United States';
        accRec.Territory__c = 'US';

        Contract con = new Contract();
        con.Territory_Country__c = 'United States';
        con.Agreement_Type__c = 'Distributor';
        con.Contract_Status__c = 'Active';
        con.AccountId = accRec.Id;

        PC_SalesDistributorsController.getDistributorsList('test','United States');
        Test.stopTest();
    }
}