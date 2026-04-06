/**************************************************************************************************
* @description       : This Class Will have All Logic For Validation on Order Trigger
* @author            : Prashant Kumar
* Modifications Log
* Ver   Date          Author        Modification
* 1.0   09-16-2025   Prashant        Initial Version
******************************************************************************/
public class OrderValidationService {
    /**
* @author Prashant Kumar
* @date 05-03-2025
* @description Compare Total Amount For multiple orders PK
* @param mapOfNewOrd
* @param stagePos
* @param orderIdOrderItemMap
* @return Map<Id, Order>
*/
  public static Map<Id, Order> validateTotAmtForMultipleOrders(Map<Id, Order> mapOfNewOrd, List<PO_Stage__c> stagePos, Map<Id, List<OrderItem>> orderIdOrderItemMap) {
    Map<Id, PO_Stage__c> stagePOWithId = new Map<Id, PO_Stage__c>(stagePos);
    Map<Id, List<PO_Item_Stage__c>> StagePOWithLines = new Map<Id, List<PO_Item_Stage__c>>();
    Map<Id, List<Order>> stagePoIdToOrders = new Map<Id, List<Order>>();
    Set<Id> checkIfRenewalLineSet = new Set<Id>();
    for (Order ord : mapOfNewOrd.values()) {
      if (orderIdOrderItemMap.get(ord.id) != null) {
        for (orderItem OI : orderIdOrderItemMap.get(ord.id)) {
          if (
            OI.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal+Expansion' &&
            OI.SBQQ__QuoteLine__r.Line_Type__c == 'Renewal' /*&& ord.Order_Sub_Type__c != 'Renewal'*/
          ) {
            checkIfRenewalLineSet.add(ord.id);
          }
        }
      }
      if (ord.Stage_PO__c != null) {
        if (stagePoIdToOrders.containskey(ord.Stage_PO__c)) {
          stagePoIdToOrders.get(ord.Stage_PO__c).add(ord);
        } else {
          stagePoIdToOrders.put(ord.Stage_PO__c, new List<Order>{ ord });
        }
      }
    }
    Map<Id, Order> mapValidatedOrders = new Map<Id, Order>();
    Decimal thresholdValue = EDI_Pricing_Difference_Threshold__mdt.getInstance('Threshold_Value').Threshold_Value__c;
    for (Id poId : stagePoIdToOrders.keySet()) {
      Decimal totalOrdAmt = 0;
      Decimal totalOrdNewSaleAmt = 0.0;
      Decimal totalOrdRenewalAmt = 0.0;
      Decimal renewalLineOnPO = 0.0;
      Decimal newSaleLineOnPO = 0.0;
      Set<String> storeLineFromPOLInes = new Set<String>();
      if (stagePOWithId.containskey(poId) && !stagePOWithId.get(poId).PO_Item_Stage__r.isempty()) {
        for (PO_Item_Stage__c POLine : stagePOWithId.get(poId).PO_Item_Stage__r) {
          storeLineFromPOLInes.add(POLine.Type__c);
          if (POLine.Total_Price__c != null) {
            if (POLine.Type__c == 'Renewal') {
              renewalLineOnPO += POLine.Total_Price__c; // Total_Price__c  to add.
            }
            if (POLine.Type__c == 'New') {
              newSaleLineOnPO += POLine.Total_Price__c;
            }
          }
        }
      }
      Boolean checkBothRenewalAndNewSale = storeLineFromPOLInes.contains('New') && storeLineFromPOLInes.contains('Renewal');
      for (Order eachOrd : stagePoIdToOrders.get(poId)) {
        totalOrdAmt += eachOrd.TotalAmount;
        if (!checkIfRenewalLineSet.isempty() && checkIfRenewalLineSet.contains(eachOrd.id)) {
          totalOrdRenewalAmt += eachOrd.TotalAmount;
        } else {
          totalOrdNewSaleAmt += eachOrd.TotalAmount;
        }
      }
      if (
        stagePOWithId.get(poId) != null &&
        ((((stagePOWithId.get(poId).TotalAmount__c - totalOrdAmt) > (-thresholdValue)) && ((stagePOWithId.get(poId).TotalAmount__c - totalOrdAmt) < thresholdValue)) ||
        (OrderInsertHelper.PONonEDIOrdersAmtMap.containsKey(poId) &&
        (stagePOWithId.get(poId).TotalAmount__c - OrderInsertHelper.PONonEDIOrdersAmtMap.get(poId)) > (-thresholdValue) &&
        (stagePOWithId.get(poId).TotalAmount__c - OrderInsertHelper.PONonEDIOrdersAmtMap.get(poId)) < thresholdValue))
      ) {
        for (Order ord : stagePoIdToOrders.get(poId)) {
          mapValidatedOrders.put(ord.id, ord);
        }
      }
      for (Order ord : stagePoIdToOrders.get(poId)) {
        Boolean checkIfRenewalLine = false;
        if (!checkIfRenewalLineSet.isempty() && checkIfRenewalLineSet.contains(ord.id))
          checkIfRenewalLine = true;
        Boolean compareRenewalPOAndOrder = (checkIfRenewalLine &&
        ((renewalLineOnPO - totalOrdRenewalAmt) > (-thresholdValue)) &&
        ((renewalLineOnPO - totalOrdRenewalAmt) < thresholdValue));
        Boolean compareNewSalePOAndOrder = (!checkIfRenewalLine &&
        ((newSaleLineOnPO - totalOrdNewSaleAmt) > (-thresholdValue)) &&
        ((newSaleLineOnPO - totalOrdNewSaleAmt) < thresholdValue));
        if (checkBothRenewalAndNewSale && (compareRenewalPOAndOrder || compareNewSalePOAndOrder))
          mapValidatedOrders.put(ord.id, ord);
      }
    }
    return mapValidatedOrders;
  }                                                           
                                                                      
                                                                   
                                                                   
