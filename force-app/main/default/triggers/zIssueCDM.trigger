trigger zIssueCDM on zsfjira__ZIssue__c (after insert, after update) {
    if(!System.isBatch() && TriggerControl__c.getAll() != null && TriggerControl__c.getAll().containsKey('zIssueCDM') && !TriggerControl__c.getInstance('zIssueCDM').DisableTrigger__c){
        if (trigger.isInsert) {
            //CS21-644 - to sync case details with Jira
            ZJIRACaseWebservice.sendCaseDetailsToJira(trigger.new, trigger.oldMap);
            //CS21-644 - End
        } else if (trigger.isUpdate) {
            //CS21-644 - to sync case details with Jira
            ZJIRACaseWebservice.sendCaseDetailsToJira(trigger.new, trigger.oldMap);
            //CS21-644 - End
            Map<String,zsfjira__ZIssue__c> duplicateCaseMap = new Map<String,zsfjira__ZIssue__c>();
            for(zsfjira__ZIssue__c zIssue : trigger.new){
                zsfjira__ZIssue__c oldIssue = (zsfjira__ZIssue__c)trigger.OldMap.get(zIssue.Id);
                if(zIssue.Duplicate_of__c != null && oldIssue.Duplicate_of__c != zIssue.Duplicate_of__c)
                    duplicateCaseMap.put(zIssue.Duplicate_of__c,null);
            } 
            for(zsfjira__ZIssue__c zIssueCase : [select id,Name,zsfjira__IssueId__c   from  zsfjira__ZIssue__c where Name IN: duplicateCaseMap.Keyset()]){
                if(duplicateCaseMap.containsKey(zIssueCase.Name)){
                    duplicateCaseMap.put(zIssueCase.Name,zIssueCase);
                }
            }
            Set<Id> caseIds = new Set<Id>();
            List<zsfjira__ZIssue_Case__c> zIssueCase = [select id,zsfjira__ZIssueId__c,zsfjira__CaseId__c,zsfjira__CaseId__r.JIRA_Status__c  from  zsfjira__ZIssue_Case__c where (zsfjira__ZIssueId__c IN: trigger.NewMap.Keyset() OR  Name IN: duplicateCaseMap.Keyset())];
            Map<Id,Set<zsfjira__ZIssue_Case__c>> issueCaseMap = new Map<Id,Set<zsfjira__ZIssue_Case__c>>();
            for(zsfjira__ZIssue_Case__c issueCase : zIssueCase ){
                caseIds.add(issueCase.zsfjira__CaseId__c);
                if(!issueCaseMap.containsKey(issueCase.zsfjira__ZIssueId__c))
                    issueCaseMap.put(issueCase.zsfjira__ZIssueId__c,new Set<zsfjira__ZIssue_Case__c>());
                issueCaseMap.get(issueCase.zsfjira__ZIssueId__c).add(issueCase);
            }
            Map<Id,Integer> caseCountMap = new Map<Id,Integer>();
            if(!caseIds.isEmpty()){
                for(AggregateResult aggr : [select zsfjira__Case__c,count(id) total from zsfjira__ZIssue_SF__c Where zsfjira__Case__c IN :caseIds AND  (zsfjira__ZIssue__r.zsfjira__Status__c ='Investigating (Info Requested)' OR zsfjira__ZIssue__r.zsfjira__Status__c ='Accepted (Info Requested)' OR zsfjira__ZIssue__r.zsfjira__Status__c ='To do (Info Requested)') GROUP BY zsfjira__Case__c]){
                    caseCountMap.put((id)aggr.get('zsfjira__Case__c'),(Integer)aggr.get('total'));
                }
            }
            List<Case> caseList = new List<Case>();
            Set<Id> caseId = new Set<Id>();
            List<zsfjira__ZIssue_Case__c> issueCaseList = new List<zsfjira__ZIssue_Case__c>();
            List<zsfjira__ZIssue_SF__c> issueCaseSFList = new List<zsfjira__ZIssue_SF__c>();
            for(zsfjira__ZIssue__c zIssue : trigger.new){
                zsfjira__ZIssue__c oldIssue = (zsfjira__ZIssue__c)trigger.OldMap.get(zIssue.Id);
                if(issueCaseMap.containsKey(zIssue.Id)){
                    for(zsfjira__ZIssue_Case__c issueCase : issueCaseMap.get(zIssue.Id)){
                        if(caseCountMap.containsKey(issueCase.zsfjira__CaseId__c) && caseCountMap.get(issueCase.zsfjira__CaseId__c) > 0){
                            if(!caseId.contains(issueCase.zsfjira__CaseId__c)){
                                caseList.add(new Case(id= issueCase.zsfjira__CaseId__c,JIRA_Status__c = ''));
                                caseId.add(issueCase.zsfjira__CaseId__c);
                            }
                        }else{
                            if(!caseId.contains(issueCase.zsfjira__CaseId__c)){
                                //caseList.add(new Case(id= issueCase.zsfjira__CaseId__c,JIRA_Status__c = ''));
                                caseId.add(issueCase.zsfjira__CaseId__c);
                            }
                        }
                        if(duplicateCaseMap.containsKey(zIssue.Duplicate_of__c) && duplicateCaseMap.get(zIssue.Duplicate_of__c) != null){
                            issueCaseList.add(new zsfjira__ZIssue_Case__c(Name=zIssue.Duplicate_of__c,zsfjira__CaseId__c=issueCase.zsfjira__CaseId__c,zsfjira__ZIssueId__c=duplicateCaseMap.get(zIssue.Duplicate_of__c).Id));
                            issueCaseSFList.add(new zsfjira__ZIssue_SF__c(Name=zIssue.Duplicate_of__c,zsfjira__Case__c=issueCase.zsfjira__CaseId__c,zsfjira__ZIssue__c=duplicateCaseMap.get(zIssue.Duplicate_of__c).Id,zsfjira__IssueId__c =duplicateCaseMap.get(zIssue.Duplicate_of__c).zsfjira__IssueId__c));
                        }
                    }
                }
            }
            insert issueCaseList;
            insert issueCaseSFList;
            database.Update(caseList,false) ;
        }
    }
}