/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : May 16th 2023
 * @TstClass    : EscalationManagementTeamControllerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1378        Vijay Kumar K R          May 16, 2023    only one escalation per primary case, with a single lessons learned child case per escalation case. 
 * -------------------------------------------------------------------------
 */
public class LessonsLearnedTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        
        Set<Id> escIdSet = new Set<Id>();
        for(Lessons_Learned__c objll : (List<Lessons_Learned__c>) Trigger.new) {
            escIdSet.add(objll.Escalation__c);
        }

        Map<Id, Integer> llListByCaseIdMap = new Map<Id, Integer>();
        for(AggregateResult aggr: [SELECT Escalation__c, Count(Id) numlls
                                    FROM Lessons_Learned__c 
                                    WHERE Escalation__c IN: escIdSet
                                    AND Lessons_Learnt_Status__c != 'Closed'
                                    GROUP BY Escalation__c]){             
            llListByCaseIdMap.put((Id)aggr.get('Escalation__c'), (Integer)aggr.get('numlls'));
        } 

        for(Lessons_Learned__c objll : (List<Lessons_Learned__c>) Trigger.new) {
            if(!llListByCaseIdMap.isEmpty()
                && llListByCaseIdMap.containsKey(objll.Escalation__c)
                && llListByCaseIdMap.get(objll.Escalation__c) >= 1){
                    objll.addError('Lessons Learned already existing under this Escalation');
            }
        }
    }
    
}