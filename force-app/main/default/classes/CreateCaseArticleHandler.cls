public class CreateCaseArticleHandler{

    public static void afterUpdate(map<Id,How_to__kav> mapOfArticle){
        set<Id> caseIds = new set<Id>();
        List<Case> lstUpdate = new List<Case>();
        map<Id,Case> mapOFCase = new map<Id,Case>();
        for(how_to__kav each : mapOfArticle.values()){
            how_to__kav oldRecord = (how_to__kav)trigger.oldMap.get(each.Id);
            if(each.case__c!=null && each.status__c == 'Published' && each.status__c!=oldRecord.status__c){
                caseIds.add(each.case__c);    
            }
        }
        if(caseIds!=null && !caseIds.isEMpty()){   
            for(Case cs : [select id,KCS_Article_Candidate__c,KCS_Article_Status__c from case where ID IN : caseIds]){
                mapOFCase.put(cs.Id,cs);        
            }
        }
        for(how_to__kav each : mapOfArticle.values()){
            if(each.case__c!=null && mapOFCase!=null && !mapOFCase.isEmpty() && mapOFCase.containsKey(each.case__c)){
                if(mapOFCase.get(each.case__c).KCS_Article_Candidate__c!=null && mapOFCase.get(each.case__c).KCS_Article_Candidate__c!='' && mapOFCase.get(each.case__c).KCS_Article_Candidate__c == 'New Article Created'){
                    Case cs = new Case(Id=each.case__c);
                    cs.KCS_Article_Status__c = 'Published';
                    lstUpdate.add(cs);
                }   
            }
        }
        if(lstUpdate!=null && !lstUpdate.isEmpty()){
            update lstUpdate;
        }
        
    }
}