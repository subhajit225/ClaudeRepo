/*********************************************************************************** 
* @description       : This Queueable class Splits Gc Offer contract in to multiple Service Contracts. As there could be multiple bundles included in an order and contract. 
                        And requirement is to have a dedicated contract per Global Commit Id which is not possible using the CPQ'a OOTB feature. 
                        So, we updated the Order's Contracting method as Single contract and created this job to split the contract.
* Project            : Scale Utility
* JIRA(s)            : CSU-336, CSU-339, CSU-407, CSU-444, CSU-487
* @author            : Prashant
* @last modified on  : 01-09-2023
* @last modified by  : Prashant
* Modifications Log
*******************************************************************************/
global class SplitGCOfferServiceContractQueueable implements Queueable {
  private Id orderId;
  private Set<String> globalCommitIds;
  private Set<String> globalCommitIdsAlreadyProcessed = new Set<String>();  
  private Map<Id, List<Id>> quoteToOrderIds;
  private Map<String, ContractlineItem> upgradedQLICLIMap;
  private Map<String,String> globalCommitIdToLicenceAndHw;  // CSU-686  


  private Queueable nextJob;

  global SplitGCOfferServiceContractQueueable(Map<String, ContractlineItem> upgradedQLICLIMap, Queueable nextJob) {
    this.upgradedQLICLIMap = upgradedQLICLIMap;
    this.nextJob = nextJob;
  }

  global SplitGCOfferServiceContractQueueable(Set<String> globalCommitIds, Id OrderId,Map<String,String> globalCommitIdToLicenceAndHw, Queueable nextJob) {
    this.globalCommitIds = globalCommitIds;
    this.orderId = orderId;
    this.nextJob = nextJob;
    this.globalCommitIdToLicenceAndHw = globalCommitIdToLicenceAndHw;  

  }

  public void execute(QueueableContext qc) {
    try {
        system.debug('this.upgradedQLICLIMap  is ' + this.upgradedQLICLIMap);
      if (this.upgradedQLICLIMap != null) {
        splitUpgradedCLIs();
      } else {
        splitServiceContractsByGCIds();
      }
    } catch (Exception e) {
      UtilityClass.logException(e, 'SplitGCOfferServiceContractQueueable', 'executes (Generic)', 'ServiceContract', this.orderId, 'SFDC', false);
    }
    if (this.nextJob != null && !Test.isRunningTest()) {
      System.enqueueJob(this.nextJob);
    }
  }

    /******************************************************
   * Description : This method is going Clone the ContractLine Items and Entitlements based on related quotelines and order line items
   * Arguements :  none   
   * Return : void 	   
   * Author : Prashant
   * CreatedDate : 13-12-2023
   * ******************************************************/    
  private void splitUpgradedCLIs() {
    try {
      List<ContractLineItem> clonedCLIsToInserted = new List<ContractLineItem>();
      List<Entitlement> newENTsToInserted = new List<Entitlement>();
      Map<Id, List<Entitlement>> qliEntLstMap = new Map<Id, List<Entitlement>>();
      Map<Id, List<Entitlement>> newGCOfferSegmentEntitlementsByProductId = new Map<Id, List<Entitlement>>();

      for (SBQQ__QuoteLine__c qli : [
        SELECT
          Id,
          (
            SELECT Id, Support_Start_Date__c, Support_End_Date__c, Quantity, SBQQ__SubscriptionTerm__c, UnitPrice
            FROM SBQQ__OrderProducts__r
          )
        FROM SBQQ__QuoteLine__c
        WHERE Id IN :this.upgradedQLICLIMap.keySet()
      ]) {
        if (!qli.SBQQ__OrderProducts__r.isEmpty()) {
          for (OrderItem OI : qli.SBQQ__OrderProducts__r) {
            if (OI.Id != this.upgradedQLICLIMap.get(qli.Id)?.SBQQSC__OrderProduct__c) {
              ContractLineItem ClonedCLI = this.upgradedQLICLIMap.get(qli.Id).clone(false);
              ClonedCLI.SBQQSC__OrderProduct__c = OI.Id;
              ClonedCLI.StartDate = OI.Support_Start_Date__c;
              ClonedCLI.EndDate = OI.Support_End_Date__c;
              ClonedCLI.Quantity = OI.Quantity;
              ClonedCLI.UnitPrice = OI.UnitPrice;
              clonedCLIsToInserted.add(ClonedCLI);
            } else if (OI.Id == this.upgradedQLICLIMap.get(qli.Id)?.SBQQSC__OrderProduct__c) {
              ContractLineItem originalCLI = this.upgradedQLICLIMap.get(qli.Id);
              originalCLI.EndDate = OI.Support_End_Date__c;
              originalCLI.UnitPrice = OI.UnitPrice;
              clonedCLIsToInserted.add(originalCLI);
            }
          }
        }
      }

      if (!clonedCLIsToInserted.isEmpty()) {
        upsert clonedCLIsToInserted;
      }

      for (Entitlement ENT : [
        SELECT
          ContractLineItem.SBQQSC__QuoteLine__c,
          Name,
          RecordTypeId,
          AccountId,
          Type,
          ServiceContractId,
          ContractLineItemId,
          AssetId,
          StartDate,
          EndDate,
          SlaProcessId,
          BusinessHoursId,
          IsPerIncident,
          CasesPerEntitlement,
          RemainingCases,
          Order_Service_Item__c,
          Product__c,
          Renewed__c,
          List_Price_Manual__c,
          Calculated_List_Price__c,
          Renewedcheck__c,
          PB_List_Price__c,
          Renewable__c,
          MSP_Minimum_Consumption_Start_Date__c,
          isSCCreated__c,
          Notes__c,
          Partner_Name__c,
          is_Deprecated__c,
          MSP_Segment_Product__c,
          Entitlement_Usage__c,
          Integration_Partner_Contact_Name__c,
          Manufacturing_Integration_Partner__c,
          Primary_Contact__c,
          Renewal_Category__c,
          Go_Refresh__c,
          Refresh_Grace_Period_Start_Date__c,
          SW_Support_End_Date__c,
          MSP_End_User_Lookup__c,
          Prior_Entitlement__c,
          isAssigned__c,
          RSC_Status__c,
          Manual_Adj_Lic_Qty__c,
          Manual_Adj_Lic_Price__c,
          Quantity__c,
          Has_linked_CSAT_Extension_Entitlement__c,
          New_Extended_End_Date__c,
          New_Extension_Term__c,
          RSC_Entitlement_Id__c,
          PAG__c,
          Entitlement_Subtype__c,
          Product__r.Scale_Utility_Product__c,
          Product__r.Product_Type__c,
          Product__r.Product_Subtype__c,
          Product__r.License_Category__c,
          Order_Service_Item__r.Order.Order_Sub_Type__c
        FROM Entitlement
        WHERE ContractLineItem.SBQQSC__QuoteLine__c IN :this.upgradedQLICLIMap.keySet()
      ]) {
        if (qliEntLstMap.containsKey(ENT.ContractLineItem.SBQQSC__QuoteLine__c)) {
          qliEntLstMap.get(ENT.ContractLineItem.SBQQSC__QuoteLine__c).add(ENT);
        } else {
          qliEntLstMap.put(ENT.ContractLineItem.SBQQSC__QuoteLine__c, new List<Entitlement>{ ENT });
        }
      }
      List<UpgradeSkuEntitlementSortWrapper> entitlementWrapper = new List<UpgradeSkuEntitlementSortWrapper>();

      for (ContractLineItem newCLI : clonedCLIsToInserted) {
        if (qliEntLstMap.ContainsKey(newCLI.SBQQSC__QuoteLine__c) && qliEntLstMap.get(newCLI.SBQQSC__QuoteLine__c).size() > 0 && newCLI.SBQQSC__OrderProduct__c != this.upgradedQLICLIMap.get(newCLI.SBQQSC__QuoteLine__c).SBQQSC__OrderProduct__c) {
          for (Entitlement oldENT : qliEntLstMap.get(newCLI.SBQQSC__QuoteLine__c)) {
            Entitlement clonedENT = oldENT.clone(false);
            clonedENT.StartDate = newCLI.StartDate;
            clonedENT.EndDate = newCLI.EndDate;
            clonedENT.Quantity__c = newCLI.Quantity;
            clonedENT.Order_Service_Item__c = newCLI.SBQQSC__OrderProduct__c;
            clonedENT.ContractLineItemId = newCLI.Id;
            entitlementWrapper.add(new UpgradeSkuEntitlementSortWrapper(clonedENT.startDate, clonedENT));
            newENTsToInserted.add(clonedENT);
          }
        }
      }
      if (!newENTsToInserted.isEmpty()) {
        List<String> upgradedQliCLIToString = new List<String>();
        upgradedQliCLIToString.addAll(this.upgradedQLICLIMap.keyset());
        Id getFueEntitlementId = Id.valueOf(upgradedQliCLIToString[0]);
        Entitlement getFueEntitlement = qliEntLstMap.get(getFueEntitlementId)[0];
        newENTsToInserted.add(getFueEntitlement);
        upsert newENTsToInserted;
        entitlementWrapper.add(new UpgradeSkuEntitlementSortWrapper(getFueEntitlement.startDate, getFueEntitlement));
        entitlementWrapper.sort();
        for (UpgradeSkuEntitlementSortWrapper gcOfferEntitlementWrapper : entitlementWrapper) {
          Entitlement gcOfferEntitlement = gcOfferEntitlementWrapper.ent;
          if (!newGCOfferSegmentEntitlementsByProductId.containsKey(gcOfferEntitlement.Product__c)) {
            newGCOfferSegmentEntitlementsByProductId.put(gcOfferEntitlement.Product__c, new List<Entitlement>());
          }
          newGCOfferSegmentEntitlementsByProductId.get(gcOfferEntitlement.Product__c).add(gcOfferEntitlement);
        }

        if (!newGCOfferSegmentEntitlementsByProductId.isEmpty())
          contractorders.generateEntitlementLinks(newGCOfferSegmentEntitlementsByProductId);
      }
    } catch (Exception e) {
      UtilityClass.logException(e, 'SplitGCOfferServiceContractQueueable', 'splitServiceContractsByGCIds', 'ServiceContract', this.orderId, 'SFDC', false);
    }
  }
  /*
   * Here as we have contracting method single contract so all the bundle skus will come in one service contract
   * Now If we are having all Two aor three Bundles like FE and M365 e.g
   * then we will have Different Global Commit for their respective Skus product
   * Below is the logic for splitting Service Contract as part of CSU-444
   *
   */
  private void splitServiceContractsByGCIds() {
    try {
      if (this.orderId != null) {
        Map<Id, ContractLineItem> cliToBeDeleted = new Map<Id, ContractLineItem>();
        Map<Id, OrderItem> orderItemByIdToUpdate = new Map<Id, OrderItem>();
        Map<String, ContractLineItem> newCLIByGcAndOrdItemId = new Map<String, ContractLineItem>();
        Map<String, ContractLineItem> allOldCliToClone = new Map<String, ContractLineItem>();
        Map<String, ServiceContract> newSCToCreateByGCId = new Map<String, ServiceContract>();
        Map<Id, ServiceContract> SCtoBeDeleted = new Map<Id, ServiceContract>();
        String cliQuery = queryAllCLIandContractFields(this.orderId);
          for(ContractLineItem eachCLI : Database.query(String.escapeSingleQuotes(cliQuery)))  
        {
          if (!SCtoBeDeleted.containskey(eachCLI.ServiceContractId) && !eachCLI.SBQQSC__OrderProduct__r.order.is_Amendment_Order__c)
            SCtoBeDeleted.put(eachCLI.ServiceContractId, eachCLI.ServiceContract);

            
          // Clone the Service Contract Based On RSVX Lines- CSU-444
          if (this.globalCommitIds.contains(eachCLI.Global_Commit_Split_ID__c)) { 
            if (
              eachCLI.ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
              ((eachCLI.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP && eachCLI.SBQQSC__Product__r.License_Category__c == null) || (eachCLI.SBQQSC__Product__r.Product_Type__c == 'HW Support' && eachCLI.SBQQSC__Product__r.Product_Level__c == 'Support')) &&
              !globalCommitIdsAlreadyProcessed.contains(eachCLI.Global_Commit_Split_ID__c)
            ) {
              globalCommitIdsAlreadyProcessed.add(eachCLI.Global_Commit_Split_ID__c);
              ServiceContract scToSplit = eachCLI.serviceContract.clone(false);
              scToSplit.enddate = eachCLI.SBQQSC__OrderProduct__r.endDate;
              scToSplit.startdate = eachCLI.serviceContract.startdate;
              if(eachCLI.serviceContract.startdate!=null && eachCLI.SBQQSC__OrderProduct__r.endDate!=null)
              scToSplit.Term = OrderItemTriggerHelper.getmonthsbetweenDates(eachCLI.serviceContract.startdate, eachCLI.SBQQSC__OrderProduct__r.endDate);
              if(!globalCommitIdToLicenceAndHw.isEmpty() && globalCommitIdToLicenceAndHw.containskey(eachCLI.Global_Commit_Split_ID__c))
              scToSplit.name = globalCommitIdToLicenceAndHw.get(eachCLI.Global_Commit_Split_ID__c) + ' - Contract'; 
              scToSplit.pricebook2Id = eachCLI.ServiceContract.Pricebook2Id;
              scToSplit.SBQQSC__Order__c = eachCLI.SBQQSC__OrderProduct__r.OrderId;
              if (!newSCToCreateByGCId.containskey(eachCLI.Global_Commit_Split_ID__c)) {
                newSCToCreateByGCId.put(eachCLI.Global_Commit_Split_ID__c, scToSplit);
              }
            }
            Boolean IsUpgraded = OrderItemTriggerHelper.isScaleUtilityUpgradeSKU(eachCLI.SBQQSC__Product__r);
             if (!IsUpgraded)
              allOldCliToClone.put(eachCLI.Global_Commit_Split_ID__c + eachCLI.Id, eachCLI);
          }
        }

        // Logic For deleting old clis and Linking Cloned ContractLineItem to New Service Contracts - CSU-444
        if (!newSCToCreateByGCId.isEmpty()){
          TriggerControl.stopSCTrigger = true;
          insert newSCToCreateByGCId.values();
          TriggerControl.stopSCTrigger = false;    
      }        list<ContractLineItem> newCLIsToCreate = new List<ContractLineItem>();
        Map<String, Id> gcToCli = new Map<String, Id>();

        for (String str : allOldCliToClone.keyset()) {
          ContractLineItem CLI = allOldCliToClone.get(str);
          cliToBeDeleted.put(CLI.Id, CLI);
          ContractLineItem splitCliBasedOnGCId = CLI.clone();
          if (newSCToCreateByGCId.containskey(splitCliBasedOnGCId.Global_Commit_Split_ID__c))
            splitCliBasedOnGCId.serviceContractid = newSCToCreateByGCId.get(splitCliBasedOnGCId.Global_Commit_Split_ID__c).Id;
          newCLIsToCreate.add(splitCliBasedOnGCId);
        }
        if (!newCLIsToCreate.isEmpty())
          insert newCLIsToCreate;
        for (ContractLineItem cliNew : newCLIsToCreate) {
          if (cliNew.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP && cliNew.SBQQSC__Product__r.License_Category__c == null)
            gcToCli.put(cliNew.Global_Commit_Split_ID__c, cliNew.Id);

          newCLIByGcAndOrdItemId.put(cliNew.Global_Commit_Split_ID__c + cliNew.SBQQSC__OrderProduct__c, cliNew);
          orderItemByIdToUpdate.put(cliNew.SBQQSC__OrderProduct__c, new OrderItem(Id = cliNew.SBQQSC__OrderProduct__c, SBQQSC__ContractLineItem__c = cliNew.Id));
        }

        /* Update the Required By Field for AR,SR,OND and RSV segement Lines*/
        for (ContractLineItem cliNew : newCLIsToCreate) {
          if (
            (cliNew.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP && cliNew.SBQQSC__Product__r.License_Category__c == constants.LICENSE_CATEGORY) ||
            (cliNew?.SBQQSC__Product__r?.Product_Subtype__c != null &&
            constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(cliNew?.SBQQSC__Product__r?.Product_Subtype__c) &&
            cliNew?.SBQQSC__Product__r?.License_Category__c != null &&
            cliNew?.SBQQSC__Product__r?.License_Category__c == Constants.LICENSE_CATEGORY)
          ) {
            cliNew.SBQQSC__RequiredById__c = gcToCli.get(cliNew.Global_Commit_Split_ID__c);
          }
        }
        update newCLIsToCreate;

        Map<Id, Entitlement> newEntitlementToBeUpdated = new Map<Id, Entitlement>();
        // Link / movinng Entitlement To New Service Contracts and ContractLineItems
        for (Entitlement objEntitlement : [
          SELECT Id, ContractLineItemId, servicecontractId, Order_Service_Item__c, Order_Service_Item__r.orderId, Order_Service_Item__r.Global_Commit_ID__c, Order_Service_Item__r.Global_Commit_Split_ID__c
          FROM entitlement
          WHERE type = 'Phone Support' AND Order_Service_Item__r.Global_Commit_Split_ID__c IN :newSCToCreateByGCId.keyset()
          ORDER BY Id LIMIT 1000
        ]) {
          if (newCLIByGcAndOrdItemId.containskey(objEntitlement.Order_Service_Item__r.Global_Commit_Split_ID__c + objEntitlement.Order_Service_Item__c)) {
            objEntitlement.ContractLineItemId = newCLIByGcAndOrdItemId.get(objEntitlement.Order_Service_Item__r.Global_Commit_Split_ID__c + objEntitlement.Order_Service_Item__c).Id;
            objEntitlement.serviceContractid = newSCToCreateByGCId.get(objEntitlement.Order_Service_Item__r.Global_Commit_Split_ID__c).Id;
            newEntitlementToBeUpdated.put(objEntitlement.Id, objEntitlement);
          }
        }

        // updating Entitlements with the new CLIs
        if (!newEntitlementToBeUpdated.isEmpty())
          update newEntitlementToBeUpdated.values();
        // updating OrderItems
        if (!orderItemByIdToUpdate.isEmpty())
          update orderItemByIdToUpdate.values();
        // deleting original Contracts and contracts lines since they are already splitted per the GC Id and no longer needed
        if (!cliToBeDeleted.isEmpty())
          delete cliToBeDeleted.values();
        if (!SCtoBeDeleted.isEmpty())
          delete SCtoBeDeleted.values();
      }
    } catch (Exception e) {
      UtilityClass.logException(e, 'SplitGCOfferServiceContractQueueable', 'splitServiceContractsByGCIds', 'ServiceContract', this.orderId, 'SFDC', false);
    }
  }

  /****************************************************************
   *  Sort Entitlement by StartDate
   *****************************************************************/
  public class UpgradeSkuEntitlementSortWrapper implements Comparable {
    Date StartDate;
    Entitlement ent;

    UpgradeSkuEntitlementSortWrapper(Date StartDate, Entitlement ent) {
      this.StartDate = StartDate;
      this.ent = ent;
    }

    public Integer compareTo(Object compareTo) {
      UpgradeSkuEntitlementSortWrapper wrapperObj = (UpgradeSkuEntitlementSortWrapper) compareTo;
      if (StartDate == wrapperObj.StartDate)
        return 0;
      if (StartDate > wrapperObj.StartDate)
        return 1;
      return -1;
    }
  }
  /******************************************************
   * Description : Method to create dynamic query for ContractlineItem and its related Service Contract
   * as it will get all the fields created from CPQ package and no fields is missed.
   * Arguements :  Id   
   * Return : String 	   
   * Author : Prashant
   * CreatedDate : 13-12-2023
   * ******************************************************/    
public static String queryAllCLIandContractFields(Id orderId) {
    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    // Get the describe result for ContractLine
    Schema.DescribeSObjectResult contractLineDescribe = globalDescribe.get('ContractLineItem').getDescribe();
    // Get all the fields for ContractLine
    Map<String, Schema.SObjectField> contractLineFieldsMap = contractLineDescribe.fields.getMap();
    // Get the describe result for ServiceContract
    Schema.DescribeSObjectResult serviceContractDescribe = globalDescribe.get('ServiceContract').getDescribe();
    // Get all the fields for ServiceContract
    Map<String, Schema.SObjectField> serviceContractFieldsMap = serviceContractDescribe.fields.getMap();
    // Build a dynamic SOQL query for both ContractLine and ServiceContract
    String dynamicQuery = 'SELECT Id,SBQQSC__OrderProduct__r.order.is_Amendment_Order__c,Global_Commit_Split_ID__c,SBQQSC__Product__r.Product_Subtype__c,SBQQSC__Product__r.License_Category__c,SBQQSC__Product__r.Product_Type__c,SBQQSC__Product__r.Product_Level__c,SBQQSC__OrderProduct__r.endDate,SBQQSC__OrderProduct__r.OrderId,ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c,SBQQSC__Product__r.Edition__c, ';
    
    // Add ContractLine fields to the query
    for (String contractLineFieldName : contractLineFieldsMap.keySet()) {
        if(contractLineFieldName!='Id'  && contractLineFieldsMap.get(contractLineFieldName).getDescribe().iscreateable()){
            system.debug('CLI FieldName ' + contractLineFieldName);
            dynamicQuery += contractLineFieldName + ', ';

        }
    }
    // Add ServiceContract fields to the query
    for (String serviceContractFieldName : serviceContractFieldsMap.keySet()) {
        if(serviceContractFieldsMap.get(serviceContractFieldName).getDescribe().iscreateable())
        dynamicQuery += 'ServiceContract.' + serviceContractFieldName + ', ';
    }
    // Remove the trailing comma and space
    dynamicQuery = dynamicQuery.removeEnd(', ');
    // Add the FROM clause
    dynamicQuery += ' FROM ContractLineItem   WHERE SBQQSC__OrderProduct__r.orderId = :orderId';
    return dynamicQuery;
  }  
    
    
    
    
}