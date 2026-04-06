/***********************************************************************************************************
 * Class Name           : QuoteDynamicCartJSONHelper
 * Date Created/Modified: 18/12/2025
 * Author               : Rahul Kappa
 * @description         : This Class is used to fetch Data from Look up Table and feed QCP for Dynamic Cart
 * Test Class           :
 /**********************************************************************************************************/
@RestResource(urlMapping='/QuoteDynamicCartJSONHelper') 
global without sharing class QuoteDynamicCartJSONHelper {
/***********************************************************************************************************
    * Method Name          : quoteDynamicCartJSONHelper
    * Date Created/Modified: 18/12/2025
    * Author               : Rahul Kappa
    * @description         : This Method is used to fetch Data from Look up Table and feed QCP for Dynamic Cart
    * @return              : Map<String, String>
    * User Story           : FY26WL-164, FY26WL-163
    * @param categoryKey
/**********************************************************************************************************/
@httppost  
    global  static Map<String, String> quoteDynamicCartJSONHelperPost(List<String> categoryKey){
        Map<String, String> mapQlIdDynJSON = new Map<String, String>();
        Set<String> setCategoryKey = new Set<String>(categoryKey);
        if(!setCategoryKey.isEmpty()){
                for(SBQQ__LookupData__c lp : [SELECT Category_Sub_Category_Link__c,Dynamic_Cart_JSON__c
                        FROM SBQQ__LookupData__c WHERE Category_Sub_Category_Link__c != NULL AND Active__c = TRUE]){
                    String catKey = String.ValueOf(lp.Category_Sub_Category_Link__c);
                    if(setCategoryKey.contains(catKey.toLowerCase())){
                        mapQlIdDynJSON.put(lp.Category_Sub_Category_Link__c.toLowerCase(),lp.Dynamic_Cart_JSON__c);
                    }
            }
        }
        system.debug(LoggingLevel.DEBUG, 'mapQlIdDynJSON is '+mapQlIdDynJSON);
        return mapQlIdDynJSON;
    }
}