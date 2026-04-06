global class GenerateQuoteDocumentScheduler implements Schedulable {
     global void execute(SchedulableContext sc) {
        database.executebatch(new GenerateQuoteDocumentBatch(), 1);
     }
  }