@isTest
public class PSProjectOrderAssignmentController_test{
    @testSetup static void setup() {
        
    
        // Creat Custom
        List<TriggerControl__c> TriggerCon = CustomTestDataFactory.TriggerControlSetting(true);
        
        
        //Create Account record
        list<Account> accId   = CustomTestDataFactory.createAccounts(1);  
        
        //Create Contact records
        list<Contact> conId   = CustomTestDataFactory.createContacts(accId);
        
        //Create Opportunity records
        list<Opportunity> opplstId  = CustomTestDataFactory.createOpp(accId,conId);
        
         
        //Creat order records
        List<Order> Ord = CustomTestDataFactory.createOrderWithOutPricebook(accId,opplstId);
      
        //Create PSProject records  
        list<PS_Project__c> projId  = CustomTestDataFactory.createPS_Projectwithopp(opplstId,conId,accId);
        
        //creat PSTask records
        List<PS_Task__c> pstsk = CustomTestDataFactory.createPS_TaskwithOrd(projId,accId,Ord);
        
        //All Debugs
        system.debug('accId--------------'+accId);
        system.debug('conId--------------'+conId);
        system.debug('opplstId--------'+opplstId);
        system.debug('projId------------'+projId); 
        system.debug('Ord------------'+Ord); 
        system.debug('pstsk--------------------' +pstsk);
      
    }
    public static testmethod void Test(){
        Test.startTest();
        Account acc = [SELECT id FROM Account limit 1];
        PS_Project__c proj = [SELECT Id FROM PS_Project__c limit 1];
        Order Ord = [SELECT Id FROM Order limit 1];
        list<String> orderIds = new list<String>();
        orderIds.add(Ord.id);  
        
        PSProjectOrderAssignmentController.getOrders('5', '1',proj.id);
        PSProjectOrderAssignmentController.deleteAccount(acc);
        PSProjectOrderAssignmentController.getAccountsWithOffset('5', '1');
        PSProjectOrderAssignmentController.assignOrdersToProject(proj.id, orderIds);
        Test.stopTest();
    }
    
}