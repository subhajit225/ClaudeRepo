/****************
 * Coverage Class-AboutController
 * Created By - Grazitti Team
 * Date - 15th April 2019
 * 
 **************/


@isTest
public class AboutController_Test {
    public static testmethod void AboutControllerTestMethod() 
    {
        
        List<Customer_Thermometer__c>  custThermoList = new List<Customer_Thermometer__c>();
        Customer_Thermometer__c ct= new Customer_Thermometer__c(Name='getApiKey',API_Key__c='xxxx',  blast_id__c ='144709');
        custThermoList.add(ct);
        Customer_Thermometer__c ct1= new Customer_Thermometer__c(Name='getBlastResults',Gold_Star__c= 6029,Green_Light__c=628,Latest_Date__c= '2018-12-14',Red_Light__c=387, Total_Response__c=7310,Yellow_Light__c=266);
        custThermoList.add(ct1);
        insert custThermoList;
        AboutController.TotalResponses();
        AboutController.blastResults();
        AboutController.hapinessFactor();
        AboutController.HappinessValue();
    }
}