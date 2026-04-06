/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description This class contains various helper methods to handle business logic related to the Risk Profile object, 
 *               including risk profile assignment, validation, owner change, notification handling, and case creation.
 *               The methods in this class are invoked by triggers associated with the Risk Profile object.
 * @TestClass - RiskProfileTriggerHandlerTest
 * RRR-156 - Made DNT enhancements as if DNT RP is there on account then new RP should not trigger using Automation			Date 09 Jan, 2026		Shailesh Kumar
 */
public class RiskProfileTriggerHelper {
    
    private static final Set<String> CLOSED_STATUSES = new Set<String>{
        'Mitigated', 'Entitlement Expired', 'Entitlement Churn', 
        'Account Churn', 'Lost', 'At Risk', 'Partially Mitigated', 'Downsell',
        'CX health score improved', 'No Risk', 'Invalid', 'Requires modification of CX Score Logic',
         'No mitigation possible', 'Less time to mitigate'
    };

    /**
     * @description Populates Earliest_Renewal_Opportunity__c on Risk_Profile__c when Account__c is set (insert)
     * or changed (update) by finding the earliest Renewal_Due_Date__c among related opportunities.
     * @param newList List of new Profiles
     * @param oldMap Map of old Risk Profile records
     */
    public static void populateEarliestRenewalOpportunity(List<Risk_Profile__c> newList, Map<Id, Risk_Profile__c> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Risk_Profile__c> riskProfileByAccount = new Map<Id, Risk_Profile__c>();

        for (Risk_Profile__c rp : newList) {
            if (Trigger.isInsert && rp.Account__c != null) {
                accountIds.add(rp.Account__c);
            }
            else if (Trigger.isUpdate) {
                Risk_Profile__c oldRp = oldMap.get(rp.Id);
                if (rp.Account__c != oldRp.Account__c && rp.Account__c != null) {
                    accountIds.add(rp.Account__c);
                }
            }
        }
	
        if (accountIds.isEmpty()) return;

        // Query earliest opportunity for each Account
        Map<Id, Opportunity> earliestOppByAccount = new Map<Id, Opportunity>();
        List<Opportunity> opps = [
            SELECT Id, AccountId, Renewal_Due_Date__c
            FROM Opportunity
            WHERE AccountId IN :accountIds
                AND Renewal_Due_Date__c != null
                AND RecordType.DeveloperName = 'Renewal_Opportunity'
                AND StageName NOT IN ('7 Closed Won', '7 Closed Lost', '7 Closed Admin')
                AND Renewal_Due_Date__c >= TODAY
            ORDER BY AccountId, Renewal_Due_Date__c ASC
            ];


        for (Opportunity opp : opps) {
            if (!earliestOppByAccount.containsKey(opp.AccountId)) {
                earliestOppByAccount.put(opp.AccountId, opp);
            }
        }

        // Set field on risk profile
        for (Risk_Profile__c rp : newList) {
            Boolean isRelevantUpdate = (oldMap != null && rp.Account__c != oldMap.get(rp.Id).Account__c);

            if ((Trigger.isInsert && rp.Account__c != null) || isRelevantUpdate) {
                Opportunity earliestOpp = earliestOppByAccount.get(rp.Account__c);
                rp.Earliest_Renewal_Opportunity__c = earliestOpp?.Id;
            }
        }
    }
	
