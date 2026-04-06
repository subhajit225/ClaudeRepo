/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description This controller centralizes Risk Creation from different mechanisms, i.e., Account/Opportunity etc.
 * @TestClass - CS_AutomaticRiskProfileCreationTest
 */
public class CS_AutomaticRiskProfileCreation {
    
    /**
     * @description Extracts the first Salesforce ID found in the input string.
     * @param input The string from which to extract the ID.
     * @return String The extracted ID or null if not found.
     */
    public static String extractId(String input) {
        Pattern p = Pattern.compile('(\\w{15,18})');
        Matcher m = p.matcher(input);
        String match;
        if (m.find()) {
            match = m.group(1);
        }
        return match;
    }
    
    /**
     * @description Identifies Opportunities that were previously in '7 Closed Lost' stage 
     *              and have been moved to a different stage. It then triggers a method to 
     *              set a private comment on related Mitigation Cases for these Opportunities.
     * @param oldMap Map of Opportunity records before update, keyed by Opportunity Id.
     * @param newMap Map of Opportunity records after update, keyed by Opportunity Id.
     */
    public static void handleNonClosureOfOpportunity(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        Map<Id,String> changedOppIds = new Map<Id,String>();
        for (Opportunity o : newMap.values())
            if (oldMap.get(o.Id).StageName == '7 Closed Lost' && o.StageName != '7 Closed Lost')
            changedOppIds.put(o.Id,oldMap.get(o.Id).StageName);
        
        if (!changedOppIds.isEmpty()){
            if(!(System.isBatch() || System.isFuture() || System.isQueueable())){
                setPrivateCommentOnMitigationCase(changedOppIds);
            }
        }
    }
    
