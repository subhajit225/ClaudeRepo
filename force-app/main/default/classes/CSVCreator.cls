public class CSVCreator  {
    
    private static List<String> separateCommas(String input){
        List<String> results = input.split(',');
        for(String result : results) {
            result = result.trim();
        }
        return results;
    }
    
    @AuraEnabled
    public static CSVObject getCSVObject(String csv_str) {
        
        List<String> lines_raw = csv_str.split('\n');
        List<String> headers_raw = separateCommas(lines_raw[0]);
        List<CSVHeader> headers = new List<CSVHeader>();
        List<Order> lstOrders = new List<Order>();
        Map<String,Integer> mapHeaderIndex = new Map<String,Integer>();
        Integer indexCount = 0;
        Map<String,List<String>> mapIdValues = new Map<String,List<String>>();
        Set<String> setDupOrds = new Set<String>();

        lines_raw.remove(0);
        
        for(String strHeader : headers_raw) {
            string header = strHeader.trim();
            boolean headerFound = false;
            
            if(header == 'Order ID'){
               headerFound =true;
               mapHeaderIndex.put('Id',indexCount); 
            }else if(header == 'Order Number'){
                headerFound =true;
                mapHeaderIndex.put('Order_Number__c',indexCount); 
            }else if(header == 'Fulfilled in QTR'){
                headerFound =true;
                mapHeaderIndex.put('Fulfilled_in_QTR__c',indexCount); 
            }else if(header == 'Current Est Ship Date'){
                headerFound =true;
                mapHeaderIndex.put('Est_Ship_Date__c',indexCount); 
            }else if(header == 'Est Delivery Date'){
                headerFound =true;
                mapHeaderIndex.put('Deliver_By__c',indexCount); 
            }
            
            if(headerFound){    
                indexCount++;
                headers.add(new CSVHeader(header));
            } 
        }

        if(headers.size() != 5 || !mapHeaderIndex.containsKey('Id')){
            return new CSVObject(headers, Null, Null, setDupOrds);
        } 
        Map<Id, Order> ordersMap = getOrders(lines_raw, mapHeaderIndex);
        for(String line : lines_raw) {
            List<String> line_sep = separateCommas(line);
            List<String> fields = new List<String>();
            if(mapHeaderIndex.size() == line_sep.size() && mapHeaderIndex.containsKey('Id') 
                && String.isNotBlank(line_sep[mapHeaderIndex.get('Id')])){

                for(String field : line_sep) {
                    fields.add(field.trim());
                }
                
                if(mapIdValues.containsKey(fields[mapHeaderIndex.get('Id')])){
                    setDupOrds.add(fields[mapHeaderIndex.get('Order_Number__c')]);
                }else{
                    mapIdValues.put(fields[mapHeaderIndex.get('Id')],fields);

                    Order objOrd = new Order(Id = (Id)line_sep[mapHeaderIndex.get('Id')].trim());

                    if(mapHeaderIndex.containsKey('Fulfilled_in_QTR__c') && String.isNotBlank(line_sep[mapHeaderIndex.get('Fulfilled_in_QTR__c')])){
                        String temp = line_sep[mapHeaderIndex.get('Fulfilled_in_QTR__c')].trim();
                        objOrd.Fulfilled_in_QTR__c = temp == '1' ? true : false;
                    }
                    if(mapHeaderIndex.containsKey('Est_Ship_Date__c') && String.isNotBlank(line_sep[mapHeaderIndex.get('Est_Ship_Date__c')])){
                        objOrd.Est_Ship_Date__c = date.parse(line_sep[mapHeaderIndex.get('Est_Ship_Date__c')].trim());
                    }
                    if(mapHeaderIndex.containsKey('Deliver_By__c') && String.isNotBlank(line_sep[mapHeaderIndex.get('Deliver_By__c')])){
                        objOrd.Deliver_By__c = date.parse(line_sep[mapHeaderIndex.get('Deliver_By__c')].trim());
                    }
                    if(ordersMap.containsKey(objOrd.Id) && ordersMap.get(objOrd.Id).Order_Status__c == 'Order Accepted'){
                    	objOrd.Sync_to_NetSuite__c = true;    
                    }
                    lstOrders.add(objOrd);
                }
            }
        }
       	return new CSVObject(headers, lstOrders, mapIdValues, setDupOrds);
    }
    private static Map<Id, Order> getOrders(List<String> lines_raw, Map<String,Integer> mapHeaderIndex) {
        Map<Id, Order> ordersMap = new Map<Id, Order>();
        Set<Id> orderIds = new Set<Id>();
        for(String line : lines_raw) {
            List<String> line_sep = separateCommas(line);
            if(mapHeaderIndex.size() == line_sep.size() && mapHeaderIndex.containsKey('Id') 
               && String.isNotBlank(line_sep[mapHeaderIndex.get('Id')])) 
            {
                Id orderId = (Id)line_sep[mapHeaderIndex.get('Id')].trim();
                orderIds.add(orderId);
            } 
        }
        if(!orderIds.isEmpty()) {
            ordersMap = new Map<Id, Order>([SELECT Id, Order_Status__c FROM Order WHERE Id IN :orderIds LIMIT 10000]);
        }
        return ordersMap;
    }
    @AuraEnabled
    public static Map<String,List<String>> saveOrderDetails(List<Order> lstOrders, Map<String,List<String>> mapOrders) {
        
        set<String> setAllKeys = mapOrders.keySet().clone();
        
        if(!lstOrders.isEmpty()){
            triggerControl.stopOrderItemTrigger = true;
            triggerControl.stopOrderTrigger = true;
            List<Database.SaveResult> updateResults = Database.update(lstOrders, false);

            for(Integer i=0;i<updateResults.size();i++){
                if(mapOrders.containsKey(updateResults.get(i).getId())){
                    string dmlStatus = '';
                    if (updateResults.get(i).isSuccess()){
                        dmlStatus = 'Yes';
                        mapOrders.get(updateResults.get(i).getId()).add(dmlStatus);
                        setAllKeys.remove(updateResults.get(i).getId());
                    }else if (!updateResults.get(i).isSuccess()){
                        Database.Error error = updateResults.get(i).getErrors().get(0);
                        dmlStatus = error.getMessage();
                        mapOrders.get(updateResults.get(i).getId()).add(dmlStatus);
                        setAllKeys.remove(updateResults.get(i).getId());
                    }
                }
            }

            for(String strKey : setAllKeys){    
                mapOrders.get(strKey).add('Error: record not found.');
            }
        }
        return mapOrders;
    }
    
    public class CSVHeader  {
        
        @AuraEnabled
        public String column_name {get; set;}
        
        public CSVHeader(String column_name) {
            this.column_name = column_name;
        }
    }
    
    public class CSVObject {
        
        @AuraEnabled
        public List<CSVHeader> headers {get; set;}
        @AuraEnabled
        public List<Order> lstOrders {get; set;}
        @AuraEnabled
        public Map<String,List<String>> mapIdValues {get; set;}
        @AuraEnabled
        public Set<String> setDupOrds {get; set;}
        
        public CSVObject(List<CSVHeader> headers, List<Order> lstOrders,Map<String,List<String>> mapIdValues,Set<String> setDupOrds){
            this.headers = headers;
            this.lstOrders = lstOrders;
            this.mapIdValues = mapIdValues;
            this.setDupOrds = setDupOrds;
        }
    }
}