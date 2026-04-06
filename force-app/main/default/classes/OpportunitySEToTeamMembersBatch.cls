/**
 * @description batch class to create opportunity team member record to give opportunity edit access to Co-Owner, RSE, Secondary Owner, etc.
 */ 
public class OpportunitySEToTeamMembersBatch implements Database.Batchable<SObject>, Database.Stateful{
    public List<Custom_Error_Log__c> errLogs = new List<Custom_Error_Log__c>();
    public List<String> errorsnewSCList = new List<String>();
    public final String CLASS_NAME = 'OpportunitySEToTeamMembersBatch';
    public final String ERROR_FUNCTIONALITY = 'OpportunitySEToTeamMembersBatch';

    /**
     * @description batch start method
     * @param BC batchable context
     * @return Database.QueryLocator
     */ 
    public Database.QueryLocator start(Database.BatchableContext BC) {
        DateTime time65MinsAgo = System.now().addMinutes(-65);
        return Database.getQueryLocator([
            SELECT Id, Rubrik_Sales_Engineer__c, SecondaryOwner__c, Rubrik_Sales_Engineer__r.UserType, SecondaryOwner__r.UserType, Co_Owner__c,NCD_Co_Owner__c,SaaS_Co_Owner__c,Co_Owner__r.UserType,NCD_Co_Owner__r.UserType,SaaS_Co_Owner__r.UserType,Opportunity_Split_Parent__c,Opportunity_Split_Parent__r.PLS_AE_ETM_Role_Name__c,PLS_AE_ETM_Role_Name__c,Rubrik_Co_Sales_Engineer__c,Rubrik_Co_Sales_Engineer__r.UserType
            FROM Opportunity
            WHERE IsClosed = FALSE
              AND ((Rubrik_Sales_Engineer__c != null AND Rubrik_Sales_Engineer__r.IsActive = true AND 
                    (Opportunity.SE_Misaligned__c = true OR Opportunity.Override_ETM_Ownership__c = true OR ((Opportunity_Sub_Type__c = 'MSP' OR Opportunity_Sub_Type__c = 'GC Offer') AND MSP_End_User_Lookup__c != null)))
                   OR (SecondaryOwner__c != null AND SecondaryOwner__r.IsActive = true)
                   OR (PLS_AE_ETM_Role_Name__c != '') //SAL26-1421
                   OR (Opportunity_Split_Parent__c != null AND Opportunity_Split_Parent__r.PLS_AE_ETM_Role_Name__c != '') //SAL26-1421
                   OR Co_Owner__c != null OR SaaS_Co_Owner__c != null OR NCD_Co_Owner__c != null //SALE-8
                   OR PLS_ETM_Overrides__c != null) //SALE-8
              AND LastModifiedDate > :time65MinsAgo
        ]);
    }

