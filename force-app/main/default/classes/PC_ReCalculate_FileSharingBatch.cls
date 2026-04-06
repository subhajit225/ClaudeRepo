global class PC_ReCalculate_FileSharingBatch implements Database.Batchable<SObject>, Database.Stateful{
global Id pdRecordTypeId;
global List<File_Sharing__c> updatefsList;
    global PC_ReCalculate_FileSharingBatch(){
        pdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        updatefsList = new List<File_Sharing__c>();
    }
	global Database.QueryLocator start(Database.BatchableContext BC){
         return Database.getQueryLocator([select Id from File_Sharing__c where Active__c=true]);
    }

    global void execute(Database.BatchableContext BC, List<File_Sharing__c> fsList){
		Set<Id> accIdSet = new Set<Id>();
        Set<Id> conIdSet = new Set<Id>();
        List<User> userList = new List<User>();
        List<ChannelProgramLevel> cplList = new List<ChannelProgramLevel>();
        Map<string,Set<Id>> fileUserMap = new Map<string,Set<Id>>();
        
        try{
            for(Account acc : [select Id,Name from Account where recordtypeId =:pdRecordTypeId AND ispartner  = true AND lastmodifieddate = TODAY]){
               accIdSet.add(acc.Id); 
            }
            if(!accIdSet.isEmpty()){
            	userList.addAll([select Id,Name from User where AccountId IN: accIdSet AND isActive = true AND ContactId != null And Profile.UserLicense.Name='Partner Community']);
            }
            for(Contact con : [select Id from Contact where Account.ispartner=true AND Account.recordtypeId =:pdRecordTypeId AND lastmodifieddate = TODAY]){
               conIdSet.add(con.Id); 
            }
            if(!conIdSet.isEmpty()){
                userList.addAll([select Id,Name from User where ContactId IN: conIdSet AND isActive = true And Profile.UserLicense.Name='Partner Community']);
            }
            userList.addAll([select Id,Name from User where isActive = true AND ContactId != null And Profile.UserLicense.Name='Partner Community' AND lastmodifieddate = TODAY]);
            cplList = [select Id from ChannelProgramLevel  where lastmodifieddate = TODAY];

            if(!userList.isEmpty() || !cplList.isEmpty()){
                updatefsList.addAll(fsList);
            }
        }catch (Exception e){
           system.debug('@@ Exception occured '+e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC){
        if(!updatefsList.isEmpty()){
            Database.update(updatefsList,false);
        }
    }
}