/**
 * @description apex class to manual override ACV amounts on opportunity and opportunity product
 */
public without sharing class OpportunityManualOverride {

    /**
     * @description to get Opportunity or Opplineitem record details
     * @param recordId
     **/
    @AuraEnabled
    public static List<recordDetailsWrap> getDetails(string recordId){
        List<recordDetailsWrap> recordDetailsWrapList = new List<recordDetailsWrap>();
        try{
            system.debug(System.logginglevel.ERROR,'@@ recordId '+recordId);
            Boolean hasPermission = FeatureManagement.checkPermission('Opportunity_Amount_Override');
            
            if(!string.isBlank(recordId) && hasPermission){
                Id recId = Id.valueOf(recordId);
                if(recId.getSObjectType().getDescribe().getName() == 'Opportunity'){
                    List<Opportunity> opplist = new List<Opportunity>();
                    opplist = [select Id,Subsumed_Renewal_Churn_TCV__c,Subsumed_Renewal_Churn_ACV__c,Opportunity_Amount_Override__c,isclosed,ACV_Amount__c,Renewal_Subsumed_ACV__c,Subsumed_Renewal_TCV__c,New_Expansion_ACV__c,New_Expansion_TCV__c,Core_New_Expansion_ACV__c,NAS_New_Expansion_ACV__c,SaaS_New_Expansion_ACV__c,PLS_New_Expansion_ACV__c,PLS_NCD_New_Expansion_ACV__c, Comp_Uplift_ACV__c from Opportunity where Id =: recId];//SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c                    
					
                    if(opplist != null && !opplist.isEmpty()){
                        if(!opplist[0].Opportunity_Amount_Override__c){
                            recordDetailsWrapList.add(new recordDetailsWrap('Please check Opportunity Amount Override on Opportunity','error',opplist[0].ACV_Amount__c,opplist[0].Renewal_Subsumed_ACV__c,opplist[0].Subsumed_Renewal_TCV__c,opplist[0].New_Expansion_ACV__c,opplist[0].New_Expansion_TCV__c,opplist[0].Core_New_Expansion_ACV__c,opplist[0].NAS_New_Expansion_ACV__c,opplist[0].SaaS_New_Expansion_ACV__c,opplist[0].PLS_NCD_New_Expansion_ACV__c,opplist[0].Subsumed_Renewal_Churn_ACV__c,opplist[0].Subsumed_Renewal_Churn_TCV__c, opplist[0].Comp_Uplift_ACV__c));//SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c
                        }
                        if(opplist[0].isclosed){
                            recordDetailsWrapList.add(new recordDetailsWrap('Cannot update already Closed Opportunity','error',opplist[0].ACV_Amount__c,opplist[0].Renewal_Subsumed_ACV__c,opplist[0].Subsumed_Renewal_TCV__c,opplist[0].New_Expansion_ACV__c,opplist[0].New_Expansion_TCV__c,opplist[0].Core_New_Expansion_ACV__c,opplist[0].NAS_New_Expansion_ACV__c,opplist[0].SaaS_New_Expansion_ACV__c,opplist[0].PLS_NCD_New_Expansion_ACV__c,opplist[0].Subsumed_Renewal_Churn_ACV__c,opplist[0].Subsumed_Renewal_Churn_TCV__c, opplist[0].Comp_Uplift_ACV__c));//SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c
                        }else{
                        	recordDetailsWrapList.add(new recordDetailsWrap('','',opplist[0].ACV_Amount__c,opplist[0].Renewal_Subsumed_ACV__c,opplist[0].Subsumed_Renewal_TCV__c,opplist[0].New_Expansion_ACV__c,opplist[0].New_Expansion_TCV__c,opplist[0].Core_New_Expansion_ACV__c,opplist[0].NAS_New_Expansion_ACV__c,opplist[0].SaaS_New_Expansion_ACV__c,opplist[0].PLS_NCD_New_Expansion_ACV__c,opplist[0].Subsumed_Renewal_Churn_ACV__c,opplist[0].Subsumed_Renewal_Churn_TCV__c, opplist[0].Comp_Uplift_ACV__c)); //SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c
                        }
                    }
                }else if(recId.getSObjectType().getDescribe().getName() == 'OpportunityLineItem'){
                    List<OpportunityLineItem> olilist = new List<OpportunityLineItem>();
                    olilist = [select Id,Subsumed_Renewal_Churn_TCV__c,Subsumed_Renewal_Churn_ACV__c,opportunity.Opportunity_Amount_Override__c,opportunity.isclosed,ACV_Amount__c,Subsumed_Renewal_Amount__c,Subsumed_Renewal_TCV__c,New_Expansion_ACV__c,New_Expansion_TCV__c,Core_New_Expansion_ACV__c,NAS_New_Expansion_ACV__c,SaaS_New_Expansion_ACV__c,PLS_NCD_New_Expansion_ACV__c,PLS_New_Expansion_ACV__c, Comp_Uplift_ACV__c from OpportunityLineItem where Id =: recId];//SAL26-1291//SAL26-1277: Comp_Uplift_ACV__c
                    if(olilist != null && !olilist.isEmpty()){
                        if(!olilist[0].opportunity.Opportunity_Amount_Override__c){
                            recordDetailsWrapList.add(new recordDetailsWrap('Please check Opportunity Amount Override on Opportunity','error',olilist[0].ACV_Amount__c,olilist[0].Subsumed_Renewal_Amount__c,olilist[0].Subsumed_Renewal_TCV__c,olilist[0].New_Expansion_ACV__c,olilist[0].New_Expansion_TCV__c,olilist[0].Core_New_Expansion_ACV__c,olilist[0].NAS_New_Expansion_ACV__c,olilist[0].SaaS_New_Expansion_ACV__c,olilist[0].PLS_NCD_New_Expansion_ACV__c,olilist[0].Subsumed_Renewal_Churn_ACV__c,olilist[0].Subsumed_Renewal_Churn_TCV__c, olilist[0].Comp_Uplift_ACV__c));//SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c
                        }
                        if(olilist[0].opportunity.isclosed){
                            recordDetailsWrapList.add(new recordDetailsWrap('Cannot update already Closed Opportunity Product','error',olilist[0].ACV_Amount__c,olilist[0].Subsumed_Renewal_Amount__c,olilist[0].Subsumed_Renewal_TCV__c,olilist[0].New_Expansion_ACV__c,olilist[0].New_Expansion_TCV__c,olilist[0].Core_New_Expansion_ACV__c,olilist[0].NAS_New_Expansion_ACV__c,olilist[0].SaaS_New_Expansion_ACV__c,olilist[0].PLS_NCD_New_Expansion_ACV__c,olilist[0].Subsumed_Renewal_Churn_ACV__c,olilist[0].Subsumed_Renewal_Churn_TCV__c, olilist[0].Comp_Uplift_ACV__c));//SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c
                        }else{
                        	recordDetailsWrapList.add(new recordDetailsWrap('','',olilist[0].ACV_Amount__c,olilist[0].Subsumed_Renewal_Amount__c,olilist[0].Subsumed_Renewal_TCV__c,olilist[0].New_Expansion_ACV__c,olilist[0].New_Expansion_TCV__c,olilist[0].Core_New_Expansion_ACV__c,olilist[0].NAS_New_Expansion_ACV__c,olilist[0].SaaS_New_Expansion_ACV__c,olilist[0].PLS_NCD_New_Expansion_ACV__c,olilist[0].Subsumed_Renewal_Churn_ACV__c,olilist[0].Subsumed_Renewal_Churn_TCV__c, olilist[0].Comp_Uplift_ACV__c)); //SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c
                        }
                    }
                }else{
                    recordDetailsWrapList.add(new recordDetailsWrap('Record Id did not match Opportunity or Opportunity Product','error',null,null,null,null,null,null,null,null,null,null,null, null)); //SAL26-1291:new param//SAL26-1277
                }
            }else{
                recordDetailsWrapList.add(new recordDetailsWrap('Insufficient access to the Opportunity Amount Override screen','error',null,null,null,null,null,null,null,null,null,null,null, null)); //SAL26-1291:new param//SAL26-1277
            }
        }catch (exception e) {
            recordDetailsWrapList.add(new recordDetailsWrap(e.getMessage()+' at line '+e.getLineNumber(),'error',null,null,null,null,null,null,null,null,null,null,null, null)); //SAL26-1291:new param//SAL26-1277
        }
        system.debug(System.logginglevel.ERROR,'@@ recordDetailsWrapList '+recordDetailsWrapList);
        return recordDetailsWrapList;
    }
    /**
     * @description to get Opportunity or Opplineitem record details
     * @param recordId
     * @param acvAmount
     * @param subsumedACV
     * @param subsumedTCV
     * @param new_expansionACV
     * @param new_expansionTCV
     * @param core_new_expansionACV
     * @param nas_new_expansionACV
     * @param saas_new_expansionACV
     * @param ncd_new_expansionACV [SAL26-1291]
     * @param subsumed_renewal_churnACV
     * @param subsumed_renewal_churnTCV
     **/
    @AuraEnabled
    public static Boolean saveItem(string recordId,Decimal acvAmount,Decimal subsumedACV, Decimal subsumedTCV, Decimal new_expansionACV, Decimal new_expansionTCV, Decimal core_new_expansionACV, Decimal nas_new_expansionACV, Decimal saas_new_expansionACV,Decimal ncd_new_expansionACV, Decimal subsumed_renewal_churnACV,Decimal subsumed_renewal_churnTCV, Decimal comp_uplift_acv){ 
        Boolean successSave = false;
        Boolean updateFlag = false;
        List<Opportunity> opplist = new List<Opportunity>();
        List<OpportunityLineItem> olilist = new List<OpportunityLineItem>();
        if(!string.isBlank(recordId)){
            Id recId = Id.valueOf(recordId);
            if(recId.getSObjectType().getDescribe().getName() == 'Opportunity'){
                for(Opportunity opp: [select Id,Subsumed_Renewal_Churn_ACV__c,Subsumed_Renewal_Churn_TCV__c,Opportunity_Amount_Override__c,isclosed,ACV_Amount__c,Renewal_Subsumed_ACV__c,Subsumed_Renewal_TCV__c,New_Expansion_ACV__c,New_Expansion_TCV__c,Core_New_Expansion_ACV__c,NAS_New_Expansion_ACV__c,SaaS_New_Expansion_ACV__c,PLS_NCD_New_Expansion_ACV__c,PLS_New_Expansion_ACV__c, Comp_Uplift_ACV__c from Opportunity where Id =: recId AND Opportunity_Amount_Override__c = true AND IsClosed = false]){ //SAL26-1291:PLS_NCD_New_Expansion_ACV__c//SAL26-1277: Comp_Uplift_ACV__c
                    if((opp.ACV_Amount__c != null && opp.ACV_Amount__c.setscale(5) != acvAmount) || opp.ACV_Amount__c != acvAmount){
                        opp.ACV_Amount__c = acvAmount;
                        updateFlag = true;
                    }
                    if((opp.Renewal_Subsumed_ACV__c != NULL && opp.Renewal_Subsumed_ACV__c.setscale(5) != subsumedACV) || opp.Renewal_Subsumed_ACV__c != subsumedACV){
                        opp.Renewal_Subsumed_ACV__c = subsumedACV;
                        updateFlag = true;
                    }
                    if((opp.Subsumed_Renewal_TCV__c != null && opp.Subsumed_Renewal_TCV__c.setscale(5) != subsumedTCV) || opp.Subsumed_Renewal_TCV__c != subsumedTCV){
                        opp.Subsumed_Renewal_TCV__c = subsumedTCV;
                        updateFlag = true;
                    }
                    if((opp.New_Expansion_ACV__c != null && opp.New_Expansion_ACV__c.setscale(5) != new_expansionACV) || opp.New_Expansion_ACV__c != new_expansionACV){
                        opp.New_Expansion_ACV__c = new_expansionACV;
                        updateFlag = true;
                    }
                    if((opp.New_Expansion_TCV__c != null && opp.New_Expansion_TCV__c.setscale(5) != new_expansionTCV) || opp.New_Expansion_TCV__c != new_expansionTCV){
                        opp.New_Expansion_TCV__c = new_expansionTCV;
                        updateFlag = true;
                    }
                    if((opp.Core_New_Expansion_ACV__c  != null && opp.Core_New_Expansion_ACV__c.setscale(5) != core_new_expansionACV) || opp.Core_New_Expansion_ACV__c  != core_new_expansionACV){
                        opp.Core_New_Expansion_ACV__c  = core_new_expansionACV;
                        updateFlag = true;
                    }
                    if((opp.NAS_New_Expansion_ACV__c  != null && opp.NAS_New_Expansion_ACV__c.setscale(5) != nas_new_expansionACV) || opp.NAS_New_Expansion_ACV__c  != nas_new_expansionACV){
                        opp.NAS_New_Expansion_ACV__c  = nas_new_expansionACV;
                        updateFlag = true;
                    }
                    if((opp.SaaS_New_Expansion_ACV__c  != null && opp.SaaS_New_Expansion_ACV__c.setscale(5) != saas_new_expansionACV) || opp.SaaS_New_Expansion_ACV__c  != saas_new_expansionACV){
                        opp.SaaS_New_Expansion_ACV__c  = saas_new_expansionACV;
                        updateFlag = true;
                    }
                    //SAL26-1291
                    if((opp.PLS_NCD_New_Expansion_ACV__c != null && opp.PLS_NCD_New_Expansion_ACV__c.setscale(5) != ncd_new_expansionACV) || opp.PLS_NCD_New_Expansion_ACV__c != ncd_new_expansionACV){
                        opp.PLS_NCD_New_Expansion_ACV__c = ncd_new_expansionACV;
                        updateFlag = true;
                    }
                    if((opp.Subsumed_Renewal_Churn_ACV__c  != null && opp.Subsumed_Renewal_Churn_ACV__c.setscale(5) != subsumed_renewal_churnACV) || opp.Subsumed_Renewal_Churn_ACV__c  != subsumed_renewal_churnACV){
                        opp.Subsumed_Renewal_Churn_ACV__c  = subsumed_renewal_churnACV;
                        updateFlag = true;
                    }
                    if((opp.Subsumed_Renewal_Churn_TCV__c  != null && opp.Subsumed_Renewal_Churn_TCV__c.setscale(5) != subsumed_renewal_churnTCV) || opp.Subsumed_Renewal_Churn_TCV__c  != subsumed_renewal_churnTCV){
                        opp.Subsumed_Renewal_Churn_TCV__c  = subsumed_renewal_churnTCV;
                        updateFlag = true;
                    }
                    if((opp.Comp_Uplift_ACV__c  != null && opp.Comp_Uplift_ACV__c.setscale(5) != comp_uplift_acv) || opp.Comp_Uplift_ACV__c  != comp_uplift_acv){ //SAL26-1277
                        opp.Comp_Uplift_ACV__c  = comp_uplift_acv;
                        updateFlag = true;
                    }
                    if(updateFlag){
                        opp.PLS_NCD_New_Expansion_ACV__c = opp.PLS_NCD_New_Expansion_ACV__c != null ? opp.PLS_NCD_New_Expansion_ACV__c : 0;//SAL26-1291
                        opp.NAS_New_Expansion_ACV__c = opp.NAS_New_Expansion_ACV__c != null ? opp.NAS_New_Expansion_ACV__c : 0;
                        opp.SaaS_New_Expansion_ACV__c = opp.SaaS_New_Expansion_ACV__c != null ? opp.SaaS_New_Expansion_ACV__c : 0;
                        opp.PLS_New_Expansion_ACV__c = opp.NAS_New_Expansion_ACV__c + opp.SaaS_New_Expansion_ACV__c + opp.PLS_NCD_New_Expansion_ACV__c;
                        opp.Subsumed_Renewal_Churn_ACV__c = opp.Subsumed_Renewal_Churn_ACV__c != null ? opp.Subsumed_Renewal_Churn_ACV__c : 0;
                        opp.Subsumed_Renewal_Churn_TCV__c = opp.Subsumed_Renewal_Churn_TCV__c != null ? opp.Subsumed_Renewal_Churn_TCV__c : 0;
                        opp.Comp_Uplift_ACV__c = opp.Comp_Uplift_ACV__c ?? 0; //SAL26-1277
                        opplist.add(opp);
                    }
                }
            }else if(recId.getSObjectType().getDescribe().getName() == 'OpportunityLineItem'){
                updateFlag = false;
                for(OpportunityLineItem oli: [select Id,Subsumed_Renewal_Churn_ACV__c,Subsumed_Renewal_Churn_TCV__c,opportunityId,opportunity.Opportunity_Amount_Override__c,opportunity.isclosed,ACV_Amount__c,Subsumed_Renewal_Amount__c,Subsumed_Renewal_TCV__c,New_Expansion_ACV__c,New_Expansion_TCV__c,Core_New_Expansion_ACV__c,NAS_New_Expansion_ACV__c,SaaS_New_Expansion_ACV__c,PLS_NCD_New_Expansion_ACV__c,PLS_New_Expansion_ACV__c, Comp_Uplift_ACV__c from OpportunityLineItem where Id =: recId AND opportunity.Opportunity_Amount_Override__c = true AND opportunity.IsClosed = false]){
                    if((oli.ACV_Amount__c != null && oli.ACV_Amount__c.setscale(5) != acvAmount) || oli.ACV_Amount__c !=acvAmount){
                        oli.ACV_Amount__c = acvAmount;
                        updateFlag = true;
                    }
                    if((oli.Subsumed_Renewal_Amount__c != null && oli.Subsumed_Renewal_Amount__c.setscale(5) != subsumedACV) || oli.Subsumed_Renewal_Amount__c != subsumedACV){
                        oli.Subsumed_Renewal_Amount__c = subsumedACV;
                        updateFlag = true;
                    }
                    if((oli.Subsumed_Renewal_TCV__c != null && oli.Subsumed_Renewal_TCV__c.setscale(5) != subsumedTCV) || oli.Subsumed_Renewal_TCV__c != subsumedTCV){
                        oli.Subsumed_Renewal_TCV__c = subsumedTCV;
                        updateFlag = true;
                    }
                    if((oli.New_Expansion_ACV__c != null && oli.New_Expansion_ACV__c.setscale(5) != new_expansionACV) || oli.New_Expansion_ACV__c != new_expansionACV){
                        oli.New_Expansion_ACV__c = new_expansionACV;
                        updateFlag = true;
                    }
                    if((oli.New_Expansion_TCV__c != null && oli.New_Expansion_TCV__c.setscale(5) != new_expansionTCV) || oli.New_Expansion_TCV__c != new_expansionTCV){
                        oli.New_Expansion_TCV__c = new_expansionTCV;
                        updateFlag = true;
                    }
                    if((oli.Core_New_Expansion_ACV__c  != null && oli.Core_New_Expansion_ACV__c.setscale(5) != core_new_expansionACV) || oli.Core_New_Expansion_ACV__c  != core_new_expansionACV){
                        oli.Core_New_Expansion_ACV__c  = core_new_expansionACV;
                        updateFlag = true;
                    }
                    if((oli.NAS_New_Expansion_ACV__c  != null && oli.NAS_New_Expansion_ACV__c.setscale(5) != nas_new_expansionACV) || oli.NAS_New_Expansion_ACV__c  != nas_new_expansionACV){
                        oli.NAS_New_Expansion_ACV__c  = nas_new_expansionACV;
                        updateFlag = true;
                    }
                    if((oli.SaaS_New_Expansion_ACV__c  != null && oli.SaaS_New_Expansion_ACV__c.setscale(5) != saas_new_expansionACV) || oli.SaaS_New_Expansion_ACV__c  != saas_new_expansionACV){
                        oli.SaaS_New_Expansion_ACV__c  = saas_new_expansionACV;
                        updateFlag = true;
                    }
                    if((oli.PLS_NCD_New_Expansion_ACV__c  != null && oli.PLS_NCD_New_Expansion_ACV__c.setscale(5) != ncd_new_expansionACV) || oli.PLS_NCD_New_Expansion_ACV__c  != ncd_new_expansionACV){//SAL26-1291
                        oli.PLS_NCD_New_Expansion_ACV__c  = ncd_new_expansionACV;
                        updateFlag = true;
                    }
                    if((oli.Subsumed_Renewal_Churn_ACV__c  != null && oli.Subsumed_Renewal_Churn_ACV__c.setscale(5) != subsumed_renewal_churnACV) || oli.Subsumed_Renewal_Churn_ACV__c  != subsumed_renewal_churnACV){
                        oli.Subsumed_Renewal_Churn_ACV__c  = subsumed_renewal_churnACV;
                        updateFlag = true;
                    }
                    if((oli.Subsumed_Renewal_Churn_TCV__c  != null && oli.Subsumed_Renewal_Churn_TCV__c.setscale(5) != subsumed_renewal_churnTCV) || oli.Subsumed_Renewal_Churn_TCV__c  != subsumed_renewal_churnTCV){
                        oli.Subsumed_Renewal_Churn_TCV__c  = subsumed_renewal_churnTCV;
                        updateFlag = true;
                    }
                    if((oli.Comp_Uplift_ACV__c  != null && oli.Comp_Uplift_ACV__c.setscale(5) != comp_uplift_acv) || oli.Comp_Uplift_ACV__c  != comp_uplift_acv){ //SAL26-1277
                        oli.Comp_Uplift_ACV__c  = comp_uplift_acv;
                        updateFlag = true;
                    }
                    if(updateFlag){
                        oli.PLS_NCD_New_Expansion_ACV__c = oli.PLS_NCD_New_Expansion_ACV__c != null ? oli.PLS_NCD_New_Expansion_ACV__c : 0; //SAL26-1291
                        oli.NAS_New_Expansion_ACV__c = oli.NAS_New_Expansion_ACV__c != null ? oli.NAS_New_Expansion_ACV__c : 0;
                        oli.SaaS_New_Expansion_ACV__c = oli.SaaS_New_Expansion_ACV__c != null ? oli.SaaS_New_Expansion_ACV__c : 0;
                        oli.PLS_New_Expansion_ACV__c = oli.NAS_New_Expansion_ACV__c + oli.SaaS_New_Expansion_ACV__c + oli.PLS_NCD_New_Expansion_ACV__c;
                        oli.Subsumed_Renewal_Churn_ACV__c = oli.Subsumed_Renewal_Churn_ACV__c != null ? oli.Subsumed_Renewal_Churn_ACV__c : 0;
                        oli.Subsumed_Renewal_Churn_TCV__c = oli.Subsumed_Renewal_Churn_TCV__c != null ? oli.Subsumed_Renewal_Churn_TCV__c : 0;

                        oli.Comp_Uplift_ACV__c = oli.Comp_Uplift_ACV__c ?? 0; //SAL26-1277
                        olilist.add(oli);
                    }
            	}
        	}
            system.debug(System.logginglevel.ERROR,'@@ updateFlag '+updateFlag);
            system.debug(System.logginglevel.ERROR,'@@ opplist '+opplist);
            system.debug(System.logginglevel.ERROR,'@@ olilist '+olilist);
            FlowControll.opportunityTriggerHandler = false;
            FlowControll.opportunityLineItemHandler = false;
            if(!opplist.isEmpty()){
                update opplist;
                successSave = true;
            }
            if(!olilist.isEmpty()){
                update olilist;
                successSave = true;
            }
            
            FlowControll.opportunityTriggerHandler = true;
            FlowControll.opportunityLineItemHandler = true;
        }
        
        return successSave;
    }
    public class recordDetailsWrap{
        @AuraEnabled public string errMsg;
        @AuraEnabled public string variant;
        @AuraEnabled public Decimal acvAmount;
        @AuraEnabled public Decimal subsumedACV;
        @AuraEnabled public Decimal subsumedTCV;
        @AuraEnabled public Decimal new_expansionACV;
        @AuraEnabled public Decimal new_expansionTCV;
        @AuraEnabled public Decimal core_new_expansionACV;
        @AuraEnabled public Decimal nas_new_expansionACV;
        @AuraEnabled public Decimal saas_new_expansionACV;
        @AuraEnabled public Decimal ncd_new_expansionACV; //SAL26-1291
        @AuraEnabled public Decimal subsumed_renewal_churnTCV;
        @AuraEnabled public Decimal subsumed_renewal_churnACV;
        @AuraEnabled public Decimal comp_uplift_acv; //SAL26-1277
        public RecordDetailsWrap(string errMsg1,string variant1,Decimal acvAmount1,Decimal subsumedACV1, Decimal subsumedTCV1, Decimal new_expansionACV1, Decimal new_expansionTCV1, Decimal core_new_expansionACV1, Decimal nas_new_expansionACV1, Decimal saas_new_expansionACV1, Decimal ncd_new_expansionACV1, Decimal subsumed_renewal_churnACV1, Decimal subsumed_renewal_churnTCV1, Decimal comp_uplift_acv1){
            errMsg = errMsg1;
            variant = variant1;
            acvAmount = acvAmount1;
            subsumedACV = subsumedACV1;
            subsumedTCV = subsumedTCV1;
            new_expansionACV = new_expansionACV1;
            new_expansionTCV = new_expansionTCV1;
            core_new_expansionACV = core_new_expansionACV1;
            nas_new_expansionACV = nas_new_expansionACV1;
            saas_new_expansionACV = saas_new_expansionACV1;
            ncd_new_expansionACV = ncd_new_expansionACV1; //SAL26-1291
            subsumed_renewal_churnACV = subsumed_renewal_churnACV1;
            subsumed_renewal_churnTCV = subsumed_renewal_churnTCV1;
            comp_uplift_acv = comp_uplift_acv1; //SAL26-1277
        } 
    }
}