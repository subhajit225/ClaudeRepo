global class StopStandardEmailForFeedBatch implements Database.Batchable<sObject>{
    public String query;
    global StopStandardEmailForFeedBatch(){
        
    }
    global StopStandardEmailForFeedBatch(String newQuery){
        if(newQuery != null && newQuery != ''){
            query = newQuery;
        }else{
            query = 'SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name LIKE \'%Community%\'';
        }
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        system.debug('@@###'+query);
        //system.debug('@@###'+Database.Query(query));
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<User> userList) {
        Map<Id,User> communityUserMap = new Map<Id,User>(userList);
        List<NetworkMember> updatedNMList = new List<NetworkMember>();
        try {
            for(NetworkMember member:[Select id,PreferencesDisableAllFeedsEmail ,MemberId from  NetworkMember where    MemberId in: communityUserMap.keySet() and NetworkId=:System.Label.networkScope]){
                if(!member.PreferencesDisableAllFeedsEmail){
                    member.PreferencesDisableAllFeedsEmail = true;
                    updatedNMList.add(member);
                }
            }
            if(!updatedNMList.isEmpty())
                Update updatedNMList;
         
        } catch(Exception e) {
            System.debug(e);
        }
         
    }   
     
    global void finish(Database.BatchableContext BC) {
        
    }
}