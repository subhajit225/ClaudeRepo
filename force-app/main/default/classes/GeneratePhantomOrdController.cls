/**
 * @file Name : GeneratePhantomOrdController.cls
 * @description : Apex controller to create Phantom Order
 * @author : Siva Kumar.V
 * @last Modified By : September 8, 2025
 * @last Modified On : September 8, 2025
 * @modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | September 8, 2025 |   | Initial Version
 **/

public class GeneratePhantomOrdController {
  @testVisible
  private static Boolean isNonITuser = true;

  public static String invalidOrderMessage = 'Order is not eligible for Phantom Order creation';
  public static String invalidOrderItemsMessage = 'Order does not have any eligible Order Items for Phantom Order creation';
  public static String phantomOrderExistsMessage = 'Phantom Order already exists';
  public static String noAccessMessage = 'Action Required: IT Ticket needed.Please reach out to Support Team on this email Prodopsapps@rubrik.com to generate Phantom Order';
  /**
   * @description This method is used to check if parentOrdId is eligible for Phantom Order Creation
   * @param parentOrdId Id of the order record on which Phantom Order has to create
   * @return Map<String, String> key represents whether Order is valid or not for Phantom order creation
   *  and value has reason if order is not eligible for Phantom Order Creation
   */
  @AuraEnabled
  public static Map<String, String> checkEligibilityForPhantomOrder(Id parentOrdId) {
    /**
     * @description this map is used to store whether order is valid to create a phantom order
     * and description if order is not eligible for Phantom Order Creation
     */
    Map<String, String> ordEligibiltyToResponse = new Map<String, String>();
    try {
      if (!isITProdOpsUser(UserInfo.getUserId()) && isNonITuser) {
        ordEligibiltyToResponse.put('InvalidOrder', noAccessMessage);
        return ordEligibiltyToResponse;
      }
      Order parentOrdRec = [
        SELECT
          Id,
          Type,
          Line_Types__c,
          Associated_Order_Numbers__c,
          (
            SELECT Id, Previous_Transaction_Reference__c, Program__c, Replacement_Type__c, Order.SBQQ__Quote__c, Credit_Amount__c
            FROM OrderItems
          )
        FROM Order
        WHERE Id = :parentOrdId
        LIMIT 1
      ];
      if (parentOrdRec.Associated_Order_Numbers__c != null) {
        ordEligibiltyToResponse.put('InvalidOrder', phantomOrderexistsMessage);
        return ordEligibiltyToResponse;
      }
      if (parentOrdRec.Type == 'Revenue' && UtilityClass.isReplacementOrder(parentOrdRec) && parentOrdRec.Associated_Order_Numbers__c == null) {
        Map<Id, List<OrderItem>> validOrdToOrdItems = new Map<Id, List<OrderItem>>();
        for (OrderItem oitem : parentOrdRec.OrderItems) {
          if (String.isNotBlank(oitem.Previous_Transaction_Reference__c) && UtilityClass.isPartialReplacementOrderItem(oitem)) {
            if (!validOrdToOrdItems.containsKey(oitem.OrderId)) {
              validOrdToOrdItems.put(oitem.OrderId, new List<OrderItem>());
            }
            validOrdToOrdItems.get(oitem.OrderId).add(oitem);
          }
        }
        if (!validOrdToOrdItems.isEmpty()) {
          return validateOriginalOrderItems(validOrdToOrdItems);
        } else {
          ordEligibiltyToResponse.put('InvalidOrder', invalidOrderItemsMessage);
        }
      } else {
        ordEligibiltyToResponse.put('InvalidOrder', invalidOrderMessage);
      }
      return ordEligibiltyToResponse;
    } catch (Exception error) {
      throw new AuraHandledException(error.getMessage());
    }
  }