     /**
     * @description populate CXClosureScores for risk profile
     * @param newList List of new Profiles
     * @param oldMap Map of old Risk Profile records
     */
    public static void populateCXScore(List<Risk_Profile__c> newList, Map<Id, Risk_Profile__c> oldMap) {
        Set<Id> accountIdsToQuery = new Set<Id>();
        //Map<Id, Risk_Profile__c> riskProfilesToUpdateMap = new Map<Id, Risk_Profile__c>();
        List<Risk_Profile__c> riskProfilesToUpdate = new List<Risk_Profile__c>();
        for (Risk_Profile__c rp : newList) {
            if (Trigger.isUpdate && rp.Account__c != null) {
                Boolean isClosed = CLOSED_STATUSES.contains(rp.Risk_Status__c);
                Risk_Profile__c oldRp = oldMap.get(rp.Id);
                // Only act if status changed to a "closed" value
                if (rp.Risk_Status__c != oldRp.Risk_Status__c && isClosed) {
                    accountIdsToQuery.add(rp.Account__c);
                    //riskProfilesToUpdateMap.put(rp.Id, rp);
                    riskProfilesToUpdate.add(rp);
                }
            }
            if(Trigger.isInsert && rp.Account__c != null){
                accountIdsToQuery.add(rp.Account__c);
                //riskProfilesToUpdateMap.put(rp.Id, rp);
                riskProfilesToUpdate.add(rp);
            }
        }

        if (accountIdsToQuery.isEmpty()) return;

        Map<Id, Account_Risk__c> accountMap = new Map<Id, Account_Risk__c>();
        // Query Account details
        for(Account_Risk__c accr : [SELECT Id, CX_Score_Status__c, OnBoarding_Score__c,Adoption_Score__c, Product_Score__c, Support_Score__c, CX_Score__c,Account__c
                                           FROM Account_Risk__c WHERE Account__c IN :accountIdsToQuery]){
                                             accountMap.put(accr.Account__c,accr);  
                                           }

        for (Risk_Profile__c rp : riskProfilesToUpdate) {
            Account_Risk__c accRisk = accountMap.get(rp.Account__c);
            Boolean noSync = false;
            if (accRisk == null) noSync = true;

            String cxScore = 'Health Status: '    + (noSync ? 'null' : String.ValueOf(accRisk.CX_Score_Status__c)) + '\n'
                           + 'CX score: '         + (noSync ? 'null' : String.ValueOf(accRisk.CX_Score__c?.setScale(2))) + '\n'
                           + 'Onboarding score: ' + (noSync ? 'null' : String.ValueOf(accRisk.OnBoarding_Score__c?.setScale(2))) + '\n'
                           + 'Adoption score: '   + (noSync ? 'null' : String.ValueOf(accRisk.Adoption_Score__c?.setScale(2))) + '\n'
                           + 'Product score: '    + (noSync ? 'null' : String.ValueOf(accRisk.Product_Score__c?.setScale(2))) + '\n'
                           + 'Support score: '    + (noSync ? 'null' : String.ValueOf(accRisk.Support_Score__c?.setScale(2))) ;

            if(Trigger.isInsert){
                rp.CXScoreCreation__c = cxScore;
            }
            if(Trigger.isUpdate){
                rp.CXScoreClosure__c = cxScore;
            }

        }
    }


    /**
     * @description Removes the Risk Profile from the associated Opportunity
     * @param oldRecordMap List of deleted Risk Profile records mapped to Id
     */
    public static void removeRiskProfileFromOpportunity(Map<Id, Risk_Profile__c> oldRecordMap){
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Set<Id> opportunityIds = new Set<Id>();
        for (Risk_Profile__c rp : oldRecordMap.values()) {
            if (rp.Risk_Origin__c == 'Opportunity' && rp.Opportunity__c != null) {
                opportunityIds.add(rp.Opportunity__c);
            }
        }

        for(Opportunity opp : [SELECT Id, Risk_Profile__c FROM Opportunity WHERE Id IN :opportunityIds]) {
            if(String.isBlank(opp.Risk_Profile__c)){
                continue;
            }
            String latestRiskProfileOnOppId = CS_AutomaticRiskProfileCreation.extractId(opp.Risk_Profile__c);
            if(oldRecordMap.containsKey(latestRiskProfileOnOppId)){
                opportunitiesToUpdate.add(new Opportunity(Id = opp.Id, Risk_Profile__c = null));
            }
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            Database.update(opportunitiesToUpdate, false);
        }
    }

     /**
     * @description Attaches the Risk Profile to the associated Opportunity by creating a hyperlink to the Risk Profile record.
     * @param newRiskProfiles List of newly inserted Risk Profile records
     */
    public static void attachRiskProfileToOpportunity(List<Risk_Profile__c> newRiskProfiles){
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for(Risk_Profile__c rp : newRiskProfiles) {
            if(rp.Opportunity__c != null && rp.Risk_Origin__c == 'Opportunity') {
                String hyperlink = String.format('<a href="{0}/{1}" target="_self">{2}</a>', new List<Object>{System.Url.getOrgDomainUrl(), rp.Id, rp.Name});
                opportunities.add(new Opportunity(Id = rp.Opportunity__c, Risk_Profile__c = hyperlink));
            }
        }
        
        update opportunities;
    }
    
