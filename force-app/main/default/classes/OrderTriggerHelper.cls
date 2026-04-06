public class OrderTriggerHelper {

    //START - SAL-196
    public static void sendAlertforMissingAssets(List<Order> newOrderList, Map<Id, Order> oldOrderMap) {
        List<id> orderIdList = new List<id>();

        for (Order o : newOrderList) {
            if (o.Order_Status__c == 'Shipped' && oldOrderMap.get(o.Id).Order_Status__c != 'Shipped') {
                orderIdList.add(o.Id);
            }
        }
        if(!orderIdList.isEmpty()){
            sendAlertforMissingAssetsInFuture(orderIdList);
        }
    }

    //SAL-196 - Update Order with Missing Serial Numbers
    @future
    public static void sendAlertforMissingAssetsInFuture( List<Id> orderIdList) {
        
        Map<Id, String> assetsSerialNumbersMap = new  Map<Id, String> ();
        Map<String, Id> serialNumbersOrderIdMap = new  Map<String, Id> ();
        List<String> snList = new List<String> ();
        List<Id> missingAssetsOrderIds = new List<Id> ();
        List<Order> orderMissingAssetsUpdate = new List<Order> ();
        
        if(!orderIdList.isEmpty()){
            for (OrderItem oI : [SELECT Id, SerialNumber__c, OrderId FROM OrderItem WHERE OrderId IN :orderIdList]) {
                
                //SAL-605
                if(oI.SerialNumber__c != NULL){
                    snList.addAll(oI.SerialNumber__c.split(','));
                    for(String sn : oI.SerialNumber__c.split(',')) {
                        //SAL-793 added serial number trim()
                        serialNumbersOrderIdMap.put(sn.trim(), oI.OrderId);
                    }
                }
            }
        }
        
        if(!snList.isEmpty()){
            //SAL-793 changed snList to snListTrim in where condition
            for (Asset asset : [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber IN :serialNumbersOrderIdMap.keySet()]) {
                if (serialNumbersOrderIdMap.containsKey(asset.SerialNumber)) {
                    serialNumbersOrderIdMap.remove(asset.SerialNumber);
                }
            }
        }        
        for (String srlNos : serialNumbersOrderIdMap.keyset()) {
            
            if (!assetsSerialNumbersMap.containsKey(serialNumbersOrderIdMap.get(srlNos))) {
                assetsSerialNumbersMap.put(serialNumbersOrderIdMap.get(srlNos), srlNos);
            } else {
                assetsSerialNumbersMap.put(serialNumbersOrderIdMap.get(srlNos), assetsSerialNumbersMap.get(serialNumbersOrderIdMap.get(srlNos)) + ',' + srlNos);
            }
        }
        missingAssetsOrderIds.addAll(assetsSerialNumbersMap.keySet());
        
        for(Id ordId : missingAssetsOrderIds) {
            if(assetsSerialNumbersMap.containsKey(ordId)) {
                Order ord = new Order (Id = ordId);
                ord.Assets_Missing_In_System__c = assetsSerialNumbersMap.get(ord.Id);
                orderMissingAssetsUpdate.add(ord);
            }
        }
        if(!orderMissingAssetsUpdate.isEmpty()){
            update orderMissingAssetsUpdate;
        }
    }
    //END - SAL-196

}