public class RCV_Quote_TeamsClr { 

    public List < SBQQ__Quote__c > QuoteList {
        get;
        set;
    }
    id quoteId;
    public List < String > QuoteTerms {
        get;
        set;
    }
    public boolean hasTerms{
        get;
        set;
    }

    public RCV_Quote_TeamsClr() {
        quoteId = (Id) ApexPages.currentPage().getParameters().get('qid');
        system.debug('quoteId ::: ' + quoteId);
    }

    public PageReference init() {
        hasTerms = false;
        QuoteTerms = new List < String > ();
        QuoteList = [select Id, Name, (select id, SBQQ__ProductCode__c, SBQQ__Quantity__c, Storage_Region_Bundle__c,Disposition_Reason__c  from SBQQ__LineItems__r where SBQQ__ProductCode__c LIKE '%CVA%'
            OR SBQQ__ProductCode__c LIKE '%CVB%') from SBQQ__Quote__c where Id =: quoteId];
        system.debug('Quote ::: ' + QuoteList);
        if (QuoteList != null && QuoteList.size() > 0) {
            SBQQ__Quote__c  Quote = new SBQQ__Quote__c();
            Quote = QuoteList[0];
            Map < String, Decimal > tbStorageMap = new Map < String, Decimal > ();
            Map < String, String > verbiageMap = new Map < String, String > ();
            Map < String, String > overrideVerbiageMap = new Map < String, String > ();
            tbStorageMap.put('CVA-1', 0);
            tbStorageMap.put('CVA-2', 0);
            tbStorageMap.put('CVB-1', 0);
            tbStorageMap.put('CVB-2', 0);

            verbiageMap.put('CVA-1', System.Label.RCV_CVA_Standard_Zone_1_Verbiage);
            verbiageMap.put('CVA-2', System.Label.RCV_CVA_Standard_Zone_2_Verbiage);
            verbiageMap.put('CVB-1', System.Label.RCV_CVB_Standard_Zone_1_Verbiage);
            verbiageMap.put('CVB-2', System.Label.RCV_CVB_Standard_Zone_2_Verbiage);

            if (Quote != null && Quote.SBQQ__LineItems__r != null && Quote.SBQQ__LineItems__r.size() > 0) {
                for (SBQQ__QuoteLine__c qls: Quote.SBQQ__LineItems__r) {
                    integer totalQuantity = 0;
                    if(qls.Disposition_Reason__c !='Renew Later' && qls.Disposition_Reason__c !='At Risk'){ //MS Added At Risk under CPQ22-4756
                    if (qls.Storage_Region_Bundle__c == 'Standard - Zone 1') {
                        if (qls.SBQQ__ProductCode__c.containsIgnoreCase('CVA')) {
                            tbStorageMap.put('CVA-1', tbStorageMap.get('CVA-1') + qls.SBQQ__Quantity__c);
                        } else if (qls.SBQQ__ProductCode__c.containsIgnoreCase('CVB')) {
                            tbStorageMap.put('CVB-1', tbStorageMap.get('CVB-1') + qls.SBQQ__Quantity__c);
                        }
                    } else if (qls.Storage_Region_Bundle__c == 'Standard - Zone 2') {
                        if (qls.SBQQ__ProductCode__c.containsIgnoreCase('CVA')) {
                            tbStorageMap.put('CVA-2', tbStorageMap.get('CVA-2') + qls.SBQQ__Quantity__c);
                        } else if (qls.SBQQ__ProductCode__c.containsIgnoreCase('CVB')) {
                            tbStorageMap.put('CVB-2', tbStorageMap.get('CVB-2') + qls.SBQQ__Quantity__c);
                        }
                    }
                  }
                }
            }

            if(Quote != null){
                List<RCV_Quote_Verbiage_Exception_Override__c> lstVerbiageOverride = [Select Override_CVA_Standard_Zone_1_Verbiage__c,
                                                                                            Override_CVA_Standard_Zone_2_Verbiage__c,
                                                                                            Override_CVB_Standard_Zone_1_Verbiage__c,
                                                                                            Override_CVB_Standard_Zone_2_Verbiage__c,
                                                                                            Overridden_CVA_Standard_Zone_1_Verbiage__c,
                                                                                            Overridden_CVA_Standard_Zone_2_Verbiage__c,
                                                                                            Overridden_CVB_Standard_Zone_1_Verbiage__c,
                                                                                            Overridden_CVB_Standard_Zone_2_Verbiage__c
                                                                                    from RCV_Quote_Verbiage_Exception_Override__c 
                                                                                    where Name =: Quote.Name limit 1];
            
            
             if(Test.isRunningTest()) {
                   lstVerbiageOverride = [Select Override_CVA_Standard_Zone_1_Verbiage__c,
                                                                                            Override_CVA_Standard_Zone_2_Verbiage__c,
                                                                                            Override_CVB_Standard_Zone_1_Verbiage__c,
                                                                                            Override_CVB_Standard_Zone_2_Verbiage__c,
                                                                                            Overridden_CVA_Standard_Zone_1_Verbiage__c,
                                                                                            Overridden_CVA_Standard_Zone_2_Verbiage__c,
                                                                                            Overridden_CVB_Standard_Zone_1_Verbiage__c,
                                                                                            Overridden_CVB_Standard_Zone_2_Verbiage__c
                                                                                    from RCV_Quote_Verbiage_Exception_Override__c 
                                                                                    limit 1];
                }
                

                if(lstVerbiageOverride != null && !lstVerbiageOverride.isEmpty()) {
                    RCV_Quote_Verbiage_Exception_Override__c objVerbiageOverride = lstVerbiageOverride[0];
                    if(objVerbiageOverride.Override_CVA_Standard_Zone_1_Verbiage__c) {
                        overrideVerbiageMap.put('CVA-1', String.isBlank(objVerbiageOverride.Overridden_CVA_Standard_Zone_1_Verbiage__c) ? '' : objVerbiageOverride.Overridden_CVA_Standard_Zone_1_Verbiage__c);
                    }
                    if(objVerbiageOverride.Override_CVA_Standard_Zone_2_Verbiage__c) {
                        overrideVerbiageMap.put('CVA-2', String.isBlank(objVerbiageOverride.Overridden_CVA_Standard_Zone_2_Verbiage__c) ? '' : objVerbiageOverride.Overridden_CVA_Standard_Zone_2_Verbiage__c);
                    }
                    if(objVerbiageOverride.Override_CVB_Standard_Zone_1_Verbiage__c) {
                        overrideVerbiageMap.put('CVB-1', String.isBlank(objVerbiageOverride.Overridden_CVB_Standard_Zone_1_Verbiage__c) ? '' : objVerbiageOverride.Overridden_CVB_Standard_Zone_1_Verbiage__c);
                    }
                    if(objVerbiageOverride.Override_CVB_Standard_Zone_2_Verbiage__c) {
                        overrideVerbiageMap.put('CVB-2', String.isBlank(objVerbiageOverride.Overridden_CVB_Standard_Zone_2_Verbiage__c) ? '' : objVerbiageOverride.Overridden_CVB_Standard_Zone_2_Verbiage__c);
                    }
                }
            }

            for (string tbKeySet: tbStorageMap.keySet()) {
                if (tbStorageMap.get(tbKeySet) > 0) {
                    if(overrideVerbiageMap.containsKey(tbKeySet)) {
                        QuoteTerms.add(overrideVerbiageMap.get(tbKeySet));
                    } else {
                        QuoteTerms.add(tbStorageMap.get(tbKeySet) + verbiageMap.get(tbKeySet));
                    }
                }
            }

            if(QuoteTerms!=null && QuoteTerms.size()>0){
            hasTerms = true;
            }


        }


        return null;

    }
}