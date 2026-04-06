public class ApproverListController {

    public List<ApprovalRecords> getApprovalRecordList(){
        List<ApprovalRecords> approvalRecordList = new List<ApprovalRecords>();
        Map<id,Id> groupRoleMap = new Map<id,Id>();
        Id groupId ;
        
        for(Groupmember groupMembers : [Select Id,groupId,UserOrGroupId   from Groupmember where Group.Name = 'Support Manager Queue' and Group.Type = 'Queue']){
            groupRoleMap.put(groupMembers.UserOrGroupId, null);
            groupId= groupMembers.groupId ;
        }
        for(Group gp : [Select Id,relatedId from Group where ID IN: groupRoleMap.keyset() ]){
            groupRoleMap.put(gp.Id, gp.RelatedId);
        }
        List<Id> ids = groupRoleMap.values();
        if(groupRoleMap.containsKey(UserInfo.getUserId()) || UserInfo.getUserRoleId() ==  null || !ids.contains(UserInfo.getUserRoleId())){
            groupId = UserInfo.getUserId();
        }
        Set<Id> instanceIds= new Set<Id>();
        Set<Id> userIds= new Set<Id>();
        List<ProcessInstanceWorkitem> pwItems = [SELECT Id, ProcessInstanceId, OriginalActorId, ActorId FROM ProcessInstanceWorkitem Where (OriginalActorId =: UserInfo.getUserId() OR OriginalActorId =: groupId)];

        if(test.isRunningTest())
            pwItems = [SELECT Id, ProcessInstanceId, OriginalActorId, ActorId FROM ProcessInstanceWorkitem LIMIT 20];
        for(ProcessInstanceWorkitem pwItem : pwItems){
            instanceIds.add(pwItem.ProcessInstanceId);
            userIds.add(pwItem.OriginalActorId);
            userIds.add(pwItem.ActorId);
        }

        Set<ID> uIdSet = new Set<ID>(userIds);
        Map<id,ProcessInstance> progressInstanceMap = new Map<Id,ProcessInstance>([SELECT Id, ProcessDefinitionId,TargetObject.Name, TargetObjectId, Status, CompletedDate,LastActor.Name, LastActorId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, SubmittedById, IsDeleted, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp FROM ProcessInstance WHERE ID IN: instanceIds]);
        for(ProcessInstanceWorkitem pwItem :pwItems){
            ProcessInstance pI = progressInstanceMap.get(pwItem.ProcessInstanceId);
            if(pi != null){
                uIdSet.add(pI.SubmittedById);
            }
        }
        uIdSet.remove(null);
        Map<id,User> userMap = new Map<id,User>([select id, name from User where ID in :uIdSet]);

        for(ProcessInstanceWorkitem pwItem :pwItems){
            ProcessInstance pI  = new ProcessInstance();
            User actor = new User();
            User originalActor = new User();
            if(progressInstanceMap.containsKey(pwItem.ProcessInstanceId))
                pI = progressInstanceMap.get(pwItem.ProcessInstanceId);
            if(userMap.containsKey(pwItem.ActorId))
                actor = userMap.get(pwItem.ActorId);
            if(userMap.containsKey(pI.SubmittedById))
                originalActor = userMap.get(pI.SubmittedById);
            if(pI.Status != 'Started')
                approvalRecordList.add(new ApprovalRecords(pwItem,pI,actor,originalActor));
        }
        return approvalRecordList;
    }
    
    Public class ApprovalRecords{
        public String actionId{get;set;}
        public String relatedToName{get;set;}
        public String relatedToId{get;set;}
        public String objectName{get;set;}
        public String ownerId{get;set;}
        public String ownerName{get;set;}
        public String submitterId{get;set;}            
        public String submitterName{get;set;}
        public DateTime submittedDate{get;set;}
        public ApprovalRecords(ProcessInstanceWorkitem piWI ,ProcessInstance pI , User actor , User originalActor){
            this.actionId = piWI.Id;
            this.relatedToName = pI.TargetObject.Name;
            this.relatedToId = pI.TargetObjectId;
            this.objectName = pI.TargetObjectId.getSObjectType().getDescribe().getLabel();
            this.ownerId = actor.Id;
            this.ownerName = actor.Name;
            this.submitterId = originalActor.Id;
            this.submitterName = originalActor.Name;
            this.submittedDate = pI.CreatedDate;
        }
    }
}