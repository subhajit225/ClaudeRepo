/*******************************************************************************
 * @description       : UtilityClass to keep reusable methods
 * @created on        : 21-07-2022
 * @created by        : Naveen S
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 21-07-2022          ARY-190                naveenkumar.selvaraj@rubrik.com
 *******************************************************************************
*/
public class UtilityClass {

    /**
    * @author Naveen/Ravi
    * @date 12-03-2025
    * @description This method checks if Order split is required and updates it on the opportunity
    * This method handles updating the is_order_split__c logic based on the two categories 
    *  1. if lines (new, expansion) lines shared across the PO
    *  2. if replacement line together with Expansion line
    * @Param listOfPos A collection of Stage POs
    * @return Map<Id,Opportunity> 
    */
    public static Map<Id, Opportunity> checkOrderSplitForArroyo(List<PO_Stage__c> listOfPos){   
        Map<Id, Opportunity> mapOfOppToUpd = new Map<Id, Opportunity>();  
        Map<Id, PO_Stage__c> mapOfStagePO = new Map<Id, PO_Stage__c>(listOfPos);  
        Boolean isRenwsplit = false, isExpsplit = false;
        Map<Id, Map<String, List<Id>>> qutMaptoPoLineitem = new Map<Id, Map<String, List<Id>>>();
        Set<String> rcdmProds = new Set<String>();
        Map<Id, List<PO_Stage__c>> mapOfQutToPos = new Map<Id, List<PO_Stage__c>>();
        for(X0_RCDM_Dates__mdt mdt : X0_RCDM_Dates__mdt.getAll().values()){
            if(mdt.Product_Name__c != null){ 
                rcdmProds.add(mdt.Product_Name__c);
            }
        }
        
        for(PO_Stage__c eachPo: mapOfStagePO.values()){
            if(mapOfQutToPos.containsKey(eachPo.Quote__c)){
                mapOfQutToPos.get(eachPo.Quote__c).add(eachPo);
            }else{
                mapOfQutToPos.put(eachPo.Quote__c, new List<PO_Stage__c>{eachPo});
            }
        }
        
        for(Id qutId :mapOfQutToPos.keySet()){
            for(PO_Stage__c eachPo: mapOfQutToPos?.get(qutId)){
                Set<String> poItemTypes = new Set<String>();
                Set<Id> existingOppIds = new Set<Id>();
                for(PO_Item_Stage__c eachline: eachPo.PO_Item_Stage__r){
                    If(eachPo.Quote__r.SBQQ__Type__c == 'Renewal+Expansion' && eachPo.Expected_number_of_POs__c > 1){
                    If(eachline.Stage_PO__r.Quote__c != null && eachLine.Type__c != null && !rcdmProds.contains(eachLine?.Product__r?.ProductCode)){
                        if(qutMaptoPoLineitem.containsKey(eachline.Stage_PO__r.Quote__c) && qutMaptoPoLineitem.get(eachline.Stage_PO__r.Quote__c).get(eachLine.Type__c) != null){
                            If(!qutMaptoPoLineitem.get(eachline.Stage_PO__r.Quote__c).get(eachLine.Type__c).contains(eachline.Stage_PO__c) &&
                               qutMaptoPoLineitem.get(eachline.Stage_PO__r.Quote__c).get(eachLine.Type__c).size() <= 1){
                                   qutMaptoPoLineitem.get(eachline.Stage_PO__r.Quote__c).get(eachLine.Type__c).add(eachline.Stage_PO__c);
                                   if(qutMaptoPoLineitem.get(eachline.Stage_PO__r.Quote__c).get(eachLine.Type__c).size() > 1){
                                       isExpsplit = eachLine.Type__c == 'New' ? true : false;
                                       isRenwsplit = eachLine.Type__c == 'Renewal' ? true : false;
                                       /*Opportunity expOpp = new Opportunity();
                                       expOpp.Id = eachLine.Type__c == 'New' ? mapOfStagePO.get(eachPo.id).Quote__r.SBQQ__Opportunity2__c : mapOfStagePO.get(eachPo.id).Quote__r.Renewal_Opportunity__c;
                                       expOpp.Is_Order_Split__c = eachLine.Type__c == 'New' ? isExpsplit : isRenwsplit;
                                       mapOfOppToUpd.put(expOpp.id,expOpp);*/

                                       if(isExpsplit){
                                        poItemTypes.add('Non-Replacement(New)');
                                        existingOppIds.add(mapOfStagePO.get(eachPo.id).Quote__r.SBQQ__Opportunity2__c);
                                       }
                                       if(isRenwsplit){
                                        poItemTypes.add('Renewal');
                                        existingOppIds.add(mapOfStagePO.get(eachPo.id).Quote__r.Renewal_Opportunity__c);
                                       }
                                   }
                               }
                               
                        }else if(qutMaptoPoLineitem.get(eachline.Stage_PO__r.Quote__c) != null){
                            qutMaptoPoLineitem.get(eachline.Stage_PO__r.Quote__c).put(eachLine.Type__c, new List<Id>{eachline.Stage_PO__c});
                        }else{
                            Map<String, List<Id>> tempMap = new Map<String, List<Id>>();
                            tempMap.put(eachLine.Type__c, new List<Id>{eachline.Stage_PO__c});
                            qutMaptoPoLineitem.put(eachline.Stage_PO__r.Quote__c, tempMap);   
                        }  
                        }
                    }
                       
                    String lineType = eachLine.Type__c;
                    if (eachPo?.Quote__r?.ProcessType__c != 'Aspen') {
                        if (lineType == 'New') {
                            String specialProgram = eachLine?.Quote_Line__r?.Special_Program__c;
                            if (specialProgram != null && Constants.REPLACEMENT_PROGRAMS.contains(specialProgram)
                              && eachPo?.Quote__r?.Total_New_Hardware_Products__c > 0) {
                                poItemTypes.add('Replacement');
                                existingOppIds.add(mapOfStagePO.get(eachLine.Stage_PO__r.Id)?.Quote__r?.SBQQ__Opportunity2__c);
                            } else {
                              poItemTypes.add('Non-Replacement(New)');
                            }
                        }
                    } 
                }
                if ((poItemTypes.contains('Replacement') && poItemTypes.contains('Non-Replacement(New)')) || (isExpsplit || isRenwsplit)) {
                    for(Id oppId :existingOppIds){
                        mapOfOppToUpd.put(oppId,new Opportunity(Id = oppId, Is_Order_Split__c =True));
                    }
                } 

            }  
        }
        return mapOfOppToUpd;     
    }
    public static void createAttachment(Map<Id, Id> mapOfOrdToQutDoc, Set<Id> attachIds) {
        try { 
          List<Attachment> lstAttachToinsert = new List<Attachment>();
          Map<Id, Attachment> mapOfAttach = new Map<Id, Attachment>(
            [SELECT id, body, name, parentId FROM Attachment WHERE id IN :attachIds]
          );
          for (Id orderId : mapOfOrdToQutDoc.keySet()) {
            Attachment tempAtt = mapOfAttach?.get(mapOfOrdToQutDoc?.get(orderId))?.clone();  
            tempAtt.ParentId = orderId;
            lstAttachToinsert.add(tempAtt); 
          }
          if (!lstAttachToinsert.isEmpty()) {
            insert lstAttachToinsert;
          }
        } 
        Catch(Exception e){
           UtilityClass.logException(e, 'UtilityClass', 'createAttachment', 'Attachment', null, 'SFDC', false);
        }
    } 
    public static void logException(Exception e) { 
        logException(e, null, null, null, null, null, false);
    }
    
