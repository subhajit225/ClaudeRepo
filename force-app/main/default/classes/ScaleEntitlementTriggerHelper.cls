public class ScaleEntitlementTriggerHelper {
   
    public static List<Scale_Entitlement__c> lstScaleEntitlements;
    public static void getQueryResult() {
            lstScaleEntitlements = new List<Scale_Entitlement__c>();
            
        if(lstScaleEntitlements.isEmpty()){
            lstScaleEntitlements = [SELECT Id, Contract_Line_Item__c, Type__c,Sub_Type__c, Entitlement__c, Order_Product__c, Asset__c,Order_Product__r.Product2.Bundle_Features__c,
                                             Order_Product__r.SBQQ__QuoteLine__r.Support_Type__c,Order_Product__r.SBQQ__QuoteLine__r.Rubrik_Suite__c,
                                             Order_Product__r.SBQQ__QuoteLine__r.Licensing_Model__c, Order_Product__r.SBQQ__QuoteLine__r.Product_Payment_Option__c, Order_Product__r.Program__c, 
                                             Order_Product__r.Order.Actual_Order_Ship_Date__c, Order_Product__r.Product2.Product_Level__c	
                                        FROM Scale_Entitlement__c
                                        WHERE Id IN : Trigger.newMap.keyset()];  
        }
    }
    
    public static void AfterInsert(){
        Map<Id, Asset> mapIdToUpdateAsset = new Map<Id, Asset>();
        if(!lstScaleEntitlements.isEmpty()){

            for(Scale_Entitlement__c objSE : lstScaleEntitlements) {
                if(objSE.Contract_Line_Item__c != null && objSE.Asset__c != null && objSE.Type__c == 'Non-Scale' && objSE.Sub_Type__c == null){
                    Asset objAsset = new Asset(Id = objSE.Asset__c);
                    if(objSE.Order_Product__r.Program__c == 'Conversion' ||
                      (objSE?.Order_Product__r?.Product2?.Bundle_Features__c != null &&
                       objSE?.Order_Product__r?.Product2?.Bundle_Features__c?.contains('Hybrid RCDM') &&
                       objSE?.Order_Product__r?.Product2?.Product_Level__c != null && 
                       objSE?.Order_Product__r?.Product2?.Product_Level__c == 'Hybrid Software')){
                       		objAsset.Licensing_Model__c = objSE?.Order_Product__r?.SBQQ__QuoteLine__r?.Licensing_Model__c;
                    		objAsset.Rubrik_Suite__c = objSE?.Order_Product__r?.SBQQ__QuoteLine__r?.Rubrik_Suite__c;
                        if(objSE.Order_Product__r.Program__c == 'Conversion'){
                 			objAsset.Support_Type__c = objSE.Order_Product__r.SBQQ__QuoteLine__r.Support_Type__c;
                        	objAsset.Payment_Options__c = objSE.Order_Product__r.SBQQ__QuoteLine__r.Product_Payment_Option__c;
                 			objAsset.Program__c = 'Converted';
                        	objAsset.Processed_Date__c = objSE.Order_Product__r.Order.Actual_Order_Ship_Date__c;
                        }
                    }
                       
                    objAsset.SBQQSC__RequiredByLineItem__c = objSE?.Contract_Line_Item__c;   
                    
                    if(!mapIdToUpdateAsset.containskey(objSE.Asset__c)){
                        mapIdToUpdateAsset.put(objSE.Asset__c, objAsset); 
                    }
                
                }
            }
            if(!mapIdToUpdateAsset.isEmpty()) {
                update mapIdToUpdateAsset.values();
            }
        }
     }

}