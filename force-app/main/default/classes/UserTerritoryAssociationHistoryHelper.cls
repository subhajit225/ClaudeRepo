/*********************************************************************************************************
Description : ETM-137: To create/update the UserTerritoryAssociation History when UTA is created or deleted
Developer : Natesh 
Date : 06/01/2020
**********************************************************************************************************/
public class UserTerritoryAssociationHistoryHelper implements Queueable{
    Set<Id> insertUTAIds;
    Set<Id> deleteUTAIds;
    String invokedFrom;
    //ETM-184: Start Date and End Date updates for commissions
    Map<Id, Date> insertUTAMap = new Map<Id, Date>();
    Map<Id, Date> updateUTAHistMap = new Map<Id, Date>();
    Set<Id> updateUTAIds = new Set<Id>();
    Set<Territory_Owner_Assignment__c> terrOwnerAssignSet = new Set<Territory_Owner_Assignment__c>(); //SAL25-57

    public UserTerritoryAssociationHistoryHelper(Set<Id> insertUTAIds, Set<Id> deleteUTAIds, String invokedFrom) {
        this.insertUTAIds = insertUTAIds;
        this.deleteUTAIds = deleteUTAIds;
        this.invokedFrom = invokedFrom;
    }

    //ETM-184: Start Date and End Date updates for commissions
    public UserTerritoryAssociationHistoryHelper(Map<Id, Date> insertUTAMap, Map<Id, Date> updateUTAHistMap, set<Id> updateUTAIds, String invokedFrom) {
        this.insertUTAMap = insertUTAMap;
        this.updateUTAHistMap = updateUTAHistMap;
        this.updateUTAIds = updateUTAIds;
        this.invokedFrom = invokedFrom;
    }

    //SAL25-57
    public UserTerritoryAssociationHistoryHelper(Set<Territory_Owner_Assignment__c> terrOwnerAssignSet, Map<Id, Date> insertUTAMap, Map<Id, Date> updateUTAHistMap, set<Id> updateUTAIds, String invokedFrom) {
        this.insertUTAMap = insertUTAMap;
        this.updateUTAHistMap = updateUTAHistMap;
        this.updateUTAIds = updateUTAIds;
        this.invokedFrom = invokedFrom;
        this.terrOwnerAssignSet = terrOwnerAssignSet;
    }
    
    //ETM-184: Start Date and End Date updates for commissions
    public void execute(QueueableContext context) {
        if(invokedFrom == 'BATCH'){
            createUTAHistory(insertUTAMap.keySet(), insertUTAMap);
            updateUTAHistory(updateUTAHistMap.keySet(), updateUTAHistMap, updateUTAIds);
            //SAL25-57
            if(terrOwnerAssignSet!= null && !terrOwnerAssignSet.isEmpty()){
                List<Territory_Owner_Assignment__c> terrOwnerAssignList = new List<Territory_Owner_Assignment__c>();
                terrOwnerAssignList.addall(terrOwnerAssignSet);
                List<Database.SaveResult> srList = Database.insert(terrOwnerAssignList, false);
                LogError.createDMLErrorLog((List<SObject>)terrOwnerAssignList, srList, 'UserTerritoryAssociationHistoryHelper','ETM - Insert TerritoryOwnerAssignment');
            }
        }
        else if(invokedFrom == 'TRIGGER-INSERT'){
            createUTAHistory(insertUTAIds, insertUTAMap); 
        }
        else if(invokedFrom == 'TRIGGER-DELETE'){
            updateUTAHistory(deleteUTAIds, updateUTAHistMap, updateUTAIds);
        }
        else{}
    }
    