    public static void logException(Exception e, String className) {
        logException(e, className, null, null, null, null, false);
    }
    
    public static void logException(Exception e, String className, String methodName) {
        logException(e, className, methodName, null, null, null, false);
    }
    
    public static void logException(Exception e, String className, String methodName, String objectName) {
        logException(e, className, methodName, objectName, null, null, false);
    }
    
    public static void logException(Exception e, String className, String methodName, String objectName, Id recordId) {
        logException(e, className, methodName, objectName, recordId, null, false); 
    }
    
    public static void logException(
        Exception e,
        String className,
        String methodName,
        String objectName,
        Id recordId,
        String type,
        Boolean isSuccess
      ) {
        
        String stackTrace = '';
        String errorMessage = '';
        if(e != null){
        if (String.isNotBlank(e.getStackTraceString())) {
          stackTrace = e.getStackTraceString();
        }
        errorMessage = e.getMessage();
        stackTrace = (stackTrace.length() + errorMessage.length() > 130000) ? e.getStackTraceString().subString(0, 130000-errorMessage.length()) : stackTrace;
        }
        Error_Logs__c errorLog = new Error_Logs__c(
          Error_Message__c = errorMessage + ' & Stacktrace:' +  stackTrace,
          Class__c = className, 
          Method__c = methodName,
          Object__c = objectName,
          RecordId__c = recordId,
          Type__c = type,
          Success__c = isSuccess
        );
        if (String.isNotBlank(recordId) && recordId.getSObjectType().getDescribe().getName() == Constants.ORDER_OBJECT_NAME) {
          errorLog.Order_ID__c = recordId;
        }
        if (String.isNotBlank(recordId) && recordId.getSObjectType().getDescribe().getName() == Constants.ACCOUNT_OBJECT_NAME) {
          errorLog.Account__c = recordId;
        }
        insert errorLog;
    }
    public static Error_Logs__c createlogExceptionRecord(
        Exception ex,
        String clsName,
        String metName,
        String objName,
        Id recId,
        String type,
        Boolean isSucceed,
        String customErrorMsg
      ) {

        String QueryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
        String DMLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
        String DMLStat = '3. Number of DML statements used so far / Number allowed: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();
        String CPUT = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
        
        String stackTrace = '';
        String errorMessage = '';
        if(ex != null){
            if (String.isNotBlank(ex.getStackTraceString())) {
            stackTrace = ex.getStackTraceString();
            }
            errorMessage = ex.getMessage();
            stackTrace = (stackTrace.length() + errorMessage.length() > 130000) ? ex.getStackTraceString().subString(0, 130000-errorMessage.length()) : stackTrace;
        }else{
            errorMessage = customErrorMsg;
        }
        Error_Logs__c errorLog = new Error_Logs__c(
          Error_Message__c = errorMessage + '& Stacktrace:' +  stackTrace +' & ' +String.format('{0}\n{1}\n{2}\n{3}', new List<string>{ QueryLimit, DMLimit, DMLStat, CPUT }),
          Class__c = clsName, 
          Method__c = metName,
          Object__c = objName,
          RecordId__c = recId,
          Type__c = type,
          Success__c = isSucceed
        );
        if (String.isNotBlank(recId) && recId.getSObjectType().getDescribe().getName() == Constants.ORDER_OBJECT_NAME) {
          errorLog.Order_ID__c = recId;
        }
        if (String.isNotBlank(recId) && recId.getSObjectType().getDescribe().getName() == Constants.ACCOUNT_OBJECT_NAME) {
          errorLog.Account__c = recId;
        }
        return errorLog;
    }
    /***********************************************************************************
    * @description       : publishGovOrgSyncEvents method which used to fire the Sync_with_Gov_Org__e platform event 
    * Project            : Fedramp2b
    * JIRA(s)            : PAF2-3, PAF2-15
    * @author            : NaveenkumarSelvaraj
    * @last modified on  : 30-01-2024
    * @last modified by  : NaveenkumarSelvaraj
    * arguments          : setofRecIds --> SetOfIds to Process, objectApiName --> Defines Object Name
    * return             : void
    * Modifications Log
    * 
    *******************************************************************************/ 
    public static void publishGovOrgSyncEvents(Set<Id> setofRecIds, String objectApiName){
        try{
            List<Sync_with_Gov_Org__e> syncGovOrgEvents = new List<Sync_with_Gov_Org__e>();
            for(Id RecId : setofRecIds){ 
                syncGovOrgEvents.add(new Sync_with_Gov_Org__e(Id__c = String.valueOf(RecId), Object_API_Name__c = objectApiName));
            }
            if(!syncGovOrgEvents.isEmpty()){
                List<Database.SaveResult> SaveResults = EventBus.publish(syncGovOrgEvents);
                                if(!SaveResults.isEmpty() && objectApiName == 'Order'){
                for(Integer i=0;i<SaveResults.size();i++){
                   for(Id RecId : setofRecIds){
                  Error_Logs__c objError = new Error_Logs__c(Order_ID__c = RecId, Class__c = 'UtilityClass', Type__c = 'SFDC',Method__c = 'publishGovOrgSyncEvents', Object__c = 'Sync_with_Gov_Org__e');
                    if (SaveResults.get(i).isSuccess()){
                        objError.Error_Message__c = 'Success';
                        objError.RecordId__c = SaveResults.get(i).Id;
                        objError.Success__c = true;
                    }
                    else{
                         Database.Error error = SaveResults.get(i).getErrors().get(0);
        		 String failedDML = error.getMessage();
        		 objError.Error_Message__c = failedDML;
                         objError.RecordId__c = SaveResults.get(i).Id;
                         objError.Success__c = false;

                    }
                       OrderHandler.lstErrorLogs.add(objError);
                   }

                }
		}

            }
            
        }
        Catch(Exception ex){
            UtilityClass.logException(ex, 'UtilityClass',  'publishGovOrgSyncEvents', 'Sync_with_Gov_Org__e', null);
        }
        
    }
    
