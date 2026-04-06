public without sharing class RemoveInactiveUserController implements Queueable{
    public Set<Id> inactivatedUsers;
public RemoveInactiveUserController(Set<Id> inactivatedUsers1){
        inactivatedUsers = new Set<Id>();
        this.inactivatedUsers = inactivatedUsers1;
    }
    
    public void execute(QueueableContext context){
        List<AccountTeamMember> members = [Select Id from AccountTeamMember where UserId in :inactivatedUsers];     
        if(members.size()>0){       
            delete members;               
        }     
    }
}