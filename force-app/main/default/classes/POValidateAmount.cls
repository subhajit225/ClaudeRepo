public with sharing class POValidateAmount implements Queueable { 
    @TestVisible
    private static Boolean isTestRunning = false; 
    private Set<Id> poIds;
    private Boolean netAppOrder; 
    Map<String,Fuzzy_Logic_Setting__c> fuzzyLogicSetting ;
    Map<id,opportunity> conditionalPOOpportunitiesMap;
    public POValidateAmount(Set<Id> poIds, Boolean netAppOrder){
        this.poIds = poIds;
        this.netAppOrder = netAppOrder;
    }

    public void execute(QueueableContext context) {
        validateAmount();
    }

    private void validateAmount(){
        fuzzyLogicSetting = Fuzzy_Logic_Setting__c.getAll();
        //Set<Id> quoteIds = new Set<Id>();
        List<PO_Stage__c> poStagesToUpdate = new List<PO_Stage__c>();
        List<PO_Stage_Errors__c> poStageErrors = new List<PO_Stage_Errors__c>();
        Map<id,opportunity> OptyUpdateMap = new Map<id,opportunity>();

        OrderHandler handler = OrderHandler.getInstance();

        List<PO_Stage__c> poStagesForInternalValidations = new List<PO_Stage__c>();
        Set<Id> quoteIdsForInternalValidations = new Set<Id>();

        set<Order> ordToUpdate = new set<Order>();

        Set<Id> successfulOpttys = new Set<Id>();
        Set<Id> failedOpttys = new Set<Id>();
        Map<id,PO_Stage__c> oppIdStgPOMap = new Map<id,PO_Stage__c>();
        for(PO_Stage__c poStage: [Select Id,EDI_DISTI_ID__c,PO_Index__c,partner_name__c,PoDate__c,ShippingCity__c,ShippingCountry__c,ShippingCountryCode__c,ShippingPostalCode__c,ShippingState__c,ShippingStateCode__c,ShippingStreet__c,Shipping_Method__c,Ship_To_Contact_Name__c,Shipping_Carrier__c,
        Shipping_Account_Number__c,End_User_PO__c,Service_Level__c,Ship_to_Email__c,Ship_to_Account_Name__c,Ship_To_Phone_Number__c,Payment_Terms__c,PoNumber__c,
        Opportunity__c,Quote__r.SBQQ__Opportunity2__c,Consult_Splitted__c,Bill_To_Name_Str__c,Note_on_Contingency_and_Special_Language__c,Expected_number_of_POs__c,Quote__c,Account_name__c,Quote__r.SBQQ__NetAmount__c,TotalAmount__c,Payment_Schedule__c,
        Payment_schedule_type__c,Quote__r.SBQQ__Opportunity2__r.owner.email, Customer_Requested_Ship_Date__c from PO_Stage__c where Id in :poIds]){
                if(!isSplitPO(poStage)){
                    System.debug(LoggingLevel.DEBUG,poStage.TotalAmount__c);
                    System.debug(LoggingLevel.DEBUG,poStage.Quote__r.SBQQ__NetAmount__c);
                    /*if(poStage.TotalAmount__c != poStage.Quote__r.SBQQ__NetAmount__c){
                        poStagesToUpdate.add(new PO_Stage__c(Id = poStage.Id, PO_Validation_Status__c = 'Failure'));
                        PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'PO-16', Error_Code__c = 'PO-16', 
                            Error_Message__c = 'Price mismatch with quote.', 
                            PO_Stage_Id__c = poStage.Id,
                            Error_Type__c = 'External'
                        );
                        poStageErrors.add(error);
                    }
                    else {*/
                        poStagesForInternalValidations.add(poStage);
                        quoteIdsForInternalValidations.add(poStage.Quote__c);
                        oppIdStgPOMap.put(poStage.Opportunity__c,poStage);
                    //}
                }
                // else{
                //     if(isFinalPO(poStage)){
                //         quoteIds.add(poStage.Quote__c);
                //     }
                // }
        }

        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([Select Id, SBQQ__Status__c, SBQQ__Primary__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SBQQ__Ordered__c,SBQQ__Opportunity2__r.Distributor_Lookup__c,  SBQQ__Opportunity2__r.Distributor_Lookup__r.name,
                SBQQ__Opportunity2__r.StageName, SBQQ__Opportunity2__r.Sell_to_Partner__r.name, SBQQ__Account__r.Name,SBQQ__ExpirationDate__c, SBQQ__Opportunity2__r.Hold_Code__c,SBQQ__Type__c,(SELECT Id,Name,SBQQ__Product__r.Appliance_Model_HW__c,SBQQ__Product__r.Product_Type__c  
                                                       FROM SBQQ__LineItems__r) from SBQQ__Quote__c where Id in :quoteIdsForInternalValidations]);
        
        Map<id,order> stagepoIdOrdMap = new map<id,order>();
        for(Order ord : [select id,account.name,Shipping_Carrier__c,shippingcountrycode,ShippingStateCode,Bill_To_Name__r.name,Sell_to_Partner__c,opportunityId,Hold_Code__c, Order_Sub_Type__c, customer_required_ship_date__c from order where opportunityId IN: oppIdStgPOMap.keyset()]){
          if(ord.Sell_to_Partner__c != null && ord.Bill_To_Name__c != ord.Sell_to_Partner__c && oppIdStgPOMap.get(ord.opportunityId)!=null){
             stagepoIdOrdMap.put(oppIdStgPOMap.get(ord.opportunityId).id,ord);
          }
        }

        Set<id> oppIds = new Set<id>();
        for(SBQQ__Quote__c po :quoteMap.values()){
            if(po.SBQQ__Opportunity2__c != null)
                oppIds.add(po.SBQQ__Opportunity2__c);
        }
        conditionalPOOpportunitiesMap = new map<id,opportunity>([select id,Opportunity_Sub_Type__c,(select id, POC_Opportunity__c, POC_Type__c from Orders__r where POC_type__c='Conditional PO' OR POC_type__c='Business Loaner Unit' limit 1) from opportunity where id in: oppIds]);
        
        for(PO_Stage__c poStage: poStagesForInternalValidations){
            boolean didValidationFail = internalValidations(poStage, quoteMap, poStageErrors, successfulOpttys, 
            failedOpttys,OptyUpdateMap,stagepoIdOrdMap.get(poStage.id));
            System.debug(LoggingLevel.DEBUG,'test code '+OptyUpdateMap);
            if(didValidationFail){
                poStagesToUpdate.add(new PO_Stage__c(Id = poStage.Id, Shipping_Account_Number__c = poStage.Shipping_Account_Number__c,Shipping_Carrier__c = poStage.Shipping_Carrier__c,Service_Level__c = poStage.Service_Level__c,PO_Internal_Validation_Status__c = 'Internal Failure'));    
            }
            else{
                poStagesToUpdate.add(new PO_Stage__c(Id = poStage.Id,Shipping_Account_Number__c = poStage.Shipping_Account_Number__c,Shipping_Carrier__c = poStage.Shipping_Carrier__c,Service_Level__c = poStage.Service_Level__c,PO_Internal_Validation_Status__c = 'Success', PO_Validation_Status__c = 'Success'));
            }
        }

        try{

            if(poStageErrors.size()>0){
                insert poStageErrors;
            }
            
            successfulOpttys.removeAll(failedOpttys);
            if(poStagesToUpdate.size()>0){
                update poStagesToUpdate;
            }
         
            if(successfulOpttys.size()>0){

                for(Id opttyId: successfulOpttys){
                    if(netAppOrder){
                        PO_Stage__c stgPO = oppIdStgPOMap?.get(opttyId);
                        Order ord = stagepoIdOrdMap?.get(stgPO?.id);
                        if(stgPO != null && ord!= null){
                            
                            ord.Stage_PO__c = stgPO.id;
                            ord.Reason_For_Split__c = 'System Split based on PO';
                            handler.helper.copyPODetails(ord,new List<PO_Stage__c>{stgPO},null);
                            ordToUpdate.add(ord);
                            
                        }
                        system.debug(LoggingLevel.DEBUG,'ordToUpdate'+ordToUpdate);
                    }
                else {
                        if(OptyUpdateMap.get(opttyId)!= null &&  OptyUpdateMap.containsKey(opttyid)){
                            OptyUpdateMap.get(opttyId).SBQQ__Ordered__c = true;
                        }else{
                            opportunity opp= new Opportunity(Id = opttyId, SBQQ__Ordered__c = true);
                            OptyUpdateMap.put(opttyId,opp);
                        }
                    }    
                
                }
    

            }
            
            System.debug(LoggingLevel.DEBUG,'test code '+OptyUpdateMap);

            if(OptyUpdateMap != null && OptyUpdateMap.size()>0){

                    update OptyUpdateMap.values();

            }

            if(!ordToUpdate.isEmpty()){
              update new List<order>(ordToUpdate);
            }

        }Catch(Exception e){
             
                        Batch_Error_Log__c bel = new Batch_Error_Log__c();
                        bel.Failure_Job_ID__c = 'Failure from Single PO Internal Validation';
                        bel.Failure_Message__c = e.getMessage();
                        insert bel;
                        
        }        
       

       
    }

    private Boolean internalValidations(PO_Stage__c poStage, Map<Id, SBQQ__Quote__c> quoteMap, List<PO_Stage_Errors__c> poStageErrorsVar, Set<Id> successfulOpttys, 
        Set<Id> failedOpttys,Map<id,opportunity> OptyUpdateMapVar, Order ord){
        Boolean internalValidationFailed = false;
        Id quoteId = poStage.Quote__c;
        SBQQ__Quote__c quote;
        List<PO_Stage_Errors__c> poStageErrors = new List<PO_Stage_Errors__c>();
        System.debug(LoggingLevel.DEBUG,quoteId);
        Map<string,POValidation_ErrorCode__c> validationCodes = POValidation_ErrorCode__c.getAll();
        if(postage != null){
        
            //added by Rahul for PRDOPS21-48
            if(String.isNotBlank(postage.Payment_schedule_type__c)){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-12', Error_Code__c = 'INT-12', 
                Error_Message__c = validationCodes.get('INT-12') != null? validationCodes.get('INT-12').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                PO_Stage_Id__c = poStage.Id,
                Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);
            }        
             
            
             
            if((conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c) != null && (conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c).Orders__r != null && conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c).Orders__r.size()>0) ) ){
                postage.Shipping_Account_Number__c = null;
                postage.Shipping_Carrier__c = 'No Shipping Required';
                postage.Service_Level__c = 'N/A';
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-10', Error_Code__c = 'INT-10', 
                    Error_Message__c = validationCodes.get('INT-10') != null? validationCodes.get('INT-10').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = postage.Id
                );
                //internalErrorCaught=true;
                poStageErrors.add(error);
            }
            
            if((String.isBlank(poStage.Shipping_Account_Number__c) && String.isBlank(poStage.Shipping_Carrier__c) && String.isBlank(poStage.Service_Level__c)) || (poStage.Shipping_Account_Number__c == null && poStage.Shipping_Carrier__c == 'No Shipping Required' && poStage.Service_Level__c == 'N/A')){
                //Do Nothing. if this is false then atleast one of them is not blank.Cypress -70
            }else{
                if(String.isBlank(poStage.Shipping_Carrier__c) || isTestRunning){
                   
                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-06', Error_Code__c = 'INT-06', 
                    Error_Message__c = validationCodes.get('INT-06A') != null? validationCodes.get('INT-06A').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                    );
                    poStageErrors.add(error);
                 }
                 if(String.isBlank(poStage.Service_Level__c)){
                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-06', Error_Code__c = 'INT-06', 
                    Error_Message__c = validationCodes.get('INT-06B') != null? validationCodes.get('INT-06B').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                    );
                    poStageErrors.add(error);
                 }
                 if(String.isBlank(poStage.Shipping_Account_Number__c)){
                    PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-06', Error_Code__c = 'INT-06', 
                    Error_Message__c = validationCodes.get('INT-06C') != null? validationCodes.get('INT-06C').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                    );
                    poStageErrors.add(error);
                 }

            }

        }
        if(quoteId != null){

            quote = quoteMap.get(quoteId);
            if(quote.SBQQ__ExpirationDate__c < System.today()){
                 PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-08',  Opp_Owners_Email__c = poStage.Quote__r.SBQQ__Opportunity2__r.owner.email,Error_Code__c = 'INT-08', 
                    Error_Message__c =validationCodes.get('INT-08') != null? validationCodes.get('INT-08').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);
            }
            
           If(poStage.Note_on_Contingency_and_Special_Language__c != null && poStage.Note_on_Contingency_and_Special_Language__c !=''){
                 PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-09', Error_Code__c = 'INT-09', 
                    Error_Message__c = validationCodes.get('INT-09') != null? validationCodes.get('INT-09').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id
                );
                 poStageErrors.add(error);
            }
            
            string distiName = netAppOrder ? ord?.Bill_To_Name__r?.name : quote?.SBQQ__Opportunity2__r?.Distributor_Lookup__r?.name ;

            if(poStage.Bill_To_Name_Str__c != distiName ){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-07', Error_Code__c = 'INT-07', 
                    Error_Message__c =validationCodes.get('INT-07') != null? validationCodes.get('INT-07').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);

            }


            if(quote.SBQQ__Status__c == 'Approved' && quote.SBQQ__Primary__c){
                //errorMessagesMap.put('Is Primary Quote Approved', 'Success');
            }
            else if(quote.SBQQ__Primary__c){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-01', Error_Code__c = 'INT-01', 
                    Error_Message__c = validationCodes.get('INT-01') != null? validationCodes.get('INT-01').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);
                String OpptyHoldCode = quote?.SBQQ__Opportunity2__r?.Hold_Code__c;
                if(OptyUpdateMapVar.get(quote.SBQQ__Opportunity2__c)!= null && OptyUpdateMapVar.containskey(quote.SBQQ__Opportunity2__c)){
                    String tempOpptyHoldCode = OptyUpdateMapVar.get(quote.SBQQ__Opportunity2__c).Hold_Code__c;
                    OptyUpdateMapVar.get(quote.SBQQ__Opportunity2__c).Hold_Code__c = (tempOpptyHoldCode != null && !tempOpptyHoldCode.contains('Unapproved Quote')) ? (tempOpptyHoldCode +=';Unapproved Quote') : (tempOpptyHoldCode == null) ? 'Unapproved Quote' : tempOpptyHoldCode;
                }else{
                    opportunity opp= new Opportunity();
                    opp.Id = quote.SBQQ__Opportunity2__c; 
                    Opp.Hold_Code__c = (String.isNotBlank(opptyHoldCode) && !opptyHoldCode.contains('Unapproved Quote')) ? (opptyHoldCode += ';Unapproved Quote') : string.isBlank(opptyHoldCode) ? 'Unapproved Quote' : opptyHoldCode;
                    OptyUpdateMapVar.put(quote.SBQQ__Opportunity2__c,opp);
                }
                
            }
            else{
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-01', Error_Code__c = 'INT-01', 
                    Error_Message__c =validationCodes.get('INT-01A') != null? validationCodes.get('INT-01A').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);
            }
            System.debug(LoggingLevel.DEBUG,quote.SBQQ__Opportunity2__r.StageName);
            //if(quote.SBQQ__Opportunity2__r.StageName != '6 PO With Channel'){
                if((quote.SBQQ__Opportunity2__r.StageName != '6 PO With Channel' && quote.SBQQ__Opportunity2__r.StageName != '7 Closed Won' && netAppOrder)
                || (quote.SBQQ__Opportunity2__r.StageName != '6 PO With Channel'  && !netAppOrder)){
                 PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-02', Error_Code__c = 'INT-02', 
                     Error_Message__c =validationCodes.get('INT-02') != null? validationCodes.get('INT-02').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                     PO_Stage_Id__c = poStage.Id,
                     Error_Type__c = 'Internal'
                 ); 
                 if(netAppOrder){
                     error = new PO_Stage_Errors__c(Name = 'INT-04', Error_Code__c = 'INT-04', 
                     Error_Message__c =validationCodes.get('INT-04') != null? validationCodes.get('INT-04').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                     PO_Stage_Id__c = poStage.Id,
                     Error_Type__c = 'Internal'); 
                 } 
                poStageErrors.add(error);
                
                if(OptyUpdateMapVar.get(quote.SBQQ__Opportunity2__c)!= null && OptyUpdateMapVar.containskey(quote.SBQQ__Opportunity2__c)){
                    if(!(conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c) != null && conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c).Orders__r != null && conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c).Orders__r.size() > 0) ){
                        OptyUpdateMapVar.get(quote.SBQQ__Opportunity2__c).PO_Received_Notification_Sent__c = true;
                    }
                    OptyUpdateMapVar.get(quote.SBQQ__Opportunity2__c).Send_Hold_Off_Email__c = true;
                }else{
                    opportunity opp= new Opportunity(Id = quote.SBQQ__Opportunity2__c, Send_Hold_Off_Email__c = true);
                    if(!(conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c) != null && conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c).Orders__r != null && conditionalPOOpportunitiesMap.get(postage.Quote__r.SBQQ__Opportunity2__c).Orders__r.size() > 0) ){
                        opp.PO_Received_Notification_Sent__c = true;
                    }
                    OptyUpdateMapVar.put(quote.SBQQ__Opportunity2__c,opp);
                }
                
            }

            //SF-6114
            if(String.isNotBlank(quote.SBQQ__Opportunity2__r.Hold_Code__c) && 
                quote.SBQQ__Opportunity2__r.Hold_Code__c.contains('Contingency with order')){
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-13', Error_Code__c = 'INT-13', 
                    Error_Message__c =validationCodes.get('INT-13') != null? validationCodes.get('INT-13').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);
            }
            

            Decimal limitFuzzy;
            Decimal fuzMatch;
            string accName = netAppOrder ? ord?.account?.name : quote?.SBQQ__Account__r?.Name ;
            system.debug(LoggingLevel.DEBUG,'accName'+accName);
            Boolean fuzzyMatchNeeded=false;
            if((fuzzyLogicSetting.get(quote.SBQQ__Opportunity2__r.Distributor_Lookup__c) != null && fuzzyLogicSetting.get(quote.SBQQ__Opportunity2__r.Distributor_Lookup__c).Fuzzy_Enabled__c)
            || (fuzzyLogicSetting.get('ALL') != null && fuzzyLogicSetting.get('ALL').Fuzzy_Enabled__c && fuzzyLogicSetting.get(quote.SBQQ__Opportunity2__r.Distributor_Lookup__c) == null)){
                
                fuzzyMatchNeeded = true;
                limitFuzzy = fuzzyLogicSetting.get(quote.SBQQ__Opportunity2__r.Distributor_Lookup__c) != null && fuzzyLogicSetting.get(quote.SBQQ__Opportunity2__r.Distributor_Lookup__c).Fuzzy_logic_Limit__c != null?fuzzyLogicSetting.get(quote.SBQQ__Opportunity2__r.Distributor_Lookup__c).Fuzzy_logic_Limit__c : null;
                limitFuzzy = limitFuzzy == null && fuzzyLogicSetting.get('ALL') != null && fuzzyLogicSetting.get('ALL').Fuzzy_logic_Limit__c!=null?fuzzyLogicSetting.get('ALL').Fuzzy_logic_Limit__c:null;
                fuzMatch = FuzzyMethod.JaroFuzzyMethod(poStage.Account_Name__c,accName);
            }
            System.debug(LoggingLevel.DEBUG,'test fuzzy '+limitFuzzy);
            System.debug(LoggingLevel.DEBUG,'test fuzzy '+fuzMatch);
            System.debug(LoggingLevel.DEBUG,'test fuzzy '+fuzzyMatchNeeded);
            
            if((accName != poStage.Account_Name__c && !fuzzyMatchNeeded) || (fuzzyMatchNeeded && fuzMatch <limitFuzzy ) )
            {
                PO_Stage_Errors__c error = new PO_Stage_Errors__c(Name = 'INT-03', Error_Code__c = 'INT-03', 
                    Error_Message__c = validationCodes.get('INT-03') != null? validationCodes.get('INT-03').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                    PO_Stage_Id__c = poStage.Id,
                    Error_Type__c = 'Internal'
                );
                poStageErrors.add(error);
            }
        }
        System.debug(LoggingLevel.DEBUG,poStageErrors);
        if(poStageErrors.size() > 0){
            internalValidationFailed = true;
            //insert poStageErrors;
            poStageErrorsVar.addAll(poStageErrors);
            failedOpttys.add(quote.SBQQ__Opportunity2__c); 
        }
        else{ 
            
            if(!quote.SBQQ__Opportunity2__r.SBQQ__Ordered__c || netAppOrder){
                successfulOpttys.add(quote.SBQQ__Opportunity2__c);
                //update new Opportunity(Id = quote.SBQQ__Opportunity2__c, SBQQ__Ordered__c = true);
            }
        }
        return internalValidationFailed;
    }

    private boolean isSplitPO(PO_Stage__c poStage){
        return poStage.Expected_number_of_POs__c != null && poStage.Expected_number_of_POs__c > 1;
    }

    private boolean isFinalPO(PO_Stage__c poStage){
        return poStage.PO_Index__c != null && poStage.Expected_number_of_POs__c != null && poStage.Expected_number_of_POs__c == poStage.PO_Index__c;
    }
}