    /**
    * @description
    * Attach comment and send notification about Stage changes on Opportunity
    * @param oppClosedStageChange opportunityId and stage map
    */
    @future
    public static void setPrivateCommentOnMitigationCase(Map<Id,String> oppClosedStageChange) {
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, name, StageName FROM Opportunity WHERE Id IN :oppClosedStageChange.keySet() WITH USER_MODE]);
        Map<Id, List<Case>> oppToCases = new Map<Id, List<Case>>();
        
        for (Case c : [
            SELECT Id, Risk_Opportunity__c, Risk_Profile__r.OwnerId, Risk_Profile__r.Owner.Email, Risk_Profile__c,Risk_Profile__r.Name 
            FROM Case 
            WHERE Risk_Opportunity__c IN :oppClosedStageChange.keySet()
            AND RecordType.Name = 'Retention Case' 
            AND IsClosed = false
        ]) {
            if (!oppToCases.containsKey(c.Risk_Opportunity__c)) {
                oppToCases.put(c.Risk_Opportunity__c, new List<Case>());
            }
            oppToCases.get(c.Risk_Opportunity__c).add(c);
        }
        
        List<SObject> caseComments = new List<SObject>();
        Map<Id, List<String>> ownerIdToMessages = new Map<Id, List<String>>();
        for (Opportunity o : newMap.values()) {

        if (!oppToCases.containsKey(o.Id)) continue;

        String oldStage = oppClosedStageChange.get(o.Id);
        String newStage = o.StageName;
        for (Case relatedCase : oppToCases.get(o.Id)) {
                if(relatedCase.Risk_Profile__c != null){
                 Id ownerId = relatedCase.Risk_Profile__r.OwnerId;
                    if (!ownerIdToMessages.containsKey(ownerId)) {
                        ownerIdToMessages.put(ownerId, new List<String>());
                    }
                    
                    String oppUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + o.Id;
                    String riskProfileUrl = URL.getOrgDomainUrl().toExternalForm() + '/' + relatedCase.Risk_Profile__c;
                   
                        SObject c1 = CaseComment.sObjectType.newSObject();
                        c1.put('ParentId', relatedCase.Id);
                        c1.put(
                            'CommentBody',
                            'The opportunity stage has been updated from "'+ oldStage+ '" to "' + newStage + '"'
                        );
                        caseComments.add(c1);
                        
                        ownerIdToMessages.get(ownerId).add(
                            '<p>The stage of the tagged opportunity <a href="' + oppUrl + '">' +
                            o.Name + '</a> has been updated from "' + oldStage+ '" to "' +
                            newStage + '" for the risk profile <a href="' +
                            riskProfileUrl + '">' + relatedCase.Risk_Profile__r.Name + '</a>.</p>'
                        );
                }
            }
        }
			
        if (!caseComments.isEmpty()) insert as user caseComments;
        if(!ownerIdToMessages.isEmpty()){
            sendBulkEmailNotifications(ownerIdToMessages);
        }
    }
    /**
    * @description
    * Send notification about Stage changes on Opportunity
    * @param ownerIdToMessages Risk Profile Owner and messages to be sent
    */
    private static void sendBulkEmailNotifications(Map<Id, List<String>> ownerIdToMessages) {
        if (ownerIdToMessages.isEmpty()) return;

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIdToMessages.keySet()]);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Id ownerId : ownerIdToMessages.keySet()) {
            User owner = userMap.get(ownerId);
            if (owner == null || String.isBlank(owner.Email)) continue;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Opportunity Stage Updated');
            mail.setHtmlBody(String.join(ownerIdToMessages.get(ownerId), ''));            
            mail.setTargetObjectId(ownerId);
            mail.setSaveAsActivity(false);
            
            if(String.isNotBlank(System.Label.NoReplyAddressID)){
                mail.setOrgWideEmailAddressId(System.Label.NoReplyAddressID);
            }
            mail.setUseSignature(false);
            emails.add(mail);
        }

        try{
            if (!emails.isEmpty()){
                Messaging.sendEmail(emails);
            }
        } catch(Exception e){
            insert as system new Error_Logs__c(Object__c = 'Risk_Profile__c',
                Error_Message__c = e.getMessage() + e.getStackTraceString(),
                Class__c = 'CS_AutomaticRiskProfileCreation',
                Method__c = 'sendBulkEmailNotifications',
                Type__c = 'SFDC',
                Success__c = false);
        }
    }
    
     /**
    * @description
    * Handles updates to Risk Profiles based on changes in the Renewal Sentiment field of Opportunities.
    * Also triggers the creation of new Risk Profiles when the sentiment changes to 'Red' with defined conditions.
    * @param oldOpportunityMap  Map of old Opportunity records keyed by Id.
    * @param newOpportunityMap Map of new Opportunity records keyed by Id.
    */
    public static void handleRenewalSentimentChange(Map<Id, Opportunity> oldOpportunityMap, Map<Id, Opportunity> newOpportunityMap) {
        Boolean isCreateEvent = oldOpportunityMap == null;
        List<Opportunity> newOpportunities = newOpportunityMap.values();
        Set<Id> oppIdsForNewRiskProfiles = new Set<Id>();      
        Map<Id,Opportunity> oppIdsForRiskProfileCheck = new Map<Id,Opportunity>();   
        Set<Id> riskIdsToUpdate = new Set<Id>();
        Set<Id> changedOppIds = new Set<Id>();
        Map<Id,String> changedOppsWithOldStatus = new Map<Id,String>();
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp =  (oldOpportunityMap != NULL && oldOpportunityMap.containsKey(opp.Id)) ? oldOpportunityMap?.get(opp.Id) : new Opportunity();
            Boolean sentimentChanged = oldOpp != null && (oldOpp.Renewals_Sentiment__c != opp.Renewals_Sentiment__c);
            if(oldOpportunityMap == null && opp.Renewals_Sentiment__c == 'Red'){
                oppIdsForNewRiskProfiles.add(opp.Id);
            }
            if(sentimentChanged){
                oppIdsForRiskProfileCheck.put(opp.Id,opp);
            }
          /*  if (oldOpportunityMap!= NULL && oldOpportunityMap.containsKey(opp.Id) && oldOpportunityMap.get(opp.Id).StageName == '7 Closed Lost' && opp.StageName != '7 Closed Lost'){
                changedOppIds.add(opp.Id);
            }*/
            if(!isCreateEvent && oldOpportunityMap.containsKey(opp.Id)){
                String newStage = opp?.StageName;
                String oldStage = oldOpportunityMap.get(opp.Id)?.StageName;
                if((oldStage != newStage) && ((newStage == '7 Closed Won' || newStage == '7 Closed Lost' || newStage == '7 Closed Admin') || (oldStage == '7 Closed Won' || oldStage == '7 Closed Lost' || oldStage == '7 Closed Admin'))){
                    changedOppsWithOldStatus.put(opp.Id,oldStage);
                }
            }
        }
        Map<Id, Risk_Profile__c> oppIdToRiskProfileMap = new Map<Id, Risk_Profile__c>();
        if (!oppIdsForRiskProfileCheck.isEmpty()) {
            for (Risk_Profile__c rp : [
                SELECT Id, Opportunity__c, IsClosed__c, Risk_Validation_Status__c, Comments__c, Mitigation_Case_Number__c, Mitigation_Case_Number__r.Risk_Comments__c
                FROM Risk_Profile__c
                WHERE Opportunity__c IN :oppIdsForRiskProfileCheck.keySet()
                AND IsClosed__c = false AND Risk_Validation_Status__c != 'Invalid' order by createddate desc
            ]) {
                if(!oppIdToRiskProfileMap.containsKey(rp.Opportunity__c)){
                    oppIdToRiskProfileMap.put(rp.Opportunity__c, rp);
                }
            }
        }
        List<sObject> commentsToInsert = new List<sObject>();
        for (Opportunity opp : oppIdsForRiskProfileCheck.values()) {
            Risk_Profile__c oldRP = oppIdToRiskProfileMap.get(opp.Id);
            if (oldRP != null){
                String newComment = 'Opportunity Renewal Sentiment changed to ' + opp.Renewals_Sentiment__c;
                if (String.isNotBlank(oldRP.Mitigation_Case_Number__c)) {
                    SObject sObj = Case.sObjectType.newSObject();
                    sObj.put('Id', oldRP.Mitigation_Case_Number__c);
                    sObj.put('Comments', newComment);
                    commentsToInsert.add(sObj);
                } else {
                    String oldComment = oldRP.Comments__c;
                    SObject sObj = oldRP.Id.getSObjectType().newSObject();
                    sObj.put('Id', oldRP.Id);
                    sObj.put('Comments__c', String.isNotBlank(oldComment) ? oldComment + '\n ' + newComment : newComment);
                    commentsToInsert.add(sObj);
                }
            }else if(oldRP == null && opp.Renewals_Sentiment__c == 'Red') {
                oppIdsForNewRiskProfiles.add(opp.Id);
            }
        }
     /*   if (!oppIdsForNewRiskProfiles.isEmpty()) {
           // CS_AutomaticRiskProfileCreation.createRiskProfile(oppIdsForNewRiskProfiles, 'Opportunity');
        } 
	 */
        if (!changedOppsWithOldStatus.isEmpty()){
            if(!(System.isBatch() || System.isFuture() || System.isQueueable())){
                setPrivateCommentOnMitigationCase(changedOppsWithOldStatus);
            }
        }
        if (!commentsToInsert.isEmpty()) {
            Database.update(commentsToInsert, false);
        }
	}

    /**
     * @description Creates Risk Profiles based on record IDs and their origin.
     * @param recordIds The IDs of records to create Risk Profiles for.
     * @param riskOrigin The origin of the risk (e.g., Account or Opportunity).
     */
    public static void createRiskProfile(Set<Id> recordIds, String riskOrigin){
        Boolean isBatchOrfuture = System.isBatch() || System.isFuture();
        if(isBatchOrfuture){
            createRiskProfileSync(recordIds, riskOrigin);
        }else{
            createRiskProfileAsync(recordIds, riskOrigin);
        }
    }

    /**
     * @description Asynchronous creation of Risk Profiles.
     * @param recordIds The IDs of records to create Risk Profiles for.
     * @param riskOrigin The origin of the risk (e.g., Account or Opportunity).
     */
    @future
    public static void createRiskProfileAsync(Set<Id> recordIds, String riskOrigin){
        createRiskProfileSync(recordIds, riskOrigin);
    }

    /**
     * @description Synchronous creation of Risk Profiles.
     * @param recordIds The IDs of records to create Risk Profiles for.
     * @param riskOrigin The origin of the risk (e.g., Account or Opportunity).
     */
    public static void createRiskProfileSync(Set<Id> recordIds, String riskOrigin) {
        List<Risk_Profile__c> riskProfilesToInsert  = new List<Risk_Profile__c>();
        Map<Id, SObject> accIdRiskMap = new Map<Id, SObject>();
       // String accountRiskType = '';
        String idField = 'Id';
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        String query = 'SELECT Id, ';
        if (riskOrigin.contains('Account')) {           
            query += 'CX_Score_Status__c,Adoption_Score__c,OnBoarding_Score__c,Product_Score__c,Support_Score__c,CX_Score__c, Opportunities__c, Entitlements__c, Product_Pillar_1__c, Product_Pillar_2__c, Account__c, Risk_Type__c';
          //  accountRiskType = riskOrigin.contains('ML') ? 'ML' : (riskOrigin.contains('CX') ? 'CX' : riskOrigin);
            riskOrigin = 'Account_Risk__c';
            idField = 'Account__c';
        } 
        else if (riskOrigin == 'Opportunity') {
            query += 'AccountId ';
        }
        
        Map<Id,Account_Risk__c> idToAccount = new Map<Id,Account_Risk__c>();
        
        query += ' FROM ' + riskOrigin + ' WHERE ' + idField+ ' IN:recordIds';
        //ApexSOQLInjection False Positive, Binding Variable used.
        List<SObject> records = Database.query(query); //NOPMD
        
        if(riskOrigin.contains('Account')){
            idToAccount = new Map<Id,Account_Risk__c>((List<Account_Risk__c>)records);
        }
        for (SObject record : records) {
            Risk_Profile__c riskProfile  = new Risk_Profile__c();
            
            riskProfile.Risk_Status__c = 'New';
            if (riskOrigin == 'Opportunity') {
                riskProfile.Risk_Reason_Additional_Comments__c = baseUrl + '/'+(Id)record.get('Id');
                riskProfile.Risk_Origin__c = 'Opportunity';
                riskProfile.Risk_Type__c = 'Entitlement Risk';
                riskProfile.Risk_Level__c = 'High';
                riskProfile.Risk_Category__c = 'Renewal Sentiment Risk';
                riskProfile.Opportunity__c = (Id)record.get('Id');
                riskProfile.Account__c = (Id)record.get('AccountId');
            } else if (riskOrigin.contains('Account')) {
                String currentQuarter = 'Risk Analyzed in Q'+(((Math.mod(System.today().month() +10, 12))/3) +1)+' Quarter'; // 1 = Jan, 2 = Feb, etc.
                String accountRiskType = (String)record.get('Risk_Type__c');
                Account_Risk__c acc = (Account_Risk__c)record;
                riskProfile.Account_Risk__c = acc.Id;
                riskProfile.Risk_Reason_Additional_Comments__c = accountRiskType == 'ML' ? accountRiskType : System.Label.Retention_CX_Health_Dashboard_Tableau_Link;
                riskProfile.Risk_Origin__c = 'Account';
                riskProfile.Risk_Level__c = (String)record.get('CX_Score_Status__c') == 'Fragile' ? 'High' : 'Medium';
                riskProfile.Account__c = (Id)record.get('Account__c');
                if(accountRiskType == 'ML'){
                    accIdRiskMap.put((Id)record.get('Account__c'), record);
                    riskProfile.Risk_Category__c = 'Prediction Model';
                    riskProfile.Risk_Type__c = 'Entitlement Risk';
                    riskProfile.ML_Risk__c = true;
                    
                    String risksComment = currentQuarter + '\n\n';                    
                    risksComment += buildLinksSection(baseUrl, 'Opportunities', (String)record.get('Opportunities__c'), true);
                    risksComment += buildLinksSection(baseUrl, 'Entitlements', (String)record.get('Entitlements__c'), true);
                    risksComment += buildLinksSection(baseUrl, 'Product Pillar 1', (String)record.get('Product_Pillar_1__c'), false);
                    risksComment += buildLinksSection(baseUrl, 'Product Pillar 2', (String)record.get('Product_Pillar_2__c'), false);                    
                    riskProfile.Risk_Reason_Additional_Comments__c = risksComment;                    
                }
                else{
                    riskProfile.Risk_Category__c = 'CX Score Risk';
                    riskProfile.Risk_Type__c = 'Account Risk';
                    setRiskReasons(idToAccount.get(riskProfile.Account_Risk__c), riskProfile);                
                }
                /*String cxScoreCreation = 'Health Status: ' + acc.CX_Score_Status__c + '\n'
                   + 'CX score: ' + acc.CX_Score_RRM__c + '\n'
                   + 'Onboarding score: ' + acc.OnBoarding_Score__c  + '\n'
                   + 'Adoption score: ' + acc.Adoption_Score__c + '\n'
                   + 'Product score: ' + acc.Product_Score__c + '\n'
                   + 'Support score: ' + acc.Support_Score__c ;
                riskProfile.CXScoreCreation__c = cxScoreCreation;*/
            }

            riskProfilesToInsert.add(riskProfile );
        }
        if (!riskProfilesToInsert.isEmpty()) {
            
            try {
                // Perform the insert and get the results
                Database.SaveResult[] results = Database.insert(riskProfilesToInsert, false);

                List<Risk_Profile__c> insertedMLRP = new List<Risk_Profile__c>();
                
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        Risk_Profile__c rp = riskProfilesToInsert[i];
                        if (rp.ML_Risk__c == true) {
                            insertedMLRP.add(rp);
                        }
                    }
                }
                
                if (!insertedMLRP.isEmpty()) {
                    createRiskProfileEnt(insertedMLRP, accIdRiskMap);
                }
            }
            catch(Exception e){
                Error_Logs__c err = new Error_Logs__c(Object__c = 'Risk_Profile__c',
                                                      Error_Message__c = e.getMessage(),
                                                      Class__c = 'CS_AutomaticRiskProfileCreation',
                                                      Method__c = 'createRiskProfile',
                                                      Type__c = 'SFDC',
                                                      Success__c = false);
                insert err;
            }
        } 
    }

    /**
     * @description Sets the primary and secondary risk reasons for an account-based risk profile.
     * @param accountRisk The Account Risk record associated with the risk.
     * @param riskProfile The Risk Profile being created or updated.
     */
    @TestVisible
    private static void setRiskReasons(Account_Risk__c accountRisk, Risk_Profile__c riskProfile) {
        if(accountRisk == null){
            return;
        }
        List<CS_GenericValueCompareClass> scoreList = new List<CS_GenericValueCompareClass>();
        String lowestScoreField;
        if (accountRisk.Adoption_Score__c < 20) {
            scoreList.add(new CS_GenericValueCompareClass('Adoption_Score__c', accountRisk.Adoption_Score__c));
        }
        if (accountRisk.OnBoarding_Score__c < 20) {
            scoreList.add(new CS_GenericValueCompareClass('OnBoarding_Score__c', accountRisk.OnBoarding_Score__c));
        }
        if (accountRisk.Product_Score__c < 14) {
            scoreList.add(new CS_GenericValueCompareClass('Product_Score__c', accountRisk.Product_Score__c));
        }
        if (accountRisk.Support_Score__c < 14) {
            scoreList.add(new CS_GenericValueCompareClass('Support_Score__c', accountRisk.Support_Score__c));
        }
        if(scoreList.isEmpty()){
            return;
        }
        scoreList.sort();
        lowestScoreField = scoreList[0].key;

        String primaryRiskReason;
        String secondaryRiskReason;
    
        switch on lowestScoreField {
            when 'OnBoarding_Score__c' {
                primaryRiskReason = 'Adoption';
                secondaryRiskReason = 'Activation';
            }
            when 'Adoption_Score__c' {
                primaryRiskReason = 'Adoption';
                secondaryRiskReason = 'Lack of Adoption';
            }
            when 'Product_Score__c' {
                primaryRiskReason = 'Product';
                secondaryRiskReason = 'Product Defect';
            }
            when 'Support_Score__c' {
                primaryRiskReason = 'Support issues';
                secondaryRiskReason = 'Support Issues';
            }
        }
        riskProfile.Primary_Risk_Reason__c = primaryRiskReason;
        riskProfile.Secondary_Risk_Reason__c = secondaryRiskReason;
    }
    
    
    /**
     * @description RRR-66, Creates Risk Profile records for Cases where Customer_Sentiments__c changed to 'Red'.
     * @param caseIds List of Case record Ids that meet the trigger criteria.
     */
    @future(callout=false)
    public static void createRiskProfiles(Set<Id> caseIds) {
        List<Case> caseRecords = [SELECT Id,AccountId,CaseNumber,Entitlement__c FROM Case WHERE Id IN :caseIds];
        if (caseRecords.isEmpty()) {
            return;
        }

        Map<Id,Risk_Profile__c> caseToRiskProfile = new Map<Id,Risk_Profile__c>();
        
        for (Case cs : caseRecords) {
            Risk_Profile__c riskProfile = new Risk_Profile__c();            
            riskProfile.Account__c = cs.AccountId;
            riskProfile.Risk_Origin__c = 'Customer Success';
            riskProfile.Risk_Category__c = 'CSM Sentiment Risk';
            riskProfile.Risk_Type__c = 'Feature/Product Risk'; 
            riskProfile.Risk_Reason_Additional_Comments__c = URL.getOrgDomainURL().toExternalForm() + '/'+cs.ID;
            riskProfile.Risk_Level__c = 'High';
            riskProfile.Risk_Status__c = 'New';
            riskProfile.CSM_Case_Number__c = cs.Id;
            caseToRiskProfile.put(cs.Id, riskProfile);
        }

        if (!caseToRiskProfile.values().isEmpty()) {
            insert as user caseToRiskProfile.values();
        }
        
        List<Risk_Profile_Entitlement__c> rpeRecordsToInsert = new List<Risk_Profile_Entitlement__c>();
        for (Case cs : caseRecords) {
            cs.CSM_Risk_Profile__c = caseToRiskProfile.get(cs.Id).Id;
            if (caseToRiskProfile.containsKey(cs.Id) && String.isNotBlank(caseToRiskProfile.get(cs.Id).Id) && cs.Entitlement__c != null) {
                Risk_Profile_Entitlement__c rpe = new Risk_Profile_Entitlement__c();
                rpe.Risk_Profile__c =  caseToRiskProfile.get(cs.Id).Id;
                rpe.Entitlement__c = cs.Entitlement__c;
                rpeRecordsToInsert.add(rpe);
            }
        }
        if(!rpeRecordsToInsert.IsEmpty()){
            Database.insert(rpeRecordsToInsert, false);
        }
        
        update as user caseRecords;
    }
    
    /**
     * @description Updates Risk Profile or Mitigation Case comments if Customer Sentiment on a Case changes.Creates a new Risk Profile if sentiment becomes 'Red' and no open profile exists.
     * @param oldCaseMap Old Case records map
     * @param newCases List of new cases
     */
    public static void handleCustomerSentimentChange(Map<Id, Case> oldCaseMap, List<Case> newCases) {
      //  List<Case> newCases = newCaseMap.values();
        Map<Id, Case> caseIdsForRiskProfileCheck = new Map<Id, Case>();
        Set<Id> casesForNewRP = new Set<Id>();
        
        for (Case cs : newCases) {
            Case oldcase = oldCaseMap?.get(cs.Id);
            Boolean sentimentChanged = oldcase != null && (oldcase.Customer_Sentiments__c != cs.Customer_Sentiments__c);
            if(oldcase == null && cs.Customer_Sentiments__c == 'Red') {
                casesForNewRP.add(cs.Id);   
            }
            if(sentimentChanged){
                caseIdsForRiskProfileCheck.put(cs.Id,cs);
            }   
        }
        
        Map<Id, Risk_Profile__c> openRPByCaseId = new Map<Id, Risk_Profile__c>();
        for (Risk_Profile__c rp : [SELECT Id, IsClosed__c, Comments__c, CSM_Case_Number__c, Mitigation_Case_Number__c, Mitigation_Case_Number__r.Risk_Comments__c
            					   FROM Risk_Profile__c
            					   WHERE IsClosed__c = false AND Risk_Validation_Status__c != 'Invalid' AND CSM_Case_Number__c IN :caseIdsForRiskProfileCheck.keySet() order by createddate DESC]) {
            if(!openRPByCaseId.containsKey(rp.CSM_Case_Number__c)){
                openRPByCaseId.put(rp.CSM_Case_Number__c, rp);
            }
        }
        List<sObject> commentsToInsert = new List<sObject>();
    
        for (Case newCase : caseIdsForRiskProfileCheck.values()) {
            String newSentiment = newCase.Customer_Sentiments__c;
            Risk_Profile__c openRP = openRPByCaseId.get(newCase.Id);
            String newComment = 'Case Customer Sentiment changed to ' + newSentiment;
            
                if (openRP != null) {
                    if (openRP.Mitigation_Case_Number__c != null) {
                        SObject mCase = Case.sObjectType.newSObject();
                        mCase.put('Id', openRP.Mitigation_Case_Number__c);
                        mCase.put('Comments', newComment);
                        commentsToInsert.add(mCase);
                    } else {
                        SObject rpUpdate = openRP.Id.getSObjectType().newSObject();
                        String existingComment = openRP.Comments__c;
                        rpUpdate.put('Id', openRP.Id);
                        rpUpdate.put('Comments__c', String.isNotBlank(existingComment) ? existingComment + '\n' + newComment : newComment);
                        commentsToInsert.add(rpUpdate);
                    }
                } else if(openRP == null && newCase.Customer_Sentiments__c == 'Red'){
                     casesForNewRP.add(newCase.Id); 
                }
        }
        

        if (!casesForNewRP.isEmpty()) {
            if(!(System.isBatch() || System.isFuture() || System.isQueueable())){
                CS_AutomaticRiskProfileCreation.createRiskProfiles(casesForNewRP);
            }
        }
        if (!commentsToInsert.isEmpty()) {
            Database.update(commentsToInsert, false);
        }
    }
    
     /**
     * @description Insert Risk Profile Entitlements for ML Risks.
     * @param rpList new Risk Profiles inserted
     * @param accIdRiskMap account and account risks map to get the entitlements.
     */
    public static void createRiskProfileEnt(List<Risk_Profile__c> rpList, Map<Id, SObject> accIdRiskMap) {
        List<Risk_Profile_Entitlement__c> rpeRecordsToInsert = new List<Risk_Profile_Entitlement__c>();
        for (Risk_Profile__c rp : rpList) {
            List<String> entIdsList = accIdRiskMap.containsKey(rp.Account__c) && accIdRiskMap.get(rp.Account__c).get('Entitlements__c') != null ? String.valueOf(accIdRiskMap.get(rp.Account__c).get('Entitlements__c')).replaceAll('\\s+', '').split(',') : null;
            for(String entId: entIdsList){
                Risk_Profile_Entitlement__c rpe = new Risk_Profile_Entitlement__c();
                rpe.Risk_Profile__c =  rp.Id;
                rpe.Entitlement__c = Id.ValueOf(entId);
                rpeRecordsToInsert.add(rpe); 
            }
        }
        if(!rpeRecordsToInsert.IsEmpty()){
            Database.insert(rpeRecordsToInsert, false);
        }          
    }
    
     /**
     * @description Builds a formatted section of clickable Salesforce record links from a comma-separated list of record IDs.
     *              Each record ID will be converted into a full Salesforce URL with line breaks.
     * @param baseUrl The base URL of the Salesforce org (e.g., https://yourdomain.my.salesforce.com).
     * @param sectionTitle The label/title for the section (e.g., "Opportunities", "Entitlements").
     * @param recordIds A comma-separated string of Salesforce record IDs.
     * @param createLink Whether we need to create a link for the IDs we are sending.
     * @return A formatted multiline string containing the section title followed by clickable record links.
     */
 	public static String buildLinksSection(String baseUrl, String sectionTitle, String recordIds, Boolean createLink) {
        if (String.isBlank(recordIds)) return '';
        // Remove spaces and format links
        
        String cleaned = recordIds.replaceAll('\\s+', '').replaceAll(',', '\n' + '-' + baseUrl + '/');
        if(!createLink){
            cleaned = recordIds.replaceAll('\\s+', '').replaceAll(',', '\n' + '- ');
        }
        return sectionTitle + ' - \n' + (createLink ? '- ' + baseUrl +  '/' : '- ') + cleaned + '\n\n';
    }


     /**
     * @description Retrieves the most recently modified Custom_Configuration_Change__c record.
     *              This method is used to get the current risk profile frequency configuration.
     * @return The latest Custom_Configuration_Change__c record.
     */
    @AuraEnabled(cacheable=true)
    public static Custom_Configuration_Change__c getRPFrequencySettingRecord() {
        List<Custom_Configuration_Change__c> settings = [ SELECT Last_Run__c, Config_Type__c, Next_Run__c, Config_For__c, LastModifiedBy.Name, RecordTypeId, Config_Disabled__c FROM Custom_Configuration_Change__c WHERE RecordType.DeveloperName = 'RP_Frequency_Config' ORDER BY LastModifiedDate DESC LIMIT 1];
        return settings.isEmpty() ? null : settings[0];
    }
}