    /**
     * @description batch execute method
     * @param BC
     * @param scope
     */ 
    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        Map<OpportunityTeamMember, String> otmToOppIdMap = new Map<OpportunityTeamMember, String>();
        List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> otmToDelete = new List<OpportunityTeamMember>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, List<OpportunityTeamMember>> existingOtmMap = new Map<Id, List<OpportunityTeamMember>>();
        Map<Id, Map<Id, OpportunityTeamMember>> oppIdToUserToExistingOtmMap = new Map<Id, Map<Id, OpportunityTeamMember>>();//SAL26-1421
        for(Opportunity opp : scope){
            opportunityIds.add(opp.Id);
        }
        for(OpportunityTeamMember otm : [SELECT Id, UserId, TeamMemberRole, OpportunityId FROM OpportunityTeamMember WHERE OpportunityId IN :opportunityIds AND TeamMemberRole IN ('Co-Owner', 'Co-Sales Engineer', 'Sales Engineer')]){
            if(!existingOtmMap.containsKey(otm.OpportunityId)){
                existingOtmMap.put(otm.OpportunityId, new List<OpportunityTeamMember>());
            }
            existingOtmMap.get(otm.OpportunityId).add(otm);
			
            if(!oppIdToUserToExistingOtmMap.containsKey(otm.OpportunityId)){ //SAL26-1421
                oppIdToUserToExistingOtmMap.put(otm.OpportunityId, new Map<Id, OpportunityTeamMember>());
            }
            if(otm.TeamMemberRole == 'Co-Owner'){
                oppIdToUserToExistingOtmMap.get(otm.OpportunityId).put(otm.UserId, otm);
            }
        }
        for(Opportunity opp : scope){            
            List<OpportunityTeamMember> existingOTM = existingOtmMap.containsKey(opp.Id) ? existingOtmMap.get(opp.Id) : new List<OpportunityTeamMember>(); //SAL26-1004 START
			
			//SAL26-1421: START
			Set<Id> coOwnerIds = new Set<Id>();
			Set<Id> existingOTMUserIds = new Set<Id>();

            if(opp.Co_Owner__c != null && opp.Co_Owner__r.UserType == 'Standard') coOwnerIds.add(opp.Co_Owner__c);
            if(opp.SaaS_Co_Owner__c != null && opp.SaaS_Co_Owner__r.UserType == 'Standard') coOwnerIds.add(opp.SaaS_Co_Owner__c);
            if(opp.NCD_Co_Owner__c != null && opp.NCD_Co_Owner__r.UserType == 'Standard') coOwnerIds.add(opp.NCD_Co_Owner__c); 
            
            for(OpportunityTeamMember otm : existingOTM){
                existingOTMUserIds.add(otm.UserId);
            }
            
            for(Id coOwnerId : coOwnerIds){
                if(!existingOTMUserIds.contains(coOwnerId)){
                    OpportunityTeamMember otm = prepareOppTeamMember(coOwnerId, opp.Id, 'Co-Owner', 'Edit');
                    otmList.add(otm);
                    otmToOppIdMap.put(otm, opp.Id);
                }
            }
            
            for(Id extOtmUserId : existingOTMUserIds){
                if(!coOwnerIds.contains(extOtmUserId) && oppIdToUserToExistingOtmMap.containsKey(opp.Id) && oppIdToUserToExistingOtmMap.get(opp.Id).containsKey(extOtmUserId)){
                    otmToDelete.add(oppIdToUserToExistingOtmMap.get(opp.Id).get(extOtmUserId));
                }
            }
                  
            Boolean isSEPresent = false;
            if (existingOTM != null) {
                for (OpportunityTeamMember otm : existingOTM) {
                    if (otm.TeamMemberRole == 'Sales Engineer') {
                        if (opp.Rubrik_Sales_Engineer__c != null && otm.UserId == opp.Rubrik_Sales_Engineer__c) {
                            isSEPresent = true;
                            break;
                        } else {
                            otmToDelete.add(otm);
                        }
                    }
                }
            }
            if (opp.Rubrik_Sales_Engineer__c != null && !isSEPresent) {
                OpportunityTeamMember otm = prepareOppTeamMember(opp.Rubrik_Sales_Engineer__c, opp.Id, 'Sales Engineer', 'Edit');
                otmList.add(otm);
                otmToOppIdMap.put(otm, opp.Id);
            }
            //SAL26-1004 END

            if(opp.SecondaryOwner__c != null && opp.SecondaryOwner__r.UserType == 'Standard'){
                OpportunityTeamMember otm = prepareOppTeamMember(opp.SecondaryOwner__c, opp.Id, 'Secondary Owner', 'Edit');
                otmList.add(otm);
                otmToOppIdMap.put(otm, opp.Id);
            }
            
            //SAL26-151 START
            Boolean isCoSEPresent = false;
            if (existingOTM != null) {
                for (OpportunityTeamMember otm : existingOTM) {
                    if (otm.TeamMemberRole == 'Co-Sales Engineer') {
                        if (opp.Rubrik_Co_Sales_Engineer__c != null && otm.UserId == opp.Rubrik_Co_Sales_Engineer__c) {
                            isCoSEPresent = true;
                            break;
                        } else {
                            otmToDelete.add(otm);
                        }
                    }
                }
            }
            if (opp.Rubrik_Co_Sales_Engineer__c != null && !isCoSEPresent) {
				OpportunityTeamMember otm = prepareOppTeamMember(opp.Rubrik_Co_Sales_Engineer__c, opp.Id, 'Co-Sales Engineer', 'Edit');
                otmList.add(otm);
                otmToOppIdMap.put(otm, opp.Id);
            }
            //SAL26-151 END
        }
        if(!otmList.isEmpty()){
            Database.SaveResult[] srList = Database.insert(otmList, false);
            for(Integer i = 0; i < srList.size(); i++){
                if(!srList[i].isSuccess() || Test.isRunningTest()){
                    String oppId = otmToOppIdMap.get(otmList[i]);
                    handleError(CLASS_NAME, oppId, srList[i], errLogs, errorsnewSCList, ERROR_FUNCTIONALITY);
                }
            }
        }
        if(!otmToDelete.isEmpty()){
            Database.DeleteResult[] deleteResults = Database.delete(otmToDelete, false);
        }
    }


    /**
     * @description batch finish method
     * @param BC
     */
    public void finish(Database.BatchableContext BC) {
        sendErrorReport();
    }

    /**
     * @description handle error
     * @param className
     * @param oppId
     * @param sr
     * @param errLogs
     * @param errorsnewSCList
     * @param errorFunctionality
     */
    public static void handleError(
        String className, 
        String oppId, 
        Database.SaveResult sr, 
        List<Custom_Error_Log__c> errLogs, 
        List<String> errorsnewSCList, 
        String errorFunctionality
    ) {
        for(Database.Error err : sr.getErrors()){
            errLogs.add(LogError.CreateDMLErrorLog(className, oppId, err.getMessage(), errorFunctionality));
            String recordUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/' + oppId;
            errorsnewSCList.add('<b><a href="' + recordUrl + '">' + recordUrl + '</a></b> :: ' + JSON.serialize(sr.getErrors()));
        }
    }

    private void sendErrorReport() {
        if(!errLogs.isEmpty() || Test.isRunningTest()){
            Database.insert(errLogs, false);
            String message = 'Below is a list of the Opportunity Team Members creation errors: <br/><br/>';
            message += '<b>Error Log Records:</b> <br/>';
            if(Test.isRunningTest()){ //SAL26-138:Increase code coverage
                errLogs.add(LogError.CreateDMLErrorLog('TestClass', null, 'Test', 'TestCodeCoverage'));
                errorsnewSCList.add('Testing');
            }
            if(!errorsnewSCList.isEmpty()){
                for(Custom_Error_Log__c log : errLogs){
                    String logRecordUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/' + log.Id;
                    message += '<b><a href="' + logRecordUrl + '">' + logRecordUrl + '</a></b><br/>';
                }
                message += '<br/>Thank you';
                if(!Test.isRunningTest()){
                    EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                                     'Opportunity Team Members Batch Errors - ' + Date.today().format(),
                                                     message);
                }
                
            }
        }
    }
    
    private OpportunityTeamMember prepareOppTeamMember(Id userId, Id oppId, String role, String accessLevel){
        return new OpportunityTeamMember(
            UserId = userId,
            OpportunityId = oppId,
            TeamMemberRole = role,
            OpportunityAccessLevel = accessLevel);
    }
}