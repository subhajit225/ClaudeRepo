/*--
  Related PAGE NAME:    AddOrderItems
  CONTROLLER:           AddOrderItemsExtnCntllr
  RELATED OBJECT:       OrderItem
  PURPOSE:              To provide UI to Clone Order and Split the quantity for Order items.
  DEVELOPER:            SHADAB HUSSAIN
  DATE OF CREATION:     25/11/2016
  LAST MODIFIED DATE:   26/11/2016
*/  
public class AddOrderItemsExtnCntllr {
    /*
    public Order newSalesOrder{get;set;}
    public Order order{get;set;}
    public Boolean renderOrderBool{get;set;}
    public List<OrderItem> newOrderItemsList{get;set;} 
    ID newOrderId;
    public AddOrderItemsExtnCntllr(ApexPages.StandardController controller) {
        try{
            ID oldOrderId=apexpages.currentpage().getparameters().get('oldOrderId');
            newOrderId=apexpages.currentpage().getparameters().get('newOrderId');
            ID OppID =apexpages.currentpage().getparameters().get('OppID');
            newOrderItemsList = new List<OrderItem>();
            List<Opportunity> OppList = [Select id,Name,(select id,unitprice,Description,quantity, PriceBookEntryId from OpportunityLineItems) from Opportunity where Id =: OppID];
            Map<Id,Decimal> prodQuantityMap= new Map<Id,Decimal>();
            for(Opportunity opps : OppList){
                for(OpportunityLineItem OLItem : opps.OpportunityLineItems)
                    prodQuantityMap.put(OLItem.PriceBookEntryId,OLItem.quantity);
            }
            System.debug('prodQuantityMap Values=='+prodQuantityMap+'==Size()=='+prodQuantityMap.Size());
            Map<Id,Decimal> orderProdQuantityMap= new Map<Id,Decimal>();
            for(Order Ord : [select id,OpportunityId,(select id,unitprice,Description,quantity, PriceBookEntryId from OrderItems) from Order where OpportunityId =: OppID ] ){
                Decimal localQuantity=0.0;
                for(OrderItem oItem : Ord.OrderItems){
                    
                    if(orderProdQuantityMap.containsKey(oItem.PriceBookEntryId)){
                        localQuantity =orderProdQuantityMap.get(oItem.PriceBookEntryId)+oItem.Quantity;
                    }else{
                        localQuantity = oItem.Quantity;
                    }
                    orderProdQuantityMap.put(oItem.PriceBookEntryId, localQuantity);
                }
            }
            System.debug('orderProdQuantityMap Values=='+orderProdQuantityMap+'==Size()=='+orderProdQuantityMap.Size());
            Map<Id,Decimal> RemainingProdQuantityMap= new Map<Id,Decimal>();
            for(Id orderItemId : orderProdQuantityMap.keySet()){
                if(prodQuantityMap.containsKey(orderItemId)){
                    Decimal remainder = prodQuantityMap.get(orderItemId)- orderProdQuantityMap.get(orderItemId);
                    RemainingProdQuantityMap.put(orderItemId,remainder);
                }
            }
            System.debug('RemainingProdQuantityMap Values=='+RemainingProdQuantityMap+'==Size()=='+RemainingProdQuantityMap.Size());
            //Map<ID,OrderItem> orderItemMap  = new Map<ID,OrderItem>([select id,unitprice,Description,quantity, PriceBookEntryId,Pricebookentry.Product2.Name from OrderItem where PriceBookEntryId IN :RemainingProdQuantityMap.KeySet() ]);
            Map<ID,OrderItem> orderItemMap  = new Map<ID,OrderItem>();
            for(OrderItem oItem :[select id,unitprice,Description,quantity, PriceBookEntryId,Pricebookentry.Product2.Name from OrderItem where PriceBookEntryId IN :RemainingProdQuantityMap.KeySet() ]){
                if(!orderItemMap.containsKey(oItem.PriceBookEntryId)) orderItemMap.put(oItem.PriceBookEntryId, oItem);
            }
                
            for(ID OIE : RemainingProdQuantityMap.KeySet()){
                OrderItem item =orderItemMap.get(OIE);
                if(item != null){
                    system.debug('PricebookEntry.Prodcut2ID.Product2.Name--'+item.PriceBookEntry.Product2.Name);
                    OrderItem oli = new OrderItem();
                    oli.orderId = newOrderId;
                    oli.PriceBookEntryId = item.PriceBookEntryId;
                    oli.UnitPrice = item.UnitPrice;
                    oli.Description = item.PriceBookEntry.Product2.Name;
                    oli.Quantity = RemainingProdQuantityMap.get(OIE);
                    newOrderItemsList.add(oli);
                }
            }
        }
        catch(Exception ex){
            system.debug('Exception Occured Method AddOrderItemsExtnCntllr and class AddOrderItemsExtnCntllr');  
        }
        
    }
    public pagereference insertOderitems(){
        try{
            insert newOrderItemsList;
            Pagereference ref = new Pagereference('/'+newOrderId);
            return ref;   
        }
        catch(Exception ex){
            system.debug('Exception Occured Method insertOderitems and class AddOrderItemsExtnCntllr');  
            return null;
        }
    }
    public pagereference cancel(){
        try{
            Pagereference ref = new Pagereference('/'+newOrderId);
            return ref;  
        }
        catch(Exception ex){
            system.debug('Exception Occured Method cancel and class AddOrderItemsExtnCntllr');  
            return null;
        }
        
    }
    */
}