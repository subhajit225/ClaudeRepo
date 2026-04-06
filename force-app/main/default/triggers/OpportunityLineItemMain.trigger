trigger OpportunityLineItemMain on OpportunityLineItem (before insert, after delete) {
    TriggerFactory.createHandler(OpportunityLineItem.sObjectType);
}