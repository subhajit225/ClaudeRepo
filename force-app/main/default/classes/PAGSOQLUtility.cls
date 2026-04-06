/*
* Class Name :- PAGSOQLUtility
* Author :- Rubrik Dev
* Created Date :- Aug 29th , 2023
* Description : CPQ22-3109 :- SOQL Utility Class for PAGService API
* TestClass   : PAGServiceTest
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
* 
* 
// ********************Modification Log *****************************************************************************
*/
public class PAGSOQLUtility {


    /*public static PAGServiceUtility.ExistingDataWrapper getPAGDetails(PAGServiceUtility.ExistingDataWrapper existingDetails,PAGRequestWrapper pagReqWrapper){

        List<Product_Assisted_Growth__c> pAGList = [Select ID,Opportunity__c,Trial_ID__c FROM Product_Assisted_Growth__c where Trial_ID__c =: pagReqWrapper.pags[0].pagWrapper.pagRecord.Trial_ID__c];
        system.debug('pAGList'+pAGList);
        if(pAGList == null || pAGList.size() == 0){
            existingDetails.pagDetails = null;
            existingDetails.errorDetails = '';
        }else if(pAGList.size() == 1){
            existingDetails.pagDetails = pAGList[0];
            existingDetails.errorDetails = '';          
        }else{
            //Move message to PAG Constant Class
            existingDetails.errorDetails = existingDetails.errorDetails + 'Multiple PAG created with the Trial ID : ' + pagReqWrapper.pags[0].pagWrapper.pagRecord.Trial_ID__c;
            existingDetails.pagDetails = null;
        }
        system.debug('existingDetails.errorDetails '+existingDetails.errorDetails);
        return existingDetails;
    }

    public static PAGServiceUtility.ExistingDataWrapper getEntitlementDetails(PAGServiceUtility.ExistingDataWrapper existingDetails,PAGRequestWrapper pagReqWrapper){
        
        Set<String> EntitlementIDSet = new Set<String>();
        
        //Collect RSC_Entitlement_Id__c from Request Wrapper Entitlments
        for(PAGRequestWrapper.Entitlements entitlementWrapper : pagReqWrapper.entitlements){
            if(String.isNotBlank(entitlementWrapper.entWrapper.entitlementRecord.RSC_Entitlement_Id__c)){
                EntitlementIDSet.add(entitlementWrapper.entWrapper.entitlementRecord.RSC_Entitlement_Id__c);
            }
        }

        if(!EntitlementIDSet.isEmpty()){

            for(Entitlement entRec : [Select ID,RSC_Entitlement_Id__c FROM Entitlement where RSC_Entitlement_Id__c IN: EntitlementIDSet]){
                existingDetails.entitlementMap.put(entRec.RSC_Entitlement_Id__c,entRec);
            }
        }
        return existingDetails;
    }
    */
    
    
    public static Map<String,Product_Assisted_Growth__c> getPAGDetails(Set<String> setTrialID){

        Map<String,Product_Assisted_Growth__c> trialIdPAGMap = new Map<String,Product_Assisted_Growth__c>();
        for(Product_Assisted_Growth__c pagRec:[Select ID,Opportunity__c,Trial_ID__c FROM Product_Assisted_Growth__c where Trial_ID__c IN : setTrialID]){
            trialIdPAGMap.put(pagRec.Trial_ID__c,pagRec);
        }
        return trialIdPAGMap;
    }

    /** 
     * @description SAL25-818 Method to query on PAG to get PQL records against PQL external id.
     * @param setPQLExternalID
     * @return trialIdPAGMap
     */
    public static Map<String,Product_Assisted_Growth__c> getPQLDetails(Set<String> setPQLExternalID){

        Map<String,Product_Assisted_Growth__c> trialIdPAGMap = new Map<String,Product_Assisted_Growth__c>();
        for(Product_Assisted_Growth__c pagRec:[Select ID,Opportunity__c,PQL_External_Id__c FROM Product_Assisted_Growth__c where PQL_External_Id__c IN : setPQLExternalID]){
            trialIdPAGMap.put(pagRec.PQL_External_Id__c,pagRec);
        }
        return trialIdPAGMap;
    }
    
    public static Map<String,Entitlement> getEntitlementDetails(PAGRequestWrapper pagReqWrapper){
        
        Set<String> EntitlementIDSet = new Set<String>();
        Map<String,Entitlement> entitlementMap = new Map<String,Entitlement>();
        //Collect RSC_Entitlement_Id__c from Request Wrapper Entitlments
        for(PAGRequestWrapper.Entitlements entitlementWrapper : pagReqWrapper.entitlements){
            if(String.isNotBlank(entitlementWrapper.entWrapper.entitlementRecord.RSC_Entitlement_Id__c)){
                EntitlementIDSet.add(entitlementWrapper.entWrapper.entitlementRecord.RSC_Entitlement_Id__c);
            }
        }

        if(!EntitlementIDSet.isEmpty()){

            for(Entitlement entRec : [Select ID,RSC_Entitlement_Id__c FROM Entitlement where RSC_Entitlement_Id__c IN: EntitlementIDSet]){
                entitlementMap.put(entRec.RSC_Entitlement_Id__c,entRec);
            }
        }
        return entitlementMap;
    }

    public static Map<String,Account> getAccountDetails(Map<String,Account> mapAccount){
              //Added following fields (Rubrik_Sales_Engineer__c,Non_Core_Adaptive_Territory_Ids__c ,Non_Core_Type_and_Adaptive_Id__c,Adaptive_Territory_Id__c) in below query as part of SAL25-819
              mapAccount = new Map<String,Account>([Select ID ,Name,OwnerId, Rubrik_Sales_Engineer__c,Non_Core_Adaptive_Territory_Ids__c ,Non_Core_Type_and_Adaptive_Id__c,Adaptive_Territory_Id__c from Account where ID IN : mapAccount.keySet()]);
        
        return mapAccount;
    }

    public static Map<String,Product2> getProductDetails(Set<String> productNameSet){
        Map<String,Product2> productMap = new Map<String,Product2>();
        for(Product2 prod : [SELECT ID, ProductCode FROM Product2 WHERE ProductCode IN: productNameSet]){
            productMap.put(prod.ProductCode,prod);
        }
        return productMap;
    }
}