/** 
 * @Author      : Shiva Sharma
 * @TstClass    : BatchCaseRenewalTest
 * -------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1509          Shiva					   Feb 14, 2023   change reference of field Lifetime_Total_Value__c to Sum_of_Opportunities__c
 * CS21-2345          Shiva                    April 8,2024   change to include create case for renewal opportunity 
 * --------------------------------------------------------------------------------------------------------------------------------
 */
global class BatchCaseRenewal  implements Database.Batchable<sObject>, Schedulable{
    global String query;
    global Boolean skipR300;
    global Boolean legacyCode;
    public static Set<String> pFamily = new Set<String>{'R300','R500','R300S','RBK-R300','RBK-R500','R300/R6000'};
    public static Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();

    public static Map<Id,Id> oppToUpdate = new Map<Id,Id>();
    global BatchCaseRenewal (String query, Boolean skipR300){
        this.query = query;
        this.skipR300 = skipR300;
        this.legacyCode = query.containsIgnoreCase('FROM ServiceContract');
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCaseRenewal(query,skipR300));
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(query == ''){
            query += 'SELECT Id, OwnerId, Account.Name, AccountId, Partner_Lookup__r.Name, Partner_Lookup__c, Partner_SE_Phone__c, Partner_SE_Name__c, Partner_SE_Email__c, Distributor_Rep_Email__c, Distributor_Rep_Name__c, Distributor_Rep_Phone_Number__c, Distributor_Lookup__c,SBQQSC__RenewedServiceContract__c FROM Opportunity WHERE RecordType.Name = \'Renewal Opportunity\' AND Renewal_Case__c = null AND (IsClosed != true AND StageName !=\'6 PO With Channel\') AND Createddate = LAST_N_DAYS:1';        }
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Sobject> scope){
        List<Case> caseList = new List<Case>();
        if(legacyCode){
            caseList = BatchCaseRenewal.newCaseFromContracts((List<ServiceContract>)scope, skipR300);
        }else{
            caseList = BatchCaseRenewal.newCaseFromOpportunities((List<Opportunity>)scope);
        }
        // system.assert(false,caseList.size());
        if(!caseList.isEmpty()){
            CaseTriggerHandler.isRepeat = false;
            insert caseList;
            List<Opportunity> oppList = new List<Opportunity>();
            for(Case cs : caseList){
                oppList.add(new Opportunity(
                    id = cs.Opportunity_lookup__c,
                    Renewal_Case__c = cs.Id
                ));
            }
            if(!oppToUpdate.isEmpty()){
                for(Id oppId : oppToUpdate.KeySet()){
                    oppList.add(new Opportunity(
                        id = oppId,
                        Renewal_Case__c = oppToUpdate.get(oppId)
                    ));
                }
            }
            Database.SaveResult[] srList = database.update(oppList,false);
            List<Batch_Error_Log__c> errorsLogs = new List<Batch_Error_Log__c>();
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        Batch_Error_Log__c bel = new Batch_Error_Log__c();
                        bel.Failure_Job_ID__c = 'Failure on BatchCaseRenewal';
                        bel.Failure_Message__c = err.getMessage();
                        bel.Object_ID__c = sr.getId();
                        errorsLogs.add(bel);
                    }
                    
                }
            }
            if(!errorsLogs.isEmpty()){
                insert errorsLogs;
            }
        }
    }    
    global void finish(Database.BatchableContext bc){
    }
    
    private static List<Case> newCaseFromOpportunities(List<Opportunity> scope){
        List<Case> caseList = new List<Case>();
        Set<Id> opportunitiesIds = new Set<Id>();
        for(Opportunity opportunityRecord : (List<Opportunity>)scope){
            opportunitiesIds.add(opportunityRecord.Id); 
        }
        Set<Id> opportunityWithCases = new Set<Id>();
        for(Case caseRecords : [Select Id,Opportunity_lookup__c,Opportunity_lookup__r.Renewal_Case__c from Case where Opportunity_lookup__c IN: opportunitiesIds]){
            opportunityWithCases.add(caseRecords.Opportunity_lookup__c);
            if(caseRecords.Opportunity_lookup__r.Renewal_Case__c == null && !oppToUpdate.containsKey(caseRecords.Opportunity_lookup__c)){
                oppToUpdate.put(caseRecords.Opportunity_lookup__c,caseRecords.Id);
            }
        }
        for(Opportunity opportunityRecord : (List<Opportunity>)scope){
            if(!opportunityWithCases.contains(opportunityRecord.Id)){
                String descVal = System.label.Renewal_Case_Desc;
                String subject = 'Renewal Case - '+opportunityRecord.Account.Name +' ';
                String subjectDetails = opportunityRecord.Partner_Lookup__r.Name == null ? '' :' - '+opportunityRecord.Partner_Lookup__r.Name;
                
                Case caseRecord = new Case(
                    RecordTypeId = recordTypeId,
                    OwnerId = opportunityRecord.OwnerId,
                    Priority = 'P4',
                    Status = 'New',
                    Description = descVal.replace('[[Account]]',opportunityRecord.Account.Name) ,
                    AccountId = opportunityRecord.AccountId,
                    Renewal_Automated__c = true,
                    Opportunity_lookup__c = opportunityRecord.id,
                    ServiceContractId = opportunityRecord.SBQQSC__RenewedServiceContract__c,
                    Distributer_Account_Name__c =  opportunityRecord.Distributor_Lookup__c,
                    Distributer_Contact_Phone__c =  opportunityRecord.Distributor_Rep_Phone_Number__c,
                    Distributer_Contact_Name__c = opportunityRecord.Distributor_Rep_Name__c,
                    Distributer_Contact_Email__c = opportunityRecord.Distributor_Rep_Email__c,
                    Partner_Contact_Email__c =  opportunityRecord.Partner_SE_Email__c,
                    Partner_Contact_Name__c = opportunityRecord.Partner_SE_Name__c,
                    Partner_Contact_Phone__c = opportunityRecord.Partner_SE_Phone__c,
                    Partner_Account_Name__c =  opportunityRecord.Partner_Lookup__c,
                     Subject = subject + subjectDetails
                );
                caseList.add(caseRecord);
            }
        }
        return caseList;
    }
    
    private static List<Case> newCaseFromContracts(List<ServiceContract> scope, Boolean skipR300){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> contractId = new Set<Id>();
        List<Case> caseList = new List<Case>();
        Id queueId = [select Id from Group where  Type = 'Queue' AND developername= 'Renewal_Queue' LIMIT 1].Id;
        for(ServiceContract sc:scope){
            if(sc.Cases == null || sc.Cases.size() == 0){
                oppIds.add(sc.SBQQSC__Opportunity__c);
                accountIds.add(sc.AccountId);
                quoteIds.add(sc.SBQQSC__Quote__c);
                contractId.add(sc.Id);
            }
            
        }
        //Mossaic
        Map<Id,SBQQ__Quote__c> quoteMosacMap = new Map<Id,SBQQ__Quote__c>([select id ,(select id from SBQQ__LineItems__r where SBQQ__Product__r.Family = 'MOSAIC') from SBQQ__Quote__c where Id IN: quoteIds]);
        //Prior Discount
        Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>([select id ,(select id from SBQQ__LineItems__r where Approval_Discount__c = 100 AND Category__c = 'Support') from SBQQ__Quote__c where Id IN: quoteIds]);
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([SELECT Id,Account.Name,Partner_Lookup__r.Name,Initial_Contacts_Name__c,Partner_SE_Phone__c,Partner_SE_Email__c,Partner_SE_Name__c, Partner_Lookup__c,Distributor_Rep_Phone_Number__c,Distributor_Rep_Name__c,Distributor_Rep_Email__c, Distributor_Lookup__c, Valooto_Quote__c,(select id from OpportunityLineItems where (Product2.Family = 'R300' OR Product2.Family = 'R500'))  FROM Opportunity where Id IN: oppIds]);
        Map<Id,Account> accountMap = new Map<Id,Account>([SELECT id,Name, Sum_of_Opportunities__c,US_Federal_Account__c from account where Id IN: accountIds]);
        Map<Id,List<Entitlement>> contractsEntitlment = new Map<Id,List<Entitlement>>();
        for(Entitlement ent : [SELECT Id, ServiceContractId, AssetId,Asset.ProductFamily FROM Entitlement where ServiceContractId IN: contractId AND Asset.ProductFamily IN :pFamily]){
            if(!contractsEntitlment.containsKey(ent.ServiceContractId)){
                contractsEntitlment.put(ent.ServiceContractId,new List<Entitlement>());
            }
            contractsEntitlment.get(ent.ServiceContractId).add(ent);
        }
        for(ServiceContract sc:scope){
            if((sc.Cases == null || sc.Cases.size() == 0 ) && accountMap.containsKey(sc.AccountId) && accountMap.get(sc.AccountId).Sum_of_Opportunities__c < Integer.valueOf(System.Label.Renewal_Amount)){
                String descVal = System.label.Renewal_Case_Desc;
                Case cs = new Case(
                    RecordTypeId = recordTypeId,
                    OwnerId = queueId,
                    Priority = 'P4',
                    Status = 'New',
                    Description = descVal.replace('[[Account]]',accountMap.get(sc.AccountId).Name) ,
                    AccountId = sc.AccountId,
                    Renewal_Automated__c = true,
                    ServiceContractId = sc.Id
                );
                
                if(accountMap.get(sc.AccountId).US_Federal_Account__c || (quoteMap.containsKey(sc.SBQQSC__Quote__c) && quoteMap.get(sc.SBQQSC__Quote__c).SBQQ__LineItems__r != null && (quoteMap.get(sc.SBQQSC__Quote__c).SBQQ__LineItems__r.size() > 0 || quoteMosacMap.get(sc.SBQQSC__Quote__c).SBQQ__LineItems__r.size() > 0))){
                    continue;
                }
                
                if(!skipR300 && opportunityMap.containsKey(sc.SBQQSC__Opportunity__c) && opportunityMap.get(sc.SBQQSC__Opportunity__c).OpportunityLineItems != null && opportunityMap.get(sc.SBQQSC__Opportunity__c).OpportunityLineItems.size() > 0){
                    continue;
                }
                if(!skipR300 && contractsEntitlment.containsKey(sc.Id) && contractsEntitlment.get(sc.Id).size() > 0 ){
                    Continue;
                }
                if(opportunityMap.containsKey(sc.SBQQSC__Opportunity__c  ) && opportunityMap.get(sc.SBQQSC__Opportunity__c).Valooto_Quote__c  == null){
                    Opportunity opp = opportunityMap.get(sc.SBQQSC__Opportunity__c);
                    cs.Distributer_Account_Name__c =  opp.Distributor_Lookup__c;
                    cs.Distributer_Contact_Phone__c =  opp.Distributor_Rep_Phone_Number__c;
                    cs.Distributer_Contact_Name__c = opp.Distributor_Rep_Name__c;
                    cs.Distributer_Contact_Email__c = opp.Distributor_Rep_Email__c;
                    cs.Partner_Contact_Email__c =  opp.Partner_SE_Email__c;
                    cs.Partner_Contact_Name__c = opp.Partner_SE_Name__c;
                    cs.Partner_Contact_Phone__c = opp.Partner_SE_Phone__c;
                    cs.Partner_Account_Name__c =  opp.Partner_Lookup__c;
                    cs.Subject = 'Renewal Case - '+opp.Account.Name;
                    cs.Subject += opp.Partner_Lookup__r.Name == null ? '' :' - '+opp.Partner_Lookup__r.Name;
                    caseList.add(cs); 
                }
            }
        }
        return caseList;
    }
}