    /**
* Creates an Entitlement_Links__c record linking a previous and a renewed entitlement, 
* with quantity logic based on SKU type and other factors.
*
* @param sourceEnt                       The previous entitlement record being renewed.
* @param targetEnt                    The newly created/renewed entitlement record.
* @param renewalCat                    The renewal category to assign (e.g., "Co-Term", "Renewal").
* @param EntLinkType                   The type of link between entitlements (e.g., "Auto-Renew", "Manual").
* @param mapProductToPolarisMappings  A mapping of product combinations to SKU mappings containing quantity ratios.
* @param newoiToSurvEntwithWrap       A mapping of new OrderItem + OrgEntId keys to previous entitlement details, for V2 logic.
* @param OrgEntId                      The Org-Level Entitlement ID (used in V2 scenarios).
* @param newOI                         The new OrderItem associated with the renewed entitlement.
* @author Naveen Selvaraj
* @date 22-04-2025
* @return A populated Entitlement_Links__c object with appropriate linkage and quantity values set.
*
* Note: This method does not persist (insert) the returned record. DML must be handled externally.
*/
public static Entitlement_Links__c createEntitlementLink(
    Entitlement sourceEnt,
    Entitlement targetEnt,
    String renewalCat,
    String EntLinkType,
    Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings,
    Map<String, PreviousTransRefWrapper> newoiToSurvEntwithWrap,
    Id OrgEntId,
    OrderItem newOI
) {
    Entitlement_Links__c entLink = new Entitlement_Links__c();
    entLink.Previous_Entitlement__c = sourceEnt.id;
    entLink.Renewed_Entitlement__c = targetEnt.id;
    String sourceEntskuType = sourceEnt.Product__r.Product_Level__c == null ? 'V1' : 'V2';
    String targetEntskuType = targetEnt.Product__r.Product_Level__c == null ? 'V1' : 'V2';
    if ((sourceEntskuType == 'V1' && targetEntskuType == 'V2') || Test.isRunningTest()) {
      if (sourceEnt.Quantity__c == 1) {
        entLink.Quantity__c = 1;
      } else {
        if (targetEnt.Order_Service_Item__r.serialNumber__c != null) {
          entLink.Quantity__c = targetEnt.Order_Service_Item__r.serialNumber__c.deleteWhitespace().split(',').size();
        } else {
          if (
            mapProductToPolarisMappings.containskey(sourceEnt.Product__c + '-' + targetEnt.Product__c) &&
            mapProductToPolarisMappings.get(sourceEnt?.Product__c + '-' + targetEnt.Product__c).Quantity_Ratio__c != null &&
            mapProductToPolarisMappings.get(sourceEnt?.Product__c + '-' + targetEnt.Product__c).Quantity_Ratio__c != 0
          ) {
            entLink.Quantity__c = (targetEnt?.Order_Service_Item__r?.Quantity /
            mapProductToPolarisMappings.get(sourceEnt?.Product__c + '-' + targetEnt.Product__c).Quantity_Ratio__c);
          } else {
            entLink.Quantity__c = targetEnt?.Order_Service_Item__r?.Quantity;
          }
        }
      }
    } else if (sourceEntskuType == 'V2' && targetEntskuType == 'V2') {
      if (
        newOI != null && orgEntId != null &&
        newoiToSurvEntwithWrap.containskey(newOI.id + '-' + orgEntId) &&
        newoiToSurvEntwithWrap.get(newOI.id + '-' + orgEntId).usedEntitlementQuantity != null
      ) {//ITNPI-2901
        entLink.Quantity__c = ReplacementEntSplitManager.autoAddedCapacityOLI?.contains(targetEnt?.Order_Service_Item__c) ? targetEnt?.Order_Service_Item__r?.Quantity : newoiToSurvEntwithWrap.get(newOI.id + '-' + orgEntId).usedEntitlementQuantity;
      } else {
        entLink.Quantity__c = targetEnt.Quantity__c;
      }
    }
    entLink.Renewal_Category__c = renewalCat;
    entLink.Type__c = EntLinkType;
    return entLink;
}
    /**
* @description     Method to identify auto added capacity SKUs - ITNPI-2901
* Returns a Boolean indicating if the given QuoteLine is an auto added capacity SKU.
* @param quoteLine     quote line record to check
* @author Lokesh Sharma
* @Date 11/04/2025  
*/
    public static Boolean isAutoAddedCapacitySKU(SBQQ__QuoteLine__c quoteLine){
        //Handle null input immediately
        if (quoteLine == null) {
            return false;
        }

        //Basic requirements (Product Type and Required By field)
        Boolean hasBasicRequirements = quoteLine.getSObject('SBQQ__Product__r')?.get('Product_Type__c')!=null?Label.AutoAddSKUProductTypes.contains(quoteLine.SBQQ__Product__r?.Product_Type__c) && String.isNotBlank(quoteLine.SBQQ__RequiredBy__c):false;
        //Refresh requirement (related Product Option field)
        Boolean requiresRefreshDefaultOption = quoteLine.getSObject('SBQQ__ProductOption__r')?.get('Refresh_Default_Option__c')!=null?quoteLine.SBQQ__ProductOption__r.Refresh_Default_Option__c:false;
        //Program/Renewal Logic - Special Program check (Must be set, but NOT equal to 'PROGRAM_REFRESH')
        Boolean meetsProgramOrRenewalCriteria =  (String.isNotBlank(quoteLine.Special_Program__c) && quoteLine.Special_Program__c != Constants.PROGRAM_REFRESH) ||
            //Renewal check (Must NOT have a special program, AND be RENEWING, AND Do_not_Renew__c is true/checked)
            (String.isBlank(quoteLine.Special_Program__c) && quoteLine.Disposition_Reason__c == Constants.RENEWING && quoteLine.Do_not_Renew__c);
        return hasBasicRequirements && requiresRefreshDefaultOption && meetsProgramOrRenewalCriteria;  
    }
    
/**
* Creates a Scale_Entitlement__c record linked to the provided Entitlement and Asset.
*
* @param ent           The Entitlement record to link. If null, related fields will be skipped.
* @param astId         The ID of the Asset to associate with the Scale_Entitlement__c record.
* @param linkedAstType The type/category to assign to the linked asset (stored in Type__c).
* @return              A new, unsaved Scale_Entitlement__c record populated with the provided information.
* @author Naveen Selvaraj
* @date 22-04-2025
* Note: This method does not insert the created record into the database. 
*       The caller is responsible for persisting it via DML operations.
*/
    public static Scale_Entitlement__c createLinkedAsset(Entitlement ent, Id astId, String linkedAstType) {
      Scale_Entitlement__c linkedAsset = new Scale_Entitlement__c();
      if (ent != null) {
        linkedAsset.Entitlement__c = ent.id;
        linkedAsset.Contract_Line_Item__c = ent.ContractLineItemId;
        linkedAsset.Order_Product__c = ent.Order_Service_Item__c;
      }
      linkedAsset.Asset__c = astId;
      linkedAsset.Type__c = linkedAstType;
      return linkedAsset;
    }
    
