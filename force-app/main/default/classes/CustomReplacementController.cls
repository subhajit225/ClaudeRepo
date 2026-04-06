/**
 * @author Paritosh
 * @Date Created/Modified: 06/05/25
 * @description Controller for CustomReplacementPage
 * @Story FY25SR-1092
 */
public with sharing class CustomReplacementController {

    /** @description show custom replacement table */
    public Boolean showCustomReplacementTable {get; set;}
    /** @description replacement table rows wrapper list */
    public List<RowWrapper> rowWrapperList {get; set;}
    /** @description custom replacement label */
    public String customReplacementLabel {get; set;}
    /** @description template */
    public SBQQ__QuoteTemplate__c template {get; set;}

    /**
     * @description Contructor
     */
    public CustomReplacementController() {

        try {

            Id quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
            Id templateId = ApexPages.currentPage().getParameters().get('tid');
            List<Id> orderLineIds = new List<Id>();
            Map<String, ReplacementWrapper> ReplacementWrapperByKey = new Map<String, ReplacementWrapper>();
            showCustomReplacementTable = false;
            rowWrapperList = new List<RowWrapper>();
            template = getTemplate(templateId);

            //CPQ22-6040 get verbiages from quote terms
            Map<String, String> labelMap = QuoteDocumentHelper.getVerbiages(quoteId);

            List<SBQQ__QuoteLine__c>  quoteLines = [
                SELECT Id, Prepayment_Credit__c, SBQQ__ProductCode__c, Disposition_Reason__c, Special_Program__c, Arroyo_Subsumed_Old_Contract_Line_Items__c,
                Replacement_Details__c, SBQQSC__RenewedContractLine__c, SBQQSC__RenewedContractLine__r.SBQQSC__Quantity__c, 
                SBQQ__Quantity__c, SBQQSC__RenewedContractLine__r.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name,
                SBQQSC__RenewedContractLine__r.SBQQSC__OrderProduct__r.Order.OrderNumber, SBQQSC__RenewedContractLine__r.StartDate, SBQQSC__RenewedContractLine__r.EndDate,
                SBQQSC__RenewedContractLine__r.SBQQSC__ProductName__c, SBQQ__Quote__r.SBQQ__Account__c
                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =:quoteId];

            Id accountId = quoteLines.size() > 0 ? quoteLines[0].SBQQ__Quote__r?.SBQQ__Account__c : null;

            List<SBQQ__QuoteLine__c> replacementLines = new List<SBQQ__QuoteLine__c>();
            
            for (SBQQ__QuoteLine__c quoteLine : quoteLines){
                if (quoteLine.Special_Program__c == 'Conversion' || quoteLine.Special_Program__c == 'Upgrade'){
                    replacementLines.add(quoteLine);

                    if (quoteLine.Prepayment_Credit__c > 0){
                        showCustomReplacementTable = true;
                    }

                    //create row wrappers
                    if (quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c != null){
                        String key = quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c;
                        if (!ReplacementWrapperByKey.containsKey(key)){
                            ReplacementWrapperByKey.put(key, new ReplacementWrapper());
                        }
                        ReplacementWrapper replacementWrap = ReplacementWrapperByKey.get(key);
                        ReplacementSKUWrapper replacementSKUWrap = new ReplacementSKUWrapper();
                        replacementSKUWrap.productCode = quoteLine.SBQQ__ProductCode__c;
                        replacementSKUWrap.quantity = Math.round(quoteLine.SBQQ__Quantity__c);
                        replacementWrap.replacementSKUs.add(replacementSKUWrap);

                    }
                }
            }

            List<Order_Item_Extension__c> orderItemExtensions = QuoteDocumentHelper.getOrderItemExtensionRecords(replacementLines);

            for (Order_Item_Extension__c orderItemExtension : orderItemExtensions){
                if (orderItemExtension.Unbilled__c || orderItemExtension.Unpaid__c){
                    showCustomReplacementTable = true;
                    break;
                }
            }

            if (showCustomReplacementTable){
                //CPQ22-6053 start
                Replacement_Field_Mapping__mdt objectData=
                    Replacement_Field_Mapping__mdt.getInstance(
                        ReplacementConstants.REPLACEMENT_ENTITLEMENT_MDT);
                String firstWhereClause= objectData.First_Filter_Criteria__c;
                String secondWhereClause= objectData.Second_Filter_Criteria__c;
                String thirdWhereClause= objectData.Third_Filter_Criteria__c;
                String query='SELECT Id, Name, Quantity__c, Product__r.Name, Product__r.Product_Level__c,Product__r.ProductCode, ' +
                    'StartDate, EndDate, ' +
                    'ContractLineItem.Product_Level__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Name, ' +
                    'ContractLineItem.SBQQSC__OrderProduct__r.Order.OrderNumber, ' +
                    'ContractLineItem.StartDate, ContractLineItem.Related_End_Date__c, ' +
                    'ContractLineItem.SBQQSC__Quantity__c ' +
                    'FROM Entitlement WHERE AccountId =:accountId AND '
                    + firstWhereClause + ' '+ secondWhereClause + ' '+ thirdWhereClause;
                
                List<Entitlement> entList = Database.query(query.trim());
                Map<Id, Entitlement> entMap = new Map<Id, Entitlement>(entList);
                //CPQ22-6053 end

                for (SBQQ__QuoteLine__c quoteLine : quoteLines){
                    if ((quoteLine.Disposition_Reason__c == 'Upgraded' || quoteLine.Disposition_Reason__c == 'Converted') && quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c != null){
                        for (String key : ReplacementWrapperByKey.keySet()){
                            if (key.contains(quoteLine.Arroyo_Subsumed_Old_Contract_Line_Items__c)){
                                ReplacementWrapper replacementWrap = ReplacementWrapperByKey.get(key);
                                ReplacedSKUWrapper replacedSKUWrap = new ReplacedSKUWrapper();
                                populateReplacedSKU(quoteLine, replacedSKUWrap,entMap);//CPQ22-6053
                                replacementWrap.replacedSKUs.add(replacedSKUWrap);

                                //populate inactive ents
                                for (Id inactiveEntId : replacedSKUWrap.inactiveQtyMap.KeySet()){
                                    if (entMap.containsKey(inactiveEntId)){//CPQ22-6053
                                        Entitlement inactiveEnt = entMap.get(inactiveEntId);//CPQ22-6053
                                        ReplacedSKUWrapper replacedSKUWrapInactive = new ReplacedSKUWrapper();
                                        populateInactiveEnt(inactiveEnt, replacedSKUWrap, replacedSKUWrapInactive);
                                        replacementWrap.replacedSKUs.add(replacedSKUWrapInactive);
                                    }
                                }
                            }
                        }
                    }
                }

                for (ReplacementWrapper replaceWrapper : ReplacementWrapperByKey.values()){
                    //one to many
                    if (replaceWrapper.replacementSKUs.size() > 1){
                        List<RowWrapper> newRows = new List<RowWrapper>();
                        for (ReplacementSKUWrapper replacementSKUWrap : replaceWrapper.replacementSKUs){
                            RowWrapper rowWrap = new RowWrapper();
                            rowWrap.replacementSKUWrap = replacementSKUWrap;
                            newRows.add(rowWrap);
                        }
                        if (newRows.size() > 0 && replaceWrapper.replacedSKUs.size() > 0){
                            newRows[0].replacedSKUWrap = replaceWrapper.replacedSKUs[0];
                            newRows[0].rowSpanReplaced = replaceWrapper.replacementSKUs.size();
                            rowWrapperList.addAll(newRows);
                        }
                    }
                    //many to one
                    else if (replaceWrapper.replacedSKUs.size() > 1){
                        List<RowWrapper> newRows = new List<RowWrapper>();
                        for (ReplacedSKUWrapper replacedSKUWrap : replaceWrapper.replacedSKUs){
                            RowWrapper rowWrap = new RowWrapper();
                            rowWrap.replacedSKUWrap = replacedSKUWrap;
                            newRows.add(rowWrap);
                        }
                        if (newRows.size() > 0 && replaceWrapper.replacementSKUs.size() > 0){
                            newRows[0].replacementSKUWrap = replaceWrapper.replacementSKUs[0];
                            newRows[0].rowSpanReplacement = replaceWrapper.replacedSKUs.size();
                            rowWrapperList.addAll(newRows);
                        }
                    }
                    //one to one
                    else {
                        RowWrapper rowWrap = new RowWrapper();
                        if (replaceWrapper.replacementSKUs.size() > 0 && replaceWrapper.replacedSKUs.size() > 0){
                            rowWrap.replacementSKUWrap = replaceWrapper.replacementSKUs[0];
                            rowWrap.replacedSKUWrap = replaceWrapper.replacedSKUs[0];
                            rowWrapperList.add(rowWrap);
                        }
                    }
                }

                customReplacementLabel = labelMap.get('Custom_Replacement_Label');
            }

            if (rowWrapperList == null || rowWrapperList.size() == 0){
                showCustomReplacementTable = false;
            }
        }
        catch(Exception e){
            LogError.logCustomError('CustomReplacementController', e.getMessage(), e.getStackTraceString(), 'CustomReplacementController controller');
        }
    }

    /**@description replacement info wrapper*/
    public class ReplacementWrapper{
        List<ReplacedSKUWrapper> replacedSKUs = new List<ReplacedSKUWrapper>();
        List<ReplacementSKUWrapper> replacementSKUs = new List<ReplacementSKUWrapper>();
    }

    /** @description replaced sku wrapper*/
    public class ReplacedSKUWrapper{
        /** @description productcode*/
        public String productCode {get; set;}
        /** @description replaced assets*/
        public String assets {get; set;}
        /** @description original qty*/
        public Decimal purchasedQty {get; set;}
        /** @description replaced qty*/
        public Decimal terminatedQty {get; set;}
        /** @description remaining qty*/
        public Decimal survivingQty {get; set;}
        /** @description original quote*/
        public String originalQuote {get; set;}
        /** @description original order*/
        public String originalOrder {get; set;}
        /** @description original start date*/
        public String originalStartDate {get; set;}
        /** @description original end date*/
        public String originalEndDate {get; set;}
         /** @description inactiveQtyMap*/
        public Map<Id,Decimal> inactiveQtyMap {get; set;}
    }

    /** @description replacement sku wrapper*/
    public class ReplacementSKUWrapper{
        /** @description product code*/
        public String productCode {get; set;}
        /** @description quantity*/
        public Decimal quantity {get; set;}
    }

    /**
     * @description row wrapper
     */
    public class RowWrapper{
        /** @description replaced sku wrapper*/
        public ReplacedSKUWrapper replacedSKUWrap {get; set;}
        /** @description replacement sku wrapper*/
        public ReplacementSKUWrapper replacementSKUWrap {get; set;}
        /** @description row span replaced cells*/
        public Integer rowSpanReplaced {get; set;}
        /** @description row span replacement cells*/
        public Integer rowSpanReplacement {get; set;}

        /** @description constructor*/
        public RowWrapper(){
            rowSpanReplaced = 1;
            rowSpanReplacement = 1;
        }
    }

    /**
     * @description get template info
     * @param templateId template id
     * @return template record
     */
    public SBQQ__QuoteTemplate__c getTemplate(Id templateId){
        return [SELECT Id, SBQQ__FontFamily__c, SBQQ__FontSize__c, SBQQ__ShadingColor__c FROM SBQQ__QuoteTemplate__c WHERE Id = :templateId];
    }

    /**
     * @description populate replaced sku details
     * @param quoteLine quote line
     * @param replacedSKUWrap : replaced SKU wrapper
     * @param entMap //CPQ22-6053
     */
    public void populateReplacedSKU(SBQQ__QuoteLine__c quoteLine, ReplacedSKUWrapper replacedSKUWrap,Map<Id, Entitlement> entMap){//CPQ22-6053
        try {
            Decimal selectedQty=0;
            //Decimal intSelectedQty=0;
            Integer assetCount = 0;
            Id entId; //CPQ22-6053  
            if (quoteLine.Replacement_Details__c != null){
                ReplacementJson replaceWrapper = (ReplacementJson) JSON.deserialize(quoteLine.Replacement_Details__c, ReplacementJson.class);
                String assetNames = '';
               // replacedSKUWrap.inactiveEnts = new List<Id>();
                replacedSKUWrap.inactiveQtyMap = new Map<Id,Decimal>();
                for (ReplacementJson.RowDetail rowDetail : replaceWrapper.rowValues){
                    if(rowDetail.entId!=null){
                       entId = rowDetail.entId;//CPQ22-6053 
                       selectedQty += rowDetail.selectedQty;//CPQ22-6053
                    }
                    if (rowDetail.selectedAssetList != null){
                        for (String assetName : rowDetail.selectedAssetList.values()){
                            assetNames += assetName + ', ';
                            assetCount ++;
                        }
                    }
                    if (rowDetail.inactiveLines != null){
                        for (ReplacementJson.RelatedChildEntRowDetail childDetail : rowDetail.inactiveLines){
                            //intSelectedQty += childDetail.childQnty;
                            replacedSKUWrap.inactiveQtyMap.put(childDetail.childEntId,childDetail.childQnty);
                            //replacedSKUWrap.inactiveEnts.add(childDetail.childEntId);
                        }
                    }
                }
                assetNames = assetNames.removeEnd(', ');
                replacedSKUWrap.assets = assetNames;
               // replacedSKUWrap.inactiveSelectedQty=intSelectedQty;
            } 
             //CPQ22-6053 start
            if (entId != null && entMap.containsKey(entId)){
                Entitlement ent = entMap.get(entId);
                replacedSKUWrap.productCode = ent.Product__r.Name;
                replacedSKUWrap.purchasedQty = ent.Quantity__c != null ? Math.round(ent.Quantity__c) : 0;
                if (ent.Product__r.Product_Level__c == null) {
                    replacedSKUWrap.terminatedQty = (assetCount != 0) ? assetCount : Math.round(selectedQty);
                } else {
                    replacedSKUWrap.terminatedQty = Math.round(selectedQty);
                }
                 replacedSKUWrap.originalStartDate = String.valueOf(ent.ContractLineItem.StartDate);
                replacedSKUWrap.originalEndDate = String.valueOf(ent.ContractLineItem.Related_End_Date__c);
            }
            //CPQ22-6053 end
            
            replacedSKUWrap.survivingQty = replacedSKUWrap.purchasedQty != null ? Math.round(replacedSKUWrap.purchasedQty - replacedSKUWrap.terminatedQty) : 0;
            replacedSKUWrap.originalQuote = quoteLine.SBQQSC__RenewedContractLine__r?.SBQQSC__QuoteLine__r?.SBQQ__Quote__r?.Name;
            replacedSKUWrap.originalOrder = quoteLine.SBQQSC__RenewedContractLine__r?.SBQQSC__OrderProduct__r?.Order?.OrderNumber;


        }
        catch(Exception e){
            LogError.logCustomError('CustomReplacementController', e.getMessage(), e.getStackTraceString(), 'CustomReplacementController controller');
        }
    }

    /**
     * @description populate inactive ent
     * @param inactiveEnt inactive ent
     * @param replacedSKUWrap : replaced SKU wrapper
     * @param inactiveWrapper : inactive SKU wrapper
     */
    public void populateInactiveEnt(Entitlement inactiveEnt, ReplacedSKUWrapper replacedSKUWrap, ReplacedSKUWrapper inactiveWrapper){
        try {
            Integer assetCount =replacedSKUWrap.assets!=null ? replacedSKUWrap.assets.split(',').size() : 0;//FY25SR-2432
            inactiveWrapper.assets = replacedSKUWrap.assets;
            inactiveWrapper.productCode = inactiveEnt.Product__c!=null ? inactiveEnt.Product__r.ProductCode : replacedSKUWrap.productCode;
            if (inactiveEnt.Product__r.Product_Level__c == null) { //FY25SR-2432
                inactiveWrapper.terminatedQty = (assetCount != 0) ? Math.round(assetCount)  : Math.round(replacedSKUWrap.inactiveQtyMap.get(inactiveEnt.Id));
            } else {
                inactiveWrapper.terminatedQty =Math.round(replacedSKUWrap.inactiveQtyMap.get(inactiveEnt.Id));
            }
            //CPQ22-6053 start
            inactiveWrapper.purchasedQty = inactiveEnt.Quantity__c != null ? Math.round(inactiveEnt.Quantity__c) : 0;
            inactiveWrapper.survivingQty = inactiveWrapper.purchasedQty != null ? Math.round(inactiveWrapper.purchasedQty - inactiveWrapper.terminatedQty) : 0;
            inactiveWrapper.originalQuote = inactiveEnt.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__Quote__r?.Name;
            inactiveWrapper.originalOrder = inactiveEnt.ContractLineItem?.SBQQSC__OrderProduct__r?.Order?.OrderNumber;
            inactiveWrapper.originalStartDate = String.valueOf(inactiveEnt.StartDate);
            inactiveWrapper.originalEndDate = String.valueOf(inactiveEnt.EndDate);
            //CPQ22-6053 end
        }
        catch(Exception e){
            LogError.CreateGenericErrorLog('CustomReplacementController', e, 'CustomReplacementController controller');
        }
    }

}