/* Handler class for QuoteDocumentTrigger trigger */
public class QuoteDocumentTriggerHandler extends TriggerHandler{
    public override void beforeInsert(){
        QuoteDocumentTriggerHelper.checkDocIsApproved(Trigger.New);
        QuoteDocumentTriggerHelper.populateFields(Trigger.New);
        QuoteDocumentTriggerHelper.handleDuplicateKey(Trigger.New);
    }
}