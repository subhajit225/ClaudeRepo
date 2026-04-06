public with sharing class NightlyScheduledJob implements Schedulable{
    public void execute(SchedulableContext sc){
        AssetDatesUpdateFromParent_Batch ob1 = new AssetDatesUpdateFromParent_Batch();
        Database.executeBatch(ob1, 100);

        ClusterAccountUpdate ob2 = new ClusterAccountUpdate();
        Database.executeBatch(ob2, 100);
    }
}