public with sharing class FileSharingController {
	public static Set<Id> queryCVSharing(){
        Set<Id> fsIdSet = new Set<Id>();
        for(File_Sharing__c fs : [select Id from File_Sharing__c]){
            fsIdSet.add(fs.Id);
        }
        return fsIdSet;
    }
}