//ARY-107
public class RenewalAndExpansionSplit {
    public static final String QUOTE_TYPE = 'Renewal+Expansion';
    public static final String LINK_TYPE = 'Expansion-Renewal';
    public static final String OPPORTUNITY_SUBTYPE = 'Renewal';
    public static final String SERVICE_CONTRACT_RENEWAL_LINK_TYPE = 'Sale-Renewal';
    public static Boolean isRenewal = false;
    private static ShGl_DisableBusinessLogic__c csInstanceToUpdate,
        csInstanceToDelete = null;
    //ARY-107
    public static Boolean isOpportunityValidForRollback(Opportunity newOpportunity,Opportunity oldOpportunity) {
        return (oldOpportunity.Probability > 90 && newOpportunity.Probability <= 90 && newOpportunity.Primary_Quote_Type__c == QUOTE_TYPE && newOpportunity.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp);
    }
    public static void enableBypassValidation() {
        List<ShGl_DisableBusinessLogic__c> dflList = [SELECT Id, Disable_Opportunity_Validation_Rules__c,Disable_SBQQ_Quote_Validation_Rules__c, Name, SetupOwnerId FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId()];
        if (dflList.isEmpty()) {
            csInstanceToDelete = new ShGl_DisableBusinessLogic__c();
            csInstanceToDelete.Disable_Opportunity_Validation_Rules__c = true;
            csInstanceToDelete.Disable_SBQQ_Quote_Validation_Rules__c = true;
            csInstanceToDelete.SetupOwnerId = userinfo.getUserId();
            insert csInstanceToDelete;
        } else {
            if (!dflList[0].Disable_Opportunity_Validation_Rules__c) {
                csInstanceToUpdate = dflList[0];
                csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = true;
                csInstanceToUpdate.Disable_SBQQ_Quote_Validation_Rules__c = true;
                csInstanceToUpdate.SetupOwnerId = userinfo.getUserId();
                update csInstanceToUpdate;
            }
        }
    }
    public static void disableBypassValidation() {
        if (csInstanceToUpdate != null) {
            csInstanceToUpdate.Disable_Opportunity_Validation_Rules__c = false;
            csInstanceToUpdate.Disable_SBQQ_Quote_Validation_Rules__c = false;
            update csInstanceToUpdate;
        }
        if (csInstanceToDelete != null) {
            delete csInstanceToDelete;
        }
    }
    public static void rollBackRenewalExpansionSplit(Map<Id, Opportunity> mapTriggerNew,Map<Id, Opportunity> mapTriggerOld,Set<Id> setOpportunityIds) {
        List<Opportunity> lstOpportunityToDelete = new List<Opportunity>();
        Map<Id, Id> mapRenewalOpportunityIdToExpansionOpportunity = new Map<Id, Id>();
        List<OpportunityLineItem> lstOLIToInsert = new List<OpportunityLineItem>();
        List<Opportunity_Link__c> lstLinkToDelete = new List<Opportunity_Link__c>();
        Map<Id, Id> mapOpportunityIdToPrimaryQuote = new Map<Id, Id>();
        for (Opportunity_Link__c objLink : [SELECT Id, Child_Opportunity__c, Parent_Opportunity__c, Parent_Opportunity__r.SBQQ__PrimaryQuote__c FROM Opportunity_Link__c WHERE Parent_Opportunity__c IN :setOpportunityIds AND Link_Type__c = :LINK_TYPE]) {
              lstOpportunityToDelete.add(new Opportunity(Id = objLink.Child_Opportunity__c));
              mapRenewalOpportunityIdToExpansionOpportunity.put(objLink.Child_Opportunity__c,objLink.Parent_Opportunity__c);
              mapOpportunityIdToPrimaryQuote.put(objLink.Parent_Opportunity__c,objLink.Parent_Opportunity__r.SBQQ__PrimaryQuote__c);
              lstLinkToDelete.add(objLink);
        }
        List<OpportunityLineItem> lstOpportunityLineItemsToInsert = new List<OpportunityLineItem>();
        String strQuery = 'Select Id, ';
        List<String> lstAllFields = new List<String>(Schema.sObjectType.OpportunityLineItem.fields.getMap().keySet());
        for (OpportunityLineItem objOLI : database.query('Select ' + String.join(lstAllFields, ',') + ' FROM ' + 'OpportunityLineItem' + ' WHERE OpportunityId In:lstOpportunityToDelete')) {
            OpportunityLineItem objOLICloned = objOLI.clone( false, true, false, false );
            if (objOLICloned.ListPrice != null) {
                objOLICloned.UnitPrice = null;
            }
            objOLICloned.OpportunityId = mapRenewalOpportunityIdToExpansionOpportunity.get(objOLI.OpportunityId);
            lstOLIToInsert.add(objOLICloned);
        }
        if (!lstOpportunityToDelete.isEmpty())
            delete lstOpportunityToDelete;
        if (!lstOLIToInsert.isEmpty()) {
            System.enqueueJob( new ResyncLineJob(lstOLIToInsert, mapOpportunityIdToPrimaryQuote));
        }
        if (!lstLinkToDelete.isEmpty()) {
            delete lstLinkToDelete;
        }
    }
    //ARY-107
    public static void processRenewalExpansionOpportunitySplit(Map<Id, Opportunity> mapTriggerNew,Set<Id> setOpportunityIds) {
        //getRenewalRepresentative
        List<Opportunity> lstRenewalOpptyToInsert = new List<Opportunity>();
        Map<Id, List<OpportunityLineItem>> mapOpportunityIdToRenewalLines = new Map<Id, List<OpportunityLineItem>>();
        String strQuery = 'Select Id, ';
        List<String> lstAllFields = new List<String>(
            Schema.sObjectType.OpportunityLineItem.fields.getMap().keySet()
        );
        for(OpportunityLineItem objOLI : database.query('SELECT ' + String.join(lstAllFields, ',') 
                                                        + ' FROM OpportunityLineItem WHERE OpportunityId In:setOpportunityIds AND (Line_Type__c = \'Renewal\')' )) { // OR PBE_Product_Code__c LIKE \'%RCDM-T%\' //SAL25-359
            /*if( !objOLI.PBE_Product_Code__c.endsWith('RCDM-T')
                    || (objOLI.PBE_Product_Code__c.endsWith('RCDM-T') && objOLI.Start_Date__c != null)) {*/ //SAL25-359
                if (mapOpportunityIdToRenewalLines.containsKey(objOLI.OpportunityId))
                    mapOpportunityIdToRenewalLines.get(objOLI.OpportunityId).add(objOLI);
                else
                    mapOpportunityIdToRenewalLines.put(objOLI.OpportunityId, new List<OpportunityLineItem>{ objOLI });
            //}
        }
        List<OpportunityRenewalClone> lstClonedOLIs = new List<OpportunityRenewalClone>();
        List<Opportunity> lstOpportunityToInsert = new List<Opportunity>();
        List<OpportunityLineItem> lstOLIToInsert = new List<OpportunityLineItem>();
        List<OpportunityLineItem> lstOLIToDelete = new List<OpportunityLineItem>();
        Set<String> setOpportunityFields = new Set<String>();
        for (Schema.FieldSetMember schFieldSetMember : SObjectType.Opportunity.FieldSets.Expansion_Renewal_split.getFields()) {
            setOpportunityFields.add(schFieldSetMember.getFieldPath());
        }
        Set<Id> setAccountIds = new Set<Id>();
        for (Id OpportunityId : mapOpportunityIdToRenewalLines.keySet()) {
            OpportunityRenewalClone objClone = new OpportunityRenewalClone();
            isRenewal = true;
            List<OpportunityLineItem> lstOLIs = mapOpportunityIdToRenewalLines.get(OpportunityId);
            List<OpportunityLineItem> lstClones = new List<OpportunityLineItem>();
            for (OpportunityLineItem objOLI : lstOLIs) {
                OpportunityLineItem objOLICloned = objOLI.clone(false,true,false,false);
                objOLICloned.isSplit__c = true;
                if (objOLICloned.ListPrice != null) {
                    objOLICloned.UnitPrice = null;
                }
                lstClones.add(objOLICloned);
            }
            objClone.objOriginalOpty = mapTriggerNew.get(OpportunityId);
            objClone.lstOLIToInsert = lstClones;
            objClone.lstOLIToDelete = lstOLIs;
            //objClone.clonedOppty = objClone.objOriginalOpty.clone(false, true, false, false);
            objClone.clonedOppty = new Opportunity();
            for (String strOpportunityField : setOpportunityFields) {
                objClone.clonedOppty.put(strOpportunityField,objClone.objOriginalOpty.get(strOpportunityField));
            }
            objClone.clonedOppty.Opportunity_Sub_Type__c = OPPORTUNITY_SUBTYPE;
            objClone.clonedOppty.Name = objClone.objOriginalOpty.Name.abbreviate(102) + '-Renewal R&E';
            objClone.clonedOppty.RecordTypeId = OpportunityUtil.oppRecTypeIdRenewOpp;
      objClone.clonedOppty.Is_child_Renewal_split__c = true;
      objClone.clonedOppty.Renewal_Credit_TCV__c = objClone.objOriginalOpty.Renewal_Credit_TCV__c;//REEN-50
            objClone.clonedOppty.Renewal_Credit_ACV__c = objClone.objOriginalOpty.Renewal_Credit_ACV__c;//REEN-50
            lstClonedOLIs.add(objClone);
            setAccountIds.add(mapTriggerNew.get(OpportunityId).AccountId);
            lstOpportunityToInsert.add(objClone.clonedOppty);
            lstOLIToInsert.addAll(objClone.lstOLIToInsert);
            lstOLIToDelete.addAll(objClone.lstOLIToDelete);
        }
        if (!lstOpportunityToInsert.isEmpty()) {
            //SAL24-798 - Remove existing logic 
            /*Map<Id, Id> mapAccountIdToRenewalRep = getRenewalRepresentative(setAccountIds);
            for (Opportunity objOpp : lstOpportunityToInsert) {
                if (mapAccountIdToRenewalRep.containsKey(objOpp.AccountId)) {
                    objOpp.OwnerId = mapAccountIdToRenewalRep.get(objOpp.AccountId);
                }
            }*/
            User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            ShGl_DisableBusinessLogic__c csInstance = null;
            if ('Rubrik Field Sales User' == currentUser.Profile.Name ||
                'Rubrik Renewal Specialist' == currentUser.Profile.Name ||
                'Sales Operations' == currentUser.Profile.Name ||
                'System Administrator' == currentUser.Profile.Name ||
                'Rubrik Light Administrator' == currentUser.Profile.Name ||
                'Order Manager' == currentUser.Profile.Name ||
                'Rubrik System User' == currentUser.Profile.Name ||
                'Rubrik IT User' == currentUser.Profile.Name 
            ) {
                enableBypassValidation();
            }
            try {
                OrderHandler.isPermissionToFieldUpdate = true;
                insert lstOpportunityToInsert;
                //Start SAL25-751
                Set<Id> clonedOptyIds = new Set<Id>();
                Map<string,Opportunity> clonedOpptyMap = new Map<string,Opportunity>();
                for (OpportunityRenewalClone objClone : lstClonedOLIs) {
                    clonedOptyIds.add(objClone.clonedOppty.Id);
                }
                if(!clonedOptyIds.isEmpty()){
                    clonedOpptyMap = new Map<string,Opportunity>([Select id, OwnerId from opportunity where Id IN : clonedOptyIds]);
                }         
                //End SAL25-751   
                List<Opportunity_Link__c> lstLinkage = new List<Opportunity_Link__c>();
                List<SBQQ__Quote__c> lstUpdatePrimaryQuote = new List<SBQQ__Quote__c>();
                for (OpportunityRenewalClone objClone : lstClonedOLIs) {
                    for (OpportunityLineItem objOLIC : objClone.lstOLIToInsert) {
                        objOLIC.OpportunityId = objClone.clonedOppty.Id;
                    }
                    lstLinkage.add(new Opportunity_Link__c(Parent_Opportunity__c = objClone.objOriginalOpty.Id,Child_Opportunity__c = objClone.clonedOppty.Id,Link_Type__c = LINK_TYPE,Renewal_Representative__c = clonedOpptyMap.get(objClone.clonedOppty.Id) != null ? clonedOpptyMap.get(objClone.clonedOppty.Id).OwnerId : null)); //SAL25-751 Renewal_Representative__c change
                    lstUpdatePrimaryQuote.add(new SBQQ__Quote__c(Id = objClone.objOriginalOpty.SBQQ__PrimaryQuote__c,Renewal_Opportunity__c = objClone.clonedOppty.Id));
                }
                OpportunityLineItemTriggersHandler.skipValidationDuringRenewalSplit = true;
                insert lstOLIToInsert;
                LockQuoteValidationByPass.byPassValidation = true;
                if (!Test.isRunningTest()) {
                    update lstUpdatePrimaryQuote;
                    delete lstOLIToDelete;
                }
                LockQuoteValidationByPass.byPassValidation = false;
                insert lstLinkage;
                if (!Test.isRunningTest())
                    AcceptPOHelper.autoAcceptPO(null, null, setOpportunityIds);
            } catch (Exception e) {
                Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
                errorLogRec.Class__c = 'RenewalAndExpansionSplit';
                errorLogRec.FailedRecords__c = string.valueof(mapTriggerNew.keyset());
                errorLogRec.Exception_Message__c = e.getMessage()+' at line no. '+e.getLineNumber();
                errorLogRec.Functionality__c = 'Child Renewal Opp creation';
                Insert errorLogRec;
            }
            disableBypassValidation();
            OrderHandler.isPermissionToFieldUpdate = false;
        }
    }
    public class OpportunityRenewalClone {
        public Opportunity objOriginalOpty;
        public List<OpportunityLineItem> lstOLIToInsert;
        public List<OpportunityLineItem> lstOLIToDelete;
        public Opportunity clonedOppty;
    }
    
