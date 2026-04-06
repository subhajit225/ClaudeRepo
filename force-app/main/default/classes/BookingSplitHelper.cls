/***************************************************************************** 
* @description       : This is a helper class for Booking Split trigger
* @author            : Prashik
* @last modified on  : 10-06-2025
* @last modified by  : Prashik
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Prashik              Initial Version/PRDOPS26-982
******************************************************************************/
public with sharing class BookingSplitHelper {
  public static Boolean isTestRunning = Test.isRunningTest();
  public static User currentUser = new User();
  
  /**
   * @description This method checks for the Edit Permissions added for PRDOPS26-984
   * @param newMap
   * @param oldMap
  */
  public static void validateBookingSplitUpdatePermissions(Map<Id,Booking_Split__c> newMap, Map<Id,Booking_Split__c> oldMap){
    if(currentUser.Id != UserInfo.getUserId()){
      currentUser = [SELECT Id, User_Type__c, RBAC_Group__c, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }
    Quiddity currentType = Request.getCurrent().getQuiddity();
    Boolean isUserInValidRBACGroup = currentUser.RBAC_Group__c == null || !new List<String>{'IT Prod Ops Support', 'API', 'System - IT'}.contains(currentUser.RBAC_Group__c);
    Boolean isUserOfValidType = currentUser.User_Type__c != 'API' && currentUser.User_Type__c != 'System';
    Boolean isNonSystemTriggeredTransaction = !System.isFuture() && !System.isBatch() && !System.isScheduled() && !System.isQueueable();
    Boolean isRestrictedQuiddity =  (currentType != Quiddity.AURA);
    for (Booking_Split__c bkgSplit : newMap.values()) {
    	if (!BookingHelper.bypassBookingValidationRule && isUserInValidRBACGroup && isUserOfValidType && isNonSystemTriggeredTransaction && isRestrictedQuiddity && !BookingHelper.insertTransaction && !isTestRunning) {
          bkgSplit.addError('You are not authorized to edit this Booking Split, hence please create support ticket with ProdOps Support or email "ProdOpsapps@rubrik.com" with details.');
      	}
    }
  }
  
}