   /**
   * @description enqueue job 
   * @param orderIdOrderItemMap
   * */ 
  public static void executeQueableJobOnShipped(order newOrd, Map<Id, List<OrderItem>> orderIdOrderItemMap){
    triggerControl.stopOrderItemTrigger = true;
    if(orderIdOrderItemMap.containsKey(newOrd.Id) && orderIdOrderItemMap.get(newOrd.Id).size() > 200){
      newOrd.Welcome_Letter_Status__c	= 'Hold';
      Map<String, Object> jsonData = new Map<String, Object>();
      jsonData.put('sObjectType', 'Order');
      jsonData.put('Id', newOrd.Id);
      Map<String, Object> fields = new Map<String, Object>();
      if (newOrd.ProcessType__c == 'Aspen') {
          fields.put('Welcome_Letter_Status__c', 'Send S/W welcome letter');
      } else {
          fields.put('Welcome_Letter_Status__c', 'Send H/W welcome letter');
      }
      jsonData.put('fields', fields);
      String jsonString = JSON.serialize(jsonData);
      System.enqueueJob(new JsonQueuable(jsonString));
  }  
  }

   /**
	* @description Update Expected Start Date for Replacement 
	* @param newOrd	
	* @param orderIdOrderItemMap
	**/ 

  public static void updateExpectedDateForReplacement(order newOrd, Map<Id, List<OrderItem>> orderIdOrderItemMap){
    if(newOrd.Order_Accepted_Timestamp__c != null){
      DateTime acceptedUTC = newOrd.Order_Accepted_Timestamp__c;
	    TimeZone pacificTZ = TimeZone.getTimeZone('America/Los_Angeles');
	    Datetime nowPst = acceptedUTC.addSeconds(pacificTZ.getOffset(acceptedUTC) / 1000);
	    Date pstDate = nowPst.dateGmt();
	    Integer acceptedPSTDay = pstDate.Day();
      Date expectedOrderStartDate = null;
      for (OrderItem OI : orderIdOrderItemMap.get(newOrd.Id)) {
      if((String.isNotBlank(newOrd.Line_Types__c) && (newOrd.Line_Types__c.contains(Constants.PROGRAM_UPGRADE) || newOrd.Line_Types__c.contains(Constants.PROGRAM_CONVERSION))) && !OI.Order.SBQQ__Quote__r.LoD_refreshed_to_Subscription_Deal__c){
          if(OI.Credit_Amount__c == null || OI.Credit_Amount__c <= 0){
            expectedOrderStartDate = pstDate;
          }else if(OI.Credit_Amount__c > 0){
            if(acceptedPSTDay == 1){
              expectedOrderStartDate = pstDate;
            }else if(acceptedPSTDay > 1){
              Date acceptedDateOne = pstDate.addMonths(1);
              expectedOrderStartDate = Date.newInstance( acceptedDateOne.year(), acceptedDateOne.month(), 1);
            }
            break;
          }
          }
        }
        if(expectedOrderStartDate != null){
          newOrd.Expected_Order_Start_Date__c = expectedOrderStartDate;
        }
    }
  }

   

    /**
* @description : This method will check if Field Revised By Field already has logged in user email then will not add else will add.
* @param existingValue
* @return String
*/   
    public static String storeLoggedInUserEmailWhenSyncIsTrue(String existingValue) { 
        String currentUserEmail = UserInfo.getUserEmail();
        if (String.isBlank(existingValue)) {
            return currentUserEmail;
        }
        
        // Split, normalize, and check for presence
        List<String> names = existingValue.deletewhitespace().toLowerCase().split(',');
        Set<String> emails = new Set<String>(names);
        emails.remove('');
        
        
        
        
        // Add only if not present
        if (!emails.contains(currentUserEmail.toLowerCase())) {
            return existingValue.trim() + ', ' + currentUserEmail;
        } else {
            return existingValue;
        }
    }   
}