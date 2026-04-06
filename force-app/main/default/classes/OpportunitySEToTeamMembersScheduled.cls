public class OpportunitySEToTeamMembersScheduled implements Schedulable{
    public void execute(SchedulableContext sc){
        try{
            OpportunitySEToTeamMembersBatch batch = new OpportunitySEToTeamMembersBatch();
            Database.executeBatch(batch,50);  
        }catch(Exception e){
            system.debug('Exception occured in OpportunitySEToTeamMembersBatch:: '+e.getMessage());
        } 
    }
}