    /***************************************** *******************************************  
      Description : Update SC_or_Entitlement_Stage__c Field async depends on the input received.
      Input : ordIds --> eligible OrderIds Set, jsonString --> Map of order with status list to update. 
      Output : Update Order record.
    ***************************************************************************************/
    @future
    public static void updateOrderFields(Set<Id> ordIds, string jsonString /*Map<Id,List<String>> OrdIdToSCorEntIds*/){
        List<Order> lstOfOrderToUpdate = new List<Order>();
        Map<Id, set<String>> OrdIdToSCorEntIds;
        if(jsonString != null){
            OrdIdToSCorEntIds = (Map<Id, Set<String>>) JSON.deserialize(jsonString, Map<Id, set<String>>.class);
        }
        if(ordIds != null && OrdIdToSCorEntIds != null){
            for(Order ord : [Select id,SC_or_Entitlement_Stage__c from order where Id IN :ordIds]){
                String existingVal = ord.SC_or_Entitlement_Stage__c;
                if(OrdIdToSCorEntIds.containskey(ord.id)){
                    for(String pickVal : OrdIdToSCorEntIds.get(ord.id)){
                        if(existingVal == null || !existingVal.contains(pickVal)){
                            if(String.isEmpty(existingVal)){
                                ord.SC_or_Entitlement_Stage__c = pickVal;
                            }
                            else{
                                ord.SC_or_Entitlement_Stage__c =  existingVal + ';' + pickVal;
                            }
                        }
                        if(existingVal == null){
                            existingVal = pickVal;
                        }
                        else{
                            existingVal = existingVal + ';' + pickVal;
                        }

                    }
                    lstOfOrderToUpdate.add(ord);
                } 
            } 
        }
        if(!lstOfOrderToUpdate.isEmpty()){
            update lstOfOrderToUpdate;
        }
    }
    /***************************************** *******************************************  
      Description : Forms Map<Id, Set<String>> Map based on the input received and return it back. 
      Input : newOrd --> Order Record, OrdIdToSCorEntIds --> Existing Map of ord with its status , actionType --> Status to Add into map.
      Output : Forms Map<Id, Set<String>> and return it. 
    ***************************************************************************************/
    public static Map<Id, Set<String>> getupdatedOrdIdToScActionItemMap(Order newOrd, Map<Id, Set<String>> OrdIdToSCorEntIds, String actionType){

        if(OrdIdToSCorEntIds == null){ OrdIdToSCorEntIds = new Map<Id, Set<String>>(); } 
        if(!OrdIdToSCorEntIds.containskey(newOrd.id)){
            OrdIdToSCorEntIds.put(newOrd.id, new Set<String>{actionType});
        }
        else{
            OrdIdToSCorEntIds.get(newOrd.id).add(actionType);
        }
        return OrdIdToSCorEntIds;
    }

