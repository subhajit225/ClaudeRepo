/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community - Deal registration page components controller.
*******************************************************************************************************/
public without sharing class PC_OrdersController {
    //without sharing
    
    /*******************************************************************************************************
* @description Returns User record
* @param N/A
* @return the User record for the login user
***********************************************************************************************************/
    @AuraEnabled
    public Static OrdersWrap getOrdersList(string poNumber, string endUserPO, string orderNumber,
                                           Integer pageSize, Integer pageNumber)
    {
        // pageSize = limits;
        // pageNumber = offsets;
        system.debug('Done**********************'+pageSize+'--'+pageNumber);
        //calculate range of records for capture
        
        Integer intlimits = integer.valueof(pageSize);
        Integer intoffsets = integer.valueof(pageNumber);        
        
        Integer startIdx = intoffsets;
        Integer endIdx = startIdx + intlimits;        
        Integer totalRecords = 0;
        Integer totalPages = 0;
        
        List<Order> lstOrder = new List<Order>();
        List<OrderWrap> orders = new List<OrderWrap>();
        OrdersWrap ordersWrap = new OrdersWrap();
        List<String> wheres = new List<String>();        
        
        List<User> users = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];        
        
        if(String.isNotBlank(orderNumber) && orderNumber.trim().length() >= 1) {
            wheres.add('OrderNumber LIKE \'%' + String.escapeSingleQuotes(orderNumber.trim()) + '%\'');
        }
        if(String.isNotBlank(poNumber) && poNumber.trim().length() >= 1) {
            wheres.add('PoNumber LIKE \'%' + String.escapeSingleQuotes(poNumber.trim()) + '%\'');
        }
        if(String.isNotBlank(endUserPo) && endUserPo.trim().length() >= 1) {
            wheres.add('End_User_PO__c LIKE \'%' + String.escapeSingleQuotes(endUserPo.trim()) + '%\'');
        }
        
        String query = '' +
            'SELECT Id, End_User_PO__c, OrderNumber, Name, PoNumber, ' +
            ' Status, Order_Status__c, Actual_Order_Ship_Date__c, Shipping_Carrier__c, Tracking_No__c, Tracking_Link__c, Est_Ship_Date__c ' +
            ' FROM Order ';
        
        if(!users.isEmpty() && users.get(0).Contact.AccountId != null) {
            query += 'WHERE Bill_To_Name__c = \'' + String.escapeSingleQuotes(users.get(0).Contact.AccountId + '') + '\'';
        }
        
        if(!wheres.isEmpty()) {
            if(query.contains('WHERE')){
                query += ' AND ( ' + String.join(wheres, ' OR ') + ')';
            }else{
                query += ' WHERE ( ' + String.join(wheres, ' OR ') + ')';
            }
        } 
        
        // query += ' LIMIT 50000';
        
        System.debug('query:******'+ query);
        
        List<Order> lstOrderCount = new List<Order>();
        lstOrderCount = Database.query(query);
        totalRecords = lstOrderCount.size();         
        
        System.debug('totalRecords:******'+ totalRecords);
        System.debug('intlimits:******'+ intlimits);
        System.debug('intoffsets:******'+ intoffsets);
        
        query += ' ORDER BY CreatedDate DESC ';
        query += ' LIMIT:intlimits';
        query += ' Offset :intoffsets';
        
        lstOrder = Database.query(query);
        /*
//adjust end index
if(endIdx > totalRecords){
endIdx = totalRecords;
}*/
        
        /* for(Integer i = startIdx; i < endIdx ; i++){
orders.add(new OrderWrap(lstOrder[i]));
}*/
        /*
for(Integer i = 0; i < intlimits ; i++){
// lstOrder[0].Tracking_No__c = string.valueof(i);
orders.add(new OrderWrap(lstOrder[i]));
}*/
        /* 
//cycle through
for(SObject so : Database.query(query)){
//capture records within the target range
if(totalRecords >= startIdx && totalRecords < endIdx){                
//this.orders.add(so);
orders.add(new OrderWrap(so));
}
//count the total number of records
totalRecords++;
}*/
        
        //cycle through
        for(SObject so : lstOrder){
            orders.add(new OrderWrap(so));
        }
        
        // return
        ordersWrap.lstOrders = orders;
        ordersWrap.totalRecords = totalRecords;
        ordersWrap.totalPages = totalPages;
        return ordersWrap;        
    }
    /*    
@AuraEnabled
public Static OrdersWrap getOrdersListOld(string poNumber, string endUserPO, string orderNumber,
Integer pageSize, Integer pageNumber)
{
system.debug('Done**********************'+pageSize+'--'+pageNumber);
//calculate range of records for capture
pageNumber = Integer.valueOf(pageNumber);
pageSize = Integer.valueOf(pageSize);
Integer startIdx = pageNumber > 1 ?  (pageNumber - 1) * pageSize : 0;
Integer endIdx = startIdx + pageSize;
Integer totalRecords = 0;
Integer totalPages = 0;
system.debug('Done1**********************');    
List<Order> lstOrder = new List<Order>();
List<OrderWrap> orders = new List<OrderWrap>();
OrdersWrap ordersWrap = new OrdersWrap();
List<String> wheres = new List<String>();        
String accountId = null;

List<User> users = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
system.debug('Done2**********************');
if(String.isNotBlank(orderNumber) && orderNumber.trim().length() >= 1) {
wheres.add('OrderNumber LIKE \'%' + String.escapeSingleQuotes(orderNumber.trim()) + '%\'');
}
if(String.isNotBlank(poNumber) && poNumber.trim().length() >= 1) {
wheres.add('PoNumber LIKE \'%' + String.escapeSingleQuotes(poNumber.trim()) + '%\'');
}
if(String.isNotBlank(endUserPo) && endUserPo.trim().length() >= 1) {
wheres.add('End_User_PO__c LIKE \'%' + String.escapeSingleQuotes(endUserPo.trim()) + '%\'');
}
system.debug('Done3**********************');    
String query = '' +
'SELECT Id, End_User_PO__c, OrderNumber, Name, PoNumber, ' +
' Status, Order_Status__c, Actual_Order_Ship_Date__c, Shipping_Carrier__c, Tracking_No__c, Tracking_Link__c, Est_Ship_Date__c ' +
' FROM Order ';

if(!users.isEmpty() && users.get(0).Contact.AccountId != null) {
query += 'WHERE Bill_To_Name__c = \'' + users.get(0).Contact.AccountId + '\'';
}

if(!wheres.isEmpty()) {
if(query.contains('WHERE')){
query += ' AND ( ' + String.join(wheres, ' OR ') + ')';
}else{
query += ' WHERE ( ' + String.join(wheres, ' OR ') + ')';
}
}


query += ' ORDER BY CreatedDate DESC ';        
query += ' LIMIT 50000';
System.debug('query:******'+ query);

lstOrder = Database.query(query);
totalRecords = lstOrder.size();

//adjust end index
if(endIdx > totalRecords){
endIdx = totalRecords;
}

for(Integer i = startIdx; i < endIdx ; i++){
orders.add(new OrderWrap(lstOrder[i]));
}
for(Integer i = 0; i < 50 ; i++){
orders.add(new OrderWrap(lstOrder[0]));
}



//calculate total pages
Decimal pages = Decimal.valueOf(totalRecords);
pages = pages.divide(Decimal.valueOf(pageSize), 2);
totalPages = (Integer)pages.round(System.RoundingMode.CEILING);

// return orders; 

// return
ordersWrap.lstOrders = orders;
ordersWrap.totalRecords = totalRecords;
ordersWrap.totalPages = totalPages;
system.debug('ordersWrap******'+ordersWrap);
return ordersWrap;        
}
*/  
    public class OrdersWrap {
        //SF-13925 changes
        @AuraEnabled
        public List<OrderWrap> lstOrders {get; set;}
        @AuraEnabled
        public Integer totalRecords {get; private set;}
        @AuraEnabled
        public Integer totalPages {get; private set;}
    }
    
    public class OrderWrap {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String name {get; private set;}
        @AuraEnabled
        public String orderNumber {get; private set;}
        @AuraEnabled
        public String distributorPONumber {get; private set;}
        @AuraEnabled
        public String status {get; private set;}
        @AuraEnabled
        public Date actualOrderShipDate {get; private set;}
        @AuraEnabled
        public String shippingCarrier {get; private set;}
        @AuraEnabled
        public String trackingNo {get; private set;}
        @AuraEnabled
        public String trackingLink {get; private set;}
        @AuraEnabled
        public String endUserPoNumber {get; private set;}
        @AuraEnabled
        public Date estShipDate {get; private set;}
        
        public OrderWrap(SObject so) {
            this.id = String.valueOf(so.get('Id'));
            this.name = (so.get('Name') != null) ? String.valueOf(so.get('Name')) : '';
            this.orderNumber = (so.get('OrderNumber') != null) ? String.valueOf(so.get('OrderNumber')) : '';
            //this.distributorPONumber= (so.get('PO_Number__c') != null) ? String.valueOf(so.get('PO_Number__c')) : '';
            this.distributorPONumber= (so.get('PoNumber') != null) ? String.valueOf(so.get('PoNumber')) : '';
            this.status = (so.get('Order_Status__c') != null) ? String.valueOf(so.get('Order_Status__c')) : '';
            this.actualOrderShipDate = (so.get('Actual_Order_Ship_Date__c') != null) ? Date.valueOf(so.get('Actual_Order_Ship_Date__c')) : null;
            this.shippingCarrier = (so.get('Shipping_Carrier__c') != null) ? String.valueOf(so.get('Shipping_Carrier__c')) : '';
            this.trackingNo = (so.get('Tracking_No__c') != null) ? String.valueOf(so.get('Tracking_No__c')) : '';
            this.trackingLink = (so.get('Tracking_Link__c') != null) ? String.valueOf(so.get('Tracking_Link__c')) : '';
            this.endUserPoNumber = (so.get('End_User_PO__c') != null) ? String.valueOf(so.get('End_User_PO__c')) : '';
            this.estShipDate = (so.get('Est_Ship_Date__c') != null) ? Date.valueOf(so.get('Est_Ship_Date__c')) : null;
        }
    }
    
}