public without sharing class MIPAccContriTriggerHelper {
    public void participatingAccOnContract(Map<Id, MIP_Account_Contribution__c> records ){
        Set<Id> mipContractIds = new Set<Id>();
        List<MIP_Contract__c> mipContList = new List<MIP_Contract__c>();
        Map<Id,List<String>> participatingAccMap = new Map<Id, List<String>>();

        for(MIP_Account_Contribution__c rec : records.values()){
            mipContractIds.add(rec.MIP_Contract__c);
        }
        
        for(MIP_Account_Contribution__c mipContriRec : [SELECT Id,MIP_Contract__c,Partner_Account__r.Name FROM MIP_Account_Contribution__c WHERE MIP_Contract__c IN :mipContractIds]){
            if(!participatingAccMap.containsKey(mipContriRec.MIP_Contract__c)){
                participatingAccMap.put(mipContriRec.MIP_Contract__c, new List<String> {mipContriRec.Partner_Account__r.Name});
            }else{
                participatingAccMap.get(mipContriRec.MIP_Contract__c).add(mipContriRec.Partner_Account__r.Name);
            }
        }
        
        for(Id recId : participatingAccMap.keySet()){
            MIP_Contract__c mipCont = new MIP_Contract__c(Id = recId, Participating_Partner_Accounts__c = String.join(participatingAccMap.get(recId),';'));
            mipContList.add(mipCont);
        }
        
        update mipContList;
    }
    
}