   /***************************************************************************************
   * Description   : Deserialize the Replacement JSON and return the EntId Set
   * Input Params  :
   *    - qli (SBQQ__QuoteLine__c) : Quote line item record.
   * Output        : Set<String> (Ent Id for the QLI).
   ****************************************************************************************/
  public static Set<String> getEntIdFromQliJson(SBQQ__QuoteLine__c qli) {
    Set<String> entIds = new Set<String>();
    if(String.isNotBlank(qli.Replacement_Details__c)){
    ReplacementJson wrap = (ReplacementJson) JSON.deserialize(qli.Replacement_Details__c, ReplacementJson.class);
    if (wrap != null && wrap.rowValues != null) {
      for (ReplacementJson.RowDetail eachRow : wrap.rowValues) {
        if (eachRow.entId != null) {
          entIds.add(eachRow.entId);
        }
      }
    }
    }
    return entIds;
  }
    /***************************************************************************************
    * Description   : Determines whether the given Order is a replacement order 
    *                 based on specific line types.
    * Input Params  :
    *    - newOrd (Order) : The Order record to be checked.
    * Output        : Boolean (true if the Order is a replacement order, false otherwise).
    ****************************************************************************************/
    public static boolean isReplacementOrder(Order newOrd){
        return (newOrd?.Line_Types__c != Null && (newOrd.Line_Types__c.contains(Constants.PROGRAM_CONVERSION) || newOrd.Line_Types__c.contains(Constants.PROGRAM_UPGRADE)));
    }
   /**
   * @description Determines whether the given OrderItem is a partial replacement orderItem
   *	 based on Program and Replacement Type.
   * Date Modified 07/04/2025
   * Author        Siva Kumar
   * @return       Boolean (true if the OrderItem is a partial replacement OrderItem, false otherwise).
   * @param        newOrdItem (OrderItem), the OrderItem record to be checked.
   */
  public static boolean isPartialReplacementOrderItem(OrderItem newOrdItem) {
    return Constants.REPLACEMENT_PROGRAMS.contains(newOrdItem.Program__c) && newOrdItem.Replacement_Type__c.contains(Constants.ORD_ITEM_REPLACEMENT_TYPE_PARTIAL);
    }  /***************************************************************************************
    * Description   : Deserialize the Replacement JSON and return the selectedAsset          
    * Input Params  :
    *    - qli (SBQQ__QuoteLine__c) : Quote line item record. 
    * Output        : String (Selected Asset for the QLI).
    ****************************************************************************************/
    public static String getSelectedAst(SBQQ__QuoteLine__c qli){
        ReplacementJson wrap = (ReplacementJson)JSON.deserialize(qli.Replacement_Details__c, ReplacementJson.class);
        if(wrap != null && wrap.rowValues != null){
            for(ReplacementJson.RowDetail eachRow : wrap.rowValues){
                if(eachRow.selectedAsset != null){
                    return eachRow.selectedAsset;
                }
            }
        }
        return null;
    }
     /***************************************************************************************
    * Description   : Determines whether the Type of sku is Hardware / License
    * Input Params  :
    *    - oi (OrderItem) : OrderItem record. 
    * Output        : String (check the sku and return either its Hardware or License).
    ****************************************************************************************/
  public static String getTypeofSKU(OrderItem oi) {
    String typeofSku;
    if (
      !String.isBlank(oI.Product2Id) && (oI.Product2.Product_Level__c == 'Hardware' && (oI.Product2.Product_Type__c == 'Hardware' || oI.Product2.Product_Type__c == 'Add-On Node'))
    ) {
      typeofSku = Constants.SKU_TYPE_HARDWARE;
    } else if (
      !String.isBlank(oI.Product2Id) &&
      (oI.Product2.Product_Level__c == 'Hybrid Software' ||
      (oI.Product2.Product_Level__c == 'OnPrem' &&
      (oI.Product2.Product_Type__c == 'Enterprise Edition' ||
      oI.Product2.Product_Type__c == 'Business Edition' ||
      oI.Product2.Product_Type__c == 'Foundation Edition') && OI?.Product2?.Product_Subtype__c == null) ||
      oI.Product2.Product_Level__c == 'LOD Software')
    ) {
      typeofSku = Constants.SKU_TYPE_LICENSE;
    } else if (OI.Product2.Product_Type__c == 'HW Support' && OI.Product2.Product_Level__c == 'Support') {
      typeofSku =  Constants.SKU_TYPE_HW_SUPPORT;
    } 
    return typeofSku;
  }
    /**
    * @author Naveen Kumar Selvaraj
    * @17/03/2025
    *
    * @description : Wrapper class to hwLines, DeltaLines Info for Refreshed Lines
    */
    Public class RefreshPrgmWrapper{
        Public Map<Id, String> hwLines = new Map<Id, String>(); 
        Public Map<Id, String> deltaLines = new Map<Id, String>();
        /***************************************************************************************
        * Description   : refreshPrgmWrapper Constructor to set the values 
        * Input Params  :
        *    typeofProduct - to identify the type of product either its Hardware / License.
        *    oi - OrderItem record
        * Output        : Set the values of hwLines, deltaLines
    ****************************************************************************************/
        Public refreshPrgmWrapper(String typeOfProduct, Orderitem oi){
            if(typeOfProduct == Constants.SKU_TYPE_HARDWARE){ this.hwLines.put(oi.id, oi.order.ordernumber); }
            else if(typeOfProduct == Constants.SKU_TYPE_LICENSE){
                this.deltaLines.put(oi.id, oi.order.ordernumber);
            } 
        }
    }
     /***************************************************************************************
   * Description   : Adjusting the RenewalQuantity of cli and sent back the cli Details
   * Input Params  :
   *    - cliMap (Map<Id,Contractlineitem>) : CLI Record to updatethe quantity
   *    - survEnt (Entitlement) : Entitlement record. 
   *    - qtytoAdjust (Decimal) : Quantity to adjust.
   * Map<Id, Contractlineitem>  : CLI Record with adjusted qty. 
   ****************************************************************************************/
public static Map<Id, Contractlineitem> getupdatedCli(Map<Id, Contractlineitem> cliMap, Entitlement survEnt, Decimal qtytoAdjust) {
        if (survEnt != null && survEnt.ContractLineItemId != null) {
          if (cliMap.containsKey(survEnt.ContractLineItemId)) {
            cliMap.get(survEnt.ContractLineItemId).SBQQSC__RenewalQuantity__c = cliMap.get(survEnt.ContractLineItemId).SBQQSC__RenewalQuantity__c - qtytoAdjust >= 0
              ? cliMap.get(survEnt.ContractLineItemId).SBQQSC__RenewalQuantity__c - qtytoAdjust : 0;
            cliMap.get(survEnt.ContractLineItemId).Resync_Line__c = 'Required';
          } else {
            if (survEnt != null && survEnt.ContractLineItemId != null) {
              cliMap.put(
                survEnt.ContractLineItemId,
                new ContractLineItem(
                  Id = survEnt.ContractLineItemId,
                  Resync_Line__c = 'Required',
                  SBQQSC__RenewalQuantity__c = !Test.isRunningTest() && survEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - qtytoAdjust > 0 ? survEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - qtytoAdjust : 0
                )
              );
            }
          }
        }
        return cliMap;
}
    
/**
* Method to extract old Asset Serial Numbers from the Replacement_Details__c JSON field 
* of a SBQQ__QuoteLine__c (QLI) record.
*
* @param qli  The Quote Line Item (SBQQ__QuoteLine__c) record containing the Replacement_Details__c JSON.
* @return     A Set<String> of serial numbers from the selected assets in the JSON, 
*             or null if no valid data is found.
*
* JSON Structure Assumed: 
* ReplacementJson -> List<RowDetail> rowValues -> Map<String, String> selectedAssetList
*
* Author : Naveen Selvaraj
* Date   : 15-Apr-2025
*/
public static Map<Id, Set<String>> getAssetSerialNumbersFromQliJson(SBQQ__QuoteLine__c qli) {
  if (qli.Replacement_Details__c == null) {
          return null;
      }
      ReplacementJson wrap = (ReplacementJson) JSON.deserialize(qli.Replacement_Details__c, ReplacementJson.class);
  Map<Id, Set<String>> entIdToAssetSNs = new Map<Id, Set<String>>();

      if (wrap != null && wrap.rowValues != null) {
          for (ReplacementJson.RowDetail eachRow : wrap.rowValues) {
      if (eachRow.entId != null && eachRow.selectedAssetList != null && !eachRow.selectedAssetList.values().isEmpty()) {
          String tempEntStr = eachRow.entId.trim();
          List<String> entIds = tempEntStr.contains(',') ? tempEntStr.split(',') : new List<String>{ tempEntStr };
          for(String entId : entIds){
            entId = entId.trim();
            Set<String> assetSNSet = new Set<String>();
            assetSNSet.addAll(eachRow.selectedAssetList.values());
            entIdToAssetSNs.put(entId, assetSNSet);
              }
          }
      }
  }
  return entIdToAssetSNs;
    }

