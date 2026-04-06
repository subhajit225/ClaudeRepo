/**
* @description : Queueable class for updating users to avoid MIXED DML
*/
public class PC_PartnerRegistrationRequestQueueable implements Queueable{
    public Set<Id> usersToActivate;
    public Set<Id> usersToChangeProfile;
    
    /**
    * @description : Constructor to initialize variables
    * @return : none
    */
    public PC_PartnerRegistrationRequestQueueable(Set<Id> usersToActivate, Set<Id> usersToChangeProfile){
        this.usersToActivate = usersToActivate;
        this.usersToChangeProfile = usersToChangeProfile;
    }
    
    /**
    * @description : Execute method to perform operations in Queueable
    * @return : void
    */
	public void execute(QueueableContext context) {
        Set<Id> userIds = new Set<Id>();
		if(!usersToActivate.isEmpty()){
			userIds.addAll(usersToActivate);
		}
		if(!usersToChangeProfile.isEmpty()){
			userIds.addAll(usersToChangeProfile);
		}

		List<User> userList = [SELECT Id, isActive, ProfileId FROM User WHERE Id IN :userIds];
		for(User u :userList){
			if(usersToActivate.contains(u.Id)){
				u.isActive = true;
			}else if(usersToChangeProfile.contains(u.Id)){
				u.ProfileId = ID.valueOf(system.label.PartnerManagerSFDCProfileId);
				u.isActive = true;
			}
		}
		Database.update(userList, false);
    }
}