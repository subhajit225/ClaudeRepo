global class PC_FileSharing_ShareBatchController implements Database.Batchable<SObject>{
    Map<Id,List<File_Sharing__share>> fsshareMap = new Map<Id,List<File_Sharing__share>>();
    global PC_FileSharing_ShareBatchController(Map<Id,List<File_Sharing__share>> fsshareMapBatch){
       fsshareMap = fsshareMapBatch;
    }
	global Database.QueryLocator start(Database.BatchableContext BC){
         return Database.getQueryLocator([select Id,Name from File_Sharing__c where Id IN:fsshareMap.keyset()]);
    }

    global void execute(Database.BatchableContext BC, List<File_Sharing__c> fsList){
		List<File_Sharing__share> fsshareList = new List<File_Sharing__share>();
        try{
		 	for(File_Sharing__c fs:fsList){
                fsshareList.addAll(fsshareMap.get(fs.Id));
            }
            Database.insert(fsshareList,false);
        }catch (Exception e){
           system.debug('@@ Exception occured '+e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC){}
}