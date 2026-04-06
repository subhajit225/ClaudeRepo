public with sharing class SandboxRefreshActivateUsersBatch implements Database.batchable<User>, Database.Stateful{
    private ID sandboxRefreshConfigId;
    private Sandbox_Refresh_Config__c srConfigObj;

    public SandboxRefreshActivateUsersBatch(ID sandboxRefreshConfigId) {
        this.sandboxRefreshConfigId = sandboxRefreshConfigId;
    }

    public Iterable<User> start(Database.BatchableContext bc){
        Organization orgInfo = [Select InstanceName, Name, NamespacePrefix, OrganizationType, IsSandbox, PrimaryContact  From Organization];
        if(orgInfo.IsSandbox || Test.isRunningTest()){
            srConfigObj = [Select Id, Name, isInitiatedManually__c, EmailFields__c, Status__c FROM Sandbox_Refresh_Config__c where id = :sandboxRefreshConfigId];
            List<User> userList = SandboxRefreshUtil.getUsersToActivate(srConfigObj);
            if(userList.isEmpty()){
                userList =  null;
                srConfigObj.Status__c = 'Completed';
            }
            System.debug(userList+ '~~1~~srConfigObj' + srConfigObj);
            return userList;
        }
        return null;
    }

    public void execute (Database.BatchableContext bc, List<User> userList){
        System.debug(userList + '~~21~~srConfigObj' + srConfigObj);
        SandboxRefreshUtil.updateUsers(userList, srConfigObj);
        System.debug(userList + '~~22~~srConfigObj' + srConfigObj);
    }

    public void finish(Database.BatchableContext bc){
        System.debug('~~3~~srConfigObj' + srConfigObj);
        update srConfigObj;
    }
}