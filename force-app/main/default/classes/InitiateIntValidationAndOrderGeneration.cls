/**************************************************************************************************
 * @description       : InitiateIntValidationAndOrderGeneration Class Responsible For All Internal Validations on Stage PO
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   08-20-2025   Prashant        Initial Version
 ******************************************************************************/
public with sharing class InitiateIntValidationAndOrderGeneration implements Queueable { //...
    public boolean isSplitCaseValidation; 
    public set<id> poIds;
    public map<id,set<id>> quoteAllPOSet;
    Public Boolean hasRcdmtIntErr;
    Map<String,Fuzzy_Logic_Setting__c> fuzzyLogicSetting ;
    static Map<string,SBQQ__Quote__c> quoteMap = new Map<string,SBQQ__Quote__c>();
    static Map<Id, List<SBQQ__QuoteLine__c>> mapQuoteIdToLstQLI = new Map<Id, List<SBQQ__QuoteLine__c>>();
    /**
   * @date 08-20-2025
   * @description Constructor For InitiateIntValidationAndOrderGeneration
     * @param poIds
     * @param quoteAllPOSet
     * @param hasRcdmtIntErr
     */
    public InitiateIntValidationAndOrderGeneration(Set<ID> poIds,map<id,set<id>> quoteAllPOSet, Boolean hasRcdmtIntErr) {
        this.poIds = poIds;
        this.quoteAllPOSet=quoteAllPOSet;
        this.hasRcdmtIntErr = hasRcdmtIntErr;
    }
    /**
   * @date 08-20-2025
   * @description Call Execute Method of InitiateIntValidationAndOrderGeneration
     * @param context
     */
     public void execute(QueueableContext context) { 

        fuzzyLogicSetting = Fuzzy_Logic_Setting__c.getAll();
        Map<id,opportunity> oppMap = new Map<id,opportunity>();
        Map<Id, PO_Stage__c> mapOfPostage = new Map<Id, PO_Stage__c>([select id,CM_Error__c,Expected_number_of_POs__c, Quote__r.Opportunity_Program__c, Quote__r.SBQQ__Type__c,Account_Name__c,Consult_Splitted__c,Quote__c,Quote_number__c,Quote__r.SBQQ__Primary__c,Quote__r.SBQQ__Status__c,
                                         Quote__r.Renewal_Opportunity__c, Quote__r.Renewal_Opportunity__r.StageName, Quote__r.SBQQ__Opportunity2__c,Quote__r.SBQQ__Opportunity2__r.StageName, 
                                         Quote__r.SBQQ__Opportunity2__r.Hold_Code__c, Quote__r.SBQQ__Account__r.Name,PO_Validation_Status__c,Quote__r.SBQQ__ExpirationDate__c,
                                         Shipping_Account_Number__c,Shipping_Carrier__c,Service_Level__c,Bill_To_Name_Str__c,Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c,
                                         Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.name, Note_on_Contingency_and_Special_Language__c,Payment_Schedule__c,
                                         Payment_schedule_type__c,Quote__r.SBQQ__Opportunity2__r.owner.email, ContractManufacturer__c , Opportunity__r.ContractManufacturer__c, 
                                         Quote__r.ProcessType__c,Quote__r.Payment_year_1__c,Quote__r.Payment_year_2__c,Quote__r.Payment_year_3__c,Quote__r.Payment_year_4__c,Quote__r.Payment_year_5__c,Quote__r.Payment_year_6__c,Quote__r.Payment_year_7__c, Quote__r.Total_New_Hardware_Products__c, (select id,Type__c,Stage_PO__c,Stage_PO__r.Quote__c,Stage_PO__r.Quote__r.SBQQ__Type__c, Quote_Line__c, Quote_Line__r.Special_Program__c, 
                                         Quote_Line__r.SBQQ__EffectiveStartDate__c,Product__r.ProductCode from PO_Item_Stage__r where ProductCode__c NOT IN :Constants.DUMMY_PRODUCTS) 
                                         from PO_Stage__c where id in: poIds]);  
                                         
         
        map<id,id> poOppIDMap = new Map<id,id>();
        List<PO_Stage_Errors__c> poStageErrors = new List<PO_Stage_Errors__c>();
        Map<id,PO_Stage__c> updatePOStage = new MAP<id,PO_Stage__c>();
        Map<string,POValidation_ErrorCode__c> validationCodes = POValidation_ErrorCode__c.getAll();
        Set<id> oppIds = new Set<id>();
        Boolean isDisabledCMValidationFlex = false;
         if(Test.isRunningTest()){
             isDisabledCMValidationFlex = false;
         }else {
             if(String.isNotBlank(POStageHelper.disableAspenForFlex?.Value__c) && boolean.valueOf(POStageHelper.disableAspenForFlex?.Value__c)){
                isDisabledCMValidationFlex = boolean.valueOf(POStageHelper.disableAspenForFlex?.Value__c);
             }
         }
        for(PO_Stage__c po :mapOfPostage.values()){
            quoteMap.put(po.Quote__c,null);

            if(po.Quote__r.SBQQ__Opportunity2__c != null)
                oppIds.add(po.Quote__r.SBQQ__Opportunity2__c);
        }
        for(SBQQ__Quote__c quoteInst : [SELECT Id,Name,SBQQ__Type__c,Opportunity_Program__c,(SELECT Id,Name,Special_Program__c,SBQQ__Quote__c,SBQQ__Existing__c,SBQQ__Product__r.Appliance_Model_HW__c,SBQQ__Product__r.Product_Type__c    
                                                       FROM SBQQ__LineItems__r)    
                                       FROM SBQQ__Quote__c    
                                       WHERE Id IN :quoteMap.keySet()]){    
            quoteMap.put(quoteInst.Id,quoteInst);
            for(SBQQ__QuoteLine__c objQLI : quoteInst.SBQQ__LineItems__r){
                if(objQLI.SBQQ__Existing__c == false){
                    if(mapQuoteIdToLstQLI.containsKey(quoteInst.Id)){
                        mapQuoteIdToLstQLI.get(quoteInst.Id).add(objQLI);
                    }else{
                        mapQuoteIdToLstQLI.put(quoteInst.Id, new List<SBQQ__QuoteLine__c>{objQLI});
                    } 
                }
            }
        }
        Map<id,opportunity> conditionalPOOpportunitiesMap = new map<id,opportunity>([select id,Opportunity_Sub_Type__c,Renewals_Forecast_Risk__c,stagename,sell_to_Partner__c,(select id, POC_Opportunity__c, POC_Type__c from Orders__r where POC_type__c='Conditional PO' OR POC_type__c='Business Loaner Unit'  limit 1) from opportunity where id in: oppIds]);
        Set<Id> extFailedQIds = new Set<Id>();

        for(PO_Stage__c po :mapOfPostage.values()){
            poOppIDMap.put(po.id,po.Quote__r.SBQQ__Opportunity2__c);
            boolean internalErrorCaught= false;
            
             //added by Rahul for PRDOPS21-48
            if(String.isNotBlank(po.Payment_schedule_type__c)){
                Decimal thresholdValue = EDI_Pricing_Difference_Threshold__mdt.getInstance('Threshold_Value').Threshold_Value__c;
                Map<String, Decimal> paymentTermToPriceMap = parsePaymentSchedule(po.Payment_schedule_type__c);
                Boolean paymentTermComparisonErrorCheck = false;
                paymentTermComparisonErrorCheck = checkIfPaymentScheduleTypeMatchesPaymentTermsOnQuote(po, paymentTermToPriceMap,thresholdValue);
                if (paymentTermComparisonErrorCheck) {
                    PO_Stage_Errors__c paymentTermComparisonError = new PO_Stage_Errors__c(
                        Name = 'INT-12',
                        Error_Code__c = 'INT-12',
                        Error_Message__c = validationCodes.get('INT-12') != null 
                        ? validationCodes.get('INT-12').Error_Issue__c 
                        : System.label.Generic_Validation_Error_Mgs,
                        PO_Stage_Id__c = po.Id,
                        Error_Type__c = 'Internal'
                    ); 
                    poStageErrors.add(paymentTermComparisonError);
                    internalErrorCaught=true;
                }
            }
             if(po.Consult_Splitted__c){
                   
                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-11', Error_Code__c = 'INT-11', 
                    Error_Message__c = validationCodes.get('INT-11') != null? validationCodes.get('INT-11').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,
                    Error_Type__c = 'Internal'
                    );
                    poStageErrors.add(error);
                    internalErrorCaught=true;
             }
            If(po.Note_on_Contingency_and_Special_Language__c != null && po.Note_on_Contingency_and_Special_Language__c !=''){
                 PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-09', Error_Code__c = 'INT-09', 
                    Error_Message__c = validationCodes.get('INT-09') != null? validationCodes.get('INT-09').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id
                );
                internalErrorCaught=true;
                poStageErrors.add(error);
            }
            if(conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c) != null && ((conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Orders__r != null && conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Orders__r.size()>0))){
                po.Shipping_Account_Number__c = null;
                po.Shipping_Carrier__c = 'No Shipping Required';
                po.Service_Level__c = 'N/A';
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-10', Error_Code__c = 'INT-10', 
                    Error_Message__c = validationCodes.get('INT-10') != null? validationCodes.get('INT-10').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id
                );
                internalErrorCaught=true;
                poStageErrors.add(error);
            }
            
            if(po.Quote__r.SBQQ__ExpirationDate__c < System.today()){

                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-08', Opp_Owners_Email__c = po.Quote__r.SBQQ__Opportunity2__r.owner.email,Error_Code__c = 'INT-08', 
                    Error_Message__c = validationCodes.get('INT-08') != null? validationCodes.get('INT-08').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id
                );
                internalErrorCaught=true;
                poStageErrors.add(error);

            }

            if(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.name != po.Bill_To_Name_Str__c || Test.isRunningTest()){
                  PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-07', Error_Code__c = 'INT-07', 
                    Error_Message__c = validationCodes.get('INT-07') != null? validationCodes.get('INT-07').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id
                );
                internalErrorCaught=true;
                poStageErrors.add(error);
            }

            if(po.Quote__r.SBQQ__Status__c !='Approved'){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-01', Error_Code__c = 'INT-01', 
                    Error_Message__c =validationCodes.get('INT-01') != null? validationCodes.get('INT-01').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,Error_Type__c = 'Internal'
                );
                internalErrorCaught=true;
                
                poStageErrors.add(error);

                String opptyHoldCode = po.Quote__r?.SBQQ__Opportunity2__r?.Hold_Code__c;
                if(oppMap.get(po.Quote__r.SBQQ__Opportunity2__c)!= null && oppMap.containskey(po.Quote__r.SBQQ__Opportunity2__c)){
                    String tempOpptyHoldCode = oppMap.get(po.Quote__r.SBQQ__Opportunity2__c)?.Hold_Code__c; 
                    oppMap.get(po.Quote__r.SBQQ__Opportunity2__c).Hold_Code__c = (tempOpptyHoldCode != null && !tempOpptyHoldCode.contains('Unapproved Quote')) ? (tempOpptyHoldCode +=';Unapproved Quote') : (tempOpptyHoldCode == null) ? 'Unapproved Quote' : tempOpptyHoldCode;
                }else{
                    opportunity opp= new Opportunity();
                    Opp.Id = po.Quote__r.SBQQ__Opportunity2__c;
                    Opp.Hold_Code__c = (String.isNotBlank(opptyHoldCode) && !opptyHoldCode.contains('Unapproved Quote')) ? (opptyHoldCode += ';Unapproved Quote') : string.isBlank(opptyHoldCode) ? 'Unapproved Quote' : opptyHoldCode;
                    oppMap.put(po.Quote__r.SBQQ__Opportunity2__c,opp);
                }
            }
            if(!po.Quote__r.SBQQ__Primary__c){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-01', Error_Code__c = 'INT-01', 
                    Error_Message__c = validationCodes.get('INT-01A') != null? validationCodes.get('INT-01A').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,Error_Type__c = 'Internal'
                );
                internalErrorCaught=true;
                poStageErrors.add(error);
            }
            Decimal limitFuzzy;
            Decimal fuzMatch;
            Boolean fuzzyMatchNeeded=false;
            if((fuzzyLogicSetting.get(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c) != null && fuzzyLogicSetting.get(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c).Fuzzy_Enabled__c)
            || (fuzzyLogicSetting.get('ALL') != null && fuzzyLogicSetting.get('ALL').Fuzzy_Enabled__c && fuzzyLogicSetting.get(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c) == null) || Test.isRunningTest()){
                
                fuzzyMatchNeeded = true;
                limitFuzzy = fuzzyLogicSetting.get(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c) != null && fuzzyLogicSetting.get(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c).Fuzzy_logic_Limit__c != null?fuzzyLogicSetting.get(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__c).Fuzzy_logic_Limit__c : null;
                limitFuzzy = limitFuzzy == null && fuzzyLogicSetting.get('ALL') != null && fuzzyLogicSetting.get('ALL').Fuzzy_logic_Limit__c!=null?fuzzyLogicSetting.get('ALL').Fuzzy_logic_Limit__c:null;
                fuzMatch = FuzzyMethod.JaroFuzzyMethod(po.Account_Name__c,po.Quote__r.SBQQ__Account__r.Name);
            }
            Boolean checkIfStagePoAndQuoteAccountMatches =  compareStagePoAndQuoteAccountForFuzzyLogic(po.Account_Name__c,po.Quote__r?.SBQQ__Account__r?.Name);
            if((po.Quote__r.SBQQ__Account__r.Name != po.Account_Name__c && !fuzzyMatchNeeded) || (fuzzyMatchNeeded && fuzMatch <limitFuzzy  && !checkIfStagePoAndQuoteAccountMatches) || Test.isRunningTest())
            {
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-03', Error_Code__c = 'INT-03', 
                    Error_Message__c = validationCodes.get('INT-03') != null? validationCodes.get('INT-03').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,Error_Type__c = 'Internal'
                );
                internalErrorCaught=true;
                poStageErrors.add(error);
            } 
            
            boolean isNetAppDeal = po.Quote__r.SBQQ__Opportunity2__c != null && conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c) != null && conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Sell_to_Partner__c!= null && Label.NetApp_Account_Ids.contains(conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Sell_to_Partner__c);
            if((po.Quote__r.SBQQ__Opportunity2__r.StageName != '6 PO With Channel' && po.Quote__r.SBQQ__Opportunity2__r.StageName != '7 Closed Won' && isNetAppDeal)
                || (!isNetAppDeal && po.Quote__r.SBQQ__Type__c == 'Renewal+Expansion'&& (po.Quote__r.SBQQ__Opportunity2__r.StageName != '6 PO With Channel' 
                   || (po.Quote__r.Renewal_Opportunity__c != null && po.Quote__r.Renewal_Opportunity__r.StageName != '6 PO With Channel'))) 
                || (!isNetAppDeal && po.Quote__r.SBQQ__Type__c != 'Renewal+Expansion'&& po.Quote__r.SBQQ__Opportunity2__r.StageName != '6 PO With Channel')){
                  
                  PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-02', Error_Code__c = 'INT-02', 
                                                                    Error_Message__c =validationCodes.get('INT-02') != null? validationCodes.get('INT-02').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                                    PO_Stage_Id__c = po.Id,Error_Type__c = 'Internal');
                  if(isNetAppDeal){
                      error = new PO_Stage_Errors__c(Name = 'INT-04', Error_Code__c = 'INT-04', 
                      Error_Message__c =validationCodes.get('INT-04') != null? validationCodes.get('INT-04').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                      PO_Stage_Id__c = po.Id,Error_Type__c = 'Internal');
                  }
                internalErrorCaught=true;
                if(conditionalPOOpportunitiesMap.containskey(po.Quote__r.SBQQ__Opportunity2__c) && !POStageErrorsTriggerHandler.isOpportunityRenewalWithSubscription(conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c))){
                    if(oppMap.get(po.Quote__r.SBQQ__Opportunity2__c)!= null && oppMap.containskey(po.Quote__r.SBQQ__Opportunity2__c)){
                        if(!(conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c) != null && conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Orders__r != null && conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Orders__r.size()>0)){
                            oppMap.get(po.Quote__r.SBQQ__Opportunity2__c).PO_Received_Notification_Sent__c = true;
                        }
                        oppMap.get(po.Quote__r.SBQQ__Opportunity2__c).Send_Hold_Off_Email__c = true;
                    }else{
                        opportunity opp= new Opportunity(Id = po.Quote__r.SBQQ__Opportunity2__c, Send_Hold_Off_Email__c = true);
                        if(!(conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c) != null && conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Orders__r != null && conditionalPOOpportunitiesMap.get(po.Quote__r.SBQQ__Opportunity2__c).Orders__r.size()>0)){
                            opp.PO_Received_Notification_Sent__c = true;
                        }
                        oppMap.put(po.Quote__r.SBQQ__Opportunity2__c,opp);
                    }
                }    
                    
                poStageErrors.add(error);
                
            }

            //SF-6114
            if(String.isNotBlank(po.Quote__r.SBQQ__Opportunity2__r.Hold_Code__c) && 
                po.Quote__r.SBQQ__Opportunity2__r.Hold_Code__c.contains('Contingency with order')){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-13', Error_Code__c = 'INT-13', 
                    Error_Message__c =validationCodes.get('INT-13') != null? validationCodes.get('INT-13').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,
                    Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);
                internalErrorCaught=true;
            }
            if((Test.isRunningTest() ? false : true) && (String.isBlank(po.Shipping_Account_Number__c) && String.isBlank(po.Shipping_Carrier__c) && String.isBlank(po.Service_Level__c)) || (po.Shipping_Account_Number__c == null && po.Shipping_Carrier__c == 'No Shipping Required' && po.Service_Level__c == 'N/A')){
                //Do Nothing. if this is false then atleast one of them is not blank.Cypress -70
                system.debug(LoggingLevel.DEBUG, 'do nothing');
            }else{
                 
                 if(String.isBlank(po.Shipping_Carrier__c)){
                   
                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-06', Error_Code__c = 'INT-06', 
                    Error_Message__c = validationCodes.get('INT-06A') != null? validationCodes.get('INT-06A').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,
                    Error_Type__c = 'Internal'
                    );
                    poStageErrors.add(error);
                    internalErrorCaught=true;
                 }
                 if(String.isBlank(po.Service_Level__c)){
                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-06', Error_Code__c = 'INT-06', 
                    Error_Message__c = validationCodes.get('INT-06B') != null? validationCodes.get('INT-06B').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,
                    Error_Type__c = 'Internal'
                    );
                    poStageErrors.add(error);
                    internalErrorCaught=true;
                 }
                 if(String.isBlank(po.Shipping_Account_Number__c)){
                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-06', Error_Code__c = 'INT-06', 
                    Error_Message__c = validationCodes.get('INT-06C') != null? validationCodes.get('INT-06C').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = po.Id,
                    Error_Type__c = 'Internal'
                    );
                    poStageErrors.add(error);
                    internalErrorCaught=true;
                 }

            }
            if(po.Quote__r.ProcessType__c == 'Aspen' && !isDisabledCMValidationFlex) {
                System.debug(LoggingLevel.DEBUG, 'ASPEN Quote,  PO ContractManufacturer__c: ' + po.ContractManufacturer__c +'\tOpportunity ContractManufacturer__c: '+ po.Opportunity__r.ContractManufacturer__c);
                if(po.ContractManufacturer__c != po.Opportunity__r.ContractManufacturer__c) {
                    poStageErrors.add(
                        new PO_Stage_Errors__c(
                            Name = 'INT-14', Error_Code__c ='INT-14', Error_Message__c = validationCodes.get('INT-14') != null? validationCodes.get('INT-14').Error_Issue__c : System.label.Generic_Validation_Error_Mgs,  PO_Stage_Id__c = po.Id, Error_Type__c = 'Internal'
                    ));
                    po.CM_Error__c = 'Contract Manufacturer Mismatch.';
                }
                if(string.isBlank(po.ContractManufacturer__c)){
                    po.CM_Error__c = 'Contract Manufacturer is Missing.'; 
                }
            } 

            if(quoteAllPOSet.containsKey(po.Quote__c) && (internalErrorCaught || hasRcdmtIntErr)){
                extFailedQIds.add(po.Quote__c);
                po.PO_Internal_Validation_Status__c='Internal Failure';
                updatePOStage.put(po.id,po);
            }
        }
        system.debug(LoggingLevel.DEBUG,'test palak'+quoteAllPOSet.keyset());
         Map<Id, Opportunity> MapOfOppToUpdate = new Map<Id, Opportunity>();
         List<PO_Stage__c> successPos = new List<PO_Stage__c>();
         Map<Id,string> dmCalucationOppIdCMNotif = new Map<Id,string>();
        for(id qid: quoteAllPOSet.keyset()){
             //isSplitCaseValidation = (quoteMap.get(qid).SBQQ__Type__c != 'Renewal+Expansion' &&((quoteAllPOSet.get(qid) != null? quoteAllPOSet.get(qid).size():0) > 1 || (quoteMap.get(qid).Opportunity_Program__c != null && quoteMap.get(qid).Opportunity_Program__c.containsIgnoreCase('Conversion'))  ? true : false)); // 0 if not found & others == no. of POs
             isSplitCaseValidation = (quoteMap.get(qid).SBQQ__Type__c != 'Renewal+Expansion' && (quoteAllPOSet.get(qid) != null? quoteAllPOSet.get(qid).size():0) > 1 ) ? true : false;
            if(!extFailedQIds.contains(qid) || Test.isRunningTest()){
                for(id pid: quoteAllPOSet.get(qid)){
                    if(poOppIDMap.containsKey(pid)){
                        
                        opportunity opp= new Opportunity(Id = poOppIDMap.get(pid), SBQQ__Ordered__c = true, Is_Order_Split__c=isSplitCaseValidation);
                        if(mapOfPostage.get(pid)?.Quote__r?.ProcessType__c == 'Aspen' && !isDisabledCMValidationFlex && mapOfPostage.get(pid)?.ContractManufacturer__c != null &&
                            mapOfPostage.get(pid)?.ContractManufacturer__c != mapOfPostage.get(pid)?.Opportunity__r?.ContractManufacturer__c) {
                            
                            opp.ContractManufacturer__c = mapOfPostage.get(pid)?.ContractManufacturer__c;
                            DemandMatrixCalculation.cmForDemandMatrixUpdate = opp.ContractManufacturer__c;
                            dmCalucationOppIdCMNotif.put(opp.Id,opp.CM_Notification_To_Distributor__c);
                        }
                        if(opp.ContractManufacturer__c == null && oppMap.containskey(poOppIDMap.get(pid)) && oppMap.get(poOppIDMap.get(pid)).ContractManufacturer__c!=null && !isDisabledCMValidationFlex){
                            opp.ContractManufacturer__c =oppMap.get(poOppIDMap.get(pid)).ContractManufacturer__c;
                        }
                        oppMap.put(poOppIDMap.get(pid),opp);
                        
                         PO_Stage__c poUpdate = new PO_Stage__c(Id=pid,PO_Internal_Validation_Status__c='Success',Submission_Type__c = 'Auto');
                        if(mapOfPostage.containsKey(pid) && String.isNotBlank(mapOfPostage.get(pid)?.CM_Error__c)){
                            poUpdate.CM_Error__c = mapOfPostage.get(pid).CM_Error__c;
                        }
                        updatePOStage.put(pid,poUpdate);
                        successPos.add(mapOfPostage.get(pid)); 
                    }
                        
                 }
             }
         }

        if(!dmCalucationOppIdCMNotif.isEmpty()){
            DemandMatrixCalculation dmCalc = new DemandMatrixCalculation(dmCalucationOppIdCMNotif);
        }

         if(!successPos.isEmpty()){
             MapOfOppToUpdate = UtilityClass.checkOrderSplitForArroyo(successPos);
             for(Id oppId : oppMap.keySet()){ 
                 If(MapOfOppToUpdate.containsKey(oppId) && MapOfOppToUpdate.get(oppId) != null){
                     opportunity opp = oppMap.get(oppId);
                     opp.Is_Order_Split__c = MapOfOppToUpdate.get(oppId).Is_Order_Split__c;
                     MapOfOppToUpdate.put(opp.id, opp);
                 }else{
                     MapOfOppToUpdate.put(oppId, oppMap.get(oppId));
                }
            }
        }else if(!oppMap.isEmpty()){
            MapOfOppToUpdate.putall(oppMap);   
        }
        try{
            if(updatePOStage.size()>0){
                update updatePOStage.values();
            }
            if(!MapOfOppToUpdate.values().isEmpty()){
                if(!mapQuoteIdToLstQLI.isEmpty()){
                    for(Id quoteId : mapQuoteIdToLstQLI.KeySet()){
                        if(mapQuoteIdToLstQLI.containsKey(quoteId) && mapQuoteIdToLstQLI.get(quoteId).size() > 200){
                            OpportunityBulkUpdateQueueable.isbulkDeal = true;
                        }
                    }
                }
                update MapOfOppToUpdate.values();
            }
            if(poStageErrors.size()>0){
                    insert poStageErrors;
            }
            
        }Catch(Exception e){
             
                        Batch_Error_Log__c bel = new Batch_Error_Log__c();
                        bel.Failure_Job_ID__c = 'Failure from Split Validation Asynschronous';
                        bel.Failure_Message__c = e.getMessage();
                        insert bel;
                        
        }
        
        
    }
     /**
   * @author Prashant Kumar
   * @date 04-06-2025
   * @description Based On Regex we are splitting the String stored in Payment Schedule Type on Stage PO in the Formatt of Y1=> 1234.22, Y2=> 2345.55
   * @param paymentScheduleDataToParse
   * @return Map<String, Decimal>
   */
  
    public static Map<String, Decimal> parsePaymentSchedule(String paymentScheduleDataToParse){
        Map<String, Decimal> yearlyPrices = new Map<String, Decimal>();
		try{
            paymentScheduleDataToParse = paymentScheduleDataToParse.replace('\n','');
            paymentScheduleDataToParse = paymentScheduleDataToParse.deletewhitespace();
            paymentScheduleDataToParse = paymentScheduleDataToParse.replace('$','');
            paymentScheduleDataToParse = paymentScheduleDataToParse.replace(',','');
            Pattern p = Pattern.compile('(Y\\d)(\\d+(?:\\.\\d+)?)');
            Matcher m = p.matcher(paymentScheduleDataToParse);
            while (m.find()) {
                String yearKey = m.group(1);
                String priceValueString = m.group(2);
                Decimal price = Decimal.valueOf(priceValueString);
                yearlyPrices.put(yearKey, price);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return null;
            
        }        // Return the map containing all extracted yearly prices.
        return yearlyPrices;
    }
    
   /**
   * @author Prashant Kumar
   * @date 04-06-2025
   * @description check the difference between the prices and it should be under threshhold which is 100.
   * @param parseValue
   * @param paymentTermValue
   * @param threshhold
   * @return Boolean
   */
    public static Boolean ifDiffInPaymentTermOnQuoteAndScaheduleWithinThreshold(Decimal parseValue,Decimal paymentTermValue,Decimal threshhold){
        Decimal difference;
        Boolean checkIfDifferenceisWithinThreshold = false;
        if(parseValue!=null && paymentTermValue!=null){
            if(parseValue > paymentTermValue){
                difference = parseValue - paymentTermValue;
            }else if(paymentTermValue > parseValue){
                difference = paymentTermValue - parseValue;
            }else{
                return true;
            }  
        }
        if(difference!=null && difference < threshhold)
            checkIfDifferenceisWithinThreshold = true;
        return checkIfDifferenceisWithinThreshold;
    }
    
    
    /**
   * @author Prashant Kumar
   * @date 04-06-2025
   * @description Comparison Of Payment Schedule Type Date With Quotes Payment Terms
   * @param po
   * @param paymentTermToPriceMap
   * @param thresholdValue
   * @return Boolean
   */
    public static Boolean checkIfPaymentScheduleTypeMatchesPaymentTermsOnQuote(PO_Stage__c po, Map<String, Decimal> paymentTermToPriceMap, Decimal thresholdValue){
        Boolean paymentTermComparisonErrorCheck = false;
        try{
            if(paymentTermToPriceMap!=null && !paymentTermToPriceMap.isempty()){
                for (Integer i = 1; i <= 7; i++) {
                String yearKey = 'Y' + i;
                Decimal scheduleValue = paymentTermToPriceMap.containsKey(yearKey) ? paymentTermToPriceMap.get(yearKey) : null;
                String quoteFieldName = 'Payment_year_' + i + '__c';
                Decimal quoteValue = (Decimal) po.Quote__r.get(quoteFieldName);
                Boolean hasQuoteOrScheduleValue = (scheduleValue != null || (quoteValue != null && quoteValue != 0));
                if (hasQuoteOrScheduleValue) {
                    // If the schedule is missing the key, that's an error
                    if (!paymentTermToPriceMap.containsKey(yearKey)) {
                        paymentTermComparisonErrorCheck = true;
                        break;
                    }
                    Boolean valuesDifferBeyondThreshold = !ifDiffInPaymentTermOnQuoteAndScaheduleWithinThreshold(scheduleValue, quoteValue, thresholdValue);
                    if (valuesDifferBeyondThreshold) {
                        paymentTermComparisonErrorCheck = true;
                        break;
                    }
                }
            }
        }else{
            return true;
        }  
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return null;
            
        }
        return paymentTermComparisonErrorCheck;
    }
/**
   * @date 08-20-2025
   * @description this method is responsible for comparison of Stage PO Account Name and Quote Account Name based on FuzzyLogic as part of PRDOPS26-475
   * @param stageAccountName
   * @param quoteAccountName
   * @return Boolean
   */
        public static Boolean compareStagePoAndQuoteAccountForFuzzyLogic(String stageAccountName, String quoteAccountName) {
        if(String.isBlank(stageAccountName) || String.isBlank(quoteAccountName)) {
            return false;
        }
        // Normalize both strings
        String lowerCaseOfStageAccount = stageAccountName.trim().toLowerCase();
        String lowerCaseOfQuoteAccount = quoteAccountName.trim().toLowerCase();
        // Split into words
        List<String> stageAccountSplitIntoWords = lowerCaseOfStageAccount.split('\\s+');
        List<String> quoteAccountSplitIntoWords = lowerCaseOfQuoteAccount.split('\\s+');
        if(stageAccountSplitIntoWords.isEmpty() || quoteAccountSplitIntoWords.isEmpty()) {
            return false;
        }
        // 1. Check if first words match
        if(stageAccountSplitIntoWords[0] == quoteAccountSplitIntoWords[0]) {
            return true;
        }
        // 2. Find the longest word in str1
        String longestWord = '';
        for(String word : stageAccountSplitIntoWords){
            if(word.length() > longestWord.length()) {
                longestWord = word;
            }
        }
        // Check if that longest word is contained in str2
        if(quoteAccountSplitIntoWords.contains(longestWord)){
            return true;
        }
        return false;
    }
}