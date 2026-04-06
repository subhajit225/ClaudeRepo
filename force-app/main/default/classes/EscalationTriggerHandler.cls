/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : May 16th 2023
 * @TstClass    : EscalationManagementTeamControllerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1378        Vijay Kumar K R          May 16, 2023    only one escalation per primary case, with a single lessons learned child case per escalation case. 
 * -------------------------------------------------------------------------
 */
public class EscalationTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        
        Set<Id> caseIdSet = new Set<Id>();
        for(Escalation__c objEsc : (List<Escalation__c>) Trigger.new) {
            caseIdSet.add(objEsc.Case__c);
        }

        // Open Escalations Under Case
        Map<Id, Integer> escCountByCaseIdMap = new Map<Id, Integer>();
        for(AggregateResult aggr: [SELECT Case__c, Count(Id) numEscs
                                    FROM Escalation__c 
                                    WHERE Case__c IN: caseIdSet 
                                    AND Status__c != 'Closed'
                                    GROUP BY Case__c]){             
            escCountByCaseIdMap.put((Id)aggr.get('Case__c'), (Integer)aggr.get('numEscs'));
        } 

        for(Escalation__c objEsc : (List<Escalation__c>) Trigger.new) {
            if(!escCountByCaseIdMap.isEmpty()
                && escCountByCaseIdMap.containsKey(objEsc.Case__c)
                && escCountByCaseIdMap.get(objEsc.Case__c) >= 1){
                    // Case can have only one Open Escalation
                    objEsc.addError('Open Escalation already existing under this Case');
            }
        }
    }

    public override void beforeUpdate() {
        
        Set<Id> closedEscIdSet = new Set<Id>();
        for(Escalation__c objEsc : (List<Escalation__c>) Trigger.new) {
            if(isChanged('Status__c', objEsc)
                && objEsc.Status__c == 'Closed'){
                    closedEscIdSet.add(objEsc.Id);
            }
        }

        // Open Lessons Learned Under Escalation
        Map<Id, Integer> llListByEscIdMap = new Map<Id, Integer>();
        if(!closedEscIdSet.isEmpty()){
            for(AggregateResult aggr: [SELECT Escalation__c, Count(Id) total
                                        FROM Lessons_Learned__c 
                                        WHERE Escalation__c IN: closedEscIdSet 
                                        AND Lessons_Learnt_Status__c != 'Closed'
                                        GROUP BY Escalation__c]){             
                llListByEscIdMap.put((Id)aggr.get('Escalation__c'), (Integer)aggr.get('total'));
            } 
        }

        for(Escalation__c objEsc : (List<Escalation__c>) Trigger.new) {
            if(isChanged('Status__c', objEsc)
                && objEsc.Status__c == 'Closed'){
                    if(!llListByEscIdMap.isEmpty()
                        && llListByEscIdMap.containsKey(objEsc.Id)
                        && llListByEscIdMap.get(objEsc.Id) >= 1){
                            // Escalation can't be close unless unless LL status is closed
                            objEsc.addError('Please close Lessons Learned prior to close this Escalation');
                        }else{
                            objEsc.Activity_Levels__c = null;
                        }
            }
        }
    }
    
}