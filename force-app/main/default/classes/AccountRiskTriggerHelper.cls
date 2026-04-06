/**
* @class AccountRiskTriggerHelper
* @description
*   Provides business logic for managing Account_Risk__c trigger operations.
*   - Evaluates ML and CX risks based on inserted or updated Account_Risk__c records.
*   - Creates or updates related Risk_Profile__c records accordingly.
*   - Manages expiration of outdated ML profiles.
*   - Controls the frequency of risk profile creation using Custom_Configuration_Change__c.
*/
public class AccountRiskTriggerHelper {
    
    public static final String CURRENT_QUARTER = 'Risk Analyzed in Q'+(((Math.mod(System.today().month() +10, 12))/3) +1)+' Quarter';
    public static Boolean allowCX = true;
    public static Boolean allowML = true;
    public static Boolean allowSync = true;
    public static Boolean allowExpRun = true;
    private static final String CX = 'CX';
    private static final String ML = 'ML';
    private static final String ACCOUNT = 'Account';
    private static final String ACCOUNT_ML = 'Account-ML';
    private static final String EXPIRE_NOTE = System.label.Risk_ML_Expiry_Note;
    private static final Boolean isApiUser = isApiOrderAutomationUser();
    
    private static final Custom_Configuration_Change__c freqConfig;
    
    // Static initializer block to set configuration flags
    static {
        Id recordTypeId = Schema.SObjectType.Custom_Configuration_Change__c.getRecordTypeInfosByName().get('RP Frequency Config').getRecordTypeId();
        
        List<Custom_Configuration_Change__c> configList = [
            SELECT Config_For__c, Config_Type__c, Next_Run__c, Config_Disabled__c
            FROM Custom_Configuration_Change__c WHERE RecordTypeId =: recordTypeId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!configList.isEmpty()  && configList[0].Config_Disabled__c == false) {
            freqConfig = configList[0];
            Date today = Date.today();
            
            Boolean blockedUntilFuture = freqConfig.Next_Run__c != null && freqConfig.Next_Run__c > today;
            
            if (freqConfig.Config_For__c == 'CX Sync') {
                allowCX = !blockedUntilFuture;
            } else if (freqConfig.Config_For__c == 'ML Sync') {
                allowML = !blockedUntilFuture;
            } else if (freqConfig.Config_For__c == 'CX & ML Both') {
                allowCX = !blockedUntilFuture;
                allowML = !blockedUntilFuture;
            }
        }

        String expiryLabel = System.Label.Risk_ML_Expiry;
        if (!String.isBlank(expiryLabel)) {
            allowExpRun = expiryLabel.toLowerCase() == 'true';
        } else {
            allowExpRun = false; 
        }
    }
    
    /**
* @description
*   Handles logic after Account_Risk__c records are inserted.
*   - Determines if CX or ML Risk_Profile__c records should be created.
*   - Updates existing Risk_Profile__c with currentQuarter notes if applicable.
*   - Enforces frequency restrictions and updates the next run schedule.
* @param newMap Map of newly inserted Account_Risk__c records keyed by ID.
*/
    public static void processAfterInsert(Map<Id, Account_Risk__c> newMap) {
        handleBatch(newMap.values(), null, true, true);
    }
    
