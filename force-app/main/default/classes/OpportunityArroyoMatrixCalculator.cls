public without sharing class OpportunityArroyoMatrixCalculator {
    public static final string GC_OFFER ='GC Offer';
    public static final string StageFIVE ='5 Negotiate & Close';
    public static final string StageSIX ='6 PO With Channel';
    private static List<Arroyo_Quote_Opportunity_matrix__mdt> getMatrixMapping(){
        return [SELECT MasterLabel, Source_Object__c, Target_Object__c, Source_Field__c, Target_Field__c
                    FROM Arroyo_Quote_Opportunity_matrix__mdt];
    } 

    public static void copyMatrixValuesToOpportunity(Set<Id> quoteIds){
        List<Opportunity> opptyResults = new List<Opportunity>();
        Set<Id> oppACVExcludeSet = new Set<Id>();
        String oppQuery = 'SELECT Id,SBQQ__PrimaryQuote__c,recordtypeId,StageName,Opportunity_Sub_Type__c, Opportunity_Amount_Override__c ';
        String opplineQuery = 'SELECT Id,SBQQ__QuoteLine__c';
        //List<Opportunity> opptyResults = [SELECT Id,SBQQ__PrimaryQuote__c, (SELECT Id,SBQQ__QuoteLine__c FROM OpportunityLineItems) FROM Opportunity WHERE SBQQ__PrimaryQuote__c IN :quoteIds];
        Boolean isOppUpdate = false;
        List<Opportunity> opptyToUpdateList = new List<Opportunity>();
        Set<Id> OppACVIdSet = new Set<Id>();
        if(!quoteIds.isEmpty()){
              //build the dynamic query
            String quoteQuery = 'SELECT Id, SBQQ__Opportunity2__c';
            String quoteLineQuery = 'SELECT Id,SBQQ__Quote__c';

            List<Arroyo_Quote_Opportunity_matrix__mdt> matrixMapping = getMatrixMapping();
            //add the source fields

            for(Arroyo_Quote_Opportunity_matrix__mdt matrix : matrixMapping){
                if('Quote' == matrix.Source_Object__c){
                    quoteQuery= quoteQuery+','+matrix.Source_Field__c;
                }else if('QuoteLine' == matrix.Source_Object__c){
                    quoteLineQuery = quoteLineQuery+','+matrix.Source_Field__c;
            }
                if('Opportunity' == matrix.Target_Object__c){
                    oppQuery = oppQuery+','+matrix.Target_Field__c;
                }else if('OpportunityLineItem' == matrix.Target_Object__c){
                    opplineQuery = opplineQuery+','+matrix.Target_Field__c;
                }
            }
            opplineQuery = opplineQuery+' FROM OpportunityLineItems';
            quoteQuery = quoteQuery+' FROM SBQQ__Quote__c WHERE Id IN :quoteIds';
            quoteLineQuery += ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds';
            oppQuery = oppQuery+',( '+opplineQuery+' )  FROM Opportunity WHERE SBQQ__PrimaryQuote__c IN :quoteIds';

            opptyResults = Database.query(oppQuery);
            for(Opportunity oppty : opptyResults) {  //SAL24-484
                if(oppty.recordtypeId == OpportunityUtil.oppRecTypeIdRenewOpp && (oppty.StageName == StageFIVE || oppty.StageName == StageSIX) && oppty.Opportunity_Sub_Type__c == GC_OFFER){
                    oppACVExcludeSet.add(oppty.Id); 
                }
            }
            Map<Id, SObject> quoteResults = new Map<Id, SObject>(Database.query(quoteQuery));
            Map<Id, SObject> quoteLineResults = new Map<Id, SObject>(Database.query(quoteLineQuery));
            
            Map<Id, OpportunityLineItem> opptyLineItems = new Map<Id, OpportunityLineItem>();

            //build the logic to copy
            for(Opportunity oppty : opptyResults) {
                isOppUpdate = false;
                for(Arroyo_Quote_Opportunity_matrix__mdt matrix : matrixMapping){
                    if('Quote' == matrix.Source_Object__c && quoteResults.get(oppty.SBQQ__PrimaryQuote__c).get(matrix.Source_Field__c) != oppty.get(matrix.Target_Field__c)){
                        if(!oppACVExcludeSet.isEmpty() && oppACVExcludeSet.contains(oppty.Id) && (matrix.Target_Field__c == 'Expansion_ACV__c' || matrix.Target_Field__c == 'Renewal_ACV__c' || matrix.Target_Field__c == 'Renewal_Subsumed_ACV__c')){
                            //SAL24-484
                        }else{
                            oppty.put(matrix.Target_Field__c, quoteResults.get(oppty.SBQQ__PrimaryQuote__c).get(matrix.Source_Field__c));
                            isOppUpdate = true;
                        }
                    }
                    else if('QuoteLine' == matrix.Source_Object__c ){
                        for(OpportunityLineItem oi : oppty.OpportunityLineItems){
                            if(quoteLineResults.containsKey(oi.SBQQ__QuoteLine__c)){
                                if(opptyLineItems.containsKey(oi.Id) && quoteLineResults.get(oi.SBQQ__QuoteLine__c).get(matrix.Source_Field__c) != opptyLineItems.get(oi.Id).get(matrix.Target_Field__c)){
                                    if(matrix.Target_Field__c == 'Subsumed_Renewal_Amount__c'){
                                        if(!oppty.Opportunity_Amount_Override__c){
                                    		opptyLineItems.get(oi.Id).put(matrix.Target_Field__c, quoteLineResults.get(oi.SBQQ__QuoteLine__c).get(matrix.Source_Field__c));
                                        }
                                        OppACVIdSet.add(oppty.Id);
                                    }else{
                                        opptyLineItems.get(oi.Id).put(matrix.Target_Field__c, quoteLineResults.get(oi.SBQQ__QuoteLine__c).get(matrix.Source_Field__c));
                                    }
                                }
                                else {
                                    OpportunityLineItem oli = new OpportunityLineItem();
                                    oli = oi;
                                    if(quoteLineResults.get(oi.SBQQ__QuoteLine__c).get(matrix.Source_Field__c) != oli.get(matrix.Target_Field__c)){
                                        if(matrix.Target_Field__c == 'Subsumed_Renewal_Amount__c'){
                                            if(!oppty.Opportunity_Amount_Override__c){
                                                oli.put(matrix.Target_Field__c, quoteLineResults.get(oi.SBQQ__QuoteLine__c).get(matrix.Source_Field__c));
                                                opptyLineItems.put(oi.Id,oli);
                                            }
                                            OppACVIdSet.add(oppty.Id);
                                        }else{
                                            oli.put(matrix.Target_Field__c, quoteLineResults.get(oi.SBQQ__QuoteLine__c).get(matrix.Source_Field__c));
                                            opptyLineItems.put(oi.Id,oli);
                                        }
                                    }
                            	}
                        }
                    }
                }
            }
                if(isOppUpdate){
                    opptyToUpdateList.add(oppty);
                }
            }
            //TODO: turn off the oppty trigger
            FlowControll.opportunityTriggerHandler = false;
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            if(!opptyToUpdateList.isEmpty()){
                update opptyToUpdateList;
                
            } 
            if(!opptyLineItems.isEmpty()){
                update opptyLineItems.values();
            }
            if(!OppACVIdSet.isEmpty()){ //ARY-886
                OppAnnualContractValueUtil.calculateAcvAmount(OppACVIdSet);
            }
            FlowControll.opportunityTriggerHandler = true;
            SBQQ.TriggerControl.enable();
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
        } 
    }
}