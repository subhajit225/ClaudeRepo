/* Created by Grazitti
 * This class is getting all case articles being created in last 1 hour which are linked with Cases 
 * Creating Jira Realtionship(ZIssue_SF) records between those Jira issues and cases which exist on the on Kb Arctile record 
 * in the field Jira Reference.
 * Ticket: CS21-1191
 */
public class CreateZissue_SFFArticle_CaseScheduler implements Queueable {
    public static void execute(QueueableContext qc){
        
        DateTime dt = System.Now().addHours(-1);
        List<CaseArticle> caseArticleList = [SELECT Id, CaseId, KnowledgeArticleId, KnowledgeArticleVersionId, ArticleLanguage FROM CaseArticle WHERE CreatedDate > :dt Order by CreatedDate desc];
        
        Map<Id, List<String>> caseToArticleIdMap = new Map<Id, List<String>>();
        Map<Id, List<String>> articleIdToCaseMap = new Map<Id, List<String>>();
        Map<Id, Set<String>> articleJiraMap = new Map<Id, Set<String>>();
        Set<String> listOfJiraRef = new Set<String>();
        Map<String, Id> zissueIdMap = new Map<String, Id>();
        Map<String, String> zissueKeyMap = new Map<String, String>();
        Map<String, Set<String>> finalCaseJiraMap = new Map<String, Set<String>>();
        List<zsfjira__ZIssue_SF__c> listToInsert = new List<zsfjira__ZIssue_SF__c>();
        Map<String, zsfjira__ZIssue_SF__c> caseJiraMap = new Map<String, zsfjira__ZIssue_SF__c>();
        String jiraRefVal;
        
        for(CaseArticle cs : caseArticleList){
            if(caseToArticleIdMap.containsKey(cs.CaseId)){
                List<String> tempList = caseToArticleIdMap.get(cs.CaseId);
                tempList.add(cs.KnowledgeArticleId);
                caseToArticleIdMap.put(cs.CaseId, tempList);
            }else{
                caseToArticleIdMap.put(cs.CaseId, new List<Id> {cs.KnowledgeArticleId});
            }
            if(articleIdToCaseMap.containsKey(cs.KnowledgeArticleId)){
                List<String> tempList = articleIdToCaseMap.get(cs.KnowledgeArticleId);
                tempList.add(cs.CaseId);
                articleIdToCaseMap.put(cs.KnowledgeArticleId, tempList);
            }else{
                articleIdToCaseMap.put(cs.KnowledgeArticleId, new List<Id> {cs.CaseId});
            }			
        }
        
        for(How_To__kav hkav : [SELECT Id, JIRA_Reference__c, KnowledgeArticleId FROM How_To__kav WHERE KnowledgeArticleId IN : articleIdToCaseMap.keySet() AND PublishStatus  = 'online']){
            
            jiraRefVal = hkav.JIRA_Reference__c;
            Pattern pattern = Pattern.compile('\\b[a-zA-Z]+-\\d+\\b');
            Matcher matcher = pattern.matcher(jiraRefVal);
            List<String> matches = new List<String>();
            while (matcher.find()) {
                matches.add(matcher.group());
            }
            
            for(String jr : matches){
              
                listOfJiraRef.add(jr);
               
                if(articleJiraMap.containsKey(hkav.KnowledgeArticleId)){
                    Set<String> tempList = articleJiraMap.get(hkav.KnowledgeArticleId);
                    tempList.add(jr);
                    articleJiraMap.put(hkav.KnowledgeArticleId, tempList);
                }else{
                    articleJiraMap.put(hkav.KnowledgeArticleId, new Set<String> {jr});
                }
            }
           
        }
        
        //Getting Id of Jira Ref from ZIssue Object
        for(zsfjira__ZIssue__c zissueRec : [SELECT Id, zsfjira__IssueKey__c, zsfjira__IssueId__c FROM zsfjira__ZIssue__c 
                                            Where zsfjira__IssueKey__c IN : listOfJiraRef]){
                                              
                                                zissueIdMap.put(zissueRec.zsfjira__IssueKey__c, zissueRec.Id);
                                                zissueKeyMap.put(zissueRec.zsfjira__IssueKey__c, String.valueOf(zissueRec.zsfjira__IssueId__c));
                                               
                                            }
        
        for(zsfjira__ZIssue_SF__c zissueSFRec : [SELECT Id, zsfjira__ZIssue__c, zsfjira__Case__c, zsfjira__IssueCreated__c, 
                                                 zsfjira__IssueId__c FROM zsfjira__ZIssue_SF__c WHERE zsfjira__Case__c 
                                                 IN : caseToArticleIdMap.keySet()]){
                                                     
                                                     caseJiraMap.put(zissueSFRec.zsfjira__Case__c+''+zissueSFRec.zsfjira__ZIssue__c, zissueSFRec); 
                                                     
                                                 }
        
        
        //setting final record for insertion
        for(CaseArticle caseArt : caseArticleList){
       
            if(articleJiraMap.containsKey(caseArt.KnowledgeArticleId)){
              
                for(String jiraRef : articleJiraMap.get(caseArt.KnowledgeArticleId)){
                  
                    if(zissueIdMap.ContainsKey(jiraRef) && !caseJiraMap.containsKey(caseArt.CaseId+''+zissueIdMap.get(jiraRef))){
                      
                        if(finalCaseJiraMap.containsKey(caseArt.CaseId)){
                            Set<String> tempList = finalCaseJiraMap.get(caseArt.CaseId);
                           
                            tempList.add(zissueIdMap.get(jiraRef)+','+zissueKeyMap.get(jiraRef));
                            finalCaseJiraMap.put(caseArt.CaseId, tempList);
                        }else{
                            
                            finalCaseJiraMap.put(caseArt.CaseId, new Set<String> {zissueIdMap.get(jiraRef)+','+zissueKeyMap.get(jiraRef)});
                        }
                        
                    }
                } 
            }
        }
		
        //Creating final map for insertion of Jira Relationship Records
        for(String ins : finalCaseJiraMap.keySet()){
           
            for(String jiraVal : finalCaseJiraMap.get(ins)){
                
                if(jiraVal != null){
                  
                    List<String> tempstr = String.valueOf(jiraVal).split(',');
                    zsfjira__ZIssue_SF__c zissuRec = new zsfjira__ZIssue_SF__c();
                    zissuRec.zsfjira__Case__c = ins;
                    if(tempstr[0] != null)
                        zissuRec.zsfjira__ZIssue__c = tempstr[0];
                    if(tempstr[1] != null)
                        zissuRec.zsfjira__IssueId__c = Decimal.valueOf(tempstr[1]);
                    listToInsert.add(zissuRec); 
                }
            }
        }
        
        if(!listToInsert.isEmpty()){
            INSERT listToInsert; 
        }
        //+++++++++++Ended here++++++++++++++++++++
    }
}