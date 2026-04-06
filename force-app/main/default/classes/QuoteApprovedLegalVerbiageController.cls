/*
Author : Ashwini Borse
Description : As part of POC implemented under CPQ22-4591
Date : 02/09/2024
*/
public class QuoteApprovedLegalVerbiageController{
    @AuraEnabled(cacheable=true)
    public static List<Quote_Approved_Legal_Verbiage__mdt> getData(){
       	system.debug('method');
        return [SELECT Id, Approved_Legal_Language_Name__c, Approved_Legal_Verbiage__c from Quote_Approved_Legal_Verbiage__mdt ];
    }
    
    @AuraEnabled
    public static Map<String,String> updateQuote(List<Quote_Approved_Legal_Verbiage__mdt> legalList, String recId){
        Map<String,String> retMap = new Map<String,String>();
        SBQQ__Quote__c quote = [SELECT Id,Name,SBQQ__Account__r.Name,Legal_Approved_Verbiage__c FROM SBQQ__Quote__c WHERE Id =:recId];
        system.debug('legalList '+legalList);
        system.debug('recId '+recId);
        String legal = quote.Legal_Approved_Verbiage__c != null ? quote.Legal_Approved_Verbiage__c+'\n': '' ;
        for(Quote_Approved_Legal_Verbiage__mdt custMeta : legalList){
            legal += '\r\n'+custMeta.Approved_Legal_Verbiage__c.replace('<COMPANY>',quote.SBQQ__Account__r.Name).replace('<#XXXXX>',quote.Name)+'\n';
            system.debug('After Company legal '+legal);
            
        }
        try{
            if(legal.length() <= 131072){
        		update new SBQQ__Quote__c(Id=recId,Legal_Approved_Verbiage__c = legal);
            }else{
                retMap.put('Error','Legal verbiage Field Character Limit Has Reached. Please Remove Duplicates and try again.');
            }
        }catch(System.Exception e){
			retMap.put('Error',e.getMessage());
        }
        return retMap;
    }
}