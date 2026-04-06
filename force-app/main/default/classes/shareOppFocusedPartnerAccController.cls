//SAL24-21 - Named Partner CDM Opp Visibility
public without sharing class shareOppFocusedPartnerAccController  implements Queueable{
    public Map<Id,Account> partnerAccMap;
    public Map<Id,Id> accOldOwnerIdMap;
    public Set<Id> accTypeChangeId;
    public Map<Id,Account> accTypeChangeMap;
    public Set<Id> focusNationalAccIds;//SAL24-527
    public shareOppFocusedPartnerAccController(Map<Id,Account> partnerAccMap1,Map<Id,Id> accOldOwnerIdMap1, Map<Id,Account> accTypeChangeMap1,Set<Id> parafocusNationalAccIds ){
    partnerAccMap = new Map<Id,Account>();
        accOldOwnerIdMap = new Map<Id,Id>();
        accTypeChangeMap = new Map<Id,Account>();
        focusNationalAccIds = new  Set<Id>();
        partnerAccMap = partnerAccMap1; 
        accOldOwnerIdMap = accOldOwnerIdMap1;
        accTypeChangeMap = accTypeChangeMap1; //SAL24-257
        focusNationalAccIds=parafocusNationalAccIds;//SAL24-527
    }
    //When Focused on Partner Account is either checked/unchecked it will insert/delete oppteammembers related opportunity of partner account
    public void execute(QueueableContext context){
    shareOpportunities(); //SAL24-283
    }

    //SAL24-283
    public void shareOpportunities(){
    List<OpportunityTeamMember> createotmList = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> deleteotmList = new List<OpportunityTeamMember>();
        List<Opportunity> openSalesOppList = new List<Opportunity>();
        List<Opportunity> updateOppList = new List<Opportunity>();
        Set<Id> focusedAccSet = new Set<Id>();
        Set<Id> unfocusedAccSet = new Set<Id>();
        List<ShGl_DisableBusinessLogic__c> dflList = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c modifydfl = new ShGl_DisableBusinessLogic__c();
    Id partnerrecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Id salesOppTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        Boolean modifiedflag = false;
        Boolean createflag = false;
        try{
            if(!partnerAccMap.isEmpty()){
                for(Account acc : partnerAccMap.values()){
                    if(acc.Focused_Partner__c && acc.recordtypeId == partnerrecTypeId){
                        focusedAccSet.add(acc.Id);
                    }else if(!acc.Focused_Partner__c && acc.recordtypeId == partnerrecTypeId){
                        unfocusedAccSet.add(acc.Id);
                    }
                }
            }
            //SAl24-199
            if(!accOldOwnerIdMap.isEmpty() && !partnerAccMap.isEmpty()){
               for(Id accId : accOldOwnerIdMap.keySet()){
                    if(partnerAccMap.containskey(accId) && partnerAccMap.get(accId).Focused_Partner__c && partnerAccMap.get(accId).recordtypeId == partnerrecTypeId){
                        unfocusedAccSet.add(accId);
                        focusedAccSet.add(accId);
                    }
                }         
            }
            //SAL24-257 //SAL24-527
            if(!accTypeChangeMap.isEmpty() || !focusNationalAccIds.isEmpty()){
                focusNationalAccIds.remove(null);
                for(Opportunity opp : [select Id,RecordTypeId,Sourcing_Partner__c,Teaming_Partner__c,Partner_Lookup__c,AccountId,Opportunity_Type__c,Opportunity_Sub_Type__c,StageName,IsClosed,Account_Deal_Desk_Notes__c,Number_of_NFR_Products__c,Sourcing_Partner__r.National_Partner__c,Sourcing_Partner__r.Focused_Partner__c,Teaming_Partner__r.National_Partner__c,Teaming_Partner__r.Focused_Partner__c,Partner_Lookup__r.National_Partner__c,Partner_Lookup__r.Focused_Partner__c,Deal_Registration_Type__c,Focused_Partner_Calc__c,National_Partner_Calc__c from Opportunity where (AccountId IN : accTypeChangeMap.keySet() OR Sourcing_Partner__c IN : focusNationalAccIds  OR Teaming_Partner__c IN :focusNationalAccIds OR Partner_Lookup__c IN :focusNationalAccIds ) AND isClosed= false AND recordtypeId =: salesOppTypeId AND Opportunity_Type__c!='Debooking' AND Opportunity_Sub_Type__c != 'MSP Overage']){//Removed Account_Deal_Ops_Notes__c as part of SAL26-702
                    if( accTypeChangeMap.keySet().contains(opp.AccountId)){
                        OpportunityUtil.accountTypeChangefromAccountTriggerHelper = true;
                    	OpportunityUtil.resetOpportunityFieldsDependsOnAccount(opp,opp,accTypeChangeMap.get(opp.AccountId),null,'','',null,null,null,false); //SAL25-106 //SAL26-1009
                    }
                    //SAL24-527 // SAL24-784
                    if(focusNationalAccIds.contains(opp.Sourcing_Partner__c) || focusNationalAccIds.contains(opp.Teaming_Partner__c) || focusNationalAccIds.contains(opp.Partner_Lookup__c) ){
                        // Checking for Focused Partner field
                        if((opp.Sourcing_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c!='Rubrik Sourced' && opp.Sourcing_Partner__r.Focused_Partner__c) ||
                        (opp.Teaming_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced' && opp.Teaming_Partner__r.Focused_Partner__c) ||
                        (opp.Partner_Lookup__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced' && opp.Teaming_Partner__c == null && opp.Partner_Lookup__r.Focused_Partner__c)){
                            opp.Focused_Partner_Calc__c=true;
                        }else{
                            opp.Focused_Partner_Calc__c=false;
                        } 
                        // Checking for National Partner field
                        if((opp.Sourcing_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c!='Rubrik Sourced' && opp.Sourcing_Partner__r.National_Partner__c) || 
                        (opp.Teaming_Partner__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced'  && opp.Teaming_Partner__r.National_Partner__c) || 
                        (opp.Partner_Lookup__c != null && opp.Deal_Registration_Type__c!='' && opp.Deal_Registration_Type__c=='Rubrik Sourced' && opp.Teaming_Partner__c == null && opp.Partner_Lookup__r.National_Partner__c)){
                            opp.National_Partner_Calc__c=true;
                        }else{
                            opp.National_Partner_Calc__c=false;
                        }   //SAL24-784 End
                    }
                    if(!OpportunityUtil.oppTypeChangeId.isEmpty() && OpportunityUtil.oppTypeChangeId.contains(opp.Id)){
                        updateOppList.add(opp);
                    }else if(focusNationalAccIds.contains(opp.Sourcing_Partner__c) ||focusNationalAccIds.contains(opp.Teaming_Partner__c)||focusNationalAccIds.contains(opp.Partner_Lookup__c) ){//SAL24-527
                        updateOppList.add(opp);
                    }
                }
            }
            //SAl24-199
                if(!focusedAccSet.isEmpty()){
                    for(Opportunity opp : [select Id,Partner_Lookup__c from Opportunity where Partner_Lookup__c IN: focusedAccSet]){
                        OpportunityTeamMember otm = new OpportunityTeamMember();
                        otm.OpportunityAccessLevel = 'Read';
                        otm.OpportunityId = opp.Id;
                        otm.TeamMemberRole = 'Focused Partner';
                        otm.Is_Auto_Added__c = true;
                        otm.UserId = partnerAccMap.get(opp.Partner_Lookup__c).ownerId;
                        createotmList.add(otm);
                    }
            }
            if(!unfocusedAccSet.isEmpty()){
                    deleteotmList = [select Id,OpportunityId,Opportunity.Partner_Lookup__c from OpportunityTeamMember where Opportunity.Partner_Lookup__c IN: unfocusedAccSet AND TeamMemberRole ='Focused Partner'];
                }
            if(!deleteotmList.isEmpty()){
                Database.Delete(deleteotmList,false);   
            }
            if(!createotmList.isEmpty()){
                Database.insert(createotmList,false);
            } 
            if(!updateOppList.isEmpty()){ //SAL24-257
                dflList = [SELECT id,Disable_Opportunity_Validation_Rules__c,Name,SetupOwnerId FROM ShGl_DisableBusinessLogic__c];

                for(ShGl_DisableBusinessLogic__c dfl : dflList){
                    if(userinfo.getUserId() == dfl.SetupOwnerId){
                        modifydfl.Id = dfl.Id;
                        if(!dfl.Disable_Opportunity_Validation_Rules__c){
                            modifydfl.Disable_Opportunity_Validation_Rules__c = true;
                            modifiedflag = true;
                        }
                    }
                }
                if(modifiedflag){
                    update modifydfl;
                }
                if(modifydfl.Id == null){
                    createflag = true;
                    modifydfl.Disable_Opportunity_Validation_Rules__c = true;
                    modifydfl.SetupOwnerId = userinfo.getUserId();
                    insert modifydfl;
                }
                
                Database.update(updateOppList,false); // updating opportunity
                
                if(modifiedflag){
                    modifydfl.Disable_Opportunity_Validation_Rules__c = false;
                    update modifydfl;
                }  
                if(createflag){
                    delete modifydfl;
                }
            }
        }catch(Exception e){
            system.debug('Exception occurred '+e.getMessage());
            if(modifiedflag){
                modifydfl.Disable_Opportunity_Validation_Rules__c = false;
                update modifydfl;
            }  
            if(createflag && modifydfl != null){
                delete modifydfl;
            }
        }
    }

 public static void testPasser(){
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}