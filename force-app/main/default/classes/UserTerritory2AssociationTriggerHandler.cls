/*****************************************************************************************
Description : Handler class for Territory2 trigger
Developer : Santosh/Chaitra
Date : 10/2019
*******************************************************************************************/


public class UserTerritory2AssociationTriggerHandler extends TriggerHandler {
    
    private Boolean isDisabled = false;
    public static Boolean runUTAHistoryMethod = true;

    public UserTerritory2AssociationTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_User_Territory_Trigger__c;
    }

    public override void beforeInsert() {
        //SAL21-320
        if(!isDisabled) {
            System.debug('@@@before insert Trigger');
            UserTerritory2AssociationTriggerHelper.validateAllowedUTAChanges(Trigger.new);
        }
    }

    public override void beforeUpdate() {
        //SAL21-320
        if(!isDisabled) {
            System.debug('@@@before update Trigger');
            UserTerritory2AssociationTriggerHelper.validateAllowedUTAChanges(Trigger.new);
        }
    }

    public override void beforeDelete() {}

    public override void afterInsert() {
        if(!isDisabled) {
            System.debug('@@@after Insert Trigger');
            UserTerritory2AssociationTriggerHelper.ownerAssignment(Trigger.new,null);
            UserTerritory2AssociationTriggerHelper.addNewRole(Trigger.new);
            //ETM-137: Create and update UTA History tracking record 
            if(runUTAHistoryMethod) {
                UserTerritory2AssociationTriggerHelper.createUTAHistory((Map<Id,UserTerritory2Association>)Trigger.newMap);
                CaseTriggerHandler.accountTerritoryToCaseTeams(Trigger.newMap.keySet(), 'User Territory Association insert', null);
            }
        }
    }

    public override void afterUpdate() {
       if(!isDisabled) {
            System.debug('@@@after update Trigger');
            UserTerritory2AssociationTriggerHelper.ownerAssignment(Trigger.new,(Map<Id,UserTerritory2Association>)Trigger.oldMap);
            UserTerritory2AssociationTriggerHelper.addORRemoveRole(Trigger.new,(Map<Id,UserTerritory2Association>)Trigger.oldMap);
            CaseTriggerHandler.accountTerritoryToCaseTeams(Trigger.newMap.keySet(), 'User Territory Association update', JSON.serialize(Trigger.oldMap));
        }
    }

    public override void afterDelete() {
        if(!isDisabled) {
            system.debug('In delete');
            UserTerritory2AssociationTriggerHelper.ownerAssignment(Trigger.old,null);
            UserTerritory2AssociationTriggerHelper.removeRTSEMorSED(Trigger.old,null);
            //ETM-137: Create and update UTA History tracking record
            if(runUTAHistoryMethod) {
                UserTerritory2AssociationTriggerHelper.updateUTAHistory((Map<Id,UserTerritory2Association>)Trigger.oldMap);
                CaseTriggerHandler.accountTerritoryToCaseTeams(null, 'User Territory Association delete', JSON.serialize(Trigger.oldMap));
            }

        }
    }

    public override void afterUndelete() {}
    
}