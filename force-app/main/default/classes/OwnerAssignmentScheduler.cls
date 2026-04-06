global class OwnerAssignmentScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      Database.executeBatch(new ETMTerritoryOwnerAssociationBatch('AccountUpdate',null,0));
   }
}