    /**
     * @description Changes the owner of the Risk Profiles based on specific business rules.
     * @param newRiskProfiles List of newly inserted or updated Risk Profile records
     */
    public static void changeRPOwner(List<Risk_Profile__c> newRiskProfiles) {
        List<Risk_Profile__c> nonDNTRiskProfiles = new List<Risk_Profile__c>();
        for(Risk_Profile__c rp : newRiskProfiles) {
            if(!rp.hasErrors()) {
                nonDNTRiskProfiles.add(rp);
            }
        }
        Set<Id> accountIds = getAccountIds(nonDNTRiskProfiles);
        Map<Id, List<Risk_Profile__c>> accountRiskMap = getExistingRiskProfiles(accountIds, 'changeRPOwner');
        assignOwners(nonDNTRiskProfiles, accountRiskMap);
    }

    /**
     * @description Checks for existing Risk Profiles and applies business rules to avoid duplication.
     * @param newRiskProfiles List of newly inserted or updated Risk Profile records
     */
    public static void checkExistingRP(List<Risk_Profile__c> newRiskProfiles) {
        Set<Id> accountIds = getAccountIds(newRiskProfiles);
        Map<Id, List<Risk_Profile__c>> accountRiskMap = getExistingRiskProfiles(accountIds, 'checkExistingRP');
        checkNewRPDataWithExisting(newRiskProfiles, accountRiskMap);
    }

    /**
     * @description Validates that a Risk Profile cannot be created if an active Risk Profile with 'Do Not Trigger' is already present.
     * @param newRiskProfiles List of newly inserted or updated Risk Profile records
     */
    public static void validateDoNotTrigger(List<Risk_Profile__c> newRiskProfiles) {
        Map<Id,Risk_Profile__c> dntRiskProfileMap = new Map<Id,Risk_Profile__c>();
        Set<Id> accIdList = new Set<Id>();
        for(Risk_Profile__c rp : newRiskProfiles){
             if(rp.Risk_Origin__c == 'Account') {
                accIdList.add(rp.Account__c);
            }
        }
        for(Risk_Profile__c existingRiskProfile : [SELECT Id,Name,Risk_Origin__c,Account__c,Opportunity__c FROM Risk_Profile__c WHERE Account__c IN : accIdList AND Do_Not_Trigger__c = true]) {
                dntRiskProfileMap.put(existingRiskProfile.Account__c, existingRiskProfile);
        }
        if(dntRiskProfileMap.isEmpty()) {
           return;
        }

        for(Risk_Profile__c newRiskProfile : newRiskProfiles) {
            if(newRiskProfile.Risk_Origin__c == 'Account') {
                Risk_Profile__c existingRiskProfile = dntRiskProfileMap.get(newRiskProfile.Account__c);
                if(existingRiskProfile != null) {
                    newRiskProfile.addError('Can\'t create record when Account has active Risk Profile '+existingRiskProfile.Name+' with Do Not Trigger set to true.');
                }
            }
        }
    }
    
    /**
     * @description Creates a new Case for valid Risk Profiles with status 'Valid'.
     * @param newRiskProfiles List of newly inserted Risk Profile records
     * @param oldRecordMap Map of old Risk Profile records before the update
     */
    public static void createCaseforValidRP(List<Risk_Profile__c> newRiskProfiles, Map<Id, Risk_Profile__c> oldRecordMap) {
        List<Case> caseList = new List<Case>();
        Id RETENTION_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Retention_Case').getRecordTypeId();
        Set<Id> setIds = new Set<Id>();
        for (Risk_Profile__c rp : newRiskProfiles) {
            setIds.add(rp.Id);
        }
        for (Risk_Profile__c rp : newRiskProfiles) {
            Risk_Profile__c oldRiskRecord = oldRecordMap.get(rp.Id);
            if(rp.Mitigation_Case_Number__c == null && rp.Risk_Validation_Status__c == 'Valid' && oldRiskRecord.Risk_Validation_Status__c != rp.Risk_Validation_Status__c){
                caseList.add(createCaseList(rp,RETENTION_RECORD_TYPE_ID));
            }
        }
        
        if(!caseList.isEmpty()){
            try{
                insert caseList ;
                updateRPCaseNumber(caseList);
                updateRiskProfileEntitlements(caseList);
            }catch(Exception e){
                insertErrorLogs('case',e.getMessage(),'RiskProfileTriggerHelper','createCaseforValidRP');
            }
        }
    }
    