    /**
* @description
*   Handles logic after Account_Risk__c records are updated.
*   - Detects changes in CX score or ML risk types.
*   - Updates or creates Risk_Profile__c records accordingly.
*   - May expire outdated ML risk profiles if applicable.
* @param newList List of updated Account_Risk__c records.
* @param oldMap Map of original Account_Risk__c records keyed by ID.
*/
    public static void processAfterUpdate(List<Account_Risk__c> newList, Map<Id, Account_Risk__c> oldMap) {
        handleBatch(newList, oldMap, false, true);
    }
    
    
    /**
* @description
*   Handles logic after Account_Risk__c records are inserted.
*   - Determines if CX or ML Risk_Profile__c records should be created.
*   - Updates existing Risk_Profile__c with currentQuarter notes if applicable.
*   - Enforces frequency restrictions and updates the next run schedule.
* @param newList List of newly inserted Account_Risk__c records keyed by ID.
*/
    public static void processBeforeInsert(List<Account_Risk__c> newList) {
        handleBatch(newList, null, true, false);
    }
    
    
    /**
* @description
*   Handles logic after Account_Risk__c records are updated.
*   - Detects changes in CX score or ML risk types.
*   - Updates or creates Risk_Profile__c records accordingly.
*   - May expire outdated ML risk profiles if applicable.
* @param newList List of updated Account_Risk__c records.
* @param oldMap Map of original Account_Risk__c records keyed by ID.
*/
    public static void processBeforeUpdate(List<Account_Risk__c> newList, Map<Id, Account_Risk__c> oldMap) {
        handleBatch(newList, oldMap, false, false);
    }
    
    /**
* @description
*   Central handler for both insert and update logic on Account_Risk__c records.
* @param accRiskMap Iterable collection of new or updated Account_Risk__c records.
* @param oldMap Map of original records (null for insert operations).
* @param existingMap Map of the existing risk profiles
*/
    private static void handleBatchBefore(Map<Id, Account_Risk__c> accRiskMap,Map<Id, Account_Risk__c> oldMap, Map<Id, Risk_Profile__c> existingMap){
        if(isApiUser){
            for (Account_Risk__c ar : accRiskMap.values()) { 
                Account_Risk__c oldAr = oldMap?.get(ar.Account_External_Id__c);
                Risk_Profile__c rp = existingMap.get(ar.Account_External_Id__c);
                if (rp != null && oldAr != null && ar.Risk_Type__c =='ML' && (!hasChanged(oldAr, ar, 'Opportunities__c') && !hasChanged(oldAr, ar, 'Entitlements__c'))) {  
                    continue;
                }
                else if (ar.Risk_Type__c == ML && allowML) {
                    ar.Need_Update__c = true;
                }
                else if(ar.Risk_Type__c == CX && allowCX){ 
                    ar.Need_Update__c = true; 
                } 
            }
        }
    }
    
