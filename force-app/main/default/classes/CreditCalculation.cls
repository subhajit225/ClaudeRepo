/**
* @File Name : CreditCalculation.cls
* @description : The utililty class for Replacement and Refresh classes
* @Author : Ankita
* @Last Modified By :
* @Last Modified On : April 20, 2025
* Developed as part of : FY25SR-1203
* Dependant Components : DataDumping
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | April 20, 2025 |   | Initial Version
**/
public without sharing class CreditCalculation {
    /***********************************************************************************************************
    * Method Name          : creditCalculationPost
    * Date Created/Modified: 4/22/2025
    * Author               : Ankita
    * @description         : Calculates the Prepayment Credit for all the replaced lines
    * @return              : list of Quotelines with credit calculated
    * User Story           : FY25SR-1203
    * Test Class Methods   : CreditCalculationTestMethod
    * @param quotelines
    /**********************************************************************************************************/
   public static QuoteLineDataResponse creditCalculationPost(List<QuoteLineRecordResponse> quotelines) {
       Map<Id, Order_Item_Extension__c> orderLineToExtension = new Map<Id, Order_Item_Extension__c>();
       List<SBQQ__QuoteLine__c> updateCreditOnQL = new List<SBQQ__QuoteLine__c>();
       Map<Id, Map<String,QuoteLineData>> filteredQuoteLine = new Map<Id, Map<String,QuoteLineData>>();
       Map<Id, Id> entitlementToOrderProduct = new Map<Id, Id>();
       Map<String, Integer> entitlementsToQty = new Map<String, Integer>();
       Map<String, Double> entilementToTotalCredit = new Map<String, Double>();
       Map<String, Double> entilementToTotalListPrice = new Map<String, Double>();
       Date creditCalculationStartDate ;
       Set<Id> selectedEntIds = new Set<Id>();
       Map<Id, Entitlement> entitlementMap = new Map<Id, Entitlement>();
       Boolean isPrepayZero = false;
       QuoteLineDataResponse response = new QuoteLineDataResponse();
       //Get the entitlement information
       Set<String> sourceProductIds = new Set<String> ();//ITNPI-3213
        Map<String, Decimal> polarisQtyRatioMapping = new Map<String, Decimal>();//ITNPI-3213
       try{
           for(Integer i = 0; i<quotelines.size(); i++) {
               QuoteLineRecordResponse line = (QuoteLineRecordResponse) quotelines[i];
               if(line.lTyp.equals(ReplacementConstants.QUOTE_TYPE_NEW) && !String.isBlank(line.replacementDetails)) {
                   ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(
                       line.replacementDetails,
                       ReplacementJson.class
                   );
                   for(ReplacementJson.RowDetail row: lineJson.rowValues) {
                       if(row.disposition != null && row.disposition != 'Refreshed'){
                       selectedEntIds.add(row.entId);
                       if(row.inactiveLines != null && row.inactiveLines.size() > 0) {
                           for(ReplacementJson.RelatedChildEntRowDetail inactiveRow : row.inactiveLines) {
                               selectedEntIds.add(inactiveRow.childEntId);
                           }
                       }
                       if(row.upgradeLines != null && row.upgradeLines.size() > 0) {
                           for(ReplacementJson.RelatedChildEntRowDetail ugRow : row.upgradeLines) {
                               selectedEntIds.add(ugRow.childEntId);
                           }
                       }
                   }
               }
           }
           }
           //Get the OrderProduct from Entitlement
           entitlementMap = new Map<Id, Entitlement>(
                [SELECT Id, Order_Service_Item__c, Quantity__c,
                 Product__c, Product__r.Product_Payment_Option__c,Product__r.name,Product__r.Product_Level__c,Product__r.Support_Type__c,
                 ContractLineItem.Payment_Options__c,ContractLineItem.Support_Type__c
                 FROM Entitlement
                 WHERE Id IN :selectedEntIds]);
            
            //ITNPI-3213:Populate sourceProductIds Set with v1 SKU's product id.
            for(Entitlement entitlement: entitlementMap.values()){
                if(String.isBlank(entitlement.Product__r.Product_Level__c)){
                    sourceProductIds.add(entitlement.Product__c);
                }
            }
            
            //ITNPI-3213:query Polaris_SKU_Mapping_V2__c to get quantity ratio for v1-v2 conversion.
            if(!sourceProductIds.isEmpty()){
                for(Polaris_SKU_Mapping_V2__c polarisMapping: [SELECT Id,Old_Product__c,Quantity_Ratio__c,Payment_Option__c, Support_Type__c   from Polaris_SKU_Mapping_V2__c  where Old_Product__c in :sourceProductIds ]){
                    //polarisKey - unique key to fetch quantity ratio
                    String polarisKey = polarisMapping.Old_Product__c+'_'+polarisMapping.Payment_Option__c+'_'+polarisMapping.Support_Type__c;
                    polarisQtyRatioMapping.put(polarisKey, polarisMapping.Quantity_Ratio__c);
                }
            }
           //Step 1
           for(Integer i = 0; i<quotelines.size(); i++) {
               QuoteLineRecordResponse line = (QuoteLineRecordResponse) quotelines[i];
               String quotelineId = line.rcId;
               creditCalculationStartDate = line.creditSD;
               if (line.listTotal == null) {
                   line.listTotal = 0;
               }
               if (line.listTotal == 0 && line.newQty != null && line.lP != null && line.subsTerm != null) {
                   line.listTotal = Decimal.valueOf(line.lP) * line.newQty * line.subsTerm;
               }
               
               if(line.lTyp.equals(ReplacementConstants.QUOTE_TYPE_NEW) 
                && !String.isBlank(line.replacementDetails) && line.listTotal != null 
                && line.listTotal != 0) {
                   ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(
                       line.replacementDetails,
                       ReplacementJson.class
                   );
                   if(lineJson.rowValues != null 
                    && (lineJson.mode == ReplacementConstants.ONE_TO_MANY 
                    || lineJson.mode == ReplacementConstants.ONE_TO_ONE 
                    || lineJson.mode == ReplacementConstants.MANY_TO_1)){
                       //Iterate on all the Entilements of the QL
                       for(ReplacementJson.RowDetail row: lineJson.rowValues) {
                           Integer totalQTY = 0;
                           
                           //Check if it is non asset to non asset Line
                           QuoteLineData qlData = new QuoteLineData();
                           if(row.isMismatch != null && row.isMismatch) {
                               qlData.quantity = Integer.valueOf(entitlementMap.get(row.entId).Quantity__c);
                               qlData.totalListPrice = qlData.quantity * line.listTotal;
                               totalQTY = qlData.quantity;
                           } else if(String.isNotBlank(line.rqBy) && String.isNotBlank(line.sP) && Label.AutoAddSKUProductTypes.contains(line.pTyp)){
                                Entitlement entitlement = !entitlementMap.isEmpty()? entitlementMap?.get(row.entId):null;
                                String paymentOptions = entitlement.ContractLineItem!=null?entitlement.ContractLineItem.Payment_Options__c:entitlement.Product__r.Product_Payment_Option__c;
                                String supportType =   entitlement.ContractLineItem!=null?entitlement.ContractLineItem.Support_Type__c:entitlement.Product__r.Support_Type__c;
                                String polarisKey = entitlement!=null?entitlement.Product__c+'_'+paymentOptions+'_'+supportType:null;
                                // get quantity ratio for polarisKey from polarisQtyRatioMapping
                                Decimal qtyRatio = !polarisQtyRatioMapping.isEmpty() && polarisQtyRatioMapping.get(polarisKey)!=null ? polarisQtyRatioMapping.get(polarisKey): 1;
                                qlData.quantity = Integer.valueOf(line.newQty);
                                //divide listTotal with quantity ratio.
                                qlData.totalListPrice =  line.listTotal/qtyRatio;
                            }else {
                                qlData.quantity = row.selectedQty != null ? row.selectedQty: 0;
                                qlData.totalListPrice = (qlData.quantity/line.newQty) * line.listTotal;
                                totalQTY = row.selectedQty == null ? 0 : row.selectedQty ;
                            }
                           //create entitlement to Quantity Map
                           if (String.isBlank(line.rqBy) && String.isNotBlank(line.sP)) {
                           if(entitlementsToQty.containsKey(row.entId)) {
                               entitlementsToQty.put(row.entId, entitlementsToQty.get(row.entId) + totalQTY);
                           } else {
                               entitlementsToQty.put(row.entId, totalQTY);
                           }
                           }
                           
                           //Look for inactive and Upgrade SKUs
                           Map<String,QuoteLineData> inactiveEntitlementMap = new Map<String,QuoteLineData>();
                           if(row.inactiveLines != null && row.inactiveLines.size() > 0) {
                               //Iterate on all the inactive Entilements of the QL
                               for(ReplacementJson.RelatedChildEntRowDetail inactiveRow : row.inactiveLines) {
                                   QuoteLineData inactiveQlData = new QuoteLineData();
                                   if(row.isMismatch != null && row.isMismatch) {
                                       inactiveQlData.quantity = 
                                            Integer.valueOf(entitlementMap.get(inactiveRow.childEntId).Quantity__c);
                                   } else {
                                       inactiveQlData.quantity = inactiveRow.childQnty != null ? inactiveRow.childQnty : 0; 
                                   }
                                   // row.selectedQty;
                                   inactiveQlData.totalListPrice = 
                                        (inactiveQlData.quantity/line.newQty) * line.listTotal; //List price of QL
                                   inactiveEntitlementMap.put(inactiveRow.childEntId, inactiveQlData);
                                   Integer inactiveTotalQTY =  inactiveRow.childQnty == null ? 0 : inactiveRow.childQnty ;
                                   entitlementsToQty.put(inactiveRow.childEntId, inactiveTotalQTY);
                               }
                           }
                           Map<String,QuoteLineData> ugEntitlementMap = new Map<String,QuoteLineData>();
                           if(row.upgradeLines != null && row.upgradeLines.size() > 0) {
                               //Iterate on all the Upgrade Entilements of the QL
                               for(ReplacementJson.RelatedChildEntRowDetail ugRow : row.upgradeLines) {
                                   QuoteLineData ugQlData = new QuoteLineData();
                                   if(row.isMismatch != null && row.isMismatch) {
                                       ugQlData.quantity = Integer.valueOf(entitlementMap.get(ugRow.childEntId).Quantity__c);
                                   } else {
                                       ugQlData.quantity = ugRow.childQnty != null ? ugRow.childQnty : 0; 
                                   }
                                   ugQlData.totalListPrice = (ugQlData.quantity/line.newQty) * line.listTotal; //List price of QL
                                   ugEntitlementMap.put(ugRow.childEntId, ugQlData);
                                   Integer ugTotalQTY =  ugRow.childQnty == null ? 0 : ugRow.childQnty ;
                                   entitlementsToQty.put(ugRow.childEntId, ugTotalQTY);
                               }
                           }
                           //Create Map for each QL to all Entilements
                           if(filteredQuoteLine.containsKey(line.rcId)) {
                               filteredQuoteLine.get(line.rcId).put(row.entId, qlData );
                               //Add inactive Entitlements
                               if(inactiveEntitlementMap.size() > 0) {
                                   for(String entId : inactiveEntitlementMap.keySet()) {
                                       filteredQuoteLine.get(line.rcId).put(entId, inactiveEntitlementMap.get(entId));
                                   }                                    
                               }
                               //Add upgrade Entitlements
                               if(ugEntitlementMap.size() > 0) {
                                   for(String entId : ugEntitlementMap.keySet()) {
                                       filteredQuoteLine.get(line.rcId).put(entId, ugEntitlementMap.get(entId));
                                   }                                    
                               }
                           } else {
                               filteredQuoteLine.put(line.rcId, new Map<String,QuoteLineData>{row.entId => qlData});
                               //Add inactive Entitlements
                               if(inactiveEntitlementMap.size() > 0) {
                                   for(String entId : inactiveEntitlementMap.keySet()) {
                                       filteredQuoteLine.get(line.rcId).put(entId, inactiveEntitlementMap.get(entId));
                                   }                                    
                               }
                               //Add upgrade Entitlements
                               if(ugEntitlementMap.size() > 0) {
                                   for(String entId : ugEntitlementMap.keySet()) {
                                       filteredQuoteLine.get(line.rcId).put(entId, ugEntitlementMap.get(entId));
                                   }                                    
                               }
                           }
                       }
                   }
               }             
           }//Step 1 End
           if(!entitlementsToQty.isEmpty()) {
               //Get the OrderProduct from Entitlement
               for(Id entId : entitlementsToQty.keySet()) {
                  if(entitlementMap.containsKey(entId)) {
                   entitlementToOrderProduct.put(entId, entitlementMap.get(entId).Order_Service_Item__c);                                             
               }
               }
               List<Id> orderLineIds= entitlementToOrderProduct.values();
               for(Order_Item_Extension__c oLe : ReplacementQueryController.getOrderItemExtensionCreditCal(orderLineIds)){
                   orderLineToExtension.put(oLe.Order_Line_ID__c, oLe);
               }
           }
           //Step 2
           //For each Entitlement get the total credit
           if(!orderLineToExtension.isEmpty()) {
               for(Id entId : entitlementToOrderProduct.keySet()) {
                   if(orderLineToExtension.containsKey(entitlementToOrderProduct.get(entId))) {
                       Integer calcDate=0;
                       Double prePaymentCreditAmount = 0.0;
                       if(orderLineToExtension.get(entitlementToOrderProduct.get(entId)).Per_DayQuantity_amount__c != null
                       && orderLineToExtension.get(entitlementToOrderProduct.get(entId)).Order_Line_ID__r.EndDate != null) {
                           if(orderLineToExtension.get(entitlementToOrderProduct.get(entId)).Order_Line_ID__r.ServiceDate > creditCalculationStartDate) {
                               //For inactive lines - find difference in endDate and StartDate
                               calcDate = orderLineToExtension.get(entitlementToOrderProduct
                                            .get(entId)).Order_Line_ID__r.ServiceDate.daysBetween(orderLineToExtension
                                                .get(entitlementToOrderProduct.get(entId)).Order_Line_ID__r.EndDate) + 1;
                           } else {
                               //For rest of line - find difference in Credit SD and EndDate
                               calcDate = creditCalculationStartDate.daysBetween(orderLineToExtension
                                            .get(entitlementToOrderProduct.get(entId)).Order_Line_ID__r.EndDate) + 1;
                           }
                           if(calcDate >= 0) {
                               //Step 1
                               Double creditAmountStep1 = 
                               orderLineToExtension.get(entitlementToOrderProduct.get(entId)).Per_DayQuantity_amount__c 
                                * calcDate * entitlementsToQty.get(entId);
                               //Step 2
                               Double creditAmountStep2 = 
                               orderLineToExtension.get(entitlementToOrderProduct.get(entId)).Remaining_Amount__c 
                                * entitlementsToQty.get(entId); 
                               prePaymentCreditAmount = creditAmountStep1 - creditAmountStep2;
                               entilementToTotalCredit.put(entId, prePaymentCreditAmount);
                           }
                       }
                   }
               }//Step 2 END
               //Step 3: Iterate on Quotelines to get total List price on Entitlement
               if(!filteredQuoteLine.isEmpty()){
                   for(Id qlId : filteredQuoteLine.keySet()) {
                       Map<String, QuoteLineData> entitlementToQlDetails = filteredQuoteLine.get(qlId);
                       for(String entId : entitlementToQlDetails.keySet()) {
                           if(entilementToTotalListPrice.containsKey(entId)) {
                               Double totalListPrice = entilementToTotalListPrice.get(entId) 
                                    + entitlementToQlDetails.get(entId).totalListPrice;
                               entilementToTotalListPrice.put(entId, totalListPrice);
                           } else {
                               entilementToTotalListPrice.put(entId, entitlementToQlDetails.get(entId).totalListPrice);
                           }
                       }
                   }
                   //Step 3 end
                   //Step 4 : calculate total Credits
                   for(Id qlId : filteredQuoteLine.keySet()) {
                       Double prePaymentAmount = 0.0;
                       Map<String, QuoteLineData> entitlementToQlDetails = filteredQuoteLine.get(qlId);
                       for(String entId : entitlementToQlDetails.keySet()) {
                           if(entilementToTotalListPrice.containsKey(entId) 
                           && entilementToTotalCredit.containsKey(entId)
                           && entilementToTotalListPrice.get(entId) > 0) {
                               prePaymentAmount = prePaymentAmount 
                                   + (entitlementToQlDetails.get(entId).totalListPrice/entilementToTotalListPrice.get(entId))
                                   * entilementToTotalCredit.get(entId);
                           }
                       }
                       SBQQ__QuoteLine__c updateLine = new SBQQ__QuoteLine__c(Id = qlId);
                       /*Updated for - FY25SR-2161*/
                       updateLine.Prepayment_Credit__c = prePaymentAmount >= 0 
                                                       ? Decimal.valueOf(prePaymentAmount).setScale(2) : 0;
                       updateCreditOnQL.add(updateLine);
                   }
               }
               
               
            }
            //Additional updates
            for(String entId : entitlementMap.keySet()) {
                if(entitlementMap.get(entId).Product__c != null 
                && entitlementMap.get(entId).Product__r.Product_Payment_Option__c != null
                && entitlementMap.get(entId).Product__r.Product_Payment_Option__c.equals(ReplacementConstants.PAYMENT_OPTION_ANNUAL)) {
                    
                    if(entilementToTotalCredit.containsKey(entId)) {
                        if(entilementToTotalCredit.get(entId) <= 0) { //If credit is calculated and is zero
                            isPrepayZero = true;
                        }
                    } else { //If there is no credit is applied
                        isPrepayZero = true;
                    }
                }
            }
            response.quotelines = updateCreditOnQL;
            response.isPrepayZero = isPrepayZero;
       } catch(Exception ex) {
           Custom_Error_Log__c logError = LogError.CreateGenericErrorLog('CreditCalculation', ex, 'FY25SR-CPQ-Credit-Calculation');
           insert logError;
       }
       return response;
   }
   /***********************************************************************************************************
    * Method Name          : QuoteLineData
    * Date Created/Modified: 4/22/2025
    * Author               : Ankita
    * @description         : Wrapper Method
    * @return              : 
    * User Story           : FY25SR-1203
    * Test Class Methods   : 
    * @param 
    /**********************************************************************************************************/
   class QuoteLineData {
       public Integer quantity;
       public Double totalListPrice;
   }
   /***********************************************************************************************************
    * Method Name          : QuoteLineDataResponse
    * Date Created/Modified: 08/25/2025
    * Author               : Ankita
    * @description         : Wrapper Method
    * @return              : 
    * User Story           : FY25SR-2209
    * Test Class Methods   : 
    * @param 
    /**********************************************************************************************************/
    public class QuoteLineDataResponse {
        public List<SBQQ__QuoteLine__c> quotelines;
        public Boolean isPrepayZero;
    }
}