    /**
     * @description Creates a new Case record based on Risk Profile data.
     * @param rp Risk Profile record to be used for creating the Case
     * @param RETENTION_RECORD_TYPE_ID The Record Type Id for 'Retention Case'
     * @return Case The newly created Case record
     */
    private static Case createCaseList(Risk_Profile__c rp, Id RETENTION_RECORD_TYPE_ID) {
        Case cs = new Case();
        cs.AccountId = rp.Account__c;
        cs.Description = rp.Comments__c;
        cs.Origin = 'Retention';
        cs.RecordTypeId = RETENTION_RECORD_TYPE_ID;
        cs.Risk_Profile__c = rp.Id;
        cs.Subject = rp.Name;
        cs.Risk_Category__c = rp.Risk_Category__c;
        cs.Risk_Type__c = rp.Risk_Type__c;
        cs.Primary_Risk_Reason__c = rp.Primary_Risk_Reason__c;
        cs.Secondary_Risk_Reason__c = rp.Secondary_Risk_Reason__c;
        cs.Risk_Reason_Additional_Comments__c = rp.Risk_Reason_Additional_Comments__c;
        cs.Risk_Level__c = rp.Risk_Level__c;
        cs.Risk_Priority__c = rp.Risk_Priority__c;
        cs.Risk_Validation_Status__c = rp.Risk_Validation_Status__c;
        // Removed since we now have multiple entitlements
        //cs.Entitlement__c = rp.Entitlement__c;
        cs.ACV_At_Risk__c = rp.ACV_At_Risk__c;
        cs.OwnerId = rp.OwnerId;
        cs.Risk_Comments__c = rp.Comments__c;
        cs.Risk_Status__c = rp.Risk_Status__c;
        cs.Subject = 'Retention Case - ' + rp.Name;
        cs.Risk_Opportunity__c = rp.Opportunity__c;
        cs.Top_100__c=rp.Top_100__c;
        cs.Health_Assessment__c=rp.HealthAssessment__c;
        return cs;
    }
    
    /**
     * @description Updates the Risk Profile with the associated Case number after creation.
     * @param caseList List of Case records to update the Risk Profile with the created Case number
     */
    private static void updateRPCaseNumber(List<Case> caseList) {
        List<Risk_Profile__c> rpListToUpdate = new List<Risk_Profile__c>();
        
        for(case cs : caseList){
            Risk_Profile__c risk = new Risk_Profile__c();
            risk.Id = cs.Risk_Profile__c;
            risk.Mitigation_Case_Number__c = cs.Id;
            rpListToUpdate.add(risk);
        }
        if(!rpListToUpdate.isEmpty()){
            try{
                update rpListToUpdate;
            }catch(Exception e){
                insertErrorLogs('Risk Profile',e.getMessage(),'RiskProfileTriggerHelper','updateRPCaseNumber');
            }
        }
        
    }
    /**
     * @description Updates the Risk Profile Entitlements with Case Id after Mitigation Case creation.
     * @param caseList List of Case records to update the Risk Profile Entitlement with the created Case number
     */
    private static void updateRiskProfileEntitlements(List<Case> caseList) {
        Map<Id,Id> riskToCase = new Map<Id,Id>();
        for(case cs : caseList){
            riskToCase.put(cs.Risk_Profile__c, cs.Id);
        }
        
        List<Risk_Profile_Entitlement__c> rpes = new List<Risk_Profile_Entitlement__c>();
        for(Risk_Profile_Entitlement__c rpe : [SELECT Id,Risk_Profile__c FROM Risk_Profile_Entitlement__c WHERE Risk_Profile__c IN :riskToCase.keyset()]){
            rpes.add(new Risk_Profile_Entitlement__c(Id = rpe.Id, Case__c = riskToCase.get(rpe.Risk_Profile__c)));
        }
        
        try{

            update as user rpes;
        }
        catch(Exception e){
            insertErrorLogs('Risk Profile',e.getMessage(),'RiskProfileTriggerHelper','updateRiskProfileEntitlements');
        }
        
    }
    
     /**
     * @description Logs errors encountered during the process into the Error Logs object.
     * @param objectName Name of the object where the error occurred
     * @param errorMsg Error message details
     * @param className Class name where the error occurred
     * @param methodName Method name where the error occurred
     */
    private static void insertErrorLogs(String objectName, String errorMsg, String className, String methodName) {
        Error_Logs__c err = new Error_Logs__c(Object__c = objectName,
                                              Error_Message__c = errorMsg,
                                              Class__c = className,
                                              Method__c = methodName,
                                              Type__c = 'SFDC',
                                              Success__c = false);
        insert err;
    }
    
