public class PC_MDF_RequestRemiderMailSchedular implements Schedulable{
	public void execute(SchedulableContext sc){
		Database.executeBatch(new PC_MDF_RequestRemiderMailBatch());
    }
}