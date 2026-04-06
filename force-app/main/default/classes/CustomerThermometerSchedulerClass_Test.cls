/********************************************************************************************************
* Name              : CustomerThermometerSchedulerClass_Test 
* Purpose           : CustomerThermometerSchedulerClass_Test is Used for Testing CustomerThermometerSchedulerClass Class
*********************************************************************************************************/
@isTest
public class CustomerThermometerSchedulerClass_Test{
    public static testMethod void testThermometerBlastResults() {
        CustomerThermometerSchedulerClass schedulerClass= new CustomerThermometerSchedulerClass();
        Test.startTest();
        list<Customer_Thermometer__c> listCustomer_Thermometer= new list<Customer_Thermometer__c> ();

        Customer_Thermometer__c Cu1= new Customer_Thermometer__c ();
        Cu1.name= 'getApiKey';
        Cu1.api_key__c= 'xxxxx';
        Cu1.gold_star__c= null;
        Cu1.green_light__c= null;
        Cu1.latest_date__c= 'null';
        Cu1.red_light__c= null;
        Cu1.total_response__c= null;
        Cu1.yellow_light__c= null;
        Cu1.blast_id__c= '144709';

        listCustomer_Thermometer.add(Cu1);
        Customer_Thermometer__c Cu2= new Customer_Thermometer__c ();
        Cu2.name= 'getBlastResults';
        Cu2.api_key__c= 'null';
        Cu2.gold_star__c= 5644;
        Cu2.green_light__c= 581;
        //Cu2.latest_date__c= '2018-11-18'; 
        Cu2.red_light__c= 356;
        Cu2.total_response__c= 6832;
        Cu2.yellow_light__c= 251;
        Cu2.blast_id__c= 'null';

        listCustomer_Thermometer.add(Cu2);


        insert listCustomer_Thermometer;
        
        Test.setMock(HttpCalloutMock.class, new CustomerTemperatureControllerMock());
        schedulerClass.execute(null);
        listCustomer_Thermometer[1].latest_date__c='2018-11-18';
        update listCustomer_Thermometer;
        schedulerClass.execute(null);
        Test.stopTest();
    } 
        
}