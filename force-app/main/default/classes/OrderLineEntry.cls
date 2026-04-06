public with sharing class OrderLineEntry {

    //public id oppId = !Test.isRunningTest() ? System.currentPageReference().getParameters().get('oppid') : [select id from Opportunity limit 1].id ;
    public id oppId = System.currentPageReference().getParameters().get('oppid');

    //This is the wrapper class of Active Program Products
    public List<wrapLines> wrapPurchasedLines {get; set;}
    public List<OrderItem> selectedOrderItems {get;set;}
    public List<OrderItem> deletedOrderItems {get;set;}

    public Opportunity opp;    
    public Order newOrder;
    public static Id orderId;
    public string action = System.currentPageReference().getParameters().get('action');

    public map<String, Decimal> mapProduct_To_Quantity = new map<String, Decimal>();
    public Set<Id> productSet {get;set;}
    public Map<Id, String> mapProduct_Name = new map<Id, String>();
    Public Map<Id, Id> mapProduct_to_PBE = new Map<Id, Id>();
    Public Map<String, Id> mapProduct_to_Key = new Map<String, Id>();
    Public Map<String, String> mapProduct_to_OLI = new Map<String, String>();
    Public Map<String, Decimal> mapPrice_to_Key = new Map<String, Decimal>();
    Public Map<String, Decimal> mapSalesPrice_to_Key = new Map<String, Decimal>();
    Public Map<String, Decimal> mapValootoSalesPrice_to_Key = new Map<String, Decimal>();
 
    public boolean lines {
        get { 
            if(lines == null) 
        lines = [SELECT Id, HasOpportunityLineItem FROM Opportunity  WHERE Id = :oppId].HasOpportunityLineItem; 
        return lines; 
        }
       private set; 
      }   
   
      public OrderLineEntry(ApexPages.StandardController sController)
      {    
          Opportunity opp = [SELECT Id, Type, AccountId, HasOpportunityLineItem, Account.Name,
                             Pricebook2ID, CloseDate FROM Opportunity WHERE Id = :oppId];
          this.newOrder = (Order)sController.getRecord();
          this.newOrder.Pricebook2ID = opp.Pricebook2ID;
      }  
   
     public void initWrapper(){
            system.debug('### initwrapper started');
            Set<Id> productSet = new Set<Id>();
            Set<String> productKeys = new Set<String>();

            orderId = newOrder.Id;           
            if(wrapPurchasedLines == null) {
                wrapPurchasedLines = new List<wrapLines>();
                {
                
                 //We use the custom field Key__c so it can be modified outside the code
                 for(OpportunityLineItem o : [Select UnitPrice, Key__c,Discount, Quantity, Product2.Name,Valooto_Sales_Price__c,Valooto_Unit_Price__c, TotalPrice, Product2.IsActive, Product2.Family, PricebookEntry.Id
                                              from OpportunityLineItem Where OpportunityId = :oppId]) 
                  //Add the purchases to the map                        
                  {                  
                  productKeys.add(o.Key__c);
                  productSet.add(o.Product2.Id);
                  mapProduct_Name.put(o.Product2.Id, o.Product2.Name);
                  mapProduct_to_PBE.put(o.Product2.Id, o.PriceBookEntry.Id);
                  mapProduct_to_Key.put(o.Key__c, o.Product2.Id);
                  if(o.Discount != null)
                     mapPrice_to_Key.put(o.Key__c, o.UnitPrice- (o.UnitPrice*o.Discount)/100);
                  else
                     mapPrice_to_Key.put(o.key__c,o.UnitPrice);
                   //oli.Sales_Price__c = (o.TotalPrice/o.quantity).setScale(2) ;
                  //mapPrice_to_Key.put(o.Key__c, o.UnitPrice);
                  mapProduct_to_OLI.put(o.Key__c, o.Id); 
                  system.debug('total Price'+ o.totalPrice);
                  system.debug('o.quantity'+ o.quantity);
                  system.debug('o.quantity'+ o.Valooto_Unit_Price__c);
                  mapSalesPrice_to_Key.put(o.Key__c , (o.TotalPrice/o.quantity).setScale(2));
                  system.debug(' o.Valooto_Sales_Price__c'+  o.Valooto_Sales_Price__c);
                  mapValootoSalesPrice_to_Key.put(o.key__c , o.Valooto_Sales_Price__c);
                  
                  if(!mapProduct_To_Quantity.containsKey(o.Key__c)){
                  mapProduct_To_Quantity.put(o.Key__c, 0);
                  }
                  system.debug('### mapProduct_To_Quantity a' + mapProduct_To_Quantity);
                  
                  mapProduct_To_Quantity.put(o.Key__c, o.Quantity + mapProduct_To_Quantity.get(o.Key__c) );
                  system.debug('### mapProduct_To_Quantity b' + mapProduct_To_Quantity);
                 }
                 
                 //Add the order quantity reductions to the map
                 for(OrderItem oi : [Select UnitPrice, Quantity, Key__c, Product2Id, Product2.Name from OrderItem Where Order.OpportunityId = :oppId])
                  {
                    
                  if(!mapProduct_To_Quantity.containsKey(oi.Key__c)){
                  mapProduct_To_Quantity.put(oi.Key__c, 0);
                  }
                  
                  mapProduct_To_Quantity.put(oi.Key__c, mapProduct_To_Quantity.get(oi.Key__c) - oi.Quantity);
                  
                 // if (mapProduct_To_Quantity.get(oi.Key__c) == 0) mapProduct_To_Quantity.remove(oi.Key__c); 
                  system.debug('### mapProduct_To_Quantity c' + mapProduct_To_Quantity);
                 }
                 
                  //Put the products and quantity into the wrapper
                  for (String setProdId : productKeys) {
                      string realProdId = setProdId.substring(0, 15);
                      system.debug('map sales unit price'+mapSalesPrice_to_Key.get(setProdId));
                      system.debug('map all sales unit price'+mapSalesPrice_to_Key);
                      wrapPurchasedLines.add(new wrapLines(mapProduct_to_Key.get(setProdId), mapProduct_To_Quantity.get(setProdId), mapProduct_Name.get(realProdId),  mapProduct_To_Quantity.get(setProdId)==0 ? true : false, mapProduct_to_PBE.get(realProdId),  mapPrice_to_Key.get(setProdId), mapProduct_to_OLI.get(setProdId),mapValootoSalesPrice_to_Key.get(setProdId),mapSalesPrice_to_Key.get(setProdId))); 
                      
                  }

                 //done!
                 
                }
            }
        }
     
    
       public void processSelected(ID ordId) {
       
            selectedOrderItems = new List<OrderItem>();
            for(wrapLines wrapLinesObj : wrapPurchasedLines) {
                system.debug('Sales_Price__C--'+wrapLinesObj.Sales_Price);
                if(wrapLinesObj.selected == true) {

                    selectedOrderItems.add(
                        new OrderItem(OrderId = ordId,
                            PricebookentryId = wrapLinesObj.pbeid,
                            Quantity = wrapLinesObj.userquantity,
                            UnitPrice = wrapLinesObj.price,
                            AvailQuantity__c = wrapLinesObj.addquantity,
                            oliID__c = wrapLinesObj.oliOrigID.substring(0, 15),
                            Sales_Price__C = wrapLinesObj.sales_price,
                            Actual_Sales_Price__c = wrapLinesObj.valooto_sales_price
                        )
                    );
                    system.debug('### selectedOrderItems'+ selectedOrderItems);
                    
                }
                
            }
            if(!selectedOrderItems.isEmpty()){
                upsert selectedOrderItems;
            }
            
        }
        
       
       public void reset(){
       
            //ApexPages.StandardController controller = new ApexPages.StandardController(newOrder);
            delete [select id from OrderItem where OrderId=:newOrder.id]; 
            wrapPurchasedLines.clear();
            initWrapper();
            resetPage();
       
        } 
        
      public ApexPages.PageReference resetPage() {
      
          delete [select id from OrderItem where OrderId=:newOrder.id]; 
          wrapPurchasedLines.clear();
          PageReference resetPage = new PageReference('/apex/AddOrderLineItems');
          resetPage.getParameters().put('oppId', oppId);
          resetPage.getParameters().put('Id', newOrder.id);
          resetPage.setRedirect(true);

      return resetPage;     
      
      }
        
      public ApexPages.PageReference saveRecord() {
          ApexPages.StandardController controller = new ApexPages.StandardController(newOrder);
          try {
            controller.save();
            processSelected(controller.getId());            
            PageReference savePage = new PageReference('/'+controller.getId());
            

        savePage.setRedirect(true);

        return savePage; 
          }
          catch(Exception e) {
          ApexPages.addMessages(e);
          system.debug('### exception in save' + e);
            return null;
          }
  
        }
   
 /*****************************************************************************************************************************************
                                                Wrapper classes & methods
 *****************************************************************************************************************************************/
        
        // This is our wrapper/container class. 
        @TestVisible
        public class wrapLines {
            public Product2 oli {get; set;}
            public Id pid {get; set;}
            public Id pbeId {get; set;}
            public boolean selected {get; set;}
            public decimal addquantity {get; set;}
            Public string prodName {get; set;}
            public boolean disabled {get; set;}
            public decimal price {get; set;}
            public decimal userquantity {get; set;}
            public decimal sales_price {get; set;}
            public decimal valooto_sales_price {get; set;}
            public string oliOrigID {get; set;}
            public string lineID {get; set;}
     
        public wrapLines(Id product, decimal q, string name, boolean none, Id pbe, decimal unitprice, string oliID,decimal ValootoSalesPrice, decimal sales_Price) {
                pid = product;
                addquantity = q;
                prodName = name;
                disabled = none;
                selected = this.disabled == false ? true : false;
                pbeId = pbe;
                price = unitprice;
                userquantity = q;
                oliOrigID = oliID.substring(0, 15);
                this.sales_price = sales_price;
                valooto_sales_price = ValootoSalesPrice;

            }
            
        }


}