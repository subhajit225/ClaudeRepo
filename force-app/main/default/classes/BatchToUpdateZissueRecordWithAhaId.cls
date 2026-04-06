/**
* @Author       :   Grazitti Interactive
* @CreatedDate  :   28/08/2023
* @Jira Ticket  :   AS-19 - Jira Migration
* @Description  :   Below code is written to update the Unique Aha Idea Id from Aha to Salesforce on zissue Object.
* @TestClass    :   JiraCSVUploadControllerTest
* @Note         :   Script To execute the batch from anonymous window in developer console:
                    Database.executeBatch(new BatchToUpdateZissueRecordWithAhaId(), 1);
*/

global class BatchToUpdateZissueRecordWithAhaId implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful {
    global Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential'); 
    global Integer PageNumber = Integer.valueof(ahaCredential.Counter__c);
    global String url = ahaCredential.AHA_BASE_URL__c + '/ideas?fields=custom_fields,reference_num&page=';

    global Database.QueryLocator start(Database.BatchableContext BC) {      
        String query = 'SELECT Id,Name,Aha_Unique_Id__c FROM zsfjira__ZIssue__c WHERE Aha_Unique_Id__c = null';
        return Database.getQueryLocator(query);       
    }
    
    global void execute(Database.BatchableContext BC, List<zsfjira__ZIssue__c> scope) {
            
        try{
            Map<String,String>ahaIdeaandZissue = new Map<String,String>();
            Map<Id,zsfjira__ZIssue__c> zissueMap = New Map<Id,zsfjira__ZIssue__c>();
            Map<Id,Aha_Ideas__c> UpdateAha_IdeasMap = new Map<Id,Aha_Ideas__c>();
            for(Integer i = 1; i<=PageNumber; i++){
                url = ahaCredential.AHA_BASE_URL__c + '/ideas?fields=custom_fields,reference_num&page='+ i;                                    
                if (url == '') return;
                
                Map<String,zsfjira__ZIssue__c> zIssueKeyVsZIssueMap = New Map<String,zsfjira__ZIssue__c>();
                for(zsfjira__ZIssue__c zissue : scope){
                    zIssueKeyVsZIssueMap.put(zissue.name,zissue);
                }
                if(!zIssueKeyVsZIssueMap.isEmpty()){
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(url +'&per_page='+ahaCredential.Page_Size__c);
                    request.setMethod('GET');
                    request.setHeader('Authorization', 'Bearer ' + ahaCredential.AHA_API_KEY__c);
                    request.setHeader('contentType', 'application/json');
                    request.setHeader('Accept', 'application/json'); 
                    request.setTimeout(120000);
                    Http http = new Http();
                    List<Object> recordList = New List<Object>();
                     HttpResponse response = new HttpResponse();
                     String responseBody = '';
                    if(Test.isRunningTest()){
                      responseBody = '{\"ideas\":[{\"id\":\"7249702860024198077\",\"reference_num\":\"GRZWRKSPCE-I-5\",\"product_id\":\"7121752979038578773\",\"custom_fields\":[{\"id\":\"7325453623852213215\",\"key\":\"rfe_link\",\"name\":\"RFE Link (to original JIRA)\",\"updatedAt\":\"2023-10-12T07:22:10Z\",\"value\":\"https://rubrik.atlassian.net/browse/GRZ-1258\",\"type\":\"url\"}]}]}';            

                    }
                    else{
                        response = http.send(request);
                        responseBody = response.getbody();
                    } 
                   
                    if(response.getStatusCode() == 200 || Test.isRunningTest()){
                        Map<String, Object> records = (Map<String, Object>) JSON.deserializeUntyped(responseBody);                           
                        recordList = (List<Object>) records.get('ideas');
                        if(recordList.size()>0){                
                            for (Object record : recordList){
                                Map<String,String> ahaIdeafieldNameandValue = new Map<String,String>();        
                                Map<String, Object> recordMap = (Map<String, Object>) record;
                                List<object> customFieldValObj = (List<object>) recordMap.get('custom_fields'); 
                                for(object objNew : customFieldValObj){
                                    Map<String, Object> objMap = (Map<String, Object>) objnew;
                                    String name = String.valueof(objMap.get('name'));
                                    String value = String.valueof(objMap.get('value'));
                                    string fieldValue = '';
                                    if(!string.isblank(value)){
                                        fieldValue = value.trim();
                                    }
                                    ahaIdeafieldNameandValue.put(name.trim(),fieldValue);                               
                                }
                                 
                                if(!ahaIdeafieldNameandValue.isEmpty() && !zIssueKeyVsZIssueMap.isEmpty() && ahaIdeafieldNameandValue.containsKey('RFE Link (to original JIRA)') && ahaIdeafieldNameandValue.get('RFE Link (to original JIRA)')!= null){
                                    String RefLink =   ahaIdeafieldNameandValue.get('RFE Link (to original JIRA)');
                                    system.debug('RefLink--->' + RefLink);
                                    String jiraNo = RefLink.remove(Label.Jira_Base_Url);
                                    if(!String.isBlank(jiraNo) && !zIssueKeyVsZIssueMap.isEmpty() && zIssueKeyVsZIssueMap.containskey(jiraNo)){
                                        String ahaIdearefno = (String) recordMap.get('reference_num');
                                        system.debug('ahaIdearefno --->' + ahaIdearefno);
                                        zsfjira__ZIssue__c zIssue = zIssueKeyVsZIssueMap.get(jiraNo);
                                        zIssue.Aha_Unique_Id__c = ahaIdearefno;
                                        zissueMap.put(zIssue.id,zIssue); 
                                        ahaIdeaandZissue.put(ahaIdearefno,zIssue.name);                                     
                                    }    
                                }
                            }//End of For loop                 
                        }//End of If condition
                    }//End of Response
                    else{
                        throw new CalloutException('Api Response is not returing the Values'); 
                    }    
                }
            }//End of For loop
            if(!zissueMap.isEmpty()){
                UPDATE zissueMap.values(); 
            }
            if(!ahaIdeaandZissue.isEmpty()){
                for(Aha_Ideas__c idea : [Select id,zIsssue_Number__c,Aha_Unique_ID__c from Aha_Ideas__c where Aha_Unique_ID__c IN : ahaIdeaandZissue.keySet()]){
                    idea.zIsssue_Number__c = ahaIdeaandZissue.get(idea.Aha_Unique_ID__c);
                    UpdateAha_IdeasMap.put(idea.id,idea);
                }
            }
            if(!UpdateAha_IdeasMap.isEmpty()){
                UPDATE UpdateAha_IdeasMap.values();
            }
        }//End of try
        catch(exception e){
            ManageAhaIdeaHelper.insertException(e,'PageNumber : '+pageNumber);            
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}