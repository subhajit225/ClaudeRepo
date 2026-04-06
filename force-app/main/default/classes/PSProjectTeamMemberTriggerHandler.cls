public class PSProjectTeamMemberTriggerHandler extends TriggerHandler {
    
    private Boolean isDisabled = false;
   
    
    public PSProjectTeamMemberTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    }
     public static void beforeInsert(list<PS_Project_Team_Member__c> PSProjectTeamMemberList){
        system.debug('I am in Before Insert handler');
        List<PermissionSetAssignment> PermissionSetList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'PS_Time_Management_User'];
        system.debug('PermissionSetList--'+PermissionSetList);
        string UserId = UserInfo.getUserId();
        for(PS_Project_Team_Member__c PS: PSProjectTeamMemberList){
            for(PermissionSetAssignment per :PermissionSetList){
                string PsId = PS.Team_Member__c;
                string PerId =per.AssigneeId;
                //if(){
                if(per.AssigneeId == UserId && PS.Team_Member__c != UserId){
                    system.debug('per.AssigneeId--'+per.AssigneeId); 
                    system.debug('UserId--'+UserId);
                    system.debug('PS.Team_Member__c--'+PS.Team_Member__c);
                    PS.addError('You don\'t have permission to add user except you.');
                }
                //  }
            }
        }
    }
    public override void afterUpdate() {
        if(!isDisabled) {
            system.debug('New________ '+trigger.new);
            system.debug('New________ '+trigger.old);
            for(SObject member : trigger.new) {
                PS_Project_Team_Member__c newMember = (PS_Project_Team_Member__c) member ;
                PS_Project_Team_Member__c oldMember = (PS_Project_Team_Member__c ) trigger.OldMap.get(member.Id);
                if(newMember.Team_Member__c != oldMember.Team_Member__c){
                  PSProjectTeamMEmberTriggerHelper.cleanTimeEntryRecord(newMember.PS_Project__c, oldMember.Team_Member__c);    
                }    
            }
        }
    }
     public static void deletemethod(List<PS_Project_Team_Member__c> pstlst){
        system.debug('I am in Before Insert handler');
        List<PermissionSetAssignment> PermissionSetList = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'PS_Time_Management_User'];
        system.debug('PermissionSetList--'+PermissionSetList);
        id UserId = UserInfo.getUserId();
        for(PS_Project_Team_Member__c PS: pstlst){
            for(PermissionSetAssignment per :PermissionSetList){
                if(per.AssigneeId == UserId && PS.Team_Member__c != UserId){
                    system.debug('per.AssigneeId--'+per.AssigneeId); 
                    system.debug('UserId--'+UserId);
                    system.debug('PS.Team_Member__c--'+PS.Team_Member__c);
                    PS.addError('You don\'t have permission to delete user except you.');
                }
            }
        }
    }
    public override void afterDelete() {
        if(!isDisabled) {
            system.debug('New________ '+trigger.old);
            map<Id, Id> projectwithMemberMap = new map<Id, Id>();
            for(SObject member : trigger.old) {
                PS_Project_Team_Member__c oldMember = (PS_Project_Team_Member__c ) member;
                PSProjectTeamMEmberTriggerHelper.cleanTimeEntryRecord(oldMember.PS_Project__c, oldMember.Team_Member__c);   
            }
        }
    }

    
}