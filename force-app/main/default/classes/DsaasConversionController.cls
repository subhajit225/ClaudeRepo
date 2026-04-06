public with sharing class DsaasConversionController {
    Id quoteId;
    public List<SBQQ__QuoteLine__c> quoteLineItems { get; set;}
    public String Verbaige1 { get; set; }
    public String Verbaige2 { get; set; }
    public boolean showSplitVerbaige {get; set; }
    public boolean showNoSplitVerbaige {get; set; }
    public DsaasConversionController() {
        quoteId = (id)ApexPages.currentPage().getParameters().get('qid');
        system.debug('quoteId' +quoteId );
        showSplitVerbaige = false;
        showNoSplitVerbaige = false;
        init();
    }
    public void init() {
        if (quoteId != null) {
            Map<Id,String> rcvParentMapSplit = new Map<Id,String>();         
            Map<Id,String> rcvParentMapSplitNoSplit = new Map<Id,String>();  
            quoteLineItems = [SELECT Id, SBQQ__Quote__r.RWD_Deal_Ops_Exception_Justification__c,SBQQ__Quote__r.Quoting_Desk_Exception_Justification__c,SBQQ__Product__r.Name ,Product_Type__c,SBQQ__RequiredBy__c,SBQQSC__RenewedContractLine__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Name,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Custom_Renewal_Type__c,SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Is_Split_in_Polaris_2_0__c
                              FROM SBQQ__QuoteLine__c
                              WHERE SBQQ__Quote__c = :quoteId];
            if (!quoteLineItems.isEmpty()) {
                for(SBQQ__QuoteLine__c item : quoteLineItems){
                        //Sort RCV products
                        if(item.Product_Type__c != null && item.Product_Type__c.contains('Cloud Vault') && item.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Is_Split_in_Polaris_2_0__c == true){   
                            rcvParentMapSplit.put(item.SBQQ__RequiredBy__c,item.SBQQ__Product__r.Name);
                            system.debug('rcvParentMapSplit'+rcvParentMapSplit.size());
                        }else if(item.Product_Type__c != null && item.Product_Type__c.contains('Cloud Vault') && item.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Is_Split_in_Polaris_2_0__c == false){
                            rcvParentMapSplitNoSplit.put(item.Id,item.SBQQ__Product__r.Name);
                            system.debug('rcvParentMapSplitNoSplit'+rcvParentMapSplitNoSplit.size());
                        }
                    }
                Integer cnt = 0;
                String rcvNames;
                String rcvNamesNoSplit;
                String parentNames;
                String oldProdNames;
                String oldProdNamesNoSplit;
                for (SBQQ__QuoteLine__c item : quoteLineItems) {
                    if((item.SBQQ__Quote__r.Quoting_Desk_Exception_Justification__c != null && item.SBQQ__Quote__r.Quoting_Desk_Exception_Justification__c != '') && item.SBQQ__Quote__r.Quoting_Desk_Exception_Justification__c.contains('DSAAS conversion')){
                        //Sort target products
                        cnt = cnt + 1;
                        if(item.SBQQ__RequiredBy__c == null && item.SBQQSC__RenewedContractLine__c != null && item.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Custom_Renewal_Type__c == 'DSAAS'){                           
                            if(rcvParentMapSplit.containsKey(item.id)){
                                 rcvNames = rcvNames != null ?  rcvNames + ' , '+ rcvParentMapSplit.get(item.id) : rcvParentMapSplit.get(item.id);
                                 parentNames = parentNames != null ? parentNames + ' , ' + item.SBQQ__Product__r.Name : item.SBQQ__Product__r.Name;
                                 oldProdNames = oldProdNames != null ? oldProdNames + ' , ' + item.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Name : item.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Name;                                
                            }else if(rcvParentMapSplitNoSplit.containsKey(item.id)){
                                rcvNamesNoSplit = rcvNamesNoSplit != null ?  rcvNamesNoSplit + ' , '+ rcvParentMapSplitNoSplit.get(item.id) : rcvParentMapSplitNoSplit.get(item.id);
                                oldProdNamesNoSplit = oldProdNamesNoSplit != null ? oldProdNamesNoSplit + ' , ' + item.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Name : item.SBQQSC__RenewedContractLine__r.SBQQSC__Product__r.Name; 
                            }
                            
                        }
                    }
                }
                Verbaige1 = 'The former UCL+RCV bundle SKU [' + oldProdNames + '] is available for renewal only as its unbundled products, UCL SKU [' + parentNames + '] and RCV SKU [' + rcvNames + '] as shown on this Quote.';
                
                Verbaige2 = 'The former UCL+RCV bundle SKU [' + oldProdNamesNoSplit + '] is available for renewal only as its unbundled product, RCV SKU [' + rcvNamesNoSplit + '] as shown on this Quote.';
                
                if(cnt > 0 && String.isNotBlank(oldProdNames) && String.isNotBlank(parentNames) && String.isNotBlank(rcvNames)){
                    showSplitVerbaige = true;
                }
                if(cnt > 0 && String.isNotBlank(oldProdNamesNoSplit) && String.isNotBlank(rcvNamesNoSplit)){
                    showNoSplitVerbaige = true;
                }
                
            } 
        }
    }
}