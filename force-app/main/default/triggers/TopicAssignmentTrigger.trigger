trigger TopicAssignmentTrigger on TopicAssignment (after insert) {
    TopicAssignmentTriggerHandler.createSubscriptionForOwner(Trigger.new);
}