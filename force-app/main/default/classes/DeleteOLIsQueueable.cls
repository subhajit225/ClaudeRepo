public class DeleteOLIsQueueable implements Queueable {
    
    set<Id> oliIds = new set<Id> ();
    public DeleteOLIsQueueable(set<Id> oliIds){
        this.oliIds = oliIds;
    }
    
    //SAL25-590
    public void execute(QueueableContext qc){
        list<OpportunityLineItem> oppLineItemsList = [Select Id from OpportunityLineItem where Id IN:oliIds];
        if(!oppLineItemsList.isEmpty()){
            delete oppLineItemsList;
        }
    }
}