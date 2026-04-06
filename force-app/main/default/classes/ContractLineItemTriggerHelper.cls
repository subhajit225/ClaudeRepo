/***********************************************************************************
Date            Name                Description
11-JAN-2022     Shiju Thomas        Initial Implementation
24-FEB-2022     Shiju Thomas        Added method setActiveLODServiceContract    

Testclass  : ContractLineItemTriggerTests, ScaleUtilityOverageTriggerTest
************************************************************************************/
public without sharing class ContractLineItemTriggerHelper {
  //RWD-1181 : Rahul Agarwal : Users should be able to see the third-party hardware attributes (TPH OEM, TPH Model,
  //Drive Size, TPH Qty) in the QLE for renewals for all 3rd party Hybrid Cloud - Subscription
  //Logic starts here

  public static void updateTPHFields(List<ContractLineItem> newContractListItem) {
    Set<String> productIdSet = new Set<String>();
    if (newContractListItem != null && newContractListItem.size() > 0) {
      for (ContractLineItem cli : newContractListItem) {
        productIdSet.add(cli.SBQQSC__Product__c);
      }

      if (!productIdSet.isEmpty()) {
        Map<Id, Product2> productIdMap = new Map<Id, Product2>(
          [SELECT id, family, Third_party_SKU_DRIVE_Size__c, TPH_Models_Gen__c, Usable_Capacity__c, Capacity__c FROM product2 WHERE id IN :productIdSet AND product_level__c = NULL]
        );
        for (ContractLineItem contractLineItem : newContractListItem) {
          if (productIdMap.containsKey(contractLineItem.SBQQSC__Product__c)) {
            Product2 productObj = productIdMap.get(contractLineItem.SBQQSC__Product__c);
            if (productObj.Family == 'Dell' || productObj.Family == 'HPE' || productObj.Family == 'UCS') {
              contractLineItem.TPH_OEM__c = productObj.family;
              contractLineItem.TPH_Models_Gen__c = productObj.TPH_Models_Gen__c;
              contractLineItem.TPH_Drive_Size__c = productObj.Third_party_SKU_DRIVE_Size__c;
              contractLineItem.TPH_Quantity__c = String.valueof(contractLineItem.Quantity);
            }
          }
        }
      }
    }
  }
  //End Here
  //CPQ22-1159
  public static void setContractLineItemFields(List<ContractLineItem> lstContractLineItem) {
    Set<Id> quoteLineIds = new Set<Id>();
    for (ContractLineItem obj : lstContractLineItem) {
      quoteLineIds.add(obj.SBQQSC__QuoteLine__c);
    }
    if (quoteLineIds != null) {
      Map<Id, SBQQ__QuoteLine__c> mapObjLine = new Map<Id, SBQQ__QuoteLine__c>(
        [
          SELECT
            Id,
            POT_Parent_Source__c,
            POT_Parent_List_Price__c,
            SBQQSC__RenewedContractLine__c,
            SBQQSC__RenewedContractLine__r.AMER_FED_Exception__c,
            RWD_Deal_Ops_Exception__c,
            Product_Level__c,
            Product_Type__c,
            Product_Subtype__c,
            SBQQ__Optional__c
          FROM SBQQ__QuoteLine__c
          WHERE Id IN :quoteLineIds
        ]
      );

      for (ContractLineItem obj : lstContractLineItem) {
        if (mapObjLine.containsKey(obj.SBQQSC__QuoteLine__c)) {
          obj.POT_Parent_Source__c = mapObjLine.get(obj.SBQQSC__QuoteLine__c).POT_Parent_Source__c;
          obj.POT_Parent_List_Price__c = mapObjLine.get(obj.SBQQSC__QuoteLine__c).POT_Parent_List_Price__c;
          //Start CPQ22-4065
          //check for RSC prodcuts
          if (
            (mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Level__c == 'Hybrid Software' ||
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Level__c == 'SaaS Software Addon' ||
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Level__c == 'Standalone Software Addon') &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Type__c != 'RZTDP' &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).SBQQ__Optional__c == false &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Subtype__c != 'Ondemand Sub Reserve' &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Subtype__c != 'Ondemand Above Reserve' &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Subtype__c != 'Scale MSP' &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Subtype__c != 'On Demand' &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Subtype__c != 'FEDRAMP' &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Subtype__c != 'E1000' &&
            mapObjLine.get(obj.SBQQSC__QuoteLine__c).Product_Type__c != 'NAS'
          ) {
            if (
              mapObjLine.get(obj.SBQQSC__QuoteLine__c).SBQQSC__RenewedContractLine__c == null &&
              mapObjLine.get(obj.SBQQSC__QuoteLine__c).RWD_Deal_Ops_Exception__c != null &&
              mapObjLine.get(obj.SBQQSC__QuoteLine__c).RWD_Deal_Ops_Exception__c.contains('AMER-FED Account quoting RSC')
            ) {
              obj.AMER_FED_Exception__c = true;
            }
            if (mapObjLine.get(obj.SBQQSC__QuoteLine__c).SBQQSC__RenewedContractLine__c != null) {
              obj.AMER_FED_Exception__c = mapObjLine.get(obj.SBQQSC__QuoteLine__c).SBQQSC__RenewedContractLine__r.AMER_FED_Exception__c;
            }
          } //end CPQ22-4065
        }
      }
    }
  }
  /***********************************************************************************
   * @description       : updateCLIFieldforGCOfferLines method which is used to update TerminatedDate / Max Commit field values on CLI
   * Project            : Scale Utility
   * JIRA(s)            : CSU-486
   * @author            : NaveenkumarSelvaraj
   * @last modified on  : 05-12-2023
   * @last modified by  : NaveenkumarSelvaraj
   * arguments          : gcIds --> GC Ids set, newCLIsMap --> Newly inserted CLI Map
   * return             : void
   * Modifications Log
   *
   *******************************************************************************/
  public static void updateCLIFieldforGCOfferLines(Set<String> gcIds, Map<Id, ContractLineItem> newCLIsMap) {
    Map<String, list<ContractLineItem>> mapOfGCIdtoLstOfCLI = new Map<String, list<ContractLineItem>>();
    List<ContractLineItem> gcOfferCLIs = new List<ContractLineItem>(
      [
        SELECT
          id,
          SBQQSC__TerminatedDate__c,
          StartDate,
          SBQQSC__QuoteLine__r.Scale_Utility_Product_Identifier__c,
          Product2.Product_Subtype__c,
          Global_Commit_ID__c,
          Product2.License_Category__c,
          SBQQSC__RevisedSubscription__c,
          Quantity,
          SBQQSC__Product__r.Product_Subtype__c,
          SBQQSC__Product__r.License_Category__c,
          SBQQSC__SegmentQuantity__c
        FROM ContractLineItem
        WHERE Global_Commit_ID__c IN :gcIds
      ]
    );
    Map<String, Decimal> maxCommitToLicense = new Map<String, Decimal>();
    Map<String, ContractLineItem> mapOfGCIdToLicenseSku = new Map<String, ContractLineItem>();
    list<ContractLineItem> gcIdToLstofONDCLI = new List<ContractLineItem>();
    Map<String, list<ContractLineItem>> gcIdToNewONDCLI = new Map<String, list<ContractLineItem>>();
    Map<Id, Contractlineitem> mapOfCLIToUpdate = new Map<Id, Contractlineitem>();
    for (ContractLineItem cli : gcOfferCLIs) {
      if (cli.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP && cli.Product2.License_Category__c == null) {
        mapOfGCIdToLicenseSku.put(cli.Global_Commit_ID__c, cli);
      }
      if (mapOfGCIdtoLstOfCLI.containskey(cli.Global_Commit_ID__c)) {
        mapOfGCIdtoLstOfCLI.get(cli.Global_Commit_ID__c).add(cli);
      } else {
        mapOfGCIdtoLstOfCLI.put(cli.Global_Commit_ID__c, new List<ContractLineItem>{ cli });
      }
      if (
        (cli.SBQQSC__QuoteLine__r.Scale_Utility_Product_Identifier__c == 'OND SR' || cli.SBQQSC__QuoteLine__r.Scale_Utility_Product_Identifier__c == 'OND AR') &&
        newCLIsMap.containskey(cli.id)
      ) {
        if (!gcIdToNewONDCLI.containskey(cli.Global_Commit_ID__c)) {
          gcIdToNewONDCLI.put(cli.Global_Commit_ID__c, new List<ContractLineItem>{ cli });
        }
        gcIdToNewONDCLI.get(cli.Global_Commit_ID__c).add(cli);
      }
      if (
        !newCLIsMap.containskey(cli.id) &&
        (cli.SBQQSC__QuoteLine__r.Scale_Utility_Product_Identifier__c == 'OND SR' ||
        cli.SBQQSC__QuoteLine__r.Scale_Utility_Product_Identifier__c == 'OND AR' ||
        (cli.SBQQSC__Product__r.Product_Subtype__c == Constants.PRODUCT_SUBTYPE_ONDEMAND &&
        cli.SBQQSC__Product__r.License_Category__c == Constants.LICENSE_CATEGORY))
      ) {
        gcIdToLstofONDCLI.add(cli);
      }
    }
    for (String gcId : mapOfGCIdtoLstOfCLI.keySet()) {
      Boolean addedRevisedQty = false;
      for (ContractLineItem relatedCli : mapOfGCIdtoLstOfCLI.get(gcId)) {
        if (
          relatedCli.SBQQSC__SegmentQuantity__c != null &&
          relatedCli.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
          relatedCli.Product2.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS &&
          ((maxCommitToLicense.containskey(gcId) && maxCommitToLicense.get(gcId) < relatedCli.SBQQSC__SegmentQuantity__c) || !maxCommitToLicense.containskey(gcId))
        ) {
          maxCommitToLicense.put(gcId, relatedCli.SBQQSC__SegmentQuantity__c);
        }
      }
    }
    for (Contractlineitem cli : gcIdToLstofONDCLI) {
      if (gcIdToNewONDCLI.containskey(cli.Global_Commit_ID__c) && gcIdToNewONDCLI.get(cli.Global_Commit_ID__c) != null) {
        cli.SBQQSC__TerminatedDate__c = gcIdToNewONDCLI.get(cli.Global_Commit_ID__c)[0].StartDate - 1;
        mapOfCLIToUpdate.put(cli.id, cli);
      }
    }

    for (String gcId : gcIdToNewONDCLI.keySet()) {
      for (contractlineitem newcli : gcIdToNewONDCLI.get(gcId)) {
        if (maxCommitToLicense.containskey(gcId)) {
          if (mapOfCLIToUpdate.containskey(newcli.id)) {
            mapOfCLIToUpdate.get(newcli.id).Max_Commit__c = maxCommitToLicense.get(gcId);
          } else {
            newcli.Max_Commit__c = maxCommitToLicense.get(gcId);
            mapOfCLIToUpdate.put(newcli.id, newcli);
          }
        }
      }
    }
    if (!mapOfCLIToUpdate.values().isEmpty()) {
      update mapOfCLIToUpdate.values();
    }
  }

  // for REEN-63
  public static void handleBeforeUpdate(List<ContractLineItem> triggerNew, Map<Id, Contractlineitem> oldMap) {
    for (ContractLineItem cli : triggerNew) {
      if (oldMap.containsKey(cli.Id) && oldMap.get(cli.Id)?.SBQQSC__RenewalQuantity__c != cli?.SBQQSC__RenewalQuantity__c) {
        cli.Resync_Line__c = 'Required';
      }
    }
  }
}