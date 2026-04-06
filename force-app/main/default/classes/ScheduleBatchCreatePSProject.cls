global class ScheduleBatchCreatePSProject implements Schedulable{
	
    global String query ;
    
    global ScheduleBatchCreatePSProject( String query ) {
        this.query = query;
    }
    
    global ScheduleBatchCreatePSProject() {
    	this.query = '';
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCreatePSProject(query), 1);
    }
    
}