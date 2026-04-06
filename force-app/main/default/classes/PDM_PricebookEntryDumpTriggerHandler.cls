public without sharing class PDM_PricebookEntryDumpTriggerHandler extends TriggerManager.GenericTriggerHandler {
    public override void onBeforeInsert(List < sObject > newRecordsList) {
        List < PDM_PricebookEntry_Dump__c > pfList = (List < PDM_PricebookEntry_Dump__c > ) newRecordsList;
        populateProductIds(pfList);
    }
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        List < PDM_PricebookEntry_Dump__c > pfList = (List < PDM_PricebookEntry_Dump__c > ) newRecordsMap.values();
        populateProductIds(pfList);
    }

    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        Map <Id, PDM_PricebookEntry_Dump__c > pfMap = (Map <Id, PDM_PricebookEntry_Dump__c > ) newRecordsMap;
        populatePricebookEntry(pfMap);
    }

    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        Map <Id, PDM_PricebookEntry_Dump__c > pfMap = (Map <Id, PDM_PricebookEntry_Dump__c > ) newRecordsMap;
        populatePricebookEntry(pfMap);
    }



    public void populateProductIds(List < PDM_PricebookEntry_Dump__c > pfList){
        List < String > allProductCode = new List < String > ();
        String validPBs = System.Label.PDM_ValidPricebooks;
        List<String> validPBList = validPBs.split(',');
        Map < Id, List < PricebookEntry >> productToPriceEntriesMap = new Map < Id, List < PricebookEntry >> ();
        Map < String, Product2 > productNametoProductMap = new Map < String, Product2 > ();
        for (PDM_PricebookEntry_Dump__c pf: pfList) {
            if (pf.Product_Code__c != null) {
                allProductCode.add(pf.Product_Code__c);
            } else {
                pf.addError('Product Code Should Not Be Empty');
            }

        }

        for (Product2 prod: [Select Id, Name, (SELECT id, UnitPrice, IsActive, Product2Id, product2.Name, Pricebookentry_External_Id__c, Pricebook2.name from PricebookEntries where Pricebook2.name IN:validPBList) from product2 where Name In: allProductCode and Product_Master_Id__c != null]) {
            productNametoProductMap.put(prod.Name, prod);
        }

        for (PDM_PricebookEntry_Dump__c pf: pfList) {
            if (productNametoProductMap.containsKey(pf.Product_Code__c) && productNametoProductMap.get(pf.Product_Code__c) != null) {
                pf.Product__c = productNametoProductMap.get(pf.Product_Code__c).Id;
            }
        }
    }
    public void populatePricebookEntry(Map <Id, PDM_PricebookEntry_Dump__c > pfMap){
        Set<Id> productIds = new Set<Id>();
        List<PricebookEntry> peStdUpdateList = new List<PricebookEntry>();
        List<PricebookEntry> peUpdateList = new List<PricebookEntry>();
        String validPBs = System.Label.PDM_ValidPricebooks;
        List<String> validPBList = validPBs.split(',');
        Map<String,Pricebook2 > pricebookMap = new Map<String,Pricebook2 >([select id, name,IsStandard from Pricebook2 where Name IN:validPBList ]);
        Map < Id, List < PricebookEntry >> productToPriceEntriesMap = new Map < Id, List < PricebookEntry >> ();
        for (PDM_PricebookEntry_Dump__c pf: pfMap.values()) {
            productIds.add(pf.Product__c);
        }
        for (Product2 prod: [Select Id, Name, (SELECT id, UnitPrice, IsActive, Product2Id, product2.Name, Pricebookentry_External_Id__c, Pricebook2.name from PricebookEntries where Pricebook2.name IN:validPBList) from product2 where Id In: productIds and Product_Master_Id__c != null]) {
            if (prod.PricebookEntries != null && prod.PricebookEntries.size() > 0) {
                for (PricebookEntry pe: prod.PricebookEntries) {
                    if (productToPriceEntriesMap.containsKey(prod.Id)) {
                        productToPriceEntriesMap.get(prod.Id).add(pe);
                    } else {
                        productToPriceEntriesMap.put(prod.Id, new List < PricebookEntry > {
                            pe
                        });
                    }
                }

            }else{
                for (Pricebook2 pb: pricebookMap.values()) {
                    PricebookEntry tempPE = new PricebookEntry(UnitPrice = 0,IsActive = true,Product2Id = prod.Id,Pricebook2Id=pb.Id);
                    if (productToPriceEntriesMap.containsKey(prod.Id)) {
                        productToPriceEntriesMap.get(prod.Id).add(tempPE);
                    } else {
                        productToPriceEntriesMap.put(prod.Id, new List < PricebookEntry > {
                            tempPE
                        });
                    }
                }
            }
        }

        for (PDM_PricebookEntry_Dump__c pf: pfMap.values()) {
            if(productToPriceEntriesMap.containsKey(pf.Product__c) && productToPriceEntriesMap.get(pf.Product__c)!=null){
                for(PricebookEntry pe: productToPriceEntriesMap.get(pf.Product__c)){
                    pe.UnitPrice = pf.List_Price__c;
                    pe.IsActive = pf.List_Price_Status__c;
                    if(pe.Id==null && pricebookMap.containsKey(pe.Pricebook2Id) && pricebookMap.get(pe.Pricebook2Id).IsStandard){
                        peStdUpdateList.add(pe);
                    }else{
                        peUpdateList.add(pe);
                    }
                }
            }
        }

        if (peStdUpdateList.size() > 0) {     
            system.debug('peStdUpdateList >> ' + peStdUpdateList);  
            //insert peStdUpdateList;
			database.insert(peStdUpdateList,false); 
        }

        if (peUpdateList.size() > 0) {     
            system.debug('peUpdateList >> ' + peUpdateList);  
            //upsert peUpdateList;
			database.upsert(peUpdateList,false);
        }
    }
}