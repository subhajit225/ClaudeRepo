/********************************************************************************
 * @description       : AARObjectTriggerHandler to keep helper methods for AARObjectTrigger
 * @created on        : 27-12-2022
 * @created by        : Mustakim S
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 27-12-2022          SAL23-508              mustakim.shaikh@rubrik.com
 ********************************************************************************/
public with sharing class AARObjectTriggerHandler {
    
    public static Boolean isOppsUpdated = false; //Avoid Opportunity Sync Recursion
    public static void checkForExistingAARs(List<After_Action_Review__c> newAARs) {
    
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        
        for (After_Action_Review__c ar : newAARs) {
            oppIds.add(ar.Opportunity__c);
        }
        
        if(!oppIds.isEmpty()){
            oppMap.putAll([SELECT Id, CloseDate, OwnerId, Opportunity_Owner_Manager_Email__c, Rubrik_Sales_Engineer__c, Rubrik_Sales_Engineer_Manager_Email__c, (SELECT Id FROM After_Action_Reviews__r ) FROM Opportunity WHERE Id IN :oppIds]);
        }
        
        if(!oppMap.isEmpty()){
            for (After_Action_Review__c ar : newAARs) {
                if(oppMap.containsKey(ar.Opportunity__c)) {
                    if(oppMap.get(ar.Opportunity__c).After_Action_Reviews__r.Size() > 0){
                        ar.addError('After Action Review already exists on this Opportunity. Only one AAR is allowed per Opportunity.');
                    }
                    ar.Opportunity_ClosedDate__c = oppMap.get(ar.Opportunity__c).CloseDate;
                    ar.Opportunity_Owner__c = oppMap.get(ar.Opportunity__c).OwnerId;
                    if(oppMap.get(ar.Opportunity__c).Opportunity_Owner_Manager_Email__c != null) ar.Opportunity_Owner_Manager_Email__c = oppMap.get(ar.Opportunity__c).Opportunity_Owner_Manager_Email__c;
                    if(oppMap.get(ar.Opportunity__c).Rubrik_Sales_Engineer__c != null) ar.Sales_Engineer__c = oppMap.get(ar.Opportunity__c).Rubrik_Sales_Engineer__c;
                    if(oppMap.get(ar.Opportunity__c).Rubrik_Sales_Engineer_Manager_Email__c != null) ar.Sales_Engineer_Manager_Email__c = oppMap.get(ar.Opportunity__c).Rubrik_Sales_Engineer_Manager_Email__c;
                    ar.Status__c = 'Submitted';
                }
            }
        }
        
        
  }

    public static void syncAAROpportunity(List<After_Action_Review__c> aarList, Boolean isInsert){
        List<AAR_Mapping__mdt> ARRtoOppSyncList =[SELECT Opportunity_Field_Name__c, AAR_Field_Name__c FROM AAR_Mapping__mdt];
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, After_Action_Review__c> aarMap = new Map<Id, After_Action_Review__c>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Opportunity> updateOppList = new List<Opportunity>();
        List<String> oppFieldNames = new List<String>();
        Boolean isSyncRequired = false;
        Set<String> arrIdSet = new Set<String>();
        
        for(AAR_Mapping__mdt meta : ARRtoOppSyncList){
            oppFieldNames.add(meta.Opportunity_Field_Name__c);
        }
        
        for(After_Action_Review__c aar : aarList){
            oppIdSet.add(aar.Opportunity__c);
            aarMap.put(aar.Opportunity__c, aar); 
            arrIdSet.add(aar.Id);
        }
        
    
        if(!oppIdSet.isEmpty()){
            String query = 'SELECT Id, After_Action_Form_Submitted__c, ' + String.escapesinglequotes(String.join( oppFieldNames , ',' )) + ' FROM Opportunity WHERE Id IN :oppIdSet';
            oppList = Database.query( query );
        }
    
        for(Opportunity opp : oppList){
            if(!opp.After_Action_Form_Submitted__c){
                opp.After_Action_Form_Submitted__c =true;
            }
            for(AAR_Mapping__mdt meta : ARRtoOppSyncList){
                if(aarMap.get(opp.Id).get(meta.AAR_Field_Name__c) != null && 
                   (aarMap.get(opp.Id).get(meta.AAR_Field_Name__c) != opp.get(meta.Opportunity_Field_Name__c))) 
                   {
                    opp.put(meta.Opportunity_Field_Name__c, aarMap.get(opp.Id).get(meta.AAR_Field_Name__c));
                    isSyncRequired = true;
                }
            }
            if(isSyncRequired || isInsert){
                updateOppList.add(opp);
                isSyncRequired = false;
            }
        }
    
        if(!updateOppList.isEmpty()){
            bypassOpportunityUpdate(updateOppList, arrIdSet);
        }
    }

    //Bypass Trigger & VR
    public static void bypassOpportunityUpdate(List<Opportunity> oppsList, Set<String> arrIdSet){
        List<After_Action_Review__c> updateAARList = new List<After_Action_Review__c>();
        List<ShGl_DisableBusinessLogic__c> dflList = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c modifydfl = new ShGl_DisableBusinessLogic__c();
        dflList = [SELECT id,Disable_Opportunity_Validation_Rules__c,Name,SetupOwnerId FROM ShGl_DisableBusinessLogic__c];
        Boolean modifiedflag = false;
        Boolean createflag = false;

        for(ShGl_DisableBusinessLogic__c dfl : dflList){
                if(userinfo.getUserId() == dfl.SetupOwnerId){
                    modifydfl.Id = dfl.Id;
                    if(!dfl.Disable_Opportunity_Validation_Rules__c){
                        modifydfl.Disable_Opportunity_Validation_Rules__c = true;
                        modifiedflag = true;
                    }
                }
            }
            
        try{
            if(modifiedflag){
                update modifydfl;
            }
            if(modifydfl.Id == null){
                createflag = true;
                modifydfl.Disable_Opportunity_Validation_Rules__c = true;
                modifydfl.SetupOwnerId = userinfo.getUserId();
                insert modifydfl;
            }
            if(!oppsList.isEmpty()){
                isOppsUpdated = true;
                flowcontroll.opportunityTriggerHandler = false;
                update oppsList; //updating Opportunity
                List<After_Action_Review__c> aarList = new List<After_Action_Review__c>();
                aarList = [select Id,Is_sync_with_Opportunity__c,Sync_error_message__c from After_Action_Review__c where Id =: arrIdSet];
                for(After_Action_Review__c aar : aarList){
                    aar.Is_sync_with_Opportunity__c = true;
                    aar.Sync_error_message__c = '';
                }
                if(!aarList.isEmpty()){
                    flowcontroll.AARTrigger = false;
                    update aarList;
                }
                flowcontroll.opportunityTriggerHandler = true;
            }
            if(modifiedflag){
                modifydfl.Disable_Opportunity_Validation_Rules__c = false;
                update modifydfl;
            }  
            if(createflag){
                delete modifydfl;
            }
        }catch(Exception e){
            system.debug('Exception occurred '+e.getMessage());
            string errorMsg = e.getMessage();
             
            if(modifiedflag){
                modifydfl.Disable_Opportunity_Validation_Rules__c = false;
                update modifydfl;
            }  
            if(createflag && modifydfl != null){
                delete modifydfl; 
            }
            List<After_Action_Review__c> aarList = new List<After_Action_Review__c>();
            aarList = [select Id,Is_sync_with_Opportunity__c,Sync_error_message__c from After_Action_Review__c where Id =: arrIdSet];
            for(After_Action_Review__c aar : aarList){
                aar.Is_sync_with_Opportunity__c = false;
                aar.Sync_error_message__c = e.getMessage();
            }
            if(!aarList.isEmpty()){
                flowcontroll.AARTrigger = false;
                update aarList;
            }
        }
    }
    
    
    @InvocableMethod(label='Bypass Opportunity Trigger' description='Disable/Bypass the Opportunity trigger for this transaction')

    public static void stopOppTrigger(){
        FlowControll.opportunityTriggerHandler = false;
    }
    
            
}