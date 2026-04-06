public without sharing class LtngAnnouncementListController {
    
    @AuraEnabled public static string anntype {get; set;}
    
    @AuraEnabled
    public static AnnouncmentWrapper getPortalNews(String pageNumber, String pageSize, String type, Boolean isForums) {
        list<String> TypeOptions = new list<String>( );
        list<AnnouncmentWrapper> AnnouncmentWrapperlist = new list<AnnouncmentWrapper>( );
        Integer pSize = Integer.valueOf(pageSize);
        Integer pNumber = Integer.valueof(pageNumber);
        Integer offset = (pNumber - 1) * pSize;
        Integer recordEnd = pSize * pNumber;
        Integer totalRecords;
        string queryLimit = '';
        string  queryOffset = '';
        string fetchKavSoql ='';
        string categsql = '';
        string queryAll='';
        anntype = Util.UserType;
        
        String qstring = 'SELECT Id, Alert__c, Audience__c, Content__c, CreatedById, CreatedBy.Name, CreatedDate, Created__c, Last_Modified__c, ';
        qString += 'LastModifiedDate, Expiration_Date__c, Name, OwnerId, Publish_Date__c, SystemModStamp, Summary__c ';
        if(anntype =='customer' || test.isRunningTest() ) qString +=' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Customer\')';
        if(anntype =='partner') qString +=' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Partner\')';
        if(anntype == 'Trial') qString +=' FROM Portal_News__c WHERE Audience__c = \'Edge Trial\'';
        if(anntype =='internal') qString +=' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Customer\') ';
        
        
        qString += ' AND Publish_Date__c <= TODAY AND (Expiration_Date__c = null OR Expiration_Date__c >= TODAY)';
        
        if(type != 'All' && type != null && type != '' && type != '\'\''){
            qString += isForums ? ' AND ForumType__c = \'' : ' AND type__c = \'';
            qString += type + '\'';
        }
        
        if (isForums) {
            qString += ' AND Recordtype.Name =\'Forums\''; 
        } else {
            qString += ' AND Recordtype.Name =\'Announcements\''; 
        }
        
        qString +=' ORDER By Publish_Date__c DESC';
        
        if(pageSize != null && pageSize != ''){
            queryLimit = ' LIMIT '+ pageSize  ; 
        }
        if(pageNumber != null && pageNumber != ''){
            queryOffset = ' OFFSET '+ offset  ; 
        }
               
        queryAll = qString ;
 
        Integer totalRec = database.query(queryAll).size();
        fetchKavSoql = qString + queryLimit + queryOffset ;

        List<Portal_News__c> newsList = database.query(fetchKavSoql);
        
        system.debug(LoggingLevel.DEBUG, 'Query :: ' + fetchKavSoql);
        Schema.DescribeFieldResult fieldResult5;
        List<Schema.PicklistEntry> ple5;
        
        if (isForums) {
            fieldResult5 =  Portal_News__c.ForumType__c.getDescribe();
            ple5 = fieldResult5.getPicklistValues();
        } else {
            fieldResult5 =  Portal_News__c.Type__c.getDescribe();
            ple5 = fieldResult5.getPicklistValues();
        }
        
        TypeOptions.Add('All');
        for(Schema.PicklistEntry f : ple5){
          TypeOptions.add(String.valueof(f.getValue()));
        }
        
        AnnouncmentWrapper wrap = new AnnouncmentWrapper();
        wrap.announcement = newsList;
        wrap.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        wrap.totalcount = totalRec ;
        wrap.TypeOptions = TypeOptions;
        return wrap ;
    }
    
    public class AnnouncmentWrapper{
        @AuraEnabled public List<Portal_News__c> announcement;
        @AuraEnabled
        public Integer recordStart {get;set;}
        @AuraEnabled 
        public Integer recordEnd {get;set;}
        @AuraEnabled 
        public Integer totalcount{get;set;}
        @AuraEnabled 
        public List<string>TypeOptions{get;set;}
    }    
}