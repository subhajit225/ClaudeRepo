/*******************************************************************************************************
Description : ETM-137: To update the UserTerritoryAssociation History as Active/Archived
Developer : Natesh
Date : 06/01/2020 
**********************************************************************************************************/
global class ETM_UpdateUTAHistoryRecordBatch implements Database.Batchable<sObject> {
    String strArchivedTerrName;
    String strActivatedTerrName;
    public ETM_UpdateUTAHistoryRecordBatch(String strActivatedTerrName,String strArchivedTerrName) {
        this.strArchivedTerrName = strArchivedTerrName;
        this.strActivatedTerrName = strActivatedTerrName;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select Id, Territory_Model__c, Territory_Model_State__c, Start_Date__c, End_Date__c from UserTerritoryAssociation_History__c where Territory_Model_State__c != \'Archived\' AND ';
        string whereClause = (strArchivedTerrName != null && strActivatedTerrName != null) ? ' (Territory_Model__c = :strActivatedTerrName OR Territory_Model__c = :strArchivedTerrName)' : (strActivatedTerrName != null) ? ' Territory_Model__c = :strActivatedTerrName' : ' Territory_Model__c = :strArchivedTerrName';
        query += whereClause;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<UserTerritoryAssociation_History__c> scope) {
        List<UserTerritoryAssociation_History__c> utaHistoryUpdateList = new List<UserTerritoryAssociation_History__c>();
        for(UserTerritoryAssociation_History__c utaHistItem : scope){
            if(utaHistItem.Territory_Model__c == strActivatedTerrName){
                //ETM-184: Start Date and End Date updates for commissions
                //utaHistItem.Start_Date__c = System.today();
                utaHistItem.Territory_Model_State__c = 'Active';
            }
            else if(utaHistItem.Territory_Model__c == strArchivedTerrName && utaHistItem.Territory_Model_State__c != 'Archived'){
                //update end_date only if it was not stamped already
                utaHistItem.End_Date__c = utaHistItem.End_Date__c != null ? utaHistItem.End_Date__c : System.today();
                utaHistItem.Territory_Model_State__c = 'Archived';
            }
            utaHistoryUpdateList.add(utaHistItem);
        }

        if(!utaHistoryUpdateList.isEmpty()){
            try{
                Database.update(utaHistoryUpdateList, false);
            }
            catch(Exception e){
                UserTerritoryAssociationHistoryHelper.CreateErrLogs(e.getMessage(),e.getStackTraceString(), 'ETM-UTA-History-Update', 'ETM_UpdateUTAHistoryRecordBatch');
            }
        }
    }

    global void finish(Database.BatchableContext bc) {}
}