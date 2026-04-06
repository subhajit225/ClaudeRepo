public class Opportunity_Service {
    public static boolean run = true;
/*
    public static boolean runOnce;
    
    //DELETE - already moved to helper class
    public static void insertNewOrder(List<Opportunity> oppList){
        try {
            if(!oppList.isEmpty()){
                system.debug('oppList---'+oppList+'---size--'+oppList.size());
                for(Opportunity opp : oppList){                    
                    if(opp.Opportunity_Split_Parent__c == null){
                        createOrderWithOrderItems(opp.id);
                    }
                    //createOrderWithOrderItems(opp.id);
                }
            }
        } catch(Exception ex) {
            System.debug('Exception==Method: insertNewOrder==Class==Opportunity_Service'+ex);
        }
    }
    
    //DELETE - already moved to helper class
    public static void updatetExistingOrder(List<Order> orderList){
        try {
            if(!orderList.isEmpty()){
                system.debug('orderList---'+orderList+'---size--'+orderList.size());
                List<OrderItem> orderiTemsList = [select id from orderItem where orderId IN: orderList];
                system.debug('orderitemsList =='+orderiTemsList);
                if(!orderitemsList.isEmpty())
                    delete orderitemsList;
                system.debug('orderitemsList =='+orderiTemsList);
                for(Order order : orderList){
                    updateOrderWithOrderItems(order.Id,order.OpportunityID);
                }
            }
        } catch(Exception ex) {
            System.debug('Exception==Method: insertNewOrder==Class==Opportunity_Service'+ex);
        }
    }
    
    //DELETE - already moved to helper class
    public static void createOrderWithOrderItems(Id oppId) {
        try {
            Order neworder = new Order();
            Opportunity opp = [select StageName,Account.name,Account.Id,Partner_Lookup__c,Distributor_Lookup__c,Distributor_lookup__r.Payment_Term__c, OwnerId, Owner.email, Rubrik_Sales_Engineer__c,Rubrik_Sales_Engineer__r.Email,
                               Partner_Lookup__r.Shipping_Carrier__c , Partner_Lookup__r.Shipping_Method__c , Partner_Lookup__r.Shipping_Account_Number__c,Partner_Lookup__r.IncoTerms__c,
                               Distributor_Lookup__r.Shipping_Carrier__c , Distributor_Lookup__r.Shipping_Method__c , Distributor_Lookup__r.Shipping_Account_Number__c,Distributor_Lookup__r.IncoTerms__c,
                               Partner_Lookup__r.Distributor__r.Shipping_Carrier__c,Partner_Lookup__r.Distributor__r.Shipping_Method__c,Partner_Lookup__r.Distributor__r.Shipping_Account_Number__c,Partner_Lookup__r.Distributor__r.IncoTerms__c,
                               Partner_Lookup__r.Payment_Term__c,Partner_Lookup__r.Distributor__r.Payment_Term__c,Partner_Lookup__r.Distributor__c, CloseDate,Pricebook2Id,Opportunity_Split_Parent__c
                               from Opportunity where Id =:oppId];
            List<OpportunityLineItem> listOI =[select id,unitprice,TotalPrice, Valooto_Sales_Price__c ,Description,quantity,discount, PriceBookEntryId from OpportunityLineItem where opportunityid =: oppId];
            List<OpportunityContactRole> ocr =[select id,Role,ContactId,Contact.Email,isPrimary from OpportunitycontactRole where opportunityid =: oppId limit 1];
            
            //neworder.status='Pending';
            neworder.Order_Status__c = 'Pending';
            neworder.AccountId=opp.Account.Id;
            neworder.OpportunityId=opp.Id;
            neworder.PONumber='n/a';
            neworder.EffectiveDate=system.Today();
            neworder.RecordtypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
            neworder.Type ='Revenue';
            //newOrder.Ship_To_Name__c = Opp.Account.Id;
            if(opp.Distributor_Lookup__c != null)
                newOrder.Bill_To_Name__c = Opp.Distributor_Lookup__c;

            //Added per Kiet for Welcome Letter CL
            newOrder.Opportunity_Owners_Email__c = opp.Owner.email;
            newOrder.Rubrik_Sales_Engineer__c = opp.Rubrik_Sales_Engineer__r.Email;
            if( !ocr.isEmpty() ) newOrder.ShipToContact = ocr[0].Contact;
            
            neworder.Pricebook2Id = opp.Pricebook2Id;
            insert neworder;
            List<OrderItem> opptyLineItemsList = new List<OrderItem>();
            for(OpportunityLineItem oi : listOI) {
                opptyLineItemsList.add ( createOrderItem (oi, neworder) );

            }
            insert opptyLineItemsList;
            system.debug('neworder=='+neworder);
            system.debug('opptyLineItemsList=='+opptyLineItemsList+'==size of opptyLineItemsList=='+opptyLineItemsList.size());
        } catch(Exception ex) {
            System.debug('Exception==Method: createOrderWithOrderItems==Class==Opportunity_Service'+ex);
        }
    }
    
    //DELETE - already moved to helper class
    // Added new method to handle update of existing order. Logic: Only a single records per Oppoty
    public static void updateOrderWithOrderItems(Id orderId, Id oppId) {
        try {
            Order neworder = new Order(id= orderId);
            Opportunity opp = [select StageName,Account.name,Account.Id,Partner_Lookup__c,Distributor_Lookup__c,Distributor_lookup__r.Payment_Term__c,
                               Partner_Lookup__r.Shipping_Carrier__c , Partner_Lookup__r.Shipping_Method__c , Partner_Lookup__r.Shipping_Account_Number__c,Partner_Lookup__r.IncoTerms__c,
                               Distributor_Lookup__r.Shipping_Carrier__c , Distributor_Lookup__r.Shipping_Method__c , Distributor_Lookup__r.Shipping_Account_Number__c,Distributor_Lookup__r.IncoTerms__c,
                               Partner_Lookup__r.Distributor__r.Shipping_Carrier__c,Partner_Lookup__r.Distributor__r.Shipping_Method__c,Partner_Lookup__r.Distributor__r.Shipping_Account_Number__c,Partner_Lookup__r.Distributor__r.IncoTerms__c,
                               Partner_Lookup__r.Payment_Term__c,Partner_Lookup__r.Distributor__r.Payment_Term__c,Partner_Lookup__r.Distributor__c, CloseDate,Pricebook2Id
                               from Opportunity where Id =:oppId];
            List<OpportunityLineItem> listOI = [select id,unitprice,TotalPrice, Valooto_Sales_Price__c ,Description,quantity,discount, PriceBookEntryId from OpportunityLineItem where opportunityid =: oppId];
            neworder.Pricebook2Id = opp.Pricebook2Id;
            update neworder;
            List<OrderItem> opptyLineItemsList = new List<OrderItem>();
            for(OpportunityLineItem oi : listOI) {
                opptyLineItemsList.add ( createOrderItem (oi, neworder) );
            }
            insert opptyLineItemsList;
            system.debug('neworder=='+neworder);
            system.debug('opptyLineItemsList=='+opptyLineItemsList+'==size of opptyLineItemsList=='+opptyLineItemsList.size());
        } catch(Exception ex) {
            System.debug('Exception==Method: createOrderWithOrderItems==Class==Opportunity_Service'+ex);
        }
    }
    
    private static OrderItem createOrderItem (OpportunityLineItem oi, Order neworder) {
        OrderItem oli = new OrderItem();
        oli.orderId = neworder.Id;
        oli.PriceBookEntryId = oi.PriceBookEntryId;
        if(oi.Discount != null)
            oli.UnitPrice = oi.UnitPrice- (oi.UnitPrice*oi.Discount)/100;
        else
            oli.UnitPrice = oi.UnitPrice;
        oli.Actual_Sales_Price__c = oi.Valooto_Sales_Price__c;
        oli.SBQQ__QuotedListPrice__c = oi.Valooto_Sales_Price__c;
        oli.Sales_Price__c = (oi.TotalPrice/oi.quantity).setScale(2) ;
        oli.Description = oi.Description;
        oli.Quantity = oi.Quantity;
        
        return oli;
    }
    
    //DELETE - already moved to helper class
    public static void increaseHoldoverCount (List<Id> userIdList) {
        system.debug('increaseHoldoverCount :: '+userIdList);
        Map<Id, User> userMap = new Map<Id, User> ([SELECT Id, Holdover_Count__c FROM User WHERE Id IN :userIdList]);
        for(Id usrId : userIdList) {
            if(userMap.containsKey(usrId)) {
                User usr = userMap.get(usrId);
                if(usr.Holdover_Count__c == null || usr.Holdover_Count__c < 0) 
                    usr.Holdover_Count__c = 0;
                
                usr.Holdover_Count__c ++;
                userMap.put(usrId, usr);
            }
        }
        update userMap.values();
    }
    
    //DELETE - already moved to helper class
    public static void decreaseHoldoverCount (List<Id> userIdList) {
        Map<Id, User> userMap = new Map<Id, User> ([SELECT Id, Holdover_Count__c FROM User WHERE Id IN :userIdList]);
        for(Id usrId : userIdList) {
            if(userMap.containsKey(usrId)) {
                User usr = userMap.get(usrId);
                if(usr.Holdover_Count__c == null || usr.Holdover_Count__c <= 0) usr.Holdover_Count__c = 0;
                else usr.Holdover_Count__c --;
                userMap.put(usrId, usr);
            }
        }
        update userMap.values();
    }
    
    private static boolean flagvalue = false;
    
    public static boolean hasAlreadyfired() {
        return flagvalue;
    }
    
    public static void setAlreadyfired() {
        flagvalue = true;
    }
    */
}