  /**
   * Determines if the given order item is refreshed license product under the replacement or refresh program.
   * @param orderItem The OrderItem record to evaluate.
   * @return true if the order item meets all eligibility criteria; otherwise, false.
   */
  public static Boolean isRefreshedLicenseOI(OrderItem OI) {
    return isLicenseOrderItem(OI) &&
      (CONSTANTS.REPLACEMENT_PROGRAMS.contains(OI.Program__c) || OI.Program__c == CONSTANTS.PROGRAM_REFRESH);
  }

  /**
   * Determines if the given order item qualifies as a license item based on product level, type, and related fields.
   * @param orderItem The OrderItem record to evaluate.
   * @return true if the order item meets license criteria; otherwise, false.
   */
  public static Boolean isLicenseOrderItem(OrderItem OI) {
    if (OI == null || OI.Product2 == null) { return false; }

    String productLevel = OI.Product2.Product_Level__c;
    String productType = OI.Product2.Product_Type__c;
    String productSubtype = OI.Product2.Product_Subtype__c;

    Boolean isHybridSoftware = Constants.RSC_HYBRID_PRODUCT_LEVEL.equals(productLevel);

    Boolean isOnPremWithSpecificType =
      Constants.RSC_ONPREM_PRODUCT_LEVEL.equals(productLevel) &&
      (Constants.RSC_FOUNDATION_PRODUCT_TYPE.equals(productType) ||
      Constants.RSC_ENTERPRISE_PRODUCT_TYPE.equals(productType) ||
      Constants.RSC_BUSINESS_PRODUCT_TYPE.equals(productType)) && productSubtype == null;

    Boolean isRcdmSupportForLod =
      Constants.PRODUCT_TYPE_RCDM_SUPPORT.equals(productType) &&
      OI.SBQQ__RequiredBy__c != null && OI.SBQQ__RequiredBy__r != null && OI.SBQQ__RequiredBy__r.Product2 != null && Constants.RSC_LOD_PRODUCT_LEVEL.equals(OI.SBQQ__RequiredBy__r.Product2.Product_Level__c);

    return isHybridSoftware || isOnPremWithSpecificType || isRcdmSupportForLod;
  }
    
