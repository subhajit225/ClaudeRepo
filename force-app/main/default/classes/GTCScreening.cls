public without sharing class GTCScreening {

    private Set<ID> gtcScreeningOrderSet = new Set<ID>();
    private Map<ID, Set<String>> orderIdAccountNameWordsMap = new Map<ID, Set<String>>();
    private Map<ID, Set<String>> orderIdShipToNameWordsMap = new Map<ID, Set<String>>();
    private Map<ID, Set<String>> orderIdShipToContactNameWordsMap = new Map<ID, Set<String>>();
    private string onHoldReason;
    private static List<GTC_Screening__c> gtcScreeningList = new List<GTC_Screening__c>();
    private static set<string> excludeWords = new set<string>();

    public void initGTCScreening(List<Order> newOrderList, Map<ID, Order> oldOrderMap, Map<ID, Account> accountMap){
        Set<String> countryCodeSet = new Set<String>();
        Set<String> nameAllWordSet = new Set<String>();
        Set<String> nameWordSet = null;
        
        if(excludeWords.isEmpty()){
          for(GTC_Screening__c screen : [select Party_Name__c from GTC_Screening__c where Type__c='Exclude']){
             if(screen.Party_Name__c != null)
              excludeWords.add(screen.Party_Name__c.toLowerCase());
          }
        }
        for(Order newOrder: newOrderList){
            Order oldOrder = oldOrderMap?.get(newOrder.id);
            if((newOrder.Internal_Order_Stage__c == 'Pending Validation' && newOrder.Internal_Order_Stage__c != oldOrder.Internal_Order_Stage__c)
            || (newOrder.Sync_to_NetSuite__c == true && oldOrder.Sync_to_NetSuite__c == false)){
                gtcScreeningOrderSet.add(newOrder.id);
                Account accObj = accountMap.get(newOrder.AccountId);
                countryCodeSet.add(newOrder.ShippingCountryCode);
                countryCodeSet.add(accObj.BillingCountryCode);
                
                nameWordSet = getWordSet(accObj.Name);
                orderIdAccountNameWordsMap.put(newOrder.id, nameWordSet);
                nameAllWordSet.addAll(nameWordSet);

                nameWordSet = getWordSet(newOrder.Ship_To_Name__c);
                orderIdShipToNameWordsMap.put(newOrder.id, nameWordSet);
                nameAllWordSet.addAll(nameWordSet);

                nameWordSet = getWordSet(newOrder.ShipToContactName__c);
                orderIdShipToContactNameWordsMap.put(newOrder.id, nameWordSet);
                nameAllWordSet.addAll(nameWordSet);
            }
        }
        countryCodeSet.remove(null);
        nameAllWordSet.remove(null);
        system.debug('nameAllWordSet'+nameAllWordSet);
        system.debug('countryCodeSet'+countryCodeSet);
        if(!gtcScreeningOrderSet.isEmpty()){
            gtcScreeningList = [select Id,Party_Name__c,CountryCode__c from GTC_Screening__c where Type__c = 'Include' AND Party_Name__c LIKE :nameAllWordSet AND CountryCode__c IN :countryCodeSet];
            System.debug(gtcScreeningOrderSet + '\n'+ JSON.serialize(nameAllWordSet) +'\n'+countryCodeSet + '\n'+ JSON.serialize(gtcScreeningList));
        }
    }

    public void processGTCScreening(Order newOrder,account acc){
        if(gtcScreeningOrderSet.contains(newOrder.Id)){
            Set<String> nameWordSet = null;
            Set<string>blackListedAddress = new set<string>(); //{BillToAcc,ShipToAcc,ShipToContact,ShipToName}
            onHoldReason ='';
            newOrder.Is_RPS_Required__c = false;
            for(GTC_Screening__c gtcRec: gtcScreeningList){
                if(String.isBlank(newOrder.ShippingCountryCode)  || newOrder.ShippingCountryCode ==  gtcRec.CountryCode__c){
                    if(!blackListedAddress.contains('ShipToAcc')){
                    if(orderIdAccountNameWordsMap.containsKey(newOrder.Id) ){
                        scanOrder(newOrder,blackListedAddress, gtcRec, orderIdAccountNameWordsMap.get(newOrder.Id), 'ShipToAcc');
                       system.debug('blackListedAddress'+blackListedAddress);
                    }
                    else{
                      onHoldReason+= 'Account Name is blank';
                    }
                    }
                    if(!blackListedAddress.contains('ShipToName')){
                    if(orderIdShipToNameWordsMap.containsKey(newOrder.Id)){
                        scanOrder(newOrder,blackListedAddress, gtcRec, orderIdShipToNameWordsMap.get(newOrder.Id), 'ShipToName');
                    }
                    else{
                     onHoldReason+= 'Ship to name is blank';
                    }
                    } 
                    if(!blackListedAddress.contains('ShipToContact')){
                    if(orderIdShipToContactNameWordsMap.containsKey(newOrder.Id)){
                        scanOrder(newOrder,blackListedAddress, gtcRec, orderIdShipToContactNameWordsMap.get(newOrder.Id), 'ShipToContact');
                    }
                    else{
                     onHoldReason+= 'Ship to contact name is blank';
                    }
                 }    
                }
                    if(!blackListedAddress.contains('BillToAcc') && (String.isBlank(acc.BillingCountryCode) ||  acc.BillingCountryCode ==  gtcRec.CountryCode__c)){
                       if(orderIdAccountNameWordsMap.containsKey(newOrder.Id)){
                        scanOrder(newOrder, blackListedAddress,gtcRec, orderIdAccountNameWordsMap.get(newOrder.Id), 'BillToAcc');
                      }
                    }
                if(blackListedAddress.contains('BillToAcc') && blackListedAddress.contains('ShipToAcc') && blackListedAddress.contains('ShipToContact') && blackListedAddress.contains('ShipToName')){
                  break;
                }
            }
             if(string.isNotBlank(onHoldReason)){
                  if(onHoldReason.length()>131072){
                    onHoldReason = onHoldReason.substring(0,131072);
                  }  
                    newOrder.ScreenStatus__c ='On hold';
                    newOrder.Screening_Notes__c = onHoldReason;
                    newOrder.Hold_Code__c = String.isBlank(newOrder.Hold_Code__c) ? 'Global Trade Compliance Screening' : !newOrder.Hold_Code__c.contains('Global Trade Compliance Screening') ? newOrder.Hold_Code__c+';Global Trade Compliance Screening': newOrder.Hold_Code__c;
                    newOrder.Order_Status__c ='On Hold';
                }
            else{
                newOrder.ScreenStatus__c ='Approved';
                newOrder.Sync_to_NetSuite__c = true;
            }
             newOrder.Internal_Order_Stage__c='Order Submitted';
        }
    }

    private void scanOrder(Order newOrder,Set<string>blackListedAddress, GTC_Screening__c gtcRec, Set<String> nameWordSet, String screeningType){
            for(String wordStr: nameWordSet){
                wordStr = wordStr.replaceAll('%', '');
                System.debug(wordStr + ' - ' + gtcRec.Party_Name__c + '\n' + onHoldReason+'screenedAddress'+blackListedAddress+'\n screeningType'+screeningType);
                if(!excludeWords.contains(wordStr.toLowerCase()) && String.isNotBlank(gtcRec.Party_Name__c) && gtcRec.Party_Name__c.containsIgnoreCase(wordStr)){
                    onHoldReason +=  +screeningType +' - '+wordStr+' ; Ref: '+gtcRec.id+'\n';
                    blackListedAddress.add(screeningType);
                    break;
                }
            }
            
    }
    private static Set<String> getWordSet(String searchStr){
        Set<String> wordSet = new Set<String>();
        if(String.isNotBlank(searchStr)){
            searchStr = searchStr.replaceAll('\\s+',' ');
            searchStr = searchStr.replaceAll(',', ' ');
            searchStr = searchStr.replaceAll('-', ' ');
            List<String> wordList = searchStr.split(' ');
            for(String s: wordList){
                if(String.isNotBlank(s) && s.length() > 3 && !excludeWords.contains(s.toLowerCase())){
                    wordSet.add('%' + String.escapeSingleQuotes(s) + '%');
                }
            }
            if(wordSet.isEmpty()){
                wordSet.add('%' + String.escapeSingleQuotes(searchStr) + '%');
            }
        }
        system.debug('searchStr'+searchStr+'wordSet'+wordSet);
        return wordSet;
    } 
}