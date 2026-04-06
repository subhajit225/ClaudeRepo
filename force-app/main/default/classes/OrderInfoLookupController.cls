public without sharing class OrderInfoLookupController {

    // Order lookup fields
    public String orderNumber {get; set;} // OrderNumber
    public String poNumber {get; set;} // PO_Number__c
    public String endUserPo {get; set;} // End_User_PO__c

    public List<OrderWrap> orders {get; private set;}

    // pagination information
    public Integer page {get; set;}
    public Integer pageSize {get; set;}
    public Integer totalRecords {get; set;}
    public Integer totalPages {get; set;}
    public Integer startIdx {get; set;}
    public Integer endIdx {get; set;}
    public List<SelectOption> paginationSizeOptions {get; set;}

    public OrderInfoLookupController(){

        pageSize = 10;

        paginationSizeOptions = new List<SelectOption>();
        paginationSizeOptions.add(new SelectOption('5','5'));
        paginationSizeOptions.add(new SelectOption('10','10'));
        paginationSizeOptions.add(new SelectOption('20','20'));
        paginationSizeOptions.add(new SelectOption('50','50'));
        paginationSizeOptions.add(new SelectOption('100','100'));

        this.orders = new List<OrderWrap>();

        // set initial page
        this.page = 1;

        getOrders();
    }

    public without sharing class OrderWrap {

        public String name {get; private set;}
        public String orderNumber {get; private set;}
        public String distributorPONumber {get; private set;}
        public String status {get; private set;}
        public Date actualOrderShipDate {get; private set;}
        public String shippingCarrier {get; private set;}
        public String trackingNo {get; private set;}
        public String trackingLink {get; private set;}
        public String endUserPoNumber {get; private set;}
        public Date estShipDate {get; private set;}

        public OrderWrap(SObject so) {
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

    /*
    *   advance to next page
    */
    public void doNext(){

        if(getHasNext()){
            this.page++;
            getOrders();
        }

    }


    /*
    *   advance to previous page
    */
    public void doPrevious(){

        if(getHasPrevious()){
            this.page--;
            getOrders();
        }

    }

    /*
    *   returns whether the previous page exists
    */
    public Boolean getHasPrevious(){
        if(this.page > 1){
            return true;
        }
        else{
            return false;
        }
    }

    /*
    *   returns whether the next page exists
    */
    public Boolean getHasNext(){
        if(this.page < this.totalPages){
            return true;
        }
        else{
            return false;
        }
    }

    public void refreshPageSize() {
        this.page = 1;
        getOrders();
    }

    public void apply() {
        this.page = 1;
        getOrders();
    }

    /*
    *   return current page of records
    */
    public void getOrders(){

        //calculate range of records for capture
        this.startIdx = (this.page-1)*pageSize;
        this.endIdx = this.page*pageSize;
        this.totalRecords = 0;

        //clear container for records displayed
        this.orders.clear();

        List<String> wheres = new List<String>();

        String accountId = null;
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
            query += 'WHERE Bill_To_Name__c = \'' + String.escapeSingleQuotes( '' + users.get(0).Contact.AccountId) + '\'';
        }

        if(!wheres.isEmpty()) {
            query += ' AND ( ' + String.join(wheres, ' OR ') + ')';
        }

        query += ' ORDER BY CreatedDate DESC ';

        query += ' LIMIT 50000';


        //cycle through
        for(SObject so : Database.query(query)){

            //capture records within the target range
            if(this.totalRecords >= this.startIdx && this.totalRecords < this.endIdx){

                //this.orders.add(so);
                this.orders.add(new OrderWrap(so));
            }

            //count the total number of records
            this.totalRecords++;

        }


        //calculate total pages
        Decimal pages = Decimal.valueOf(this.totalRecords);
        pages = pages.divide(Decimal.valueOf(pageSize), 2);
        this.totalPages = (Integer)pages.round(System.RoundingMode.CEILING);

        //adjust start index e.g. 1, 11, 21, 31
        this.startIdx++;


        //adjust end index
        if(this.endIdx > this.totalRecords){
            this.endIdx = this.totalRecords;
        }

    }
}