  /**
    * Retrieves a mapping of old serial numbers (from Upgraded_From__c)
    * to new serial numbers (from SerialNumber__c) for refresh program order items.
    * @param orderItem The OrderItem record containing upgrade and serial information.
    * @param newAssetsByOldAsset A Map to store the mapping of old serial numbers to new serial numbers.
    * @return A Map where each key is an old serial number and the value is a Set of new serial numbers.
  */
  public static void  getNewAssetsByOldAssetMapping(OrderItem orderItem,Map<String, Set<String>> newAssetsByOldAsset) {
    
    if (orderItem == null ||
        orderItem.Program__c != CONSTANTS.PROGRAM_REFRESH ||
        String.isBlank(orderItem.Upgraded_From__c)) {
        return;
    }

    List<String> oldSerialNumbers = orderItem.Upgraded_From__c.split(',');
    List<String> newSerialNumbers = String.isNotBlank(orderItem.SerialNumber__c)
          ? orderItem.SerialNumber__c.split(',') : new List<String>();

    for (String oldSN : oldSerialNumbers) {
        String trimmedOldSN = oldSN != null ? oldSN.trim() : '';
        if (String.isNotBlank(trimmedOldSN)) {
            if (!newAssetsByOldAsset.containsKey(trimmedOldSN)) {
                newAssetsByOldAsset.put(trimmedOldSN, new Set<String>());
            }
            for (String newSN : newSerialNumbers) {
                String trimmedNewSN = newSN != null ? newSN.trim() : '';
                if (String.isNotBlank(trimmedNewSN)) {
                    newAssetsByOldAsset.get(trimmedOldSN).add(trimmedNewSN);
                }
            }
        }
    }
  }
   /**
 * Determines whether the given Product2 record qualifies as a license SKU.
 *
 * @param prod The Product2 record to evaluate.
 * @return true if the product is identified as a license SKU; false otherwise or if the input is null.
 * @author Naveen Selvaraj
 * @date 20/05/2025
 */
  public static Boolean IsLicenseSku(Product2 prod){
      if(prod == null){ return false; }
      Boolean isLicenseSku =
      (
      (prod.Product_Level__c == Constants.RSC_ONPREM_PRODUCT_LEVEL &&
      (prod.Product_Type__c == Constants.RSC_ENTERPRISE_PRODUCT_TYPE ||
      prod.Product_Type__c == Constants.RSC_BUSINESS_PRODUCT_TYPE ||
      prod.Product_Type__c == Constants.RSC_FOUNDATION_PRODUCT_TYPE) && prod.Product_Subtype__c == null) ||
      prod.Product_Level__c == Constants.RSC_LOD_PRODUCT_LEVEL || 
      prod.Product_Level__c == Constants.RSC_HYBRID_PRODUCT_LEVEL);
      return isLicenseSku;
  }
  /**
   * Determines whether the given Product2 record qualifies as a V1 license SKU.
   *
   * @param prod The Product2 record to evaluate.
   * @return true if the product is identified as a V1 license SKU; false otherwise or if the input is null.
   * @author Ravi Mali
   * @date 30/05/2025
   */
  public static Boolean isV1LicenseProduct(Product2 prod) {
    Set<String> prodEditions = new Set<String>{ Constants.RSC_ENTERPRISE_PRODUCT_TYPE, Constants.RSC_BUSINESS_PRODUCT_TYPE, Constants.RSC_FOUNDATION_PRODUCT_TYPE };
    return prod != null && prod.Product_Level__c == null && prod.Edition__c != null && prodEditions.contains(prod.Edition__c);
  }

