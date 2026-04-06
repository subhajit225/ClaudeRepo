/***************************************************************
 * @description       : This is helper class for ServiceContractMain trigger
 * @author            : Prashik
 * @last modified on  : 09-30-2025
 * @last modified by  : Prashik
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   09-30-2025   Prashik        Initial Version/PRDOPS26-984
 ************************************************************/
public with sharing class ServiceContractTriggerHelper {
    
    public static Boolean insertTransaction = false;
    public static Boolean isTestRunning = false;
    public static User currentUser = new User();
    
    /**
   * @description This method checks for the Edit Permissions for Service added for PRDOPS26-984
   * @param newMap
   * @param oldMap
   */
  public static void validateServiceContractUpdatePermissions(Map<Id,ServiceContract> newMap, Map<Id,ServiceContract> oldMap){
    if(currentUser.Id != UserInfo.getUserId()){
      currentUser = [SELECT Id, User_Type__c, RBAC_Group__c, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }
    Quiddity currentType = Request.getCurrent().getQuiddity(); // Added to Bypass any AURA/LWC updates to the Service Contract
    Boolean hasPermissionToEditSC = FeatureManagement.checkPermission('CanEditServiceContract');
    Boolean isUserInValidRBACGroup = currentUser.RBAC_Group__c == null || !new List<String>{'IT Prod Ops Support', 'API', 'System - IT'}.contains(currentUser.RBAC_Group__c);
    Boolean isUserOfValidType = currentUser.User_Type__c != 'API' && currentUser.User_Type__c != 'System';
    Boolean isNonSystemTriggeredTransaction = !System.isFuture() && !System.isBatch() && !System.isScheduled() && !System.isQueueable();
    Boolean isRestrictedQuiddity =  (currentType != Quiddity.AURA);  // Added to Bypass any AURA/LWC Updates updates to the Service Contract
    for (ServiceContract sContract : newMap.values()) {
    	if (isUserInValidRBACGroup && isUserOfValidType && isNonSystemTriggeredTransaction && isRestrictedQuiddity && !hasPermissionToEditSC && !insertTransaction && !isTestRunning) {
        	sContract.addError('You are not authorized to edit this Service Contract, hence please create support ticket with ProdOps Support or email "ProdOpsapps@rubrik.com" with details.');
      	}
    }
  }

}