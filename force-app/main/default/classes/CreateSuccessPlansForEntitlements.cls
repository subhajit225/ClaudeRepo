/**
 * @description  : CreateSuccessPlansForEntitlements Creates Success Plan records for Accounts based on the start and end dates of active Entitlements
 * @testClass    : CreateSuccessPlansQueueableTest
 * @author       : Vijay Kumar K R
 * ---------------------------------------------------- @History --------------------------------------------------------------------------------------------
 * Story Number       Modified By        Date           Description
 * CS21-3139          Vijay K R          June 18, 2025  CEM Success Plan Enhancements
 * */
public with sharing class CreateSuccessPlansForEntitlements {
    
    /**
     * @description  : Create Success Plan for Account based on Entitlement Start and End Dates
     * @param entitlements 
     */
    public static void processEntitlementIdsForSucessPlan(Set<Entitlement> entitlements) {

        Map<Id, Date> erliestStartDateByAccIdMap = new Map<Id, Date>();
        Map<Id, Date> latestEndDateByAccIdMap = new Map<Id, Date>();
        Set<Id> accIdSet = new Set<Id>();

        for (Entitlement objEnt : entitlements) {
            accIdSet.add(objEnt.AccountId);
            if (objEnt.StartDate != null) {
                if (!erliestStartDateByAccIdMap.containsKey(objEnt.AccountId) || objEnt.StartDate < erliestStartDateByAccIdMap.get(objEnt.AccountId)) {
                    erliestStartDateByAccIdMap.put(objEnt.AccountId, objEnt.StartDate);
                }
            }
            if (objEnt.EndDate != null) {
                if (!latestEndDateByAccIdMap.containsKey(objEnt.AccountId) || objEnt.EndDate > latestEndDateByAccIdMap.get(objEnt.AccountId)) {
                    latestEndDateByAccIdMap.put(objEnt.AccountId, objEnt.EndDate);
                }
            }
        }

        // Fetch existing Success Plans to avoid duplicates
        Map<Id, Set<Integer>> existingPlanYearsByAccount = new Map<Id, Set<Integer>>();
        if(Schema.sObjectType.Success_Plan__c.isAccessible()){
            for (Success_Plan__c objSc : [ SELECT Name, Account__c FROM Success_Plan__c WHERE Account__c IN :accIdSet ]) {
                String scname = objSc.Name;

                if(!scname.containsIgnoreCase('QBR / RBR / EBC') && !scname.containsIgnoreCase('CEM Renewal Touch')){
                    continue;
                }
                // extract the last 4 digits from the name 
                String[] parts = scname.split('-');
                String yearVal = parts[1].trim();

                if (!existingPlanYearsByAccount.containsKey(objSc.Account__c)) {
                    existingPlanYearsByAccount.put(objSc.Account__c, new Set<Integer>());
                }
                existingPlanYearsByAccount.get(objSc.Account__c).add(Integer.valueOf(yearVal));
            }
        }


        List<Success_Plan__c> plansToInsert = new List<Success_Plan__c>();
        for (Id accountId : erliestStartDateByAccIdMap.keySet()) {
            Date minStart = erliestStartDateByAccIdMap.get(accountId);
            Date maxEnd = latestEndDateByAccIdMap.get(accountId);
            if (minStart == null || maxEnd == null) continue;

            Integer startYear = minStart.year();
            Integer endYear = maxEnd.year();

            for (Integer yr = startYear; yr <= endYear; yr++) {
                // Skip if Success Plan already exists for this year
                if (existingPlanYearsByAccount.containsKey(accountId) 
                    && existingPlanYearsByAccount.get(accountId).contains(yr)) {
                        continue; 
                }
                // Insert 4 QBR / RBR / EBC records 
                plansToInsert.add(new Success_Plan__c(Name = 'QBR / RBR / EBC 1 - ' + yr, Account__c = accountId));
                plansToInsert.add(new Success_Plan__c(Name = 'QBR / RBR / EBC 2 - ' + yr, Account__c = accountId));
                plansToInsert.add(new Success_Plan__c(Name = 'QBR / RBR / EBC 3 - ' + yr, Account__c = accountId));
                plansToInsert.add(new Success_Plan__c(Name = 'QBR / RBR / EBC 4 - ' + yr, Account__c = accountId));
                // Only create the CEM Renewal Touch plan for the END year
                if (yr == endYear) {
                    plansToInsert.add(new Success_Plan__c(Name = 'CEM Renewal Touch - ' + yr, Account__c = accountId));
                }
            }
        }

        if (!plansToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(plansToInsert, false); 

            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Error inserting Success_Plan__c from Class CreateSuccessPlansForEntitlements: ' + err.getMessage());
                    }
                }
            }
        }

    }
}