public class OpportunityStageMovingController {
	@AuraEnabled
    public static void updateOpportunity(Id recordId, String type){
        System.debug(System.logginglevel.DEBUG, recordId);
        System.debug(System.logginglevel.DEBUG, type);
        try{
            Opportunity opp = new Opportunity();
            opp.Id = recordId;
            if(type == 'StageMoving'){
                opp.Accept_Conditions__c = true;
            }else if(type == 'ASPENChange'){ //SAL24-578
                 opp.ASPEN_Accept_Conditions__c = true;
            }else if(type == 'RubrikTBD'){ //SAL24-651
                 opp.RubrikTBD_Accept_Conditions__c = true;
            }else if(type == 'DistriMarketplace'){ //SAL24-652
                 opp.DistriMarketplace_Accept_Conditions__c = true;
            }else if(type == 'Stage4to5'){ //SAL26-314
                 opp.Unapproved_Country_Accept_Conditions__c = true;
            }else if(type == 'StageSkippedTo6'){ //SAL26-314
                 opp.Unapproved_Country_Accept_Conditions__c = true;
            }
            FlowControll.opportunityTriggerHandler = false;
            update opp;
            FlowControll.opportunityTriggerHandler = true;
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}