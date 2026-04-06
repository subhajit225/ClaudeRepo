public class PC_FileSharingCmpController {
@AuraEnabled
    public static List<File_Sharing__c> getFSRecord(string recId){
        List<File_Sharing__c> fsList = new List<File_Sharing__c>();
        fsList = [select Id,Name,Active__c,Account_Specialization__c,Area__c,Exclude_Account_Name__c,Exclude_Channel_Program__c,Exclude_Channel_Program_Level__c,Partner_Type__c,Primary_Role__c,Theatre__c from File_Sharing__c where Id =:recId];
        return fsList;
    }    
@AuraEnabled
    public static List<Account> getAccNames(string recId){
        List<File_Sharing__c> fsList = new List<File_Sharing__c>();
        fsList = [select Id,AccountIds__c,ChannelProgramIds__c,ChannelProgramLevelIds__c from File_Sharing__c where Id =:recId];
        List<Account> accList = new List<Account>();
        List<Id> accIdList = new List<Id>();
        if(!fsList.isEmpty() &&  !string.isBlank(fsList[0].AccountIds__c)){
            accIdList = fsList[0].AccountIds__c.split(';');
            if(!accIdList.isEmpty())
                accList = [select Id,Name from Account where Id IN: accIdList];
        }
        return accList;
    }
@AuraEnabled
    public static List<ChannelProgram> getCPNames(string recId){
        List<File_Sharing__c> fsList = new List<File_Sharing__c>();
        fsList = [select Id,AccountIds__c,ChannelProgramIds__c,ChannelProgramLevelIds__c from File_Sharing__c where Id =:recId];
        List<ChannelProgram> cpList = new List<ChannelProgram>();
        List<Id> cpIdList = new List<Id>();
        if(!fsList.isEmpty() &&  !string.isBlank(fsList[0].ChannelProgramIds__c)){
            cpIdList = fsList[0].ChannelProgramIds__c.split(';');
            if(!cpIdList.isEmpty())
                cpList = [select Id,Name from ChannelProgram where Id IN: cpIdList];
        }
        return cpList;
    }
@AuraEnabled
    public static List<ChannelProgramLevel> getCPLNames(string recId){
        List<File_Sharing__c> fsList = new List<File_Sharing__c>();
        fsList = [select Id,AccountIds__c,ChannelProgramIds__c,ChannelProgramLevelIds__c from File_Sharing__c where Id =:recId];
        List<ChannelProgramLevel> cplList = new List<ChannelProgramLevel>();
        List<Id> cplIdList = new List<Id>();
        if(!fsList.isEmpty() &&  !string.isBlank(fsList[0].ChannelProgramLevelIds__c)){
            cplIdList = fsList[0].ChannelProgramLevelIds__c.split(';');
            if(!cplIdList.isEmpty())
                cplList = [select Id,Name from ChannelProgramLevel where Id IN: cplIdList];
        }
        return cplList;
    }    
@AuraEnabled
    public static string saveRecord(File_Sharing__c rec, List<Account> accRecords, List<ChannelProgram> cpRecords, List<ChannelProgramLevel> cplRecords){
        string message = '';
        string accIds = '';
        string cpIds = '';
        string cplIds = '';
        string accNames = '';
        string cpNames = '';
        string cplNames = '';
        try{
            system.debug('@@ rec '+rec);
            for(Account acc : accRecords){
                accIds = accIds+acc.Id+';';
                accNames = accNames+acc.Name+';';
            }
            for(ChannelProgram cp : cpRecords){
                cpIds = cpIds+cp.Id+';';
                cpNames = cpNames+cp.Name+';';
            }
            for(ChannelProgramLevel cpl : cplRecords){
                cplIds = cplIds+cpl.Id+';';
                cplNames = cplNames+cpl.Name+';';
            }
            if(!string.isBlank(accIds)){
                accIds = accIds.removeEnd(';');
            }
            if(!string.isBlank(cpIds)){
                cpIds = cpIds.removeEnd(';');
            }
            if(!string.isBlank(cplIds)){
                cplIds = cplIds.removeEnd(';');
            }
            rec.AccountIds__c = accIds;
            rec.ChannelProgramIds__c = cpIds;
            rec.ChannelProgramLevelIds__c = cplIds;
            rec.Selected_Account_Names__c = accNames;
            rec.Selected_Channel_Program_Names__c = cpNames;
            rec.Selected_Channel_Program_Level_Names__c = cplNames;
        	upsert rec;
            message = rec.Id;
        }catch(Exception e){
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                message = 'Exception occurred : '+e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
            } else {
                message = 'Exception occurred : '+e.getMessage();
            }
            system.debug('@@ Exception occurred '+e.getMessage());
        }
        return message;
    }
}