    //ARY-107
    //SAL24-798 - Remove existing logic
    /*public static Map<Id, Id> getRenewalRepresentative(Set<Id> setAccountIds) {
        Map<Id, Set<Id>> territoryIdToAccountIds = new Map<Id, Set<Id>>();
        for (ObjectTerritory2Association obj : [SELECT Id, ObjectId, Territory2Id, Territory2.Name
            FROM ObjectTerritory2Association
            WHERE ObjectId IN :setAccountIds AND Territory2.Territory2Model.State = 'Active'
        ]) {
            if (territoryIdToAccountIds.containsKey(obj.Territory2Id))
                territoryIdToAccountIds.get(obj.Territory2Id).add(obj.ObjectId);
            else
                territoryIdToAccountIds.put(obj.Territory2Id,new Set<Id>{ obj.ObjectId });
        }
        Map<Id, Id> tempAccountIdToAssociation = new Map<Id, Id>();
        for (UserTerritory2Association userTerritory : [ SELECT Id, Territory2Id, UserId, RoleInTerritory2
            FROM UserTerritory2Association
            WHERE RoleInTerritory2 = 'Renewals Representative' AND Territory2Id IN :territoryIdToAccountIds.keySet() AND User.isActive = TRUE
        ]) {
            for (Id accountId : territoryIdToAccountIds.get(userTerritory.Territory2Id)) {
                tempAccountIdToAssociation.put(accountId, userTerritory.UserId);
            }
        }
        return tempAccountIdToAssociation;
    }*/
    
