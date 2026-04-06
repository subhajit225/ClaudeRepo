public class OrderProdController {

    Public string OrderId {get;set;}
    Public static final List<string> ProdType = new List<string> {'hardware','appliance','accessories'};
    public List<OrderItem> getOrdProducts(){
       return [select product2.name,product2.description,Quantity,SerialNumber__c,order.Ship_To_Name__c from OrderItem where OrderId=:OrderId and product2.product_type__c In: ProdType];
    
    } 
}