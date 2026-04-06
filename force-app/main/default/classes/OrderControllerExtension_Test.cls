/********************************************************************************************************
* Name              : OrderControllerExtension_Test
* Purpose           : OrderControllerExtension_Test is Used for Testing OrderControllerExtension Class
*********************************************************************************************************/
@isTest
public class OrderControllerExtension_Test{
    
    static testMethod void testPageRedirect(){
        testDataFactoryClass.createCustomSettings();
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<Account> actList = new List<Account>();
            
            //ID userId = [select id from user where Alias ='tUser'].Id;
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account act =new Account(Name = 'TestAcct1',Website='www.test3.com',OwnerId = userinfo.getUserId(),type='Customer', RecordTypeId =partnerRecordTypeId);
            insert act;
            
            actList.add(act);
            
            List<opportunity> oppUpdateList =  testDataFactoryClass.createOpporunity(actList);
            oppUpdateList[0].Distributor_Lookup__c=actList[0].id;
            oppUpdateList[0].Partner_Lookup__c=actList[0].id;
            update oppUpdateList;
            
            PageReference pageRef = Page.OrderOverridePage; // Adding VF page Name here
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('oppid', oppUpdateList[0].Id);//for page reference
            
            ApexPages.standardController controller = new ApexPages.standardController(oppUpdateList[0]);
            
            Test.startTest();
            OrderControllerExtension orderCtrlExtension = new OrderControllerExtension(controller);
            orderCtrlExtension.pageRedirect();
            Test.stopTest();
        }
        
    }   
}