    /**
* @description
*   handler for both insert and update logic of the After operation of Account_Risk__c records.
*   - Determines which records should result in new or updated Risk_Profile__c entries.
*   - Applies frequency restrictions and risk expiration rules.
* @param accRiskMap Iterable collection of new or updated Account_Risk__c records.
* @param oldMap Map of original records (null for insert operations).
* @param existingMap Map of the existing risk profiles
*/
    private static void handleBatchAfter(Map<Id, Account_Risk__c> accRiskMap,Map<Id, Account_Risk__c> oldMap, Map<Id, Risk_Profile__c> existingMap){
        
        List<Risk_Profile__c> toUpdate = new List<Risk_Profile__c>();
        Set<Id> rpToCreate = new Set<Id>();
        Set<Id> updatedRPAccIds = new Set<Id>();
        
        for (Account_Risk__c ar : accRiskMap.Values()) {
            
            Account_Risk__c oldAr = oldMap?.get(ar.Account_External_Id__c);
            Risk_Profile__c rp = existingMap.get(ar.Account_External_Id__c);

            Boolean hasComments = rp != null && rp.Risk_Reason_Additional_Comments__c != null && String.isNotBlank(rp.Risk_Reason_Additional_Comments__c);
            Boolean currentQuartSyncAllowed = hasComments ? !containsComment(rp.Risk_Reason_Additional_Comments__c) : true;
            
            if (rp != null && ar.Risk_Type__c =='ML' && (!hasChanged(oldAr, ar, 'Opportunities__c') && !hasChanged(oldAr, ar, 'Entitlements__c'))) {
                if(currentQuartSyncAllowed){
                    rp.ML_Risk__c = rp.ML_Risk__c || ar.Risk_Type__c == ML;                    
                    if (!hasComments) {
                        rp.Risk_Reason_Additional_Comments__c = CURRENT_QUARTER;
                    } else {
                        rp.Risk_Reason_Additional_Comments__c += '\n\n' + CURRENT_QUARTER;
                    }
                    toUpdate.add(rp);
                  //  updatedRPAccIds.add(rp.Account__c);
                }
            } 
            else if (ar.Risk_Type__c == ML && allowML) {
                rpToCreate.add(ar.Account_External_Id__c);
            }
            else if(allowCX && ar.Risk_Type__c == CX){ 
                rpToCreate.add(ar.Account_External_Id__c);
            }  
        }
        
        // Insertion & Updation Logics Below
        
        try {
            if (!toUpdate.isEmpty()){ 
                update toUpdate;
            }
        } catch (Exception e) {
            logError( e, 'Risk_Profile__c', 'handleBatch - update Risk_Profile__c');
        }
        
        if(!rpToCreate.isEmpty()){
            try {
              //  updatedRPAccIds.addAll(rpToCreate);  
                if(isApiUser) {
                    Integer existingJobs = [
                        SELECT COUNT() 
                        FROM CronTrigger 
                        WHERE CronJobDetail.Name LIKE '%RiskProfileCreationBatch%'
                    ];
                    
                    if (existingJobs == 0) {
                        System.enqueueJob(new RiskProfileSchedulerQueue());
                    }
                } else {
                    CS_AutomaticRiskProfileCreation.createRiskProfileSync(rpToCreate, ACCOUNT);
                }
            } catch(Exception e) {
                logError(e, 'Account_Risk__c', 'handleBatch - risk profile creation');
            }
        }
    }
    /**
* @description
*   Central handler for both insert and update logic on Account_Risk__c records.
*   - Determines which records should result in new or updated Risk_Profile__c entries.
*   - Applies frequency restrictions and risk expiration rules.
* @param newRecords Iterable collection of new or updated Account_Risk__c records.
* @param oldMap Map of original records (null for insert operations).
* @param isInsert Boolean flag indicating whether the operation is insert (true) or update (false).
* @param isAfter Boolean flag indicating whether the operation is after (true) or before (false).

*/
    private static void handleBatch(
        List<Account_Risk__c> newRecords,
        Map<Id, Account_Risk__c> oldMap,
        Boolean isInsert,
        Boolean isAfter        
    ) {
      //  if(!allowSync) return;
        Map<Id, Account_Risk__c> accRiskMap = new Map<Id, Account_Risk__c>();
        Set<Id> accIds = new Set<Id>();
        
        for(Account_Risk__c ar : newRecords){
            accIds.add(ar.Account__c);
        }
        
        Map<Id, Risk_Profile__c> existingCXRPMap = getCXRiskProfile(accIds);
     
        for (Account_Risk__c r : newRecords) {
            Account_Risk__c old = isInsert ? null : oldMap.get(r.Id);
            Risk_Profile__c existingCXRP = (r.Account__c != null) ? existingCXRPMap.get(r.Account__c) : null;
            if (r.Risk_Type__c == CX && (r.CX_Score_Status__c == 'Poor' || r.CX_Score_Status__c == 'Fragile') && (isInsert || hasChanged(old, r, 'CX_Score_Status__c') || existingCXRP == null) && r.Account_Maturity__c == true) {
                accRiskMap.put(r.Account__c, r);
            } else if (r.Risk_Type__c == ML) {
                accRiskMap.put(r.Account__c, r);
            }
        }
        Map<Id, Account_Risk__c> oldAccRiskMap = new Map<Id, Account_Risk__c>();
        if(oldMap != null){
            for(Account_Risk__c r : oldMap.Values()){
                if(!oldAccRiskMap.containsKey(r.Account__c)){
                    oldAccRiskMap.put(r.Account__c, r);
                }
            }
        }
        if (accRiskMap.isEmpty()) return;
        
        Map<Id, Risk_Profile__c> existingMap = getLatestRiskProfiles(accRiskMap.Keyset());
        if(isAfter){
            handleBatchAfter(accRiskMap,oldAccRiskMap, existingMap);
        }
        else{
            handleBatchBefore(accRiskMap,oldAccRiskMap, existingMap);
        }   
    } 
    
