/* PSTaskService - A service class for PS Objects and is used to avoid duplicacy of code in multiple classes */
public class PSTaskService {
    /*The method runs for a single instance and cannot be bulkified because of the risk of changing the current order framework*/
    public Id routePSProjectManager(Order ord){
        if(ord.AccountId != null && ord.Account_Billing_Address_Region__c != null) {
            String psProjectManagerMappingString = ord.RSC_G_Enabled__c ? 'RSC-G' : ord.Account_Billing_Address_Region__c;
            if( setRubrikUOrderId.contains( ord.Id ) ) {
                psProjectManagerMappingString = 'Rubrik-University';
            }
            PS_Project_Manager_Mapping__c psProjectManagerMapping = PS_Project_Manager_Mapping__c.getValues(psProjectManagerMappingString);
            if(psProjectManagerMapping != null && psProjectManagerMapping.Project_Manager_User_Id__c != null) {
                return psProjectManagerMapping.Project_Manager_User_Id__c;
            }
        }
        return null;
    }
    //Added for MKT26-773
    public static Set<Id> setRubrikUOrderId ;

    /*
        Created to filter out the orders which only have Rubrik University tasks.   
    */
    public static void setOrderswithRubrikU( Map<Id, List<OrderItem>> mapOrderIdtoOLI, Map<Id, Order> mapIdToOrder, Map<String, PS_Task_Meta__mdt> mapSKUToPSTaskMdt ) {
        setRubrikUOrderId = new Set<Id>();
        if( mapSKUToPSTaskMdt == null) {
            mapSKUToPSTaskMdt = new Map<String, PS_Task_Meta__mdt>();    
            for( PS_Task_Meta__mdt objPSMeta : [Select Id, MasterLabel, Task_Type__c FROM PS_Task_Meta__mdt ] ) {
                mapSKUToPSTaskMdt.put(objPSMeta.MasterLabel, objPSMeta);
            }
        }
        for( Id orderId : mapOrderIdtoOLI.keySet() ) {
            if( mapIdToOrder != null && mapIdToOrder.containsKey(orderId) && !mapIdToOrder.get(orderId).Have_PS_Products__c ) {
                continue;
            }
            Boolean isExcRubrikUOrder = True;
            for( OrderItem orderItem :  mapOrderIdtoOLI.get(orderId) ) {
                PS_Task_Meta__mdt mdtTask = mapSKUToPSTaskMdt.get(orderItem.Product2.ProductCode);
                if(mdtTask != null && mdtTask.Task_Type__c != null && mdtTask.Task_Type__c != 'Rubrik University' && mdtTask.Task_Type__c != 'T&E') {
                    isExcRubrikUOrder=FALSE; 
                    break;
                }
            }
            if( isExcRubrikUOrder ) {
                setRubrikUOrderId.add( orderId );
            }
        }
    }
}