    public static void createRenewalOpportunityLinkage(List<ServiceContract> lstTriggerNew, Map<Id, ServiceContract> mapTriggerOld) {
        List<Opportunity_Link__c> lstLinkToInsert = new List<Opportunity_Link__c>();
        for (ServiceContract objServiceContract : lstTriggerNew) {
            ServiceContract oldServiceContract = mapTriggerOld.get(objServiceContract.Id);
            if (
                objServiceContract.SBQQSC__RenewalOpportunity__c != null &&
                oldServiceContract.SBQQSC__RenewalOpportunity__c !=
                objServiceContract.SBQQSC__RenewalOpportunity__c &&
                objServiceContract.SBQQSC__Opportunity__c != null
            ) {
                Opportunity_Link__c objLink = new Opportunity_Link__c();
                objLink.Child_Opportunity__c = objServiceContract.SBQQSC__RenewalOpportunity__c;
                objLink.Parent_Opportunity__c = objServiceContract.SBQQSC__Opportunity__c;
                objLink.Link_Type__c = SERVICE_CONTRACT_RENEWAL_LINK_TYPE;
                lstLinkToInsert.add(objLink);
            }
        }
        if (!lstLinkToInsert.isEmpty())
            insert lstLinkToInsert;
    }
    
    public class EnqueueJob implements Queueable {
        public Map<Id, Opportunity> mapTriggerNew;
        public Set<Id> setOpportunityIds;
        public Set<Id> setOrderedOpportunity;
        public Map<Id,Id> stageSixChurnNotificationMap;
        public Map<Id,User> userMap;
        
