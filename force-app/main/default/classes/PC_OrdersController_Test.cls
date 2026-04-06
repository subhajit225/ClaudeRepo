@isTest
public class PC_OrdersController_Test {
    public static testmethod void testOrderDetails(){
        PC_OrdersController.getOrdersList('5','EndUserInfo','2',5,10);
        Account accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        List<Product2> lstCreateProduct = ShGl_TestFactory.testMethod_createProduct(1);
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> lstPEStandard = ShGl_TestFactory.testMethod_createPriceBookEntries(lstCreateProduct,pricebookId);
        List<Pricebook2> customPB = ShGl_TestFactory.testMethod_createPricebook(1);
        List<PricebookEntry> lstPE = ShGl_TestFactory.testMethod_createPriceBookEntries(lstCreateProduct,customPB[0].Id);
        List<Order> lstOrder = ShGl_TestFactory.testMethod_createOrder(1,accRec,customPB[0]);
        PC_OrdersController pc=new PC_OrdersController();
        PC_OrdersController.OrderWrap wraper=new PC_OrdersController.OrderWrap(lstOrder[0]);
    }
    
}