    /**
        @Description : Create UTA History record when UTA record is created
    */
    //ETM-184: Start Date and End Date updates for commissions
    public static void createUTAHistory(Set<Id> newUTAIds, Map<Id, Date> insertUTAMap) {
        List<UserTerritoryAssociation_History__c> utaHistoryList = new List<UserTerritoryAssociation_History__c>();
        for(UserTerritory2Association uta :[select Id, Territory2Id, Territory2.Adaptive_Territory_Id__c, 
                                            Territory2.Territory2Model.DeveloperName, 
                                            Territory2.Territory2Model.State, 
                                            Territory2.Territory2Type.DeveloperName, 
                                            UserId, RoleInTerritory2 from UserTErritory2Association
                                            where Id IN :newUTAIds]) {
            UserTerritoryAssociation_History__c utaHist = new UserTerritoryAssociation_History__c();
            utaHist.Territory_Id__c = uta.Territory2Id;
            utaHist.Adaptive_Territory_Id__c = uta.Territory2.Adaptive_Territory_Id__c;
            utaHist.Territory_Model__c = uta.Territory2.Territory2Model.DeveloperName;
            utaHist.Territory_Model_State__c = uta.Territory2.Territory2Model.State;
            utaHist.Territory_Type__c = uta.Territory2.Territory2Type.DeveloperName;
            utaHist.User__c = uta.UserId;
            utaHist.User_Territory_Role__c = uta.RoleInTerritory2;
            //ETM-184: Start Date and End Date updates for commissions
            //utaHist.Start_Date__c = System.today();
            utaHist.Start_Date__c = !insertUTAMap.isEmpty() && insertUTAMap.containsKey(uta.Id) ? insertUTAMap.get(uta.Id) : System.today();
            utaHist.UserTerritoryAssociation_Id__c = uta.Id;

            utaHistoryList.add(utaHist);
        }
        if(!utaHistoryList.isEmpty()){
            try{
                Database.insert(utaHistoryList, false);
            }
            catch(Exception e){
                CreateErrLogs(e.getMessage(),e.getStackTraceString(), 'ETM-UTA-History-Insert', 'UserTerritory2AssociationTriggerHelper');
            }
        }
    }

    /**
        @Description : Create UTA History record when UTA record is deleted
    */
    //ETM-184: Start Date and End Date updates for commissions
    public static void updateUTAHistory(Set<Id> oldUTAIds, Map<Id, Date> updateUTAHistMap, set<Id> updateUTAIds) {
        Map<Id, UserTerritoryAssociation_History__c> utaHistoryMap = new Map<Id, UserTerritoryAssociation_History__c>();
        List<UserTerritoryAssociation_History__c> utaHistoryUpdateList = new List<UserTerritoryAssociation_History__c>();
        for(UserTerritoryAssociation_History__c utaHistItem :[select Id, UserTerritoryAssociation_Id__c, End_Date__c, Start_Date__c 
                                                          from UserTerritoryAssociation_History__c
                                                          where UserTerritoryAssociation_Id__c IN :oldUTAIds]){
            utaHistoryMap.put(utaHistItem.UserTerritoryAssociation_Id__c, utaHistItem);
            //ETM-184: Start Date and End Date updates for commissions
            //utaHistItem.End_Date__c = System.today();
            if(!updateUTAIds.isEmpty() && updateUTAIds.contains(utaHistItem.UserTerritoryAssociation_Id__c)) {
                if(utaHistItem.Start_Date__c != updateUTAHistMap.get(utaHistItem.UserTerritoryAssociation_Id__c)){
                    utaHistItem.Start_Date__c = updateUTAHistMap.get(utaHistItem.UserTerritoryAssociation_Id__c);
                    utaHistoryUpdateList.add(utaHistItem);
                }
            }
            else{
                utaHistItem.End_Date__c = !updateUTAHistMap.isEmpty() && updateUTAHistMap.containsKey(utaHistItem.UserTerritoryAssociation_Id__c) ? updateUTAHistMap.get(utaHistItem.UserTerritoryAssociation_Id__c) : System.today();
                utaHistoryUpdateList.add(utaHistItem);
            }
        }
        if(!utaHistoryUpdateList.isEmpty()){
            try{
                Database.update(utaHistoryUpdateList, false);
            }
            catch(Exception e){
                CreateErrLogs(e.getMessage(),e.getStackTraceString(), 'ETM-UTA-History-Update', 'UserTerritoryAssociationHistoryHelper');
            }
        }
    }

    public static void CreateErrLogs(string execptionMsg , string trace, String functionality, string className) {
        Custom_Error_Log__c CaptureError = new Custom_Error_Log__c();
        CaptureError.Class__c = className;
        CaptureError.Functionality__c = functionality;
        if(execptionMsg != NULL){
            CaptureError.Exception_Message__c= execptionMsg;
            CaptureError.ErrorTrace__c= trace;
        }
        insert CaptureError;
    }
}