    /**
* @description
*   Utility method to determine if a specified field has changed between two records.
* @param oldRec The original Account_Risk__c record.
* @param newRec The updated Account_Risk__c record.
* @param fieldName The API name of the field to compare.
* @return True if the field value has changed or old record is null.
*/
    @TestVisible
    private static Boolean hasChanged(Account_Risk__c oldRec, Account_Risk__c newRec, String fieldName) {
        // If old record is null, treat as a change
        if (oldRec == null) return true;
        
        Object oldValue = oldRec.get(fieldName);
        Object newValue = newRec.get(fieldName);

        // If both are null, no change
        if (oldValue == null && newValue == null) return false;
        
        // If one is null, it's a change
        if (oldValue == null || newValue == null) return true;
        
        // If both are strings, check for comma-separated logic
        if (oldValue instanceof String && newValue instanceof String) {
            String oldStr = ((String)oldValue).trim();
            String newStr = ((String)newValue).trim();
            
            // If not comma-separated, do simple string comparison
            if (!oldStr.contains(',') && !newStr.contains(',')) {
                return oldStr != newStr;
            }
            
            // Handle as sets for comma-separated values
            Set<String> oldSet = new Set<String>();
            for (String s : oldStr.split(',')) {
                if (String.isNotBlank(s)) {
                    oldSet.add(s.trim());
                }
            }
            
            Set<String> newSet = new Set<String>();
            for (String s : newStr.split(',')) {
                if (String.isNotBlank(s)) {
                    newSet.add(s.trim());
                }
            }
            
            // Compare sets — order doesn't matter
            return !oldSet.equals(newSet);
        }
        
        // Fallback comparison for non-string values
        return oldValue != newValue;
    }

    
    /**
* @description
*   Checks whether the provided comment string already contains the current quarter annotation.
* @param comments The existing comment string.
* @return True if the currentQuarter string is found in the comment.
*/
    @TestVisible
    private static Boolean containsComment(String comments) {
        return String.isNotBlank(comments) && comments.contains(CURRENT_QUARTER);
    }
    
    /**
* @description
*   Fetches the most recent, open Risk_Profile__c record per Account ID.
* @param accountIds Set of Account__c IDs to fetch risk profiles for.
* @return Map of Account__c ID to the latest open Risk_Profile__c.
*/
    private static Map<Id, Risk_Profile__c> getLatestRiskProfiles(Set<Id> accountIds) {
        Map<Id, Risk_Profile__c> mapRP = new Map<Id, Risk_Profile__c>();
        for (Risk_Profile__c rp : [
            SELECT Id, Account__c, ML_Risk__c, Risk_Reason_Additional_Comments__c, Risk_Type__c, Risk_Category__c
            FROM Risk_Profile__c
            WHERE IsClosed__c = false AND Account__c IN :accountIds AND Risk_Origin__c = 'Account' AND (Risk_Category__c = 'Prediction Model' OR (In_Snooze__c = true OR (Do_Not_Trigger__c = true AND DNT_Reason__c IN ('Dark site','RSCP account','MSP Related'))))
            ORDER BY CreatedDate DESC
        ]) {
            if (!mapRP.containsKey(rp.Account__c)) {
                mapRP.put(rp.Account__c, rp);
            }
        }
        return mapRP;
    }
    
