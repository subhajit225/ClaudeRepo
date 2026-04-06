public with sharing class POStageHandler  extends TriggerHandler {    

    private static Boolean isDisabled = false; 
    static {
        ShGl_DisableBusinessLogic__c disableBusinessLog = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disableBusinessLog?.Disable_StagePO_Trigger__c ; 
    }
    private Boolean isHoldOffLogicDisabled = false;
    
    public static integer triggerMaxCount ;
    
    public POStageHandler() {
        
        if(Test.isRunningTest()){
            
            if( triggerMaxCount!=Null && triggerMaxCount>0 ){
              this.setMaxLoopCount(triggerMaxCount);  
            }else{
               this.setMaxLoopCount(25); 
            }
        }else
            this.setMaxLoopCount(2);
    }

     public override void beforeInsert() {
        if(!isDisabled) {
            POStageHelper.init(Trigger.new ,(Map<Id, PO_Stage__c>)trigger.newMap, null,false); //PRDOPS23-224
            POStageHelper.populateQuoteDetails(Trigger.new, (Map<Id, PO_Stage__c>)trigger.oldMap); 
            POStageHelper.populateAccountDetails(Trigger.new,(Map<Id, PO_Stage__c>)trigger.oldMap); 
            POStageHelper.setRecordType(Trigger.new);
        }
    }


    public override void beforeUpdate() { 
        if(!isDisabled) {
            POStageHelper.init(Trigger.new ,(Map<Id, PO_Stage__c>)trigger.newMap, (Map<Id, PO_Stage__c>)trigger.oldMap,false);
            POStageHelper.populateQuoteDetails(Trigger.new, (Map<Id, PO_Stage__c>)trigger.oldMap);
            POStageHelper.populateAccountDetails(Trigger.new,(Map<Id, PO_Stage__c>)trigger.oldMap);
            POStageHelper.cleanErrorMessage((List<PO_Stage__c>)Trigger.new, (Map<Id, PO_Stage__c>)Trigger.oldMap);
            PoStageHelper.populateStageDefaults(Trigger.new); 
            PoStageHelper.populateStageAddress(Trigger.new, (Map<Id, PO_Stage__c>)trigger.oldMap); //PRDOPS23-365 - External Validation for Wrong Email Id from Distributor
        }
    }

    public override void afterInsert() {}

    public override void afterUpdate() {
        if(!isDisabled) {

            Set<ID> oppIDs = new set<id>();
            Map<Id, PO_Stage__c>  oldStagePOMap = (Map<Id, PO_Stage__c>)Trigger.oldMap;
            List <PO_Stage__c> polarisPOList = new List<PO_Stage__c>();
            List <PO_Stage__c> nonPolarisPOList = new List<PO_Stage__c>();
            Map<id,opportunity> oppMap = new MAp<id,opportunity>();
            for(PO_Stage__c poStage : (List<PO_Stage__c>)Trigger.new){
                PO_Stage__c oldPOStage = oldStagePOMap.get(poStage.Id);
                if(oldPOStage.PO_Validation_Status__c == poStage.PO_Validation_Status__c || poStage.PO_Validation_Status__c == 'Staged'){
                    oppIDs.add(poStage.Opportunity__c);
                }
            }
            if(!oppIds.isEmpty()){
                oppMap = new map<id,opportunity>([SELECT id, Sell_to_Partner__c, Opportunity_Sub_Type__c  FROM opportunity WHERE id IN : oppIds]); 
            }
            POStageHelper.validationCheck((List<PO_Stage__c>)Trigger.new, (Map<Id, PO_Stage__c>)Trigger.newMap, (Map<Id, PO_Stage__c>)Trigger.oldMap, oppMap); // PO stage Validation.  
            for(PO_Stage__c poStage : (List<PO_Stage__c>)Trigger.new){
                if(
                    !POStageHelper.setIdStagePoDisorderedIndexes.contains(poStage.Id) && 
                    POStageHelper.quoteMap.containsKey(poStage.Quote__c) && 
                    POStageHelper.validateQuote.contains(poStage.Quote__c)
                ){
                    if(POStageHelper.quoteMap.get(poStage.Quote__c).Is_RWD_Polaris_Quote__c &&
                       !(oppMap.containsKey(poStage.Opportunity__c) && oppMap.get(poStage.Opportunity__c).Sell_to_Partner__c != null &&
                       Label.NetApp_Account_Ids.contains(oppMap.get(poStage.Opportunity__c).Sell_to_Partner__c))){ //PRDOPS23-358 - For the NetApp cases system to consider as nonPolaris for the validation.   
                        polarisPOList.add(poStage);
                    }
                    else{
                        nonPolarisPOList.add(poStage);
                    }
                }
            }

            if(!nonPolarisPOList.isEmpty()){
                POItemStageHelperClass.validationCheck(nonPolarisPOList, (Map<Id, PO_Stage__c>)Trigger.oldMap, oppMap);  // Used for .GPL External and GPL internal validation..
                SplitPOValidation.validateSplittedLines(nonPolarisPOList,(Map<Id, PO_Stage__c>)Trigger.oldMap, oppMap); // Split PO validation (subscription term,price,quant) 
            }
            if(!polarisPOList.isEmpty()){
                POItemValidation validate = POItemValidation.getInstance();
                validate.externalValidation((List<PO_Stage__c>)Trigger.new, (Map<Id, PO_Stage__c>)Trigger.oldMap);
            }
            POStageHelper.updateStagePO(); //PRDOPS24-821 change
             if(!POStageHelper.mapStagePOIdPreValidateStagePoErrRwdQuote.isEmpty()) {
                insert POStageHelper.mapStagePOIdPreValidateStagePoErrRwdQuote.values();
                POStageHelper.mapStagePOIdPreValidateStagePoErrRwdQuote.clear();
            }
        }
    }
    //PRDOPS25-734
    public override void beforedelete(){
        if(!isDisabled) {
          Map<Id, PO_Stage__c>  oldStagePOMap = (Map<Id, PO_Stage__c>)Trigger.oldMap;  
            PostageHelper.customValidationOnDeletePOStage(oldStagePOMap);
        }
        
    }
}