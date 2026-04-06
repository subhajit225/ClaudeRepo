global class scheduleKbSubscribeBatch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        KnowledgeSubscriptionBatch kbBatch = new KnowledgeSubscriptionBatch();
        Database.executeBatch(kbBatch);
    }
    
}