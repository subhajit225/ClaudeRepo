public class OpportunityComPortfolioScheduler implements Schedulable {
    public void execute(SchedulableContext sc){
        Database.executeBatch(new OpportunityCommissionPortfolioBatch(), 1);
    }
}