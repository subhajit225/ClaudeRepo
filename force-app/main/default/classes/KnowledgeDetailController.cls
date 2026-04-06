/*
 * Class Name :- KnowledgeDetailController
 * Visualforce Component :- KnowledgeDetailComponent
 * Author :- Shiva Sharma
 * Created Date :- 24-06-2019
 * Description : This Controller is being used in KnowledgeDetailComponent for displaying article info.
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
global class KnowledgeDetailController {

    global String kbRecordId{get;set;}
    
    global List<how_to__kav> knowRecord{get;set;}
    public List<how_to__kav> getknowRecords(){
        knowRecord = new List<how_to__kav>();
        
        knowRecord = [select id,ArticleNumber,Summary,Summary__c,Version__c,Environment__c,Cause__c,Resolution__c from how_to__kav where (KnowledgeArticleid =:kbRecordId OR ID =: kbRecordId)];
        String baseUrl = System.label.KbBaseURL;
        if(!knowRecord.isEmpty()){
            if(knowRecord[0].Summary__c != null && knowRecord[0].Summary__c.contains('src="')){            knowRecord[0].Summary__c = knowRecord[0].Summary__c.replaceAll('src="','src="'+baseUrl);            } 
            if(knowRecord[0].Version__c != null && knowRecord[0].Version__c.contains('src="')){knowRecord[0].Version__c = knowRecord[0].Version__c.replaceAll('src="','src="'+baseUrl); } 
            if(knowRecord[0].Environment__c != null && knowRecord[0].Environment__c.contains('src="')){knowRecord[0].Environment__c = knowRecord[0].Environment__c.replaceAll('src="','src="'+baseUrl);} 
            if(knowRecord[0].Cause__c != null && knowRecord[0].Cause__c.contains('src="')){knowRecord[0].Cause__c = knowRecord[0].Cause__c.replaceAll('src="','src="'+baseUrl);} 
            if(knowRecord[0].Resolution__c != null && knowRecord[0].Resolution__c.contains('src="')){knowRecord[0].Resolution__c = knowRecord[0].Resolution__c.replaceAll('src="','src="'+baseUrl);} 
        }
        
        return knowRecord;
    }
    
}