    /**
* @description
*   Marks previously open ML Risk_Profile__c records as expired if they were not updated recently.
*   Adds a predefined expiration note to the comment field if not already present.
*/
    public static void expirePreviousMLRiskProfiles() {
        List<Risk_Profile__c> toExpire = new List<Risk_Profile__c>();
        Set<String> updatedAccIds = new Set<String>();
        
        for(Account_Risk__c rp :[SELECT Id, Account__c FROM Account_Risk__c WHERE (Createddate = today OR Lastmodifieddate = today) AND Risk_Type__c = 'ML' AND ML_Risk__c = true]){
            if(!updatedAccIds.contains(rp.Account__c)){
                updatedAccIds.add(rp.Account__c);
            }
        }

        for (Risk_Profile__c rp : [
            SELECT Id, ML_Risk__c, Risk_Reason_Additional_Comments__c
            FROM Risk_Profile__c
            WHERE IsClosed__c = false AND ML_Risk__c = true AND Risk_Category__c = 'Prediction Model' AND Createddate < today AND Lastmodifieddate < today AND Account__c NOT IN :updatedAccIds
        ]) {
            rp.ML_Risk__c = false;
            if (String.isBlank(rp.Risk_Reason_Additional_Comments__c)) {
                rp.Risk_Reason_Additional_Comments__c = EXPIRE_NOTE;
            } else if (!rp.Risk_Reason_Additional_Comments__c.contains(EXPIRE_NOTE)) {
                rp.Risk_Reason_Additional_Comments__c += '\n' + EXPIRE_NOTE;
            }
            toExpire.add(rp);
        }
        
        if (!toExpire.isEmpty()) update toExpire;
    }
    
    /**
* @description
*   Updates the Next_Run__c date on the most recent Custom_Configuration_Change__c record based on its frequency type.
*   Ensures that future runs are appropriately spaced according to the configured frequency.
*/
    public static void updateNextRun() {
        if (freqConfig == null) return;
        Date today = Date.today();
        Date nextRun;
        
        switch on freqConfig.Config_Type__c {
            when 'Daily'    { nextRun = today.addDays(1); }
            when 'Weekly'   { nextRun = today.addDays(7); }
            when 'Biweekly' { nextRun = today.addDays(14); }
            when 'Monthly'  { nextRun = today.addMonths(1); }
            when 'Snooze with a Date picker'   { nextRun = today.addDays(1); }
            when else       { return; }
        }
        
        freqConfig.Next_Run__c = nextRun;
        freqConfig.Last_Run__c = System.today();
        update freqConfig;
    }
/**
* @description
*   Creates a log record in the error log object for any failure
* @param  e Any exception record we need to pass
* @param  objectName name of the object for which error occured
* @param  methodName method in which error occured
*/
    public static void logError(Exception e, String objectName,String methodName){
        List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
        errorLogs.add(new Error_Logs__c(
            Object__c = objectName,
            Error_Message__c = e.getMessage(),
            Class__c = 'AccountRiskTriggerHelper',
            Method__c = methodName,
            Type__c = 'SFDC',
            Success__c = false
        ));
        if(!errorLogs.IsEmpty()){
            insert errorLogs;
        }
    }
    /**
* @description
*   Query the API Automation user with username.
* @return True if current user id is the api user id else false.
*/
    public static Boolean isApiOrderAutomationUser() {
        User u = [SELECT Id FROM User WHERE UserName LIKE '%apiautomation@rubrik.com%' AND IsActive = true ORDER BY Createddate DESC LIMIT 1];
        return UserInfo.getUserId() == u.Id;
    }
    
        /**
* @description
*   Fetches the most recent Risk_Profile__c record per Account ID.
* @param accountIds Set of Account__c IDs to fetch risk profiles for.
* @return cxmapRP of Account__c ID to the latest Risk_Profile__c.
*/
    public static Map<Id, Risk_Profile__c> getCXRiskProfile(Set<Id> accountIds) {
        Map<Id, Risk_Profile__c> cxmapRP = new Map<Id, Risk_Profile__c>();
        for (Risk_Profile__c rp : [SELECT Id, Account__c, ML_Risk__c, Risk_Type__c, Risk_Category__c FROM Risk_Profile__c WHERE Account__c IN :accountIds AND Risk_Origin__c = 'Account' AND Risk_Category__c = 'CX Score Risk' ORDER BY CreatedDate DESC
        ]) {
            if (!cxmapRP.containsKey(rp.Account__c)) {
                cxmapRP.put(rp.Account__c, rp);
            }
        }
        return cxmapRP;
    }
    
}