    /**
     * @description Retrieves Account Ids from a list of Risk Profiles.
     * @param riskProfiles List of Risk Profile records
     * @return Set<Id> Set of Account Ids associated with the Risk Profiles
     */
    private static Set<Id> getAccountIds(List<Risk_Profile__c> riskProfiles) {
        Set<Id> accountIds = new Set<Id>();
        for (Risk_Profile__c rp : riskProfiles) {
            if (rp.Account__c != null) {
                accountIds.add(rp.Account__c);
            }
        }
        return accountIds;
    }    
    
    /**
     * @description Assigns owners to the Risk Profiles based on a round-robin mechanism or existing owners.
     * @param newRiskProfiles List of newly inserted Risk Profile records
     * @param accountRiskMap Map of existing Risk Profiles grouped by Account Id
     */
    private static void assignOwners(List<Risk_Profile__c> newRiskProfiles, Map<Id, List<Risk_Profile__c>> accountRiskMap) {
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName =: System.Label.Risk_Profile_Governance_Queue LIMIT 1];
        List<GroupMember> members = [SELECT UserOrGroupId,UserOrGroup.Employee_Time_Off__c FROM GroupMember WHERE GroupId = :queue.Id AND UserOrGroup.isActive = true Order By SystemModstamp, Id ASC];
        
        Risk_Profile_Assignment__c roundRobin = Risk_Profile_Assignment__c.getOrgDefaults();
        Integer currentIndex = roundRobin.Last_Assigned_Index__c != null ? Integer.valueOf(roundRobin.Last_Assigned_Index__c) : 0;
        
