/****************************************************************************

* @description       : Order trigger handler
* @author            : Chaitra
* @last modified on  : 01-20-2022
* @last modified by  : Chaitra
* Modifications Log
* Ver   Date          Author        Modification
* 1.0   01-20-2022   Chaitra        Initial Version 
* 2.0   24-08-2022   Sailaja        ASPEN1B-247-ASN Quote based Validations
***************************************************************************/

public class ShipmentDetailHandler extends TriggerHandler {

    private static ShipmentDetailHandler instance = null;  
    public ShipmentDetailHelper helper;
    public set<Error_Logs__c> errorLogs = new Set<Error_Logs__c>();
    public static Boolean isASNValidationDisabled = false; 
    private ShipmentDetailHandler(){
        helper = ShipmentDetailHelper.getInstance();
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isASNValidationDisabled = disabled.Disable_Shipment_Detail__c;
    }
    
    /****************************************
    Description : get Instance of class
    *****************************************/
    
    public static ShipmentDetailHandler getInstance() {
        if (instance == null)
        instance = new ShipmentDetailHandler();
        return instance;
    }
    
    /*********************************************************************************
    Before Insert
    Desciption :
    *********************************************************************************/
    public override void beforeInsert() {
    }
    /**********************************************************************************
    Before Update
    Desciption :
    ***********************************************************************************/
    public override void beforeUpdate() {
        // PRDOPS24-1089
        Map<String, ShipmentDetail__c> existingOverviews = new Map<String, ShipmentDetail__c>();
        Map<String, List<ShipmentDetail__c>> quoteNameVsSDList = new Map<String, List<ShipmentDetail__c>>();
        Set<Id> quoteIds = new Set<Id>();
        Set<String> quoteNumbers = new Set<String>(); 
        Map<String, String> quoteNameVsId = new Map<String, String>();
        Map<String, ShipmentDetail__c> shpMap = new Map<String, ShipmentDetail__c>();
        Map<String, ShipmentDetail__c> shpToValidateMap = new Map<String, ShipmentDetail__c>();
        boolean sendEmail = false;
        Map<String, ShipmentDetail__c> quoteIdVsOverviewSD = new Map<String, ShipmentDetail__c>();
        for(ShipmentDetail__c newSD : (List<ShipmentDetail__c>)Trigger.new) {
            ShipmentDetail__c oldSD = (ShipmentDetail__c) Trigger.oldMap?.get(newSD.id);
            if(newSD.RecordTypeId == Constants.overViewRecordTypeId && newSD.Quote__c != null &&
                (newSD.Quote_ShipmentValidation__c == 'Start' || newSD.Quote_ShipmentValidation__c == 'Start with Email') && 
                (newSD.Quote_ShipmentValidation__c != oldSD.Quote_ShipmentValidation__c)) {
                quoteIds.add(newSD.Quote__c);
                quoteIdVsOverviewSD.put(newSD.Quote__c, newSD);
                if (newSD.Quote_ShipmentValidation__c == 'Start with Email') {
                    sendEmail = true; 
                } else {
                    sendEmail = false;
                }
            }else if (newSD.RecordTypeId != Constants.overViewRecordTypeId && (newSD.Quote__c != null || newSD.QuoteNumber__c != null)) {
                if(newSD.Quote__c != null) { 
                    quoteIds.add(newSD.Quote__c); 
                } else {
                    quoteNumbers.add(newSD.QuoteNumber__c);
                }
                if(quoteNameVsSDList.containsKey(newSD.QuoteNumber__c)) {
                    quoteNameVsSDList.get(newSD.QuoteNumber__c).add(newSD);
                } else {
                    quoteNameVsSDList.put(newSD.QuoteNumber__c, new List<ShipmentDetail__c>{newSD});
                }
            }
        }
        for (SBQQ__Quote__c quote :  [SELECT Id, Name, Opportunity_Stage__c, ProcessType__c  FROM SBQQ__Quote__c WHERE Id IN:quoteIds OR Name IN: quoteNumbers]) {
            if (
                (isASNValidationDisabled == false ||
                 (quote.Opportunity_Stage__c != '6 PO With Channel' &&
                  quote.Opportunity_Stage__c != '7 Closed Won' &&
                  quote.Opportunity_Stage__c != '7 Closed Admin')) &&
                  quote.ProcessType__c == 'Aspen'
            ) {
                quoteNameVsId.put(quote.Name, quote.Id);
            }                         
        }
        if(!quoteNameVsId.isEmpty()) {
         shpMap = new Map<String, ShipmentDetail__c>(
                    [SELECT
                        id,
                        Quote__c,
                        Quote__r.Name,
                        Status__c,
                        QuoteNumber__c,
                        SalesOrderNumber__c,
                        order__c,
                        ProductName__c,
                        ProcessHistory__c,
                        Quantity__c,
                        Quote_Line__c,
                        Quote_Item_Ids__c,
                        HW_SerialNumber__c,
                        ShippedDate__c,
                        ContractManufacturer__c,
                        Name,
                        RecordTypeId,
                        Parent_Shipment_Detail__c,
                        Quote_ShipmentValidation__c,
                        Quote_MissingShipmentDetails__c
                        FROM ShipmentDetail__c
                        WHERE
                        ((QuoteNumber__c IN :quoteNameVsId.keySet() OR Quote__c IN : quoteNameVsId.values())
                        AND RecordTypeId !=: Constants.overViewRecordTypeId
                        AND (Status__c = 'New'
                            OR Status__c = 'Failed'
                            OR Status__c = 'Internal Failure')) OR (Quote__r.Name =: quoteNameVsSDList.keySet() AND RecordType.Name = 'Overview')
                    ]);
        }
        if (!shpMap.isEmpty()) {
            for (ShipmentDetail__c sd : shpMap.values()) {
                if (sd.RecordTypeId == Constants.overViewRecordTypeId) {
                    existingOverviews.put(sd.Quote__r.Name, sd);
                }else{
                    shpToValidateMap.put(sd.Id, sd);
                }
            }
        }
        if (!quoteNameVsSDList.isEmpty()) {
            helper.createOverviewRecord(quoteNameVsSDList, existingOverviews, quoteNameVsId);
        }
        if(shpToValidateMap != null && !shpToValidateMap.values().isEmpty() && !quoteIdVsOverviewSD.isEmpty()) {
            helper.Init(shpToValidateMap.values()); 
            helper.ProcessShipmentInfoUpdated(shpToValidateMap.values(),sendEmail,quoteIdVsOverviewSD,quoteNameVsId);        
        } else {
            helper.Init(null);
            helper.ProcessShipmentInfoUpdated(null,true,quoteIdVsOverviewSD,quoteNameVsId);      
        }  
        helper.CommitBeforeInsertUpdateRec();                 
      }         
    }