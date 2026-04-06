/***********************************************************************************************************
@description : Wrapper class for PAG/PQL api service
@Developer : Rubrik Dev
@Date : 2/17/2025
Test Class : PAGServiceTest 
Modification Logs
Modified By             Date            Description
Rubrik Dev              2/17/2025       SAL25-819 Implement Opportunity Creation Process
************************************************************************************************************/
public with sharing class PAGResponseWrapper {
    
    public String status;//NOT NEEDED
    public String pagID;//NOT NEEDED
    public String errorCode;
    public String message;    
    public Map<String,Product_Assisted_Growth__c> trialIdPagMap;
    public Map<String,Product_Assisted_Growth__c> externalIdPqlMap; //SAL25-819
    public Map<String,String> trialIDErrorMap;
    //SAL25-818 Added for PQL ID error map
    public Map<String,String> pqlExternalIDErrorMap; //SAL25-819
    public Map<String,String> pqlIDErrorMap; //SAL25-819
    public Map<String,String> entitlementIDErrorMap;
    public Map<String,String> pagIDErrorMap;
    

    /*public PAGResponseWrapper(String status,String errorCode,String message,String pagID) {
        if(String.isNotBlank(status)){
            this.status = status;
        }       
        if(String.isNotBlank(errorCode)){
            this.errorCode = errorCode;
        }
        if(String.isNotBlank(message)){
            this.message = message;
        }
        if(String.isNotBlank(pagID)){
            this.pagID = pagID;
        }
    }*/
}