        for (Risk_Profile__c rp : newRiskProfiles) {
            List<Risk_Profile__c> existingProfileList = accountRiskMap.containsKey(rp.Account__c) ? accountRiskMap.get(rp.Account__c) : new List<Risk_Profile__c>();

            RiskConflictType conflict = getRiskConflict(rp, existingProfileList);
            if (conflict == RiskConflictType.NONE) {        
                // if (!existingProfileList.isEmpty()) {
                //     rp.OwnerId = existingProfileList[0].OwnerId;
                String ownerIdFromExisting = existingProfileList.isEmpty() ? null : (existingProfileList[0].Owner.IsActive ? existingProfileList[0].OwnerId : null);
                if(String.isNotBlank(ownerIdFromExisting)){
                    rp.OwnerId = ownerIdFromExisting;
                } else if (!members.isEmpty()) {
                    Integer availableIterations = members.size();
                    while(members[currentIndex].UserOrGroup.Employee_Time_Off__c && availableIterations > 0) {
                        currentIndex = updateCurrentIndex(currentIndex, members.size());
                        availableIterations--;
                    }
                    rp.OwnerId = members[currentIndex].UserOrGroupId;
                    currentIndex = updateCurrentIndex(currentIndex, members.size());
                }
            } else {
                String errorMessage = System.Label.Risk_Analysis_Flow_Error_Message;
                
                switch on conflict {
                    when CX_OPEN_EXISTS {
                        errorMessage = 'Only one open CX Score Risk Profile is allowed per Account.';
                    }
                    when ENTITLEMENT_DUPLICATE {
                        errorMessage = 'Risk Profile with combination of this Risk Type, PRR, SRR and Entitlement already exists.';
                    }
                }
                rp.addError(errorMessage);
            }
        }
        updateRoundRobinIndex(roundRobin, currentIndex);
    }

    /**
     * @description Retrieves existing Risk Profiles for the given Account Ids based on a specific scenario.
     * @param accountIds Set of Account Ids to retrieve Risk Profiles for
     * @param calledFrom String identifier for the method or context requesting the profiles
     * @return Map<Id, List<Risk_Profile__c>> Map of Account Ids and their associated Risk Profiles
     */
    private static Map<Id, List<Risk_Profile__c>> getExistingRiskProfiles(Set<Id> accountIds, String calledFrom) {
        Map<Id, List<Risk_Profile__c>> accountRiskMap = new Map<Id, List<Risk_Profile__c>>();
        if (!accountIds.isEmpty()) {
            List<Risk_Profile__c> existingRiskProfiles = new List<Risk_Profile__c>();
            switch on calledFrom {
                when 'changeRPOwner' {
                     existingRiskProfiles = [
                        SELECT Id, Account__c, Risk_Type__c, Secondary_Risk_Reason__c, Primary_Risk_Reason__c, OwnerId,Owner.IsActive, Entitlement__c, IsClosed__c, Risk_Category__c, Risk_Validation_Status__c 
                        FROM Risk_Profile__c
                        WHERE Account__c IN :accountIds
                        ORDER BY CreatedDate DESC
                    ];
                }
                when 'checkExistingRP' {
                    existingRiskProfiles = [
                        SELECT Id, Account__c, Risk_Type__c, Secondary_Risk_Reason__c, Primary_Risk_Reason__c, OwnerId, Entitlement__c, IsClosed__c, Owner.IsActive, Risk_Category__c, Risk_Validation_Status__c  
                        FROM Risk_Profile__c
                        WHERE Account__c IN :accountIds AND Secondary_Risk_Reason__c != null AND Primary_Risk_Reason__c != null AND IsClosed__c = FALSE
                        ORDER BY CreatedDate DESC
                    ];
                }
            }
            for (Risk_Profile__c riskProfile : existingRiskProfiles) {
                if (!accountRiskMap.containsKey(riskProfile.Account__c)) {
                    accountRiskMap.put(riskProfile.Account__c, new List<Risk_Profile__c>());
                }
                accountRiskMap.get(riskProfile.Account__c).add(riskProfile);
            }
        }
        return accountRiskMap;
    }

    /**
     * @description Checks new Risk Profile data against existing Risk Profiles to ensure no duplicates are created.
     * @param newRiskProfiles List of new Risk Profiles
     * @param accountRiskMap Map of existing Risk Profiles grouped by Account Id
     */
    @TestVisible
    private static void checkNewRPDataWithExisting(List<Risk_Profile__c> newRiskProfiles, Map<Id, List<Risk_Profile__c>> accountRiskMap) {
        
        for (Risk_Profile__c rp : newRiskProfiles) {
            List<Risk_Profile__c> existingProfileList = accountRiskMap.containsKey(rp.Account__c) ? accountRiskMap.get(rp.Account__c) : new List<Risk_Profile__c>();
            RiskConflictType conflict = getRiskConflict(rp, existingProfileList);

            if (conflict != RiskConflictType.NONE) { 
            String errorMessage = System.Label.Risk_Analysis_Flow_Error_Message;
                switch on conflict {
                    when CX_OPEN_EXISTS {
                        errorMessage = 'Only one open CX Score Risk Profile is allowed per Account.';
                    }
                    when ENTITLEMENT_DUPLICATE {
                        errorMessage = 'Risk Profile with combination of this Risk Type, PRR, SRR and Entitlement already exists.';
                    }
                }
                rp.addError(errorMessage);
            }
        }
    }
    
    /**
     * @description Checks if a Risk Profile has the same type as any existing Risk Profile for the same Account.
     * @param newProfile The newly inserted Risk Profile
     * @param existingProfiles List of existing Risk Profiles for the same Account
     * @return Boolean True if a similar type exists, otherwise false
     */
    @TestVisible
    private static Boolean isSameTypeExists(Risk_Profile__c newProfile, List<Risk_Profile__c> existingProfiles) {

        for (Risk_Profile__c existingProfile : existingProfiles) {
            Boolean basicCheck = false;
            if(newProfile.isSet('Id') && (newProfile.Id == existingProfile.Id)) {
                continue;
            }

            if(existingProfile.IsClosed__c){
                continue;
            }

             if (existingProfile.Risk_Type__c == newProfile.Risk_Type__c 
                && newProfile.Secondary_Risk_Reason__c != null
                && newProfile.Primary_Risk_Reason__c != null 
                && newProfile.Risk_Type__c != null
                && existingProfile.Secondary_Risk_Reason__c == newProfile.Secondary_Risk_Reason__c
                && existingProfile.Primary_Risk_Reason__c == newProfile.Primary_Risk_Reason__c ) {
                    basicCheck = true;
                }
            //If Risk Type is Entitlement Risk, duplicate risk for same entitlement can't exist
            if (basicCheck && newProfile.Risk_Type__c == 'Entitlement Risk'){
                basicCheck = basicCheck && (existingProfile.Entitlement__c == newProfile.Entitlement__c);
            }

            if(basicCheck){
                return true;
            }
        }
        return false;
    }
    
    
    /**
     * @description Checks if a Risk Profile has the same type as any existing Risk Profile for the same Account.
     * @param newProfile The newly inserted Risk Profile
     * @param existingProfiles List of existing Risk Profiles for the same Account
     * @return Boolean True if a similar type exists, otherwise false
     */
    private static RiskConflictType getRiskConflict(Risk_Profile__c newProfile, List<Risk_Profile__c> existingProfiles) {
       
        Risk_Profile__c oldRP;
        
        if (Trigger.oldMap != null) {
            oldRP = (Risk_Profile__c) Trigger.oldMap.get(newProfile.Id);
        }        
        for (Risk_Profile__c existingProfile : existingProfiles) {
            
            if (newProfile.Id != null && newProfile.Id == existingProfile.Id) {
                continue;
            }
            
            if (existingProfile.IsClosed__c) {
                continue;
            }
            
            // CX-based rule
            if (((oldRP == null) || (oldRP != null && oldRP.Risk_Category__c != 'CX Score Risk')) && newProfile.Risk_Category__c == 'CX Score Risk' 
                && existingProfile.Risk_Category__c == 'CX Score Risk'
                && existingProfile.Risk_Validation_Status__c != 'Invalid') {
                    
                    return RiskConflictType.CX_OPEN_EXISTS;
                }
            
            // Generic duplicate rule
            if (existingProfile.Risk_Type__c == newProfile.Risk_Type__c
                && newProfile.Risk_Type__c != null
                && newProfile.Primary_Risk_Reason__c != null
                && newProfile.Secondary_Risk_Reason__c != null
                && existingProfile.Primary_Risk_Reason__c == newProfile.Primary_Risk_Reason__c
                && existingProfile.Secondary_Risk_Reason__c == newProfile.Secondary_Risk_Reason__c) {
                    
                    // Entitlement-specific rule
                    if (newProfile.Risk_Type__c == 'Entitlement Risk'
                        && existingProfile.Entitlement__c == newProfile.Entitlement__c) {
                            
                            return RiskConflictType.ENTITLEMENT_DUPLICATE;
                        }
                    
                    return RiskConflictType.DUPLICATE_RISK_TYPE;
                }
        }
        return RiskConflictType.NONE;
    }

    
    /**
     * @description Get owner from existing profiles if present otherwise, return from queue
     * @param existingProfiles Existing Profiles
     * @param members Round Robin Queue members
     * @param currentIndex Round Robin Queue member serial number
     * @return Id Id of new owner
     */
  /*  private static Id getOwnerFromExistingProfiles(List<Risk_Profile__c> existingProfiles, List<GroupMember> members, Integer currentIndex) {
        if (!existingProfiles.isEmpty()) {
            return existingProfiles[0].OwnerId;
        } else if (!members.isEmpty()) {
            return members[currentIndex].UserOrGroupId;
        }
        return null;
    }*/
    
    /**
     * @description Update current index
     * @param currentIndex Round Robin Queue member serial number
     * @param membersSize Total size of member queue
     * @return Integer updated current Index
     */
    private static Integer updateCurrentIndex(Integer currentIndex, Integer membersSize) {
        currentIndex++;
        if (currentIndex >= membersSize) {
            currentIndex = 0;
        }
        return currentIndex;
    }
    /**
     * @description Update current in round robing queue
     * @param roundRobin Risk Profile Assignment record to update
     * @param currentIndex Round Robin Queue member serial number
     */
    @TestVisible
    private static void updateRoundRobinIndex(Risk_Profile_Assignment__c roundRobin, Integer currentIndex) {
        roundRobin.Last_Assigned_Index__c = currentIndex;
        try{
            upsert roundRobin;
        }
        catch(Exception e){
            insertErrorLogs('RiskProfileAssignment',e.getMessage(),'RiskProfileTriggerHelper','updateRoundRobinIndex');
        }
    }

    /**
     * @description Sends notifications about Risk Profile creation.
     * @param riskProfileIds Set of Risk Profile Ids that triggered the event
     */
    public static void notifyOnCreate(Set<Id> riskProfileIds){  
        notify(riskProfileIds, 'Created');
    }

    /**
     * @description Sends notifications about Risk Profile updation.
     * @param newRiskProfiles List of updated Risk Profile records.
     * @param oldRecordMap Map of old Risk Profile records keyed by their Ids.
     */
    public static void notifyOnUpdate(List<Risk_Profile__c> newRiskProfiles, Map<Id, Risk_Profile__c> oldRecordMap){
        Set<Id> validatedRiskIds = new Set<Id>();
        Set<Id> InValidatedRiskIds = new Set<Id>();
        Set<Id> updatedStatusRiskIds = new Set<Id>();
        Set<Id> actionOwnerChangedRiskIds = new Set<Id>();
        Set<Id> closureRiskIds = new Set<Id>();

        for (Risk_Profile__c rp : newRiskProfiles) {
            Boolean hasValidationStatusChanged = oldRecordMap.get(rp.Id).Risk_Validation_Status__c != rp.Risk_Validation_Status__c;
			Boolean hasStatusChanged = oldRecordMap.get(rp.Id).Risk_Status__c != rp.Risk_Status__c;
            if(hasValidationStatusChanged && rp.Risk_Validation_Status__c == 'Valid'){
                validatedRiskIds.add(rp.Id);
            }
            if(hasValidationStatusChanged && rp.Risk_Validation_Status__c == 'Invalid'){
                InValidatedRiskIds.add(rp.Id);
            }
            if(hasStatusChanged && !rp.IsClosed__c){
                updatedStatusRiskIds.add(rp.Id);
            }
            if(hasStatusChanged && rp.IsClosed__c){
                closureRiskIds.add(rp.Id);
            }
            if(rp.Action_Owner__c != oldRecordMap.get(rp.Id).Action_Owner__c){
                actionOwnerChangedRiskIds.add(rp.Id);
            }
        }
        if(!actionOwnerChangedRiskIds.isEmpty()){
            notify(actionOwnerChangedRiskIds, 'ActionOwnerChange');
        }
        if(!validatedRiskIds.isEmpty()){
            notify(validatedRiskIds, 'Validated');
        }
        if(!InValidatedRiskIds.isEmpty()){
            notify(InValidatedRiskIds, 'Invalidated');
        }
        if(!updatedStatusRiskIds.isEmpty()){
            notify(updatedStatusRiskIds, 'StatusChange');
        }
        if(!closureRiskIds.isEmpty()){
            notify(closureRiskIds, 'Closure');
        }
    }

    /**
     * @description Sends notifications about Risk Profile events (e.g., creation, update).
     * @param riskProfileIds Set of Risk Profile Ids that triggered the event
     * @param evtType Type of event that occurred (e.g., 'Created', 'Validated')
     */
    public static void notify(Set<Id> riskProfileIds, String evtType){
        Boolean isBatchOrfuture = System.isBatch() || System.isFuture();
        if(isBatchOrfuture){
            notifySync(riskProfileIds, evtType);
        }else{
            notifyAsync(riskProfileIds, evtType);
        }
    }

    /**
     * @description Asynchronously notifies external systems or users about Risk Profile events.
     * @param riskProfileIds Set of Risk Profile Ids that triggered the event
     * @param evtType Type of event that occurred
     */
    @future
    public static void notifyAsync(Set<Id> riskProfileIds, String evtType){
        notifySync(riskProfileIds, evtType);
    }
    
    /**
     * @description Synchronously notifies users or external systems about Risk Profile events.
     * @param riskProfileIds Set of Risk Profile Ids that triggered the event
     * @param evtType Type of event that occurred
     */
    public static void notifySync(Set<Id> riskProfileIds, String evtType){
        (new CS_RiskMitigationNotificationService(riskProfileIds))
            .onEvent(CS_RiskMitigationNotificationService.EventType.valueOf(evtType))
            .notifyByEmail();
    }
    
    /**
     * @description
     * Represents the different types of conflicts that can occur when creating a Risk Profile for an Account.
     *
     * This enum is used to determine the exact reason a Risk Profile
     * cannot be created so that appropriate validation messages
     * can be shown to the user.
     */
    public enum RiskConflictType {
    
        /**
         * No conflict exists.
         */
        NONE,
    
        /**
         * An open CX Score based Risk Profile already exists
         * for the Account and is not marked as Invalid.
         */
        CX_OPEN_EXISTS,
    
        /**
         * A Risk Profile with the same Risk Type, Primary Risk Reason
         * and Secondary Risk Reason already exists.
         */
        DUPLICATE_RISK_TYPE,
    
        /**
         * An Entitlement Risk Profile already exists for the same
         * entitlement.
         */
        ENTITLEMENT_DUPLICATE
    }
    
    /**
     * @description Updates Risk_Validation_Status__c to 'Invalid' when Validation_Status_Approval__c is changed to 'Approved'.
     * @param newList List of updated Risk_Profile__c records.
     * @param oldMap Map of old Risk_Profile__c records keyed by Id.
     */
    public static void updateValidationStatus(List<Risk_Profile__c> newList, Map<Id, Risk_Profile__c> oldMap) {
        for (Risk_Profile__c newRec : newList) {
            Risk_Profile__c oldRec = oldMap.get(newRec.Id);
            if (newRec.Validation_Status_Approval__c == 'Approved' &&
                oldRec.Validation_Status_Approval__c != 'Approved') {
                newRec.Risk_Validation_Status__c = 'Invalid';
            }
        }
    }
}