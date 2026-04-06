/**
 * @description POS Report trigger helper
 */ 
public class POSReportTriggerHelper {
        
    public static Id ACC_RECORD_TYPE_CUSTOMER = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Prospect').getRecordTypeId();

    //SAL25-65
    /**
     * @description populate fields on POS report before insert/update
     * @param POSRecords
     * @param OldPOSRecordsMap
     */ 
    public static void populatePOSReportFields(List<POS_Report__c> POSRecords, Map<Id,POS_Report__c> OldPOSRecordsMap){
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        for(POS_Report__c pos : POSRecords){
            POS_Report__c oldPOS = OldPOSRecordsMap?.get(pos.Id);
            if(oldPOS == null || pos.Account__c != oldPOS.Account__c) accountIds.add(pos.Account__c);
            if(oldPOS == null || pos.DR_Partner_of_Record_ID__c != oldPOS.DR_Partner_of_Record_ID__c) accountIds.add(pos.DR_Partner_of_Record_ID__c);
        }

        if(!accountIds.IsEmpty()){
            accountMap = new Map<Id,Account>([Select Id,OwnerId,ETM_Theatre__c, ETM_Area__c,ETM_Region__c,ETM_Territory__c,Type From Account Where Id IN:accountIds]); //SAL26-79:added Type field
        }
        for(POS_Report__c pos : POSRecords){
            POS_Report__c oldPOS = OldPOSRecordsMap?.get(pos.Id);
            //populate Account TART values
            if(oldPOS == null || pos.Account__c != oldPOS.Account__c){
                if(pos.Account__c != null && accountMap != null && accountMap.containsKey(pos.Account__c)){
                    Account accRec = accountMap.get(pos.Account__c);
                    pos.AE__c = accRec.OwnerId;
                    pos.AE_Theatre__c = accRec.ETM_Theatre__c;
                    pos.AE_Area__c = accRec.ETM_Area__c;
                    pos.AE_Region__c = accRec.ETM_Region__c;
                    pos.AE_Territory__c = accRec.ETM_Territory__c;
                }
                else pos.AE__c = pos.AE_Theatre__c = pos.AE_Area__c = pos.AE_Region__c = pos.AE_Territory__c = null;
            }
            //populate DR Partner of Record TART values
            if(oldPOS == null || pos.DR_Partner_of_Record_ID__c != oldPOS.DR_Partner_of_Record_ID__c){
                if(pos.DR_Partner_of_Record_ID__c != null && accountMap != null && accountMap.containsKey(pos.DR_Partner_of_Record_ID__c)){
                    Account accRec = accountMap.get(pos.DR_Partner_of_Record_ID__c);
                    pos.Theatre__c = accRec.ETM_Theatre__c;
                    pos.Area__c = accRec.ETM_Area__c;
                    pos.Region__c = accRec.ETM_Region__c;
                    pos.Territory__c = accRec.ETM_Territory__c;
                }
                else pos.Theatre__c = pos.Area__c = pos.Region__c = pos.Territory__c = null;
            }
            
            //SAL26-79
            if((oldPOS == null || pos.Account__c != oldPOS.Account__c) && pos.Account__c != null && accountMap != null && accountMap.containsKey(pos.Account__c)){
                Account accRec = accountMap.get(pos.Account__c);
                if(String.isNotBlank(accRec.Type) && accRec.Type.equals('Prospect')){
                    pos.Opportunity_Type__c = 'New Customer';
                    pos.Deal_Initiated_Type__c = 'Partner Sourced New Logo (PSNL)';
                } else {
                    pos.Opportunity_Type__c = 'Existing Customer';
                    pos.Deal_Initiated_Type__c = 'Partner Sourced Expand';
                }
            }
        }
    }
    
    //SAL26-79
    /**
     * @description populate fields on POS report after insert/update
     * @param POSRecords
     * @param OldPOSRecordsMap
     */ 
    public static void populatePOSReportFieldsAfterInsertUpdate(List<POS_Report__c> POSRecords, Map<Id,POS_Report__c> OldPOSRecordsMap){
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Set<Id> oldAccountIds = new Set<Id>();
        for(POS_Report__c pos : POSRecords){
            POS_Report__c oldPOS = OldPOSRecordsMap?.get(pos.Id);
            if(oldPOS == null || pos.Account__c != oldPOS.Account__c || (pos.Partner_Lookup_Acct_ID__c != oldPOS.Partner_Lookup_Acct_ID__c && pos.Partner_Lookup_Acct_ID__c != null)) accountIds.add(pos.Account__c);
        }

        if(!accountIds.IsEmpty()){
            accountMap = new Map<Id,Account>([SELECT Id,Type,MSP_Account_Lookup__c,Shared_MSP_Customer__c,RecordTypeId FROM Account WHERE Id IN:accountIds]);
        }
 
        Map<Id, Account> accoutsToUpdateMap = new Map<Id, Account>(); 
        
        for(POS_Report__c pos : POSRecords){
            POS_Report__c oldPOS = OldPOSRecordsMap?.get(pos.Id);
            //if Partner_Lookup_Acct_ID or Account is changed on POS report
            if((oldPOS == null || pos.Account__c != oldPOS.Account__c || pos.Partner_Lookup_Acct_ID__c != oldPOS.Partner_Lookup_Acct_ID__c) && pos.Account__c != null && accountMap != null && accountMap.containsKey(pos.Account__c)){
                Account accRec = accountMap.get(pos.Account__c);
                if(accRec.MSP_Account_Lookup__c != pos.Partner_Lookup_Acct_ID__c && pos.Partner_Lookup_Acct_ID__c != null){
                    accRec.MSP_Account_Lookup__c = pos.Partner_Lookup_Acct_ID__c;
                    accoutsToUpdateMap.put(accRec.Id, accRec);
                }
                //SAL26-313
                if(accRec.Shared_MSP_Customer__c == false && pos.End_Date__c >= System.today() && accRec.RecordTypeId == ACC_RECORD_TYPE_CUSTOMER){
                    accRec.Shared_MSP_Customer__c = true;
                    accoutsToUpdateMap.put(accRec.Id, accRec);
                }
            }
        }
        if(!accoutsToUpdateMap.isEmpty()){
            UPDATE accoutsToUpdateMap.values();
        }	        
    }
}