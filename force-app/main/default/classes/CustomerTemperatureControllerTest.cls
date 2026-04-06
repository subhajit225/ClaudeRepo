/*
 * Class Name :- CustomerTemperatureControllerTest
 * Apex Class :- CustomerTemperatureController
 * Author :- Shiva Sharma
 * Created Date :- 01-06-2018
 * Description : This Controller Test class for CustomerTemperatureController.
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
@isTest
public class CustomerTemperatureControllerTest {
    
    @testSetup static void setup() {
        insert new Customer_Thermometer__c(name='getApiKey',API_Key__c = '123',blast_id__c='13293');
        insert new Customer_Thermometer__c(name='getBlastResults',Gold_Star__c=100,Green_Light__c=100,Yellow_Light__c=100,Red_Light__c=100,Total_Response__c=400,Latest_Date__c='2017-01-01');
    }
    
    @isTest static void testMethod0() {
        test.startTest();CustomerThermometerSchedulerClass.thermometerBlastResults();
        Test.setMock(HttpCalloutMock.class, new CustomerTemperatureControllerMock());
        CustomerTemperatureController cst = new CustomerTemperatureController();
        test.stopTest();
    }
}