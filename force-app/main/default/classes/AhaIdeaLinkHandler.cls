/**
* @Author       :   Grazitti
* @CreatedDate  :   04-08-2022
* @Jira Ticket  :   AS-14 Jira reference - Case fields have “Jira reference” field
* @Description  :   This class is used to update the idea reference field on Case and
opportunity record whenever we link or unlink the idea record with case and opportunity.
* @TestClass    :   AhaIdeaLinkHandler_Test
*/

public class AhaIdeaLinkHandler {
    /**
* @Author       :   Grazitti
* @CreatedDate  :   04-08-2022
* @Description  :   updating the Idea Reference field on Case and Opportunity
* whenever we merge the idea with case or Opportunity
*/
    public static void updateIdeaReference(List<Aha_Idea_Link__c> newList, String action){
        String recordId;
        Rubrik_Aha_Credencial__mdt ahaCredential = Rubrik_Aha_Credencial__mdt.getInstance('AhaCredential');
        try{ List<Case> lstCaseToUpdate = new List<Case>();
            List<Opportunity> lstOppToUpdate = new List<Opportunity>();
            List<Case> lstCase = new List<Case>();
            List<Opportunity> lstOpp = new List<Opportunity>();
            Map<ID, Case> mapCases;
            Map<ID, String> caseIdVsIdeaNamesMap = New Map<ID, String>();
            Map<ID, String> oppIdVsIdeaNamesMap = New Map<ID, String>();
            Map<ID, Opportunity> mapOpportunity;
            Map<Id,Aha_Ideas__c> ahaIdandRecordMap;
            Set<Id> case_id_set = new Set<Id>();
            Set<Id> opp_id_set = new Set<Id>();
            Set<Id> aha_Idea_id_set = new Set<Id>();
            for(Aha_Idea_Link__c idea_Link_Obj : newList){
                if(idea_Link_Obj.Case_Number__c != null){
                    case_id_set.add(idea_Link_Obj.Case_Number__c);
                }else{
                    opp_id_set.add(idea_Link_Obj.Opportunity_Name__c);}
                if(idea_Link_Obj.Aha_Ideas__c != null){
                    aha_Idea_id_set.add(idea_Link_Obj.Aha_Ideas__c);}
            }
            if(case_id_set.size()>0){ mapCases = New Map<ID, Case>([SELECT Id,Idea_Reference__c FROM Case WHERE Id IN: case_id_set]);}
            if(opp_id_set.size()>0){ mapOpportunity = New Map<ID, Opportunity>([SELECT Id,Idea_References__c FROM Opportunity WHERE Id IN: opp_id_set]);}
            if(aha_Idea_id_set.size()>0){ahaIdandRecordMap = New Map<ID, Aha_Ideas__c>([Select id,Aha_Unique_ID__c from Aha_Ideas__c where Id IN : aha_Idea_id_set]);
            }
            if(case_id_set.size()>0 || opp_id_set.size()>0){
                for(Aha_Idea_Link__c ail : newList){
                    recordId = ail.Id;
                    Aha_Ideas__c ahaIdea = ahaIdandRecordMap.get(ail.Aha_Ideas__c);
                    List<String> ideaRef = new List<String>();
                    if(ail.Case_Number__c != Null && mapCases.containsKey(ail.Case_Number__c)
                       && ail.Aha_Ideas__c != Null && ahaIdandRecordMap.containsKey(ail.Aha_Ideas__c)){
                           Case cse = mapCases.get(ail.Case_Number__c);
                           if(cse != Null && cse.Idea_Reference__c!= null){
                               ideaRef = cse.Idea_Reference__c.split(',');
                               if(action == 'DELETE' && ahaIdandRecordMap.ContainsKey(ail.Aha_Ideas__c)
                                  && ideaRef.contains('<a href="' + ahaCredential.Aha_Site_URL__c + '\\' + ahaIdandRecordMap.get(ail.Aha_Ideas__c).Aha_Unique_ID__c + '" target="_blank">' + ahaIdandRecordMap.get(ail.Aha_Ideas__c).Aha_Unique_ID__c +'</a>')){
                                      for (Integer i = (ideaRef.size()-1) ; i>= 0 ; i--){
                                          String s = ideaRef[i];
                                          if(s.contains(ahaIdea.Aha_Unique_ID__c)){
                                              ideaRef.remove(i);}
                                      }
                                  }
                               if(action == 'INSERT'){
                                   ideaRef.add('<a href="'+ahaCredential.Aha_Site_URL__c +'\\'+ ahaIdea.Aha_Unique_ID__c+ '">'+ahaIdea.Aha_Unique_ID__c+'</a>');
                               }
                           }else if(cse != Null && cse.Idea_Reference__c == null && action == 'DELETE'){
                               ideaRef.add('');}
                           if(cse != Null && cse.Idea_Reference__c == null && action == 'INSERT'){
                               ideaRef.add('<a href="'+ahaCredential.Aha_Site_URL__c +'\\'+ ahaIdea.Aha_Unique_ID__c+ '">'+ahaIdea.Aha_Unique_ID__c+'</a>');
                           }
                           cse.Idea_Reference__c = String.join(ideaRef,',');
                           
                       }
                    if(ail.Opportunity_Name__c != Null && mapOpportunity.containsKey(ail.Opportunity_Name__c)
                       && ail.Aha_Ideas__c != Null && ahaIdandRecordMap.containsKey(ail.Aha_Ideas__c)){
                           Opportunity opp = mapOpportunity.get(ail.Opportunity_Name__c);
                           if(opp != Null && opp.Idea_References__c!= null){
                               ideaRef = opp.Idea_References__c.split(',');
                               if( action == 'DELETE' && ahaIdandRecordMap.ContainsKey(ail.Aha_Ideas__c)
                                  && ideaRef.contains('<a href="' + ahaCredential.Aha_Site_URL__c + '\\' + ahaIdandRecordMap.get(ail.Aha_Ideas__c).Aha_Unique_ID__c + '" target="_blank">' + ahaIdandRecordMap.get(ail.Aha_Ideas__c).Aha_Unique_ID__c +'</a>')){
                                      for (Integer i = (ideaRef.size()-1) ; i>= 0 ; i--){
                                          String s = ideaRef[i];
                                          if(s.contains(ahaIdea.Aha_Unique_ID__c)){
                                              ideaRef.remove(i);
                                          }
                                      }
                                  }
                               if(action == 'INSERT'){
                                   ideaRef.add('<a href="'+ahaCredential.Aha_Site_URL__c +'\\'+ ahaIdea.Aha_Unique_ID__c+ '">'+ahaIdea.Aha_Unique_ID__c+'</a>');
                               }
                           }else if(opp != Null && opp.Idea_References__c == null && action == 'DELETE'){
                               ideaRef.add('');}
                           if(opp != Null && opp.Idea_References__c == null && action == 'INSERT'){
                               ideaRef.add('<a href="'+ahaCredential.Aha_Site_URL__c +'\\'+ ahaIdea.Aha_Unique_ID__c+ '">'+ahaIdea.Aha_Unique_ID__c+'</a>');
                           }
                           opp.Idea_References__c = String.join(ideaRef,',');
                       }}
                if(mapOpportunity != null && mapOpportunity.size()>0) UPDATE mapOpportunity.values();
                if(mapCases != null && mapCases.size()>0) UPDATE mapCases.values();
            } }catch(exception e){String stackTrace = e.getStackTraceString().substringBefore('\n'); String className = stackTrace.substringAfter('.').substringBefore('.');String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
            Idea_Exception__c exc = new Idea_Exception__c();
            exc.Error_Message__c = 'Exception Message'+e.getMessage()+'\nLine Number'+e.getLineNumber()+'\nMethod Name'+methodName+'\nclass Name'+className;exc.Type__c = e.getTypeName();exc.Related_record__c = recordId;
            database.insert(exc);}}
}