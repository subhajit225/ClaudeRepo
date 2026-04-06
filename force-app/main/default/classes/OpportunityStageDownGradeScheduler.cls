public class OpportunityStageDownGradeScheduler implements Schedulable {

    public void execute(SchedulableContext sc){
        Opportunity_Stage_Days__c stageDays = Opportunity_Stage_Days__c.getInstance(UserInfo.getUserId()); 
		Database.executeBatch(new OpportunityStageDownGradeBatch(), (Integer)stageDays.OpportunityStageDownGradeBatch_Size__c);
    }
}