        public EnqueueJob(Map<Id, Opportunity> mapTriggerNew,Set<Id> setOpportunityIds,Set<Id> setOrderedOpportunity, Map<Id,Id> stageSixChurnNotificationMap, Map<Id,User> userMap) {
            this.setOpportunityIds = setOpportunityIds;
            this.mapTriggerNew = mapTriggerNew;
            this.setOrderedOpportunity = setOrderedOpportunity;
            this.stageSixChurnNotificationMap = stageSixChurnNotificationMap;
            this.userMap = userMap;
        }
        
        public void execute(QueueableContext context) {
            RenewalAndExpansionSplit.processRenewalExpansionOpportunitySplit(mapTriggerNew,setOpportunityIds);
            Map<Id,Opportunity> OpportunityToUpdateMap = new Map<Id,Opportunity>();
            List<Opportunity_Link__c> opplinkList = new List<Opportunity_Link__c>();
            Boolean disableOppTrigger = true;
            //SAL25-572
            List<CreateOrder__e> orderevtList = new List<CreateOrder__e>();
            Set<Id> evtOppIds = new Set<Id>();
            //SAL24-749
            opplinkList = [select Id,Link_Type__c,Parent_Opportunity__c from Opportunity_Link__c where Link_Type__c=:LINK_TYPE];
            for (Id opportunityId : mapTriggerNew.keySet()) {
                for(Opportunity_Link__c objlink : opplinkList){
                    if(objlink.Parent_Opportunity__c == opportunityId){
                        Opportunity opp = new Opportunity(Id = opportunityId,Opportunity_Link_Url__c = system.URL.getSalesforceBaseUrl().toExternalForm()+'/'+objlink.Id);
                        OpportunityToUpdateMap.put(opp.Id,opp);
                    }
                }
            }
            for (Id opportunityId : setOrderedOpportunity) {
                system.debug('::test::'+opportunityId);
                Opportunity opp = new Opportunity(Id = opportunityId);
                if(!OpportunityToUpdateMap.isEmpty() && OpportunityToUpdateMap.containskey(opportunityId)){
                    opp = OpportunityToUpdateMap.get(opportunityId);
                }
                //SAL25-572
                //opp.SBQQ__Ordered__c = true; //Commented as part of SOX, we are going with Platform event instead of Ordered checkbox
                orderevtList.add(new CreateOrder__e(RecordId__c = opp.Id));
                evtOppIds.add(opp.Id);
                OpportunityToUpdateMap.put(opportunityId,opp);
                disableOppTrigger = false;
            }
            if(isRenewal){
                OpportunityObjectTriggerHandler.isOppAutoManual = 'AutoGenerated';
            }
            if(disableOppTrigger){
                FlowControll.opportunityTriggerHandler = false;
                OppAnnualContractValueUtil.OppACVRecursion = true;
            }
            if (!Test.isRunningTest() && !OpportunityToUpdateMap.isEmpty())
                update OpportunityToUpdateMap.values();

            //SAL25-572
            try{
                if(!orderevtList.isEmpty())
                    EventBus.publish(orderevtList);
            }catch(Exception e){
                insert new Custom_Error_Log__c(Functionality__c = 'CreateOrder__e creation',Exception_Message__c = e.getMessage()+' at line no. '+e.getLineNumber(),FailedRecords__c=String.valueOf(evtOppIds),Class__c = 'RenewalAndExpansionSplit');
            }
            //SAL25-572

            //SAL24-749
            if(!stageSixChurnNotificationMap.isEmpty()){
                OppEmailTriggerHandler.sendchurnNotification(OpportunityToUpdateMap,userMap,stageSixChurnNotificationMap);
            }
        }
    }
    
