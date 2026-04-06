public class OpportunitySplitController {
    
    private String opportunityID = '';
    public Opportunity primaryOpportunity { get; set; }
    public Double optyTotalValue { get; set; }
    public Double optyTotalACVValue { get; set; }
    public Decimal staticAmount { get; set; }
    public list<WrapSplitOpp> wrapperList {get;set;}
    public integer count=1;
    public string deleteRowIndex {get;set;}
    public boolean successSave = false;
    public Boolean disableButtons{get;set;}
    public Set<Id> previousOwnerIdSet;

    public ID emailTemplateId{
        get {
            if(emailTemplateId == null) {
                EmailTemplate vEmailTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName ='Notify_Opty_Split_Owners'];
                return vEmailTemplate.Id;
            }
            return emailTemplateId;
        }
        set { }
    }
    
  

     public OpportunitySplitController(ApexPages.StandardController controller){
        //Constructor 
        try {
			
            previousOwnerIdSet = new Set<Id>();
            disableButtons = false;
            optyTotalACVValue = 0.00;
            opportunityID = System.currentPageReference().getParameters().get('oId');
            
            ShGl_QueryConstants__mdt [] opptySplitQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OpportunitySplit_CopyQuery'];
            
            primaryOpportunity = Database.query(opptySplitQuery.get(0).Query_String__c +  ' WHERE Id = \'' +opportunityID+ '\'');
            if(primaryOpportunity.Opportunity_Split_Parent__c != null){
                disableButtons = true; 
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Current Split opportunity record cannot be split further');
                ApexPages.addMessage(msg);
            }
            optyTotalACVValue = optyTotalACVValue+primaryOpportunity.ACV_Amount__c;
            //populate other splits
            wrapperList = new List<WrapSplitOpp>();
            for(Integer i = 0; i < primaryOpportunity.Split_Opportunities__r.size(); i++) {
                WrapSplitOpp tempInst = new WrapSplitOpp(primaryOpportunity.Split_Opportunities__r.get(i),i+2);
                count = i+2;
                wrapperList.add(tempInst);
                if(primaryOpportunity.ownerId != primaryOpportunity.Split_Opportunities__r.get(i).ownerId)
                	previousOwnerIdSet.add(primaryOpportunity.Split_Opportunities__r.get(i).ownerId);
				if(primaryOpportunity.Split_Opportunities__r.get(i).ACV_Amount__c != null)
                	optyTotalACVValue = optyTotalACVValue+primaryOpportunity.Split_Opportunities__r.get(i).ACV_Amount__c;
            }
            
            optyTotalValue = 0.00;
            staticAmount = 0.00;
            for(OpportunityLineItem vLineItem : primaryOpportunity.OpportunityLineItems){
                System.debug('@@vLineItem: '+vLineItem+'\n\n\n');
                if(vLineItem.ProductCode == 'OPTY-SPLIT'){
                    if(vLineItem.TotalPrice > 0){
                        optyTotalValue = optyTotalValue+vLineItem.TotalPrice;
                        staticAmount = vLineItem.TotalPrice;
                    } 
                } else {
                    optyTotalValue = optyTotalValue+vLineItem.TotalPrice;
                }
            }
            if(optyTotalValue == 0.00){
                optyTotalValue = primaryOpportunity.Amount;
            }
            
        } catch (exception e) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occured while splitted Opportunity. Please contact System Administrator.');
            ApexPages.addMessage(msg);
            system.debug('Exception '+e.getMessage()+' at line '+e.getLineNumber());
        }
        System.debug('@@optyTotalValue: '+optyTotalValue);
        if(optyTotalValue == null){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Parent Opportunty must have an Amount.');
            ApexPages.addMessage(msg);
        }
    }

    public OpportunitySplitController() {
        
    }

    //Cancel button
    public pageReference cancelAction() {
        return returnToOrigination();
    }

    public pageReference performValidation(){
         Decimal totalPerc=primaryOpportunity.Split_percentage__c;
         //Decimal totalAmount =primaryOpportunity.Split_Amount__c; //SAL22-317
         String err1='';
         String err2='';
         String err3='';
         //boolean haserror=false;
         for(WrapSplitOpp wrapIns : wrapperList){
            Opportunity oppInst = wrapIns.opp;
            if(oppInst.ownerID != null){
            
                totalPerc=oppInst.split_percentage__c != null? totalPerc+oppInst.split_percentage__c: totalPerc;
                //totalAmount=oppInst.Split_Amount__c != null? totalAmount+oppInst.Split_Amount__c :totalAmount; //SAL22-317
                
                system.debug('test coe '+oppInst.Split_Amount__c);
                system.debug('test coe '+oppInst.split_percentage__c);
                if(oppInst.id != primaryOpportunity.id){
                    //SAL22-317
                    /*if((oppInst.split_percentage__c != null && oppInst.split_percentage__c != 0) && (oppInst.Split_Amount__c != null && oppInst.Split_Amount__c !=0)){
                     if(err1 !='')
                        err1=err1+','+wrapIns.index;
                     else
                        err1 = String.valueOF(wrapIns.index);
    
                    
    
                    }*/
                    //if(oppInst.OwnerId != null && oppInst.split_percentage__c == null && oppInst.Split_Amount__c == null){
                    if(oppInst.OwnerId != null && oppInst.split_percentage__c == null){
                      if(err2 !='')
                        err2=err2+','+wrapIns.index;
                     else
                        err2 = String.valueOF(wrapIns.index);  
                      
                    }
                    
                    //SAL22-317
                    //if(oppInst.OwnerId == null && (oppInst.split_percentage__c != null || oppInst.Split_Amount__c != null)){
                    if(oppInst.OwnerId == null && oppInst.split_percentage__c != null){
                      if(err3 !='')
                        err3=err3+','+wrapIns.index;
                     else
                        err3 =String.valueOF(wrapIns.index);
                     
                    }
                }
            }
            
            //SAL22-317
            //if(oppInst.OwnerId == null && (oppInst.split_percentage__c >0 || oppInst.Split_Amount__c>0)){
            if(oppInst.OwnerId == null && oppInst.split_percentage__c >0){
                totalPerc=oppInst.split_percentage__c != null? totalPerc+oppInst.split_percentage__c: totalPerc;
                //totalAmount=oppInst.Split_Amount__c != null? totalAmount+oppInst.Split_Amount__c :totalAmount; //SAL22-317
                      if(err3 !='')
                        err3=err3+','+wrapIns.index;
                     else
                        err3 =String.valueOF(wrapIns.index);
                     
            }
         }

         //SAL22-317
         /*if(err1 !=''){
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'SPLIT # '+err1+' You can not select both amount and percentage at the same time.'));
              //haserror = true;
         }*/

         if(err2 !=''){
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'SPLIT # '+err2+' Percentage is required when User is selected')); //SAL22-317
              //haserror = true;
         }
         if(err3 !=''){
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'SPLIT # '+err3+' User is required when Percentage is selected')); //SAL22-317
                //haserror = true;
         }

        if(totalPerc > 100){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Total percentage can not be greater than 100'));
             //haserror = true;            
        }
        //SAL22-317
        //else if(totalPerc <100 && totalAmount == 0){
        else if(totalPerc <100){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Total percentage can not be less than 100'));
                //haserror = true;
        }
        //SAL22-317
        /*else if(totalPerc > 0 && totalAmount > 0){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'You cannot combine both percentage and amount.'));
            //haserror = true;
        }else if(totalAmount > 0 && totalAmount != optyTotalValue){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Total amount is expected as $' + optyTotalValue + ' but actual it is $' + totalAmount));
            //haserror = true;
        }*/
        

        if(ApexPages.hasMessages()){
            return null;
        }
        saveItem();
        if(successSave) return returnToOrigination();
        return null;
    }

    //Primary Method
    public pageReference saveItem() {
        //ETM-182: TART update on Opp Splits
        Map<Id, UserTerritory2Association> ownerTerrIdMap = new Map<Id, UserTerritory2Association>();
        Set<Id> SEterrIds = new Set<Id>();
        Map<Id, Id> terrIdSEMap = new Map<Id,Id>();
        List<string> SERoles; // sales engineer role

        //SF-8995
        Map<Id,Id> terrToRegionSETerrIdMap = new Map<Id,Id>();

        Map<id,opportunity> existingSplitsMAp = new Map<id,opportunity>([select id from opportunity where Opportunity_Split_Parent__c=:primaryOpportunity.id]);
        System.debug('@@BEGIN SAVE ITEM: '+staticAmount+'\n\n\n');
        Id[] emailAddresses = new Id[]{};
            
        flowControll.opportunityTriggerHandler = false;
        
        system.debug('@@Processing Start');
        
        if(staticAmount>0){
            OpportunitySplitHelper.createAmountProduct(primaryOpportunity, staticAmount);
            optyTotalValue=staticAmount;
        }
        List<Opportunity> updateList = new List<Opportunity>();
        List<Opportunity> updateListNEw = new List<Opportunity>();
        Set<Id> assignOppTeamUserIds = new Set<Id>();
    	Set<Id> removeOppTeamUserIds = new Set<Id>();
        
        //calculate the number of users that have an amount defined
        Double splitAmounts=0.00;
      
        //splitAmounts=User2Opty.split_amount__c + User3Opty.split_amount__c + User4Opty.split_amount__c;  
        
        
        List<OpportunitySplitMapping__c> oppSplitMapping = [SELECT Skip_Update_if_child_has_value__c,Default_Value__c,Field__c,From_Field__c,Id,Name,Prefix__c,Suffix__c FROM OpportunitySplitMapping__c];

        for(WrapSplitOpp wrapIns : wrapperList){
            
            Opportunity oppInst = wrapIns.opp;
            system.debug('test value '+oppInst.OwnerId);
            if(oppInst.OwnerId != null ){
                system.debug('test value '+oppInst.split_percentage__c);
                if(oppInst.id == null)
                    oppInst = OpportunitySplitHelper.copyOpportunityFieldToSplit(oppInst, primaryOpportunity, oppSplitMapping);
                else
                    existingSplitsMAp.remove(oppInst.id);
                if(oppInst.split_amount__c > 0) {
                    oppInst.Amount = oppInst.split_amount__c;
                    oppInst.split_percentage__c = null;
                } else {
                    oppInst.Amount = optyTotalValue * (oppInst.split_percentage__c / 100);
                    oppInst.split_amount__c = null;
                }
                if(primaryOpportunity.OwnerId != oppInst.OwnerId){
                    if(oppInst.split_percentage__c > 0){
                        assignOppTeamUserIds.add(oppInst.OwnerId);
                    }else{
                        removeOppTeamUserIds.add(oppInst.OwnerId);
                    }
                }
                oppInst.split__c = true;
                updateListNEw.add(oppInst);
                emailAddresses.add(oppInst.OwnerId);
                if(oppInst.id != primaryOpportunity.id)
                    splitAmounts = splitAmounts + oppInst.Amount;
                //splitAmounts=User2Opty.split_amount__c + User3Opty.split_amount__c + User4Opty.split_amount__c; 

                //ETM-182: TART update on Opp Splits
                ownerTerrIdMap.put(oppInst.OwnerId, null);
            }
            
        }
        optyTotalValue=optyTotalValue-splitAmounts;
        
        //ETM-182: TART update on Opp Splits
        List<Territory_Management_Setup__mdt> fielSalesMdt = [select Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName='Role_of_Sales_Engineer'];
        if(!fielSalesMdt.isEmpty() && fielSalesMdt[0].Field_Value__c!=null){
            SERoles = fielSalesMdt[0].Field_Value__c.split(';');
        }
        for(UserTerritory2Association UTA : [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,
                                                territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,  
                                                territory2.Channel_Territory__c,territory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c, Territory2.ParentTerritory2Id, Territory2.ParentTerritory2.Adaptive_Territory_Id__c //SF-8995
                                                from UserTerritory2Association 
                                                 where Territory2.Territory2Model.state='Active' 
                                                 AND User.IsActive=true 
                                                 AND Territory2.Territory2Type.DeveloperName ='territory' 
                                                 AND UserId IN : ownerTerrIdMap.keyset() AND RoleInTerritory2 ='Account Executive'
                                                 order by lastmodifieddate
                                                ]){
                ownerTerrIdMap.put(UTA.UserId, UTA);
                SEterrIds.add(UTA.Territory2Id);

                //SF-8995:
                SEterrIds.add(UTA.Territory2.ParentTerritory2Id);
                terrToRegionSETerrIdMap.put(UTA.Territory2Id, UTA.Territory2.ParentTerritory2Id);
        }
        for(UserTerritory2Association UTA : [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c  from UserTerritory2Association 
                                                where Territory2.Territory2Model.state='Active' 
                                                AND User.IsActive=true 
                                                //AND Territory2.Territory2Type.DeveloperName ='territory' //SF-8995
                                                AND Territory2.Id IN: SEterrIds 
                                                AND RoleInTerritory2 IN : SERoles
                                                order by lastmodifieddate
                                            ]){    
            if(SERoles.contains(UTA.RoleInTerritory2) && !terrIdSEMap.containskey(UTA.Territory2Id)){
                terrIdSEMap.put(UTA.Territory2Id,UTA.UserId);
            }
        }
        
        if(!updateListNEw.isEmpty() || !existingSplitsMAp.isEmpty()) {
            /*upsert child split opportunities*/
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true; 
            
            System.debug('@@updateList: '+updateListNEw);
            //sort the updates and insert - upsert won't work with the DML options
            List<Opportunity> insertOpt = new List<Opportunity>();
            List<Opportunity> updateOpt = new List<Opportunity>();
            //SF-11236
            List<Opportunity> splitOppList = new List<Opportunity>();
            for(Opportunity vOpt : updateListNEw) {
                System.debug('@@vOpt: '+vOpt.Id);
                //ETM-182: TART update on Opp Splits
                vOpt.Territory2Id = vOpt.Territory2Id__c = vOpt.ETM_Theatre__c = vOpt.ETM_Area__c = vOpt.ETM_Region__c = vOpt.ETM_Territory__c = vOpt.CDM_Theatre__c = vOpt.CDM_Area__c = vOpt.CDM_Region__c = vOpt.CDM_Territory__c = null;
                if(ownerTerrIdMap.containsKey(vOpt.OwnerId) && ownerTerrIdMap.get(vOpt.OwnerId) != null){
                    UserTerritory2Association utaTemp = ownerTerrIdMap.get(vOpt.OwnerId);
                    vOpt.Territory2Id = utaTemp.Territory2Id;
                    vOpt.Territory2Id__c = utaTemp.Territory2Id;
                    vOpt.ETM_Theatre__c = utaTemp.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                    vOpt.ETM_Area__c = utaTemp.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                    vOpt.ETM_Region__c = utaTemp.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                    vOpt.ETM_Territory__c = utaTemp.Territory2.Internal_Territory_Name__c;
                    vOpt.CDM_Theatre__c = utaTemp.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c;
                    vOpt.CDM_Area__c = utaTemp.Territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c;
                    vOpt.CDM_Region__c = utaTemp.Territory2.ParentTerritory2.Channel_Territory__c;
                    vOpt.CDM_Territory__c = utaTemp.Territory2.Channel_Territory__c;
                }
                if(!vOpt.SE_Misaligned__c){
                    //SF-8995
                    //vOpt.Rubrik_Sales_Engineer__c = terrIdSEMap.get(vOpt.Territory2Id); 
                    String parentSETerrId = vOpt.Territory2Id != null ? terrToRegionSETerrIdMap.get(vOpt.Territory2Id) : null;
                    vOpt.Rubrik_Sales_Engineer__c = vOpt.Territory2Id != null && terrIdSEMap.get(vOpt.Territory2Id) != null ? 
                                                    terrIdSEMap.get(vOpt.Territory2Id) : 
                                                    parentSETerrId != null && terrIdSEMap.get(parentSETerrId) != null ? terrIdSEMap.get(parentSETerrId) : null ;
                }

                if(vOpt.Id != null) {
                    updateOpt.add(vOpt);
                    //SF-11236
                    splitOppList.add(vOpt);     
                } else {
                    insertOpt.add(vOpt);
                }
            }
            System.debug('@@insertOpt: '+insertOpt);
            List<Database.SaveResult> saveResult;
            //SF-10455
            Integer i= 0;
            Set<Id> oppIds = new Set<Id>();
            
            if(!insertOpt.isEmpty()) {
                saveResult = Database.insert(insertOpt, dml);
                for(Database.SaveResult sResult: saveResult){
                    if(!sResult.isSuccess()){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, sResult.getErrors().get(0).getMessage()));
                    }
                    //SF-10455
                    //SF-11236
                    else { oppIds.add(insertOpt[i].Id); splitOppList.add(insertOpt[i]);}
                    i++;
                }
                //SF-10455
                if(!oppIds.isEmpty()){
                    createOpportunityContactRole(oppIds);
                }

                if(ApexPages.hasMessages()){
                    return null;
                }
            }

            //System.debug('@@optyTotalValue: '+optyTotalValue+' -> '+splitAmounts+' -> '+primaryOpportunity.split_percentage__c+' -> '+optySplitProduct+'\n\n\n');
            
           
            
            primaryOpportunity.split__c = true;
            if(primaryOpportunity.split_amount__c > 0) {
                primaryOpportunity.split_percentage__c = null;
            } else {
                primaryOpportunity.split_amount__c = null;
            }
            updateOpt.add(primaryOpportunity);
            System.debug('@@updateOpt: '+updateOpt);
            if(!updateOpt.isEmpty()) {
                saveResult = Database.update(updateOpt, dml);
                for(Database.SaveResult sResult: saveResult){
                    if(!sResult.isSuccess()){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, sResult.getErrors().get(0).getMessage()));
                    }
                }
                if(ApexPages.hasMessages()){
                    return null;
                }
            }

            //copy co-sell records
            if(!insertOpt.isEmpty()){
                List<CoSellTracker__c> trackersToInsert = createCoSellTrackersCopy(primaryOpportunity.Id, insertOpt);
                if(!trackersToInsert.isEmpty())
                    insert trackersToInsert;
            }
            //===
            
            if(!assignOppTeamUserIds.isEmpty() || !removeOppTeamUserIds.isEmpty())
            	assignOppTeam(assignOppTeamUserIds,removeOppTeamUserIds,primaryOpportunity.Id,previousOwnerIdSet);
			if(!existingSplitsMAp.isEmpty()){
                delete existingSplitsMAp.values();
            }
            flowControll.opportunityTriggerHandler = true;
            //Insert Opportunity Line Item
            List<OpportunityLineItem> optySplitProductList = OpportunitySplitHelper.manageOptySplitLineItem(primaryOpportunity, splitAmounts);
            //SF-11236 : To create positive OPPTY-SPLIT productlines for child split opportunities
            Id pbeId = !optySplitProductList.isEmpty() ? optySplitProductList[0].PricebookEntryId : null;
            optySplitProductList.addAll(createOpptySplitProduct(splitOppList,pbeId));
            upsert optySplitProductList;
        }
        
        emailAddresses.add(primaryOpportunity.OwnerId);
        EmailHelper.sendEmail(emailTemplateId, emailAddresses, primaryOpportunity.Id);
        System.debug('@@END SAVE ITEM:\n\n\n');
        successSave = true;
        return null;
    }
    private List<CoSellTracker__c> createCoSellTrackersCopy(Id parentOpptyId, List<Opportunity> childOpportunities){
        List<CoSellTracker__c> trackersToInsert = new List<CoSellTracker__c>();
        for(CoSellTracker__c tracker : [SELECT Id, Opportunity__c, Alliance_BDM__c, AllianceOpportunityID__c, Alliance_Deal_Registration__c, PartnerAccount__c
                                            FROM CoSellTracker__c WHERE Opportunity__c = :parentOpptyId]){
            for(Opportunity oppty: childOpportunities){
                CoSellTracker__c insertTracker = tracker.clone(false, false, false, false);
                insertTracker.Opportunity__c = oppty.Id;
                trackersToInsert.add(insertTracker);
            }
        }
        return trackersToInsert;
    }
  //page Reference
    public pageReference returnToOrigination() {
        PageReference page = new PageReference('/' + OpportunityID);
        page.setRedirect(true);
        return page;
    }

    public  void addRow(){
       system.debug(wrapperList);
        WrapSplitOpp tempIns = new WrapSplitOpp(new Opportunity(),count+1);
        system.debug('test code '+tempIns);
        wrapperList.add(tempIns);
        count = count+1;
    }
    public  void deleteRow(){
        system.debug('@@ deleteRowIndex '+deleteRowIndex);
        Integer deleteindex = Integer.valueOf(deleteRowIndex)-2;
        //if(wrapperList[deleteindex].opp.Id == null){
            wrapperList.remove(deleteindex);
            for(Integer i=0;i<wrapperList.size();i++){
                wrapperList[i].index = i+2;
            }
            count--;
       /* }else{
            wrapperList[deleteindex].opp.Split_percentage__c = 0;
        }*/
    }

    public class WrapSplitOpp{
        public opportunity opp{get;set;}
        public integer index{get;set;}
        public WrapSplitOpp(opportunity opp,integer i){
            this.opp = opp;
            this.index =i;
        }

    }

    //SF-10455
    public static void createOpportunityContactRole(Set<Id> OppIds){
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        for(Opportunity opp : [Select Id, Initial_Contacts_Name__c from Opportunity where Id in :OppIds and Initial_Contacts_Name__c != null]) {
            ocrList.add(new OpportunityContactRole(isPrimary = true, OpportunityId = opp.Id, ContactId = opp.Initial_Contacts_Name__c));
        }
        if(!ocrList.isEmpty()){
            insert ocrList;
        }
    }
    //SAL23-229
    public static void assignOppTeam(Set<Id> assignOppTeamIds, Set<Id> removeOppTeamIds, Id oppId, Set<Id> prevOwnerIdSet){
        List<OpportunityTeamMember> removemembersList = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> insertmembersList = new List<OpportunityTeamMember>();
        system.debug('@@ assignOppTeamIds '+assignOppTeamIds);
        system.debug('@@ removeOppTeamIds '+removeOppTeamIds);
        
        if(!prevOwnerIdSet.isEmpty() && !assignOppTeamIds.isEmpty()){
            prevOwnerIdSet.removeAll(assignOppTeamIds);
        } 
       if(!assignOppTeamIds.isEmpty()){
            for(OpportunityTeamMember otm : [Select Id,UserId from OpportunityTeamMember where OpportunityId = :oppId and UserId IN :assignOppTeamIds]){
                if(assignOppTeamIds.contains(otm.UserId)){
                     assignOppTeamIds.remove(otm.UserId);
                }
            }
           for(Id uid : assignOppTeamIds){
               OpportunityTeamMember member = new OpportunityTeamMember(
                   OpportunityAccessLevel = 'Read', 
                   OpportunityId = oppId, 
                   TeamMemberRole = 'Sales Rep',
                   UserId = uid);
               insertmembersList.add(member);
           }
    	}
        if(!prevOwnerIdSet.isEmpty()){
        	removeOppTeamIds.AddAll(prevOwnerIdSet);
        }
        if(!removeOppTeamIds.isEmpty() && !assignOppTeamIds.isEmpty()){
            removeOppTeamIds.removeAll(assignOppTeamIds);
        }
        if(!removeOppTeamIds.isEmpty()){
            removemembersList = [Select Id,UserId from OpportunityTeamMember where OpportunityId = :oppId 
                                 and UserId IN :removeOppTeamIds AND TeamMemberRole='Sales Rep'];
        }
        if(!removemembersList.isEmpty())
        	delete removemembersList;
        
        if(!insertmembersList.isEmpty()){
            insert insertmembersList;
        }
        
        
    }
    //SF-11236
    public static List<OpportunityLineItem> createOpptySplitProduct(List<Opportunity> SplitOpps, Id pbeId){
        List<OpportunityLineItem> splitOppLines = new List<OpportunityLineItem>();
        Map<Id,OpportunityLineItem> oppToOLIMap = new Map<Id,OpportunityLineItem>();
        for(OpportunityLineItem oli :[select Id,ProductCode,OpportunityId from OpportunityLineItem where OpportunityId IN :SplitOpps and ProductCode = 'OPTY-SPLIT']){
            oppToOLIMap.put(oli.OpportunityId, oli);
        }
        if(pbeId != null){ //If there is no OPPTY-SPLIT product line in Primary Opp then delete OPPTY-SPLIT product lines from /child split opps.
            for(Opportunity opp :SplitOpps){
                OpportunityLineItem splitOppLineItem = oppToOLIMap.containsKey(opp.Id) ? 
                                                        new OpportunityLineItem(Id=oppToOLIMap.get(opp.Id).Id, TotalPrice = opp.Amount) :
                                                        new OpportunityLineItem(PricebookEntryId = pbeId,
                                                                                OpportunityId = opp.Id,
                                                                                Quantity = 1,
                                                                                isSplit__c = true,
                                                                                TotalPrice = opp.Amount);
                splitOppLines.add(splitOppLineItem);
            }
        }
        else {delete oppToOLIMap.values();}
        return splitOppLines;
    }
    

}