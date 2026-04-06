@isTest
public class OrderCaseInfoControllerTest {
    public static  testmethod void caseInfo(){
        Account ac = new Account(Name='Test account');
        insert ac;
        Contact con = new Contact(LastName = 'test contact', Phone = '9805321262',Email = 'test@gmail.com');
        insert con;
        Cluster__c cl = New Cluster__c(Name = 'test',tag__c = 'test',UUID__c = 'test');
        insert cl;
        Case cs = new Case(Subject='Test case',AccountId = ac.Id, ContactId = con.Id,Cluster__c = cl.Id,Priority = 'Low',Software_Version__c = '5.1.0-EA2-7015',Origin = 'Email',Contact_method__c = 'Email',Problem_Type__c = 'Activity',Current_Status__c = 'testing',Description='test');
        insert cs;
        RMA_Order__C rmaOrder = new RMA_Order__C(Parent_Case__c = cs.Id);
        insert rmaOrder;
        Order ord = new Order(Name = 'Test order',AccountId = ac.Id,EffectiveDate = date.today(),RMA_Request__c = rmaOrder.Id);
        insert ord;
        OrderCaseInfoController oc = new OrderCaseInfoController();
        oc.orderId = ord.Id;
        oc.getCaseInfo();
    }
}