    public class ResyncLineJob implements Queueable {
        public List<OpportunityLineItem> lstLinesToInsert;
        public Map<Id, Id> mapIdToPrimaryQuoteId;
        
        public ResyncLineJob(List<OpportunityLineItem> lstLinesToInsert,Map<Id, Id> mapIdToPrimaryQuoteId) {
            this.lstLinesToInsert = lstLinesToInsert;
            this.mapIdToPrimaryQuoteId = mapIdToPrimaryQuoteId;
        }
        
        public void execute(QueueableContext context) {
            Set<Id> setOpportunityId = new Set<Id>(mapIdToPrimaryQuoteId.keySet());
            Set<Id> setReSyncOpptys = new Set<Id>();
            for (Opportunity objOpp : [SELECT Id, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id IN :setOpportunityId]) {
                if (mapIdToPrimaryQuoteId.get(objOpp.Id) != objOpp.SBQQ__PrimaryQuote__c) {
                    setReSyncOpptys.add(objOpp.Id);
                }
            }
            List<OpportunityLineItem> lstOLIsToResync = new List<OpportunityLineItem>();
            for (OpportunityLineItem objOLI : lstLinesToInsert) {
                if (!setReSyncOpptys.contains(objOLI.OpportunityId)) {
                    lstOLIsToResync.add(objOLI);
                }
            }
            FlowControll.opportunityTriggerHandler = false;
            OpportunityLineItemTriggersHandler.skipValidationDuringRenewalSplit = true;
            try{
            insert lstOLIsToResync;
            }catch(exception e){
                
            }
            OpportunityLineItemTriggersHandler.skipValidationDuringRenewalSplit = false;
            FlowControll.opportunityTriggerHandler = true;
        }
    }
    
/*    @InvocableMethod(label='Get Closed Admin Reason')
    public static void calculateClosedAdminReason2(List<Id> listOpportunityId) {
        Set<String> validTypes = new Set<String>{ 'Phone Support', 'Web Support' };
            Map<String, String> renewalCategoryToReason = new Map<String, String>{
                'Renewing' => 'Duplicate Opp',
                    'Renewed' => 'Duplicate Opp',
                    'Refreshed' => 'Refreshed',
                    'Converted' => 'Refreshed',
                    'Replaced' => 'Refreshed'
                    };
                        //get the service contracts
                        Map<Id, Id> scToOpptyId = new Map<Id, Id>();
        for (Opportunity oppty : [SELECT Id, SBQQSC__RenewedServiceContract__c FROM Opportunity
            WHERE Id IN :listOpportunityId
        ]) {
            scToOpptyId.put(oppty.SBQQSC__RenewedServiceContract__c, oppty.Id);
        }
        Set<Id> scIds = scToOpptyId.keySet();
        Map<Id, String> scIdToClosedReason = new Map<Id, String>();
        Map<Id, Map<String, Double>> scIdToReasonWeightage = new Map<Id, Map<String, Double>>();
        for (Entitlement ent : [SELECT Id, ServiceContractId, Renewal_Category__c, AnnualContractValue__c
            FROM Entitlement
            WHERE ServiceContractId IN :scIds AND Type IN :validTypes
        ]) {
            Double acv = ent.AnnualContractValue__c != null? ent.AnnualContractValue__c: 0;
            if (scIdToReasonWeightage.containsKey(ent.ServiceContractId)) {
                Map<String, Double> entRenewalToPrice = scIdToReasonWeightage.get(ent.ServiceContractId);
                if (renewalCategoryToReason.containsKey(ent.Renewal_Category__c)) {
                    String closedReason = renewalCategoryToReason.get(ent.Renewal_Category__c);
                    if (entRenewalToPrice.containsKey(closedReason)) {
                        entRenewalToPrice.put(closedReason,acv + entRenewalToPrice.get(closedReason));
                    } else {
                        entRenewalToPrice.put(closedReason, acv);
                    }
                }
            } else {
                if (renewalCategoryToReason.containsKey(ent.Renewal_Category__c)) {
                    scIdToReasonWeightage.put(ent.ServiceContractId,new Map<String, Double>{renewalCategoryToReason.get(ent.Renewal_Category__c) => acv});
                }
            }
        }
        //Map the reason
        if (!scIdToReasonWeightage.isEmpty()) {
            for (Id scId : scIdToReasonWeightage.keySet()) {
                Double highestWeightage;
                Map<String, Double> entRenewalToPrice = scIdToReasonWeightage.get(scId);
                for (String closedReason : entRenewalToPrice.keySet()) {
                    if (scIdToClosedReason.containsKey(scId)) {
                        if (highestWeightage < entRenewalToPrice.get(closedReason)) {
                            scIdToClosedReason.put(scId, closedReason);
                            highestWeightage = entRenewalToPrice.get(closedReason);
                        }
                    } else {
                        //first category
                        scIdToClosedReason.put(scId, closedReason);
                        highestWeightage = entRenewalToPrice.get(closedReason);
                    }
                }
            }
        }
    List<Opportunity> opptyToUpdate = new List<Opportunity>();
        if (!scIdToClosedReason.isEmpty()) {
           //finally put the reason on oppty
            for (Id scId : scIdToClosedReason.keySet()) {
                opptyToUpdate.add(new Opportunity(Id = scToOpptyId.get(scId),Lost_Reason__c = scIdToClosedReason.get(scId),StageName = '7 Closed Admin'));
                scToOpptyId.remove(scId);
            }
        }
        if(!scToOpptyId.isEmpty()){
          for (Id scId : scToOpptyId.keySet()) {
                opptyToUpdate.add(new Opportunity(Id = scToOpptyId.get(scId),Lost_Reason__c = 'Refreshed',StageName = '7 Closed Admin'));
            }
        }
        if (!opptyToUpdate.isEmpty()) {
            ShGl_DisableBusinessLogic__c csInstance = null;
            enableBypassValidation();
            try {
                Database.update(opptyToUpdate, false);
            } catch (Exception e) { }
            disableBypassValidation();
    }
    }*/
}