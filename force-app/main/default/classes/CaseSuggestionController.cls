/*
 * Class Name :- CaseSuggestionController
 * Visualforce Component :- CaseSuggestionComponent
 * Author :- Shiva Sharma
 * Created Date :- 27-04-2018
 * Description : This Controller is being used in CaseSuggestionComponent for SearchUnify Suggestion based on Case status.
 * 
 // ********************Change Logs *****************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 * 
 // ********************Change Logs Ends*************************************************************************
*/
global class CaseSuggestionController {
    global String caseId{get;set;}
    global Integer rowCount{get;set;}
    global CaseSugestionParser csp{get;set;}
    global List<CaseSugestionParser.CaseWrapper> caseWrap{get;set;}
        
    global CaseSugestionParser getCaseRelatedSuggestion(){
        if(caseId == null){
            String jsonString = '{"resultsPerPage":'+6+',"aggregations":[{"filter":["how_to__kav"],"type":"_type"},{"filter":["true"],"type":"IsVisibleInPkb"}],"pageNo":1,"orderBy":"desc","sortby":"_score","from":0,"searchString":"error"}';
            Map<string, object> suggestionList = SearchUnifyEndpoint.SearchResults(jsonString);
            csp = CaseSugestionParser.parse(JSON.serialize((suggestionList)));
            return csp;
        }
        csp = CaseSugestionParser.parse(CaseTriggerHandler.caseSuggestionMap.get(caseId));
        return csp;
    }
    public List<CaseSugestionParser.CaseWrapper> getCaseWrapper(){
        caseWrap = new List<CaseSugestionParser.CaseWrapper>();
        if(caseId != null){
            Integer listSize = 0;
            Case cs = [SELECT id, ContactId,Subject,Status from Case where Id =: caseId];
            String imgUrl = Label.Su_case_label_url;
            String baseUrl = Label.Base_URL;
            Set<id> caseIds = new Set<Id>();
            caseIds.add(caseId);
            for(Case caseRec : [SELECT id,CaseNumber,Subject,Status from case where Id !=: caseId and ContactId =: cs.ContactId AND Subject =: cs.Subject]){
                caseIds.add(caseRec.Id);
                caseWrap.add(new CaseSugestionParser.CaseWrapper(imgUrl,baseUrl,caseRec));
                listSize++;
            }
            for(Case caseRec : [SELECT id,CaseNumber,Subject,Status from case where Id not IN: caseIds and ContactId =: cs.ContactId]){
                caseWrap.add(new CaseSugestionParser.CaseWrapper(imgUrl,baseUrl,caseRec));
                listSize++;
            }
        }
        
        return caseWrap;
    }
}