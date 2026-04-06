/************************************************************
 * @description       : Order Item Extension Update Helper Class
 * @author            : Ravi
 * @last modified on  : 24-04-2025
 * @last modified by  : Siva Kumar
 * Test class         : OrderItemExtensionTriggerTest
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   24-05-2024   Ravi        Initial Version
 **************************************************************/

public class OrderItemExtensionHelper {
  private static orderItemExtensionHelper OrderItemExtensionHelperInstance = null;
  public Set<Id> orderItemIds = new Set<Id>();
  public list<Order_Item_Extension__c> ordItemExtensionsToProcess = new List<Order_Item_Extension__c>();
  public List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
  /**
   * @description		Initiate orderItemExtensionHelper it instance is null else retuns the orderItemExtensionHelper instance.
   * @author 			Ravi
   * @last modified on 24-04-2025
   * @return 			orderItemExtensionHelper Instance
   */
  public static orderItemExtensionHelper getInstance() {
    if (OrderItemExtensionHelperInstance == null) {
      OrderItemExtensionHelperInstance = new OrderItemExtensionHelper();
    }
    return OrderItemExtensionHelperInstance;
  }

  /**
   * @description		Intializes OrderItem Extension records with Parent field values.
   * @author 			Ravi
   * @last modified on 24-04-2025
   */
  public void init() {
    if (orderItemIds.isEmpty()) {
      for (Order_Item_Extension__c ordItemExtension : (List<Order_Item_Extension__c>) Trigger.new) {
        if (ordItemExtension.Order_Line_ID__c != null && ordItemExtension.Credit_Calculation_Status__c == 'To process') {
          orderItemIds.add(ordItemExtension.Order_Line_ID__c);
        }
      }
    }
    ordItemExtensionsToProcess = [
      SELECT
        Id,
        Per_DayQuantity_amount__c,
        Paid_Quantity__c,
        Remaining_Amount__c,
        Order_Line_ID__c,
        Order_Line_ID__r.TotalPrice,
        Order_Line_ID__r.SerialNumber__c,
        Order_Line_ID__r.Quantity,
        Order_Line_ID__r.Support_Start_Date__c,
        Order_Line_ID__r.Support_End_Date__c,
        Order_Line_ID__r.UnitPrice,
        Order_Line_ID__r.Product2.Usable_Capacity__c,
        Order_Line_ID__r.Product2.Product_Level__c,
        Order_Line_ID__r.Product2.Bundle_Features__c,
        Order_Line_ID__r.Product2.Product_Type__c,
        Order_Line_ID__r.Product2.Family,
        Order_Line_ID__r.Is_third_party_hardware_line__c
      FROM Order_Item_Extension__c
      WHERE Order_Line_ID__c IN :orderItemIds AND Credit_Calculation_Status__c = 'To Process'
    ];
  }

  /**
   * @description		Calculates Amount fields and Update Status on Order Item Extension when new Order Item Extension record is created.
   * @author 			Ravi
   * @last modified on 24-04-2025
   */
  public void calculateOIECreditAmounts() {
    List<Order_Item_Extension__c> ordItemExtensionsToUpdate = new List<Order_Item_Extension__c>();
    for (Order_Item_Extension__c ordItemExtension : ordItemExtensionsToProcess) {
      try {
        getPerDayQuantityAmountOnItemExtension(ordItemExtension);
        ordItemExtension.Remaining_Amount__c = getRemainingAmount(ordItemExtension);
        ordItemExtension.Credit_Calculation_Status__c = 'Completed';
        ordItemExtensionsToUpdate.add(ordItemExtension);
      } catch (Exception error) {
        ordItemExtensionsToUpdate.add(handleException(ordItemExtension, error));
      }
    }
    if (!ordItemExtensionsToUpdate.isEmpty()) {
      Database.SaveResult[] updateResults = Database.update(ordItemExtensionsToUpdate, false);
      for (Integer i = 0; i < updateResults.size(); i++) {
        if (!updateResults[i].isSuccess()) {
          errorlogs.add(new Error_Logs__c(Error_Type__c = 'Order Item Extension Error', Error_Message__c = updateResults[i].getErrors()[0].getMessage(), Type__c = 'SFDC'));
        }
      }
      if (!errorlogs.isEmpty()) {
        insert errorlogs;
      }
    }
  }

  /**
   * @description							Calculates Per Day Quantity Amount of Order Item extension for V1 SKU TPH & V2 SKU's.
   * Calculate Remaining amount on Order Item extension
   * @author 								Siva Kumar
   * @date 								24-04-2025
   * @param oItemExtension 				OrderItem Extension record on which amount fields needs to be calculate
   */
  private void getPerDayQuantityAmountOnItemExtension(Order_Item_Extension__c oItemExtension) {
    Decimal perDayQuantityAmount = 0;
    Integer totalNoDays = oItemExtension?.Order_Line_ID__r?.Support_Start_Date__c.daysBetween(oItemExtension?.Order_Line_ID__r?.Support_End_Date__c) + 1;
    Decimal totalPrice = (oItemExtension?.Order_Line_ID__r?.TotalPrice != null) ? oItemExtension?.Order_Line_ID__r?.TotalPrice : 0;
    Decimal oItemQuantity = oItemExtension?.Order_Line_ID__r?.Quantity;
    oItemExtension.Quantity_Type__c = 'Quantity';
    oItemExtension.Per_DayQuantity_Amount__c = (totalPrice) / (totalNoDays * oItemQuantity);
  }
  /**
   * @description      This method is used to calculate Remaining Amount on Order Item Extension
   * @param ordItemExtension Order Item Extension record
   * @return Decimal It holds calculated remaining amount value
   */
  private Decimal getRemainingAmount(Order_Item_Extension__c ordItemExtension) {
    Decimal paidQuantity = (ordItemExtension?.Paid_Quantity__c != null) ? ordItemExtension?.Paid_Quantity__c : 0;
    Decimal totalPrice = (ordItemExtension?.Order_Line_ID__r?.TotalPrice != null) ? ordItemExtension?.Order_Line_ID__r?.TotalPrice : 0;
    Decimal unitPrice = (ordItemExtension?.Order_Line_ID__r?.UnitPrice != null) ? ordItemExtension?.Order_Line_ID__r?.UnitPrice : 0;
    Decimal quantity = (ordItemExtension?.Order_Line_ID__r?.Quantity != null) ? ordItemExtension?.Order_Line_ID__r?.Quantity : 0;

    return (totalPrice - (paidQuantity * unitPrice)) / quantity;
  }
  /**
   * @description				Maps failure reason when Order Item extension is failed to calculate Amount values
   * @author 					Siva Kumar
   * @date 					24-04-2025
   * @param failedOIE			OrderItem Externsion which has errors while calculating Amount field values
   * @param error 				Errors during Amount field calculations
   * @return					OrderItem Extension with failure reason
   */
  private Order_Item_Extension__c handleException(Order_Item_Extension__c failedOIE, Exception error) {
    failedOIE.Credit_Calculation_Status__c = 'Failed';
    failedOIE.Failure_Reason__c = error.getMessage();
    return failedOIE;
  }
}