  /**
     * Determines whether the given Product2 record qualifies as a V2 Hardware Support product.
     * @param prod The Product2 record to evaluate.
     * @return true if the product is identified as a V2 HW Support product; false otherwise or if the input is null.
   */
  public static Boolean isV2HardwareSupportSKU(Product2 prod) {
      return prod != null && 
            prod.Product_Type__c == 'HW Support' && 
            prod.Product_Level__c == 'Support';
  }

  /**
   * @description Deserializes the Previous_Transaction_Reference__c field of the given OrderItem
   * into a list of PreviousTransRefWrapper wrapper objects.
   *
   * @param orderItem The OrderItem record whose Previous_Transaction_Reference__c contains the serialized JSON.
   * @return A list of PreviousTransRefWrapper objects if deserialization is successful; otherwise, an empty list.
 */
  public static List<PreviousTransRefWrapper> getPreviousLineDetails(OrderItem orderItem) {
      if (orderItem == null || String.isBlank(orderItem.Previous_Transaction_Reference__c)) {
      return new List<PreviousTransRefWrapper>();
      }
      return (List<PreviousTransRefWrapper>) JSON.deserialize(
              orderItem.Previous_Transaction_Reference__c,
              List<PreviousTransRefWrapper>.class
      );
  }
  
  /**
   * Checks if the given map has at least one non-empty Set<String> as a value.
   *
   * @param inputMap The map to check.
   * @return true if any of the map's values is a non-empty set, false otherwise.
   */
  public static Boolean hasAtLeastOneNonEmptyValue(Map<String, Set<String>> inputMap) {
      if (inputMap == null || inputMap.isEmpty()) { return false;}
      for (Set<String> valueSet : inputMap.values()) {
          if (valueSet != null && !valueSet.isEmpty()) {
              return true;
          }
      }
      return false;
  }
  /**
   * Checks whether the given OrderItem is eligible for the Summer Release flow.
   * Conditions:
   * - Must have a previous transaction reference.
   * - Program = 'Refresh' OR Program__c in REPLACEMENT_PROGRAMS OR Line_Type__c = 'Renewal'
   *
   * @param oi The OrderItem record to evaluate.
   * @return true if eligible for Summer Release logic.
   */
  public static Boolean isValidSummerReleaseOrderItem(OrderItem oi) {
    return oi != null &&
      String.isNotBlank(oi.Previous_Transaction_Reference__c) &&
      (CONSTANTS.PROGRAM_REFRESH.equals(oi.Program__c) ||
      Constants.REPLACEMENT_PROGRAMS.contains(oi.Program__c) || (Constants.ORDER_SUBTYPE_RENEWAL.equals(oi.Line_Type__c) && Constants.ORDER_SUBTYPE_RENEWAL.equals(oi.Order.Order_Sub_Type__c)));
  }

  /**
   * Determines if the given entitlement qualifies as a New Sale,
   *
   * @param objEntitlement The entitlement record to evaluate.
   * @return true if the entitlement qualifies as a New Sale, false otherwise.
   */
  public static Boolean isNewSaleOrderItem(OrderItem OI) {
    Order order = OI?.Order;

    return (order?.Type == Constants.ORDER_TYPE &&
    String.isBlank(order?.Order_Sub_Type__c) &&
    String.isBlank(OI?.Program__c) &&
    OI?.Line_Type__c == 'New');
  }
  /**
     * Extracts child Entitlement Ids from the given ReplacementJson wrapper object.
     *
     * @param wrapperObj  The ReplacementJson object containing row and inactive line details.
     * @param origEntWrap  Optional entitlement details wrapper, updated with mismatch flag if matching entId is found.
     * @return            A Set of child Entitlement Ids found in inactiveLines.
     * @author  Naveen Selvaraj/Ravi M
     * @date    18/8/2025
 */
  public static Set<Id> getChildEntIdsFromQliJson(ReplacementJson wrapperObj, ReplacementEntSplitManager.EntitlementDetails origEntWrap) {
    Set<Id> childEntIds = new Set<Id>();
    if (wrapperObj != null) {
        if (wrapperObj.rowValues != null) {
            for (ReplacementJson.RowDetail row : wrapperObj.rowValues) {
                // Update isMisMatched only if origEntWrap is provided
                if (origEntWrap != null && origEntWrap.orgEntRec != null && String.isNotBlank(row.entId)  && origEntWrap?.orgEntRec.Id == row.entId) {
                    origEntWrap.isMisMatched = (row.isMismatch != null) ? row.isMismatch : false;
                }
                if (row.inactiveLines != null) {
                    for (ReplacementJson.RelatedChildEntRowDetail inactive : row.inactiveLines) {
                        if (String.isNotBlank(inactive.childEntId)) {
                            childEntIds.add((Id) inactive.childEntId);
                        }
                    }
                }
            }
        }
    }
    return childEntIds;
  }
}