  /**
   * @description This method is used to validate Orginal Orders fetched from Previous Transaction Reference
   * @param ordIdToReplacementOrdItems map of replacement orderId and associate orderItems
   * @return Map<String, String> key represents whether Order is valid or not for Phantom order creation
   *  and value has reason if order is not eligible for Phantom Order Creation
   */
  public static Map<String, String> validateOriginalOrderItems(Map<Id, List<OrderItem>> ordIdToReplacementOrdItems) {
    try {
      Map<String, String> ordEligibiltyToResponse = new Map<String, String>();
      Map<Id, List<OrderItem>> validPhantomOrdIdToOrdItems = getValidPhantomOrdByOrdItems(ordIdToReplacementOrdItems);
      if (!validPhantomOrdIdToOrdItems.isEmpty()) {
        Map<Id, Set<Id>> eligibleOrdItmForPhantOrdByQuoteId = new Map<Id, Set<Id>>();
        List<OrderItem> allOrdItems = new List<OrderItem>();
        for (Id ordId : validPhantomOrdIdToOrdItems.keyset()) {
          allOrdItems.addAll(validPhantomOrdIdToOrdItems.get(ordId));
        }
        for (OrderItem ordItem : allOrdItems) {
          if (!eligibleOrdItmForPhantOrdByQuoteId.containskey(ordItem.order.SBQQ__Quote__c)) {
            eligibleOrdItmForPhantOrdByQuoteId.put(ordItem.Order.SBQQ__Quote__c, new Set<Id>());
          }
          eligibleOrdItmForPhantOrdByQuoteId.get(ordItem.order.SBQQ__Quote__c).add(ordItem.Id);
        }
        ordEligibiltyToResponse.put('ValidOrder', JSON.serialize(eligibleOrdItmForPhantOrdByQuoteId));
      } else {
        ordEligibiltyToResponse.put('InvalidOrder', invalidOrderItemsMessage);
      }
      return ordEligibiltyToResponse;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }
  /**
   * @description this method is used to get OrderId with OrderItems that are eligible to create Phantom Order
   * @param ordToOrderItems map with key as Replacement OrderId and associated OrderItems as values
   * @return Map<Id, List<OrderItem>> map with OrderId and associated OrderItems eligible for Phantom Order creation,
   */
  public static Map<Id, List<OrderItem>> getValidPhantomOrdByOrdItems(Map<Id, List<OrderItem>> ordToOrderItems) {
    Map<Id, List<OrderItem>> validPhantomOrdByOrdItems = new Map<Id, List<OrderItem>>();
    List<OrderItem> allOrdItems = new List<OrderItem>();
    for (Id ordId : ordToOrderItems.keySet()) {
      allOrdItems.addAll(ordToOrderItems.get(ordId));
    }
    Set<Id> originalOrdItemIds = new Set<Id>();
    for (OrderItem oItem : allOrdItems) {
      List<PreviousTransRefWrapper> prevLineDetailsList = (List<PreviousTransRefWrapper>) JSON.deserialize(
        oItem.Previous_Transaction_Reference__c,
        List<PreviousTransRefWrapper>.class
      );
      for (PreviousTransRefWrapper wrapperInstance : prevLineDetailsList) {
        originalOrdItemIds.add(wrapperInstance.orderItemId);
      }
    }
    if (!originalOrdItemIds.isEmpty()) {
      Map<Id, Set<Id>> eligibleOrdItmForPhantOrdByQuoteId = new Map<Id, Set<Id>>();
      Map<Id, OrderItem> originalOrdItemById = new Map<Id, OrderItem>(
        [
          SELECT
            Id,
            credit_amount__c,
            Support_Start_Date__c,
            Support_End_Date__c,
            Program__c,
            Replacement_Type__c,
            Order.SBQQ__Quote__c,
            Order.Associated_Order_Numbers__c,
            (SELECT Id, End_of_Paid_Term__c FROM Order_Item_Extensions__r)
          FROM OrderItem
          WHERE Id IN :originalOrdItemIds
        ]
      );
      for (OrderItem ordItem : allOrdItems) {
        List<PreviousTransRefWrapper> wrapper = (List<PreviousTransRefWrapper>) JSON.deserialize(ordItem.Previous_Transaction_Reference__c, List<PreviousTransRefWrapper>.class);
        for (PreviousTransRefWrapper wrapperInstance : wrapper) {
          OrderItem oldOrdItem = (originalOrdItemById.containsKey(wrapperInstance.orderItemId)) ? originalOrdItemById.get(wrapperInstance.orderItemId) : null;
          Date oiExtnEndOfPaidTerms;
          if (oldOrdItem != null && oldOrdItem.Order_Item_Extensions__r != null && oldOrdItem.Order_Item_Extensions__r.size() > 0) {
            oiExtnEndOfPaidTerms = oldOrdItem.Order_Item_Extensions__r[0]?.End_of_Paid_Term__c;
          }
          if (
            wrapperInstance.orderItemRemainingQuantity > 0 &&
            oldOrdItem != null &&
            oiExtnEndOfPaidTerms != null &&
            ((ordItem.credit_amount__c != null && ordItem.credit_amount__c > 0 && oldOrdItem.Support_End_Date__c == oiExtnEndOfPaidTerms) || oldOrdItem.Support_End_Date__c != oiExtnEndOfPaidTerms)
          ) {
            if (!validPhantomOrdByOrdItems.containsKey(ordItem.OrderId)) {
              validPhantomOrdByOrdItems.put(ordItem.OrderId, new List<OrderItem>());
            }
            validPhantomOrdByOrdItems.get(ordItem.OrderId).add(ordItem);
          }
        }
      }
    }
    return validPhantomOrdByOrdItems;
  }
  /**
   * @description This method is used to create Phantom Order and its OrderItems
   * @param orderItemsJSON It contains JSON string of OrderItems eligible for Phantom Order creation
   */
  @AuraEnabled
  public static void createPhantomOrder(String orderItemsJSON) {
    try {
      Map<Id, String> quoteIdToAction = new Map<Id, String>();
      Map<Id, Set<Id>> eligibleOrdItmForPhantOrdByQuoteId = (Map<Id, Set<Id>>) JSON.deserialize(orderItemsJSON, Map<Id, Set<Id>>.class);
      System.debug(LoggingLevel.DEBUG, 'eligibleOrdItmForPhantOrdByQuoteId::' + eligibleOrdItmForPhantOrdByQuoteId);
      Set<Id> quoteIds = eligibleOrdItmForPhantOrdByQuoteId.keyset();
      quoteIdToAction.put(new List<Id>(quoteIds)[0], 'create');
      String response = OrderUpdateHelper.phantomOrderAndLineUpdate(quoteIdToAction, eligibleOrdItmForPhantOrdByQuoteId);
      if (response != null) {
        throw new AuraHandledException(response);
      }
    } catch (Exception error) {
      System.debug(LoggingLevel.DEBUG, error.getLineNumber() + '::responseData::' + error.getMessage());
      throw new AuraHandledException(error.getMessage());
    }
  }

  /**
   * @description This method is used to verify if user is internal IT team user
   * @param userId Id of user, that needs to verify internal IT team access
   * @return Boolean It returns true if userId is an intenal IT else returns false
   */
  public static Boolean isITProdOpsUser(Id userId) {
    User currentUser = [SELECT Id, User_Type__c, RBAC_Group__c, Name FROM User WHERE Id = :userId LIMIT 1];
    return (currentUser.RBAC_Group__c != null && currentUser.RBAC_Group__c.contains('IT Prod Ops Support'));
  }
}