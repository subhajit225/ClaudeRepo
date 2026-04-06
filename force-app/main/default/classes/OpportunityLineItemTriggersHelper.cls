public without sharing class OpportunityLineItemTriggersHelper { 
    public static Set<String> productTypeSwAddonsSet = new Set<String>{'Hybrid Edge','SAP HANA','FED Radar','FED Sonar','App Flows','AIR','Scale SAPHANA','Rubrik Cloud Storage','SAP HANA','NoSQL','NoSQL - Data Protection','Cloud Vault Backup','Kubernetes','Cloud Native','RADAR','FED M365','Sonar','GPS','Hybrid M365','M365','On Prem CDM','NAS Cloud Direct','CLON','NAS','FED UCL','Cloud Vault Archive','UCL','Cloud Cluster ES','O365','Hybrid M365H','EDGE','FED AppFlows','Cloud Native - Data protection','M365H','PMC'};
    public static Set<String> productTypeCompleteSet = new Set<String>{'Complete Edition','Complete Edition Elite','Complete Edition Pro'};
    public static Set<String> familyThridpartySet = new Set<String>{'Third Party License','DELL','HPE','UCS'};
    public static Set<String> productTypeEditionSet = new Set<String>{'Business Edition','Enterprise Edition','Foundation Edition'};
    public static Set<String> subTypeSaasSet = new Set<String>{'SaaS Cloud','GO'};
    public static Set<String> productLevelSet = new Set<String>{'LOD Software','Hybrid Software','SaaS Software Addon','Standalone Software Addon'};       
    public static map<Id,list<OpportunityLineItem>> deletedParentsplitLineItemsMap = new map<Id,list<OpportunityLineItem>>();  
        
    public static Map<Id,Opportunity> getOpportunityMap (List<OpportunityLineItem> opptyLineList) {
      Set<Id> opptyIdSet = new Set<Id>();
      for(OpportunityLineItem oli : opptyLineList) {
          opptyIdSet.add(oli.OpportunityId);
      }
      Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity> ([SELECT Id, StageName, Split__c,Opportunity_Sub_Type__c,split_percentage__c FROM Opportunity WHERE Id IN :opptyIdSet]);
      return opptyMap;
  }
  
  /*public static void createOpportunitySplitLineOnDelete (List<OpportunityLineItem> opptyLineList) {
      List<OpportunityLineItem> splitOliList = new List<OpportunityLineItem>();
      for(OpportunityLineItem oli : opptyLineList) {
          if(oli.ProductCode=='OPTY-SPLIT' && oli.TotalPrice < 0.00){    
              if(oli.Is_Opportunity_Split__c){
                  splitOliList.add(createOli(oli));
              }
          }
      }
      if(!splitOliList.isEmpty()){
          insert splitOliList;
      }
  }*/
  
  public static OpportunityLineItem createOli (OpportunityLineItem oli) {
      OpportunityLineItem optySplitProductLineItem = new OpportunityLineItem();
      optySplitProductLineItem.PricebookEntryId = oli.PricebookEntryId;
      optySplitProductLineItem.OpportunityId = oli.OpportunityId;
      optySplitProductLineItem.Quantity = 1;
      optySplitProductLineItem.TotalPrice = oli.TotalPrice;
      optySplitProductLineItem.isSplit__c = true;
      return optySplitProductLineItem;
  }
  
    //Collects child OpportunityLineItems related to parent items being deleted | OPPTYSPLIT-26
    public static void OppLineItemsBeforeDelete (List<OpportunityLineItem> opptyLineList) {
          Set<Id> parentLineItemIds = new Set<Id>();
          
          // Existing validation logic
          if(!opptyLineList.isEmpty()){
            for(OpportunityLineItem oli : opptyLineList) {
                if(oli.Line_Type__c != 'Renewal' && oli.Parent_split_Opplineitem_Id__c == null && oli.Applied_Split__c != null && oli.Applied_Split__c < 100 && oli.ProductCode != 'OPTY-SPLIT') {
                    parentLineItemIds.add(oli.Id);
                }
            }
            }
          
          if(!parentLineItemIds.isEmpty()){
              list<OpportunityLineItem> deletechildopplineitemList = [SELECT Id,Parent_split_Opplineitem_Id__c FROM OpportunityLineItem WHERE Parent_split_Opplineitem_Id__c IN :parentLineItemIds];
                if(!parentLineItemIds.isEmpty()){
                  for(OpportunityLineItem opp:deletechildopplineitemList){
                        if(!deletedParentsplitLineItemsMap.containsKey(opp.Parent_split_Opplineitem_Id__c)){
                            deletedParentsplitLineItemsMap.put(opp.Parent_split_Opplineitem_Id__c, new list<OpportunityLineItem>());
                        }
                        deletedParentsplitLineItemsMap.get(opp.Parent_split_Opplineitem_Id__c).add(opp);
                  }
              }
          }
      }
    
  public static void validateOpportunityOnDelete (List<OpportunityLineItem> opptyLineList, Map<Id,Opportunity> opptyMap) {
      for(OpportunityLineItem oli : opptyLineList) {
          if((opptyMap.get(oli.OpportunityId).StageName == '6 PO With Channel' || opptyMap.get(oli.OpportunityId).StageName == '7 Closed Won') && oli.isSplit__c == false && opptyMap.get(oli.OpportunityId).Opportunity_Sub_Type__c!=Constants.ORDER_SUB_TYPE_GC_ONDEMAND) {
              oli.addError('Error: You cannot update quote in stage 6 or above.');
          }
      }
  }
    
    //SAL23-284
  public static void updateProductType(List<OpportunityLineItem> opptyLineList, Map<Id,OpportunityLineItem> opptyOldLineMap ) {
      Set<Id> prodIdSet = new Set<Id>();
      Map<Id,Product2> prodTypeIdMap = new Map<Id,Product2>();
      for(OpportunityLineItem oli : opptyLineList) {
          if(oli.Product2Id != null && (opptyOldLineMap == null || (opptyOldLineMap != null && opptyOldLineMap.get(oli.Id).Product2Id != oli.Product2Id))){
              prodIdSet.add(oli.Product2Id);
          }
      }
      if(!prodIdSet.isEmpty()){
          for(Product2 prod : [select Id,Product_Type__c,Support_type__c from Product2 where Id IN: prodIdSet]){
              prodTypeIdMap.put(prod.Id,prod);
          }
          if(!prodTypeIdMap.isEmpty()){
              for(OpportunityLineItem oli : opptyLineList) {
                  if(prodTypeIdMap.containsKey(oli.Product2Id))
                      oli.Prod_Type__c = prodTypeIdMap.get(oli.Product2Id).Product_Type__c;
                  	  oli.Support_type__c = prodTypeIdMap.get(oli.Product2Id).Support_type__c;	
              }
          }
      }
  }
 
  public static void afterOLITriggerMethods(List<OpportunityLineItem> newList, Map<Id,OpportunityLineItem> opptyOldLineMap, Set<Id> OpptyHandlerIdSet ){
      List<Opportunity> updateOppLODProductsList = new List<Opportunity>();
      List<Opportunity> populateSpecialProgramList = new List<Opportunity>();
      List<Opportunity> renewalLineItemsOnChangeList = new List<Opportunity>();
      List<Opportunity> updateHasUCLScaleProdOppList = new List<Opportunity>();//SAL25-495
      Set<Id> newOliIdsSet = new Set<Id>(); //SAL25-495
      Map<Id,Boolean> sowOppIdMap = new Map<Id,Boolean>();
      Map<Id,Opportunity> totalOppMap = new Map<Id,Opportunity>();
      List<Opportunity> queriedOpptyList = new List<Opportunity>();
      List<OpportunityLineItem> queriedOppLineList = new List<OpportunityLineItem>();
      Set<Id> opportunityIds = new Set<Id>();
      Set<Id> OppIdsfor3rdPartyProds = new Set<Id>(); //SAL24-359
      
      if(newList != null){
          for(OpportunityLineItem oli : newList) {
              opportunityIds.add(oli.OpportunityId);
              newOliIdsSet.add(oli.Id);//SAL25-495
          }
      }
      if(OpptyHandlerIdSet != null && !OpptyHandlerIdSet.isEmpty()){
           opportunityIds.addAll(OpptyHandlerIdSet);
      }
      if(!opportunityIds.isEmpty()){
          queriedOpptyList = [SELECT Id,Bypass_Closed_Won_Update_Restriction__c,BundleFeatures__c,SOW_Required__c,Automated_Uncheck_SOW_Required__c, PolarisDetailsRequired__c, Has_LOD_Products__c, Has_Polaris_Product__c, Opportunity_Program__c,CloseDate,Early_ACV__c,Late_ACV__c,On_Time_ACV__c,StageName,SBQQ__PrimaryQuote__r.Amended_Renewed_Service_Contract__c,
                               LOD_Standalone_ACV__c,Subscription_ACV__c,HW_Support_ACV__c,SW_Support_ACV__c,Subscription_Add_On_ACV__c, //ARY-281, ARY-619
                               SBQQ__PrimaryQuote__r.SBQQ__Primary__c,SBQQ__PrimaryQuote__r.Polaris_Conversion__c,SBQQ__PrimaryQuote__r.SBQQ__Type__c,SBQQSC__RenewedServiceContract__c,
                               Deleted_RTA__c,SBQQSC__RenewedServiceContract__r.Renew_to_Old_SKUs__c,Deleted_line_ContractId_RTA__c,SBQQ__PrimaryQuote__c,Has_UCL_Scale_Products__c, RecordTypeId,
                               (SELECT Id, OpportunityId, Name, Special_Program__c,ProductCode,Quantity,
                               Product2.License_Type__c, Product2.Bundle_Features__c, Product2.Product_Type__c, Product2.Product_Level__c, 
                               Product2.Product_Subtype__c,Product2.Family,Product2.ProductCode,PBE_Product_Family__c,
                               Opportunity.Early_ACV__c,Opportunity.Late_ACV__c,Opportunity.On_Time_ACV__c,Opportunity.StageName,Renewal_Due_Date__c,
                               Renewal_Timing__c,Opportunity.CloseDate,ACV_Amount__c,Line_Type__c,QuoteLine_Product_Group__c, //ARY-281, ARY-619
                               Opportunity.LOD_Standalone_ACV__c,Opportunity.Subscription_ACV__c,Opportunity.HW_Support_ACV__c,Opportunity.SW_Support_ACV__c,Opportunity.Subscription_Add_On_ACV__c, //ARY-281, ARY-619
                               Renewal_Target_Amount__c,Opportunity.SBQQ__PrimaryQuote__r.Amended_Renewed_Service_Contract__c,
                               Amended_Service_Contract_Id__c,Amended_Service_Contract_Id_Text__c,Opportunity.SBQQ__PrimaryQuote__r.SBQQ__Primary__c,
                               SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c,Opportunity.Deleted_RTA__c,ContractLine_Id__c,
							   SBQQ__QuoteLine__c,SBQQ__QuoteLine__r.SBQQ__Quote__c,SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,Required_by_opportunity_product__c,
							   SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c, UCL_Scale__c	                                
                               FROM OpportunityLineItems) from Opportunity where Id IN: opportunityIds];
          
      }	  

      //SFDCSOX-1105
      List<Opportunity> closeWonOpps = new List<Opportunity>();
      if(!queriedOpptyList.isEmpty()){
          for(Opportunity opp : queriedOpptyList){
              if(opp.StageName == '7 Closed Won'){
                  closeWonOpps.add(opp);
              }
          }
          Boolean editClosedWonOppPermision = FeatureManagement.checkPermission('Can_Edit_Closed_Won_Opportunity');
          if(!closeWonOpps.isEmpty() && OpportunityObjectTriggerHandler.oppAllowEdit == false && OpportunityObjectTriggerHandler.bypassClosedWonUpdateValidation == false && !editClosedWonOppPermision && System.Label.StopCloseWonOppUpdateSwitch == 'TRUE'){
              
              Map<Id, User> userMap = new Map<Id, User>([SELECT Id, RBAC_Group__c FROM User WHERE Id =: UserInfo.getUserId()]);
              Set<String> rbackGroupNames = new Set<String>{'IT System Admin', 'IT Sales & CPQ Support', 'System - IT', 'API'};
                  Set<String> userRbackGroups = userMap.containsKey(UserInfo.getUserId()) && String.isNotBlank(userMap.get(UserInfo.getUserId()).RBAC_Group__c)  ? new Set<String>(userMap.get(UserInfo.getUserId()).RBAC_Group__c.split(';')) : new Set<String>();
              Boolean isRbackGroupUser = false;
              for(String gname : userRbackGroups){
                  if(rbackGroupNames.contains(gname)){
                      isRbackGroupUser = true;
                  }
              }
              for(Opportunity closeOpp : closeWonOpps){
                  if(!isRbackGroupUser && closeOpp.Bypass_Closed_Won_Update_Restriction__c == false){
                      newList[0].addError(System.Label.ClosedWonOppRestrictMessage);
                  }
              }
          }
                 if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate) && OpptyHandlerIdSet == null){
              
              /** SAL25-495 Start 
              updateHasUCLScaleProdOppList = updateHasUCLScaleProdCheckbox(queriedOpptyList, newOliIdsSet);
              if(!updateHasUCLScaleProdOppList.isEmpty()){
                  for(opportunity opp : updateHasUCLScaleProdOppList){
                      if(totalOppMap.containsKey(opp.Id)){
                          opportunity oppRec = totalOppMap.get(opp.Id);
                          oppRec.Has_UCL_Scale_Products__c = true;
                          totalOppMap.put(opp.Id,oppRec);
                      } else {
                          opp.Has_UCL_Scale_Products__c = true;
                          totalOppMap.put(opp.Id,opp);
                      }
                      OpportunityObjectTriggerHandler.newUCLScaleAddedOppIdsSet.add(opp.Id);
                  }
              }  SAL25-495 End */
              
              updateOppLODProductsList = updateOppLODProducts(queriedOpptyList);
              if(!updateOppLODProductsList.isEmpty()){
                  for(opportunity opp : updateOppLODProductsList){
                      if(totalOppMap.containsKey(opp.Id)){opportunity oppRec = totalOppMap.get(opp.Id);oppRec.Has_LOD_Products__c = opp.Has_LOD_Products__c;oppRec.PolarisDetailsRequired__c = opp.PolarisDetailsRequired__c;oppRec.Has_Polaris_Product__c = opp.Has_Polaris_Product__c;oppRec.BundleFeatures__c = opp.BundleFeatures__c;
                          totalOppMap.put(opp.Id,oppRec); 
                      }else{
                        totalOppMap.put(opp.Id,opp);
                      }
                  }
              }
              populateSpecialProgramList = populateSpecialProgram(queriedOpptyList);
              if(!populateSpecialProgramList.isEmpty()){
                  for(opportunity opp : populateSpecialProgramList){
                      if(totalOppMap.containsKey(opp.Id)){
                          opportunity oppRec = totalOppMap.get(opp.Id);
                          oppRec.Opportunity_Program__c = opp.Opportunity_Program__c;
                          totalOppMap.put(opp.Id,oppRec);
                      }else{
                        totalOppMap.put(opp.Id,opp);
                      }
                  }
              }
          }
          if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isDelete)){   
              renewalLineItemsOnChangeList = renewalLineItemsOnChange(newList,opptyOldLineMap,queriedOpptyList,OpptyHandlerIdSet);
              if(!renewalLineItemsOnChangeList.isEmpty()){
                  for(opportunity opp : renewalLineItemsOnChangeList){
                      if(totalOppMap.containsKey(opp.Id)){
                          opportunity oppRec = totalOppMap.get(opp.Id);
                          oppRec.Deleted_RTA__c = opp.Deleted_RTA__c;
                          oppRec.Deleted_line_ContractId_RTA__c = opp.Deleted_line_ContractId_RTA__c;
                          oppRec.On_Time_ACV__c = opp.On_Time_ACV__c;
                          oppRec.Early_ACV__c = opp.Early_ACV__c;
                          oppRec.Late_ACV__c = opp.Late_ACV__c;
                          oppRec.LOD_Standalone_ACV__c = opp.LOD_Standalone_ACV__c;
                          oppRec.Subscription_ACV__c = opp.Subscription_ACV__c;
                          oppRec.HW_Support_ACV__c = opp.HW_Support_ACV__c;
                          oppRec.SW_Support_ACV__c = opp.SW_Support_ACV__c;
                          oppRec.Subscription_Add_On_ACV__c = opp.Subscription_Add_On_ACV__c;
                          totalOppMap.put(opp.Id,oppRec);
                      }else{
                        totalOppMap.put(opp.Id,opp);
                      }
                  }
              }
	      //SAL24-359
              OppIdsfor3rdPartyProds = update3rdPartyHWonOppty(queriedOpptyList);
                 for(Opportunity opp : queriedOpptyList){
                      Opportunity oppRec = new Opportunity();
                      if(totalOppMap.containsKey(opp.Id)){
                          oppRec = totalOppMap.get(opp.Id);
                      }
                      else{
                          oppRec.Id = opp.Id; 
                      } 
                      if(OppIdsfor3rdPartyProds.contains(opp.Id)){
                          oppRec.Has_3rd_Party_Hardware_Products__c = True;
                      }
                      else if(!OppIdsfor3rdPartyProds.contains(opp.Id)){
                          oppRec.Has_3rd_Party_Hardware_Products__c = False;
                      }
                      totalOppMap.put(opp.Id,oppRec);
                  }
          }
		  if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isDelete)){   
              sowOppIdMap = updateSOWRequiredOnOppty(queriedOpptyList);
              if(!sowOppIdMap.isEmpty()){
                  for(Id oppId : sowOppIdMap.keySet()){
                      opportunity oppRec = new Opportunity();
                      if(totalOppMap.containsKey(oppId)){
                          oppRec = totalOppMap.get(oppId);
                      }else{
                          oppRec.Id = oppId; 
                      }
                      oppRec.SOW_Required__c = sowOppIdMap.get(oppId);
                      if(!oppRec.SOW_Required__c){
                          oppRec.Automated_Uncheck_SOW_Required__c = true;
                      }else{
                          oppRec.Automated_Uncheck_SOW_Required__c = false;
                      }
                      totalOppMap.put(oppId,oppRec);
                  }
              }
          }	
          if(trigger.isAfter && trigger.isInsert && OpptyHandlerIdSet == null){
          	  populateParent(queriedOpptyList);
          }
      }
      if(!totalOppMap.isEmpty()){
          FlowControll.opportunityTriggerHandler = false;
          FlowControll.opportunityLineItemHandler = false;
          update totalOppMap.values();
          FlowControll.opportunityTriggerHandler = true;
          FlowControll.opportunityLineItemHandler = true;
          OppAnnualContractValueUtil.OppACVRecursion = false;
      }
      //OPPTYSPLIT-5
      if(OpportunitySplitLWCController.skipOpplineItemTriggerCreationLogic == false){
          syncOppLineItems(newList,opptyOldLineMap);
  } 

    } 
   
  public static void populateParent(List<Opportunity> oppytList){
       Map<id,id> mapQLI_Requiredby = new Map<id,id>();
       List <OpportunityLineItem> updateRequiredby = new List<OpportunityLineItem>();
      
       for(Opportunity oppty : oppytList){
           if(!OpportunityLineItemTriggersHandler.OpprequiredSet.isEmpty() && OpportunityLineItemTriggersHandler.OpprequiredSet.contains(oppty.Id)){
              for(OpportunityLineItem oli : oppty.opportunitylineitems){
                  if(oli.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Quote' && oli.Required_by_opportunity_product__c == null && oli.SBQQ__QuoteLine__r.SBQQ__Quote__c != null){
                      mapQLI_Requiredby.put(oli.SBQQ__QuoteLine__c,oli.Id);  
                  }
              }
           }
       }
      for(Opportunity oppty : oppytList){
          if(!OpportunityLineItemTriggersHandler.OpprequiredSet.isEmpty() && OpportunityLineItemTriggersHandler.OpprequiredSet.contains(oppty.Id)){
              for(OpportunityLineItem oli : oppty.opportunitylineitems){
                  if(oli.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Quote' && oli.Required_by_opportunity_product__c == null){                
                    opportunityLineItem oppline = new opportunityLineItem();
                    if((oli.SBQQ__QuoteLine__c != null
                    && oli.Required_by_opportunity_product__c == null
                    && oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c != null
                           && mapQLI_Requiredby.containsKey(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c) && oppline.Required_by_opportunity_product__c != mapQLI_Requiredby.get(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c)) || Test.isRunningTest()){
                        oppline.id = oli.Id;
                        oppline.Required_by_opportunity_product__c = mapQLI_Requiredby.get(oli.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c);
                        updateRequiredby.add(oppline);
                    }     
                  }
              }
          }
      }
      if(!updateRequiredby.isEmpty()) {
          FlowControll.opportunityLineItemHandler = false;
          FlowControll.opportunityTriggerHandler = false;
          update updateRequiredby;
          FlowControll.opportunityTriggerHandler = true;
          FlowControll.opportunityLineItemHandler = true;
      }
  }
  
    /** SAL25-495 Start 
    public static List<Opportunity> updateHasUCLScaleProdCheckbox(List<Opportunity> opptyList, Set<Id> newOliIdsSet) {
        // get UCL Scale product codes 
        Set<String> uclScaleProductCodesMdtset = OpportunityObjectTriggerHelper.getUclScaleProductCodesSet();
        Map<Id, Opportunity> oppMapToUpdate = new Map<Id, Opportunity>();
        
        for(Opportunity opp : opptyList) {
            if(!opp.OpportunityLineItems.isEmpty()){
                for(OpportunityLineItem oli : opp.OpportunityLineItems){
                    if(newOliIdsSet.contains(oli.Id)){
                        if(uclScaleProductCodesMdtset.contains(oli.ProductCode) && oli.UCL_Scale__c == null && opp.RecordTypeId == OpportunityUtil.oppRecTypeIdSalesOpp){
                            oppMapToUpdate.put(opp.Id, opp);
                        }
                    }
                }
            }
        }
        return oppMapToUpdate.values();
    }
     SAL25-495 End */
    
  //SF-11225
  public static List<Opportunity> updateOppLODProducts(List<Opportunity> opptyList) {
      //added logic for CS21-865 - Create Bundle Features field at the Entitlement and Opportunity objects in SFDC - Veera
      List<Opportunity> opportunities = new List<Opportunity>();
      Set<Id> hasPerpetualProductOpportunityIds = new Set<Id>();
      Map<Id, Set<String>> opportunityWithBundleFeatures = new Map<Id, Set<String>>();
      Set<Id> requiredPolarisOppIdSet = new Set<Id>();
      Set<Id> hasPolarisOppIdSet = new Set<Id>();
      
      for(Opportunity opp : opptyList){
          for(OpportunityLineItem eachLineItem : opp.opportunityLineItems){
          //collect OpportunityId with Perpetual Product Licence 
          if (eachLineItem.Product2.License_Type__c == 'Perpetual') {
              hasPerpetualProductOpportunityIds.add(eachLineItem.OpportunityId);
          }
          //SAL23-429 - START
          if(!requiredPolarisOppIdSet.contains(eachLineItem.OpportunityId)){
              if (checkRequiredPolaris(eachLineItem)) {
                  requiredPolarisOppIdSet.add(eachLineItem.OpportunityId);
              }   
          }
          if(!requiredPolarisOppIdSet.contains(eachLineItem.OpportunityId) && !hasPolarisOppIdSet.contains(eachLineItem.OpportunityId)){
              if (opportunityHasPolarisProduct(eachLineItem)) {
                  hasPolarisOppIdSet.add(eachLineItem.OpportunityId);
              }
          }
          //SAL23-429 - END
          if (eachLineItem.Product2.Bundle_Features__c != null) {
              List<String> bundleFeatures = eachLineItem.Product2.Bundle_Features__c.split(';');
              
              if (!opportunityWithBundleFeatures.containsKey(eachLineItem.OpportunityId)) {
                  opportunityWithBundleFeatures.put(eachLineItem.OpportunityId, new Set<String>());
              }
              
              //converting bundle features to Set to avoid redundency
              opportunityWithBundleFeatures.get(eachLineItem.OpportunityId).addAll(bundleFeatures);
          }
      }
      }
      for (Opportunity eachOpportunity : opptyList){
              // to track if the opportunity need to be added to the update list
              Boolean updateOpportunity = false;
              
              if (eachOpportunity.Has_LOD_Products__c && !hasPerpetualProductOpportunityIds.contains(eachOpportunity.Id)) {
                  eachOpportunity.Has_LOD_Products__c = false;
                  updateOpportunity = true;
              } else if (!eachOpportunity.Has_LOD_Products__c && hasPerpetualProductOpportunityIds.contains(eachOpportunity.Id)) {
                  eachOpportunity.Has_LOD_Products__c = true;
                  updateOpportunity = true;
              }
              //SAL23-429 - START
              if(requiredPolarisOppIdSet.contains(eachOpportunity.Id)){
                  if (!eachOpportunity.PolarisDetailsRequired__c) {
                      eachOpportunity.PolarisDetailsRequired__c = true;
                      eachOpportunity.Has_Polaris_Product__c = true;
                      updateOpportunity = true;
                  }
                  if(!eachOpportunity.Has_Polaris_Product__c){
                     eachOpportunity.Has_Polaris_Product__c = true;
                     updateOpportunity = true; 
                  }
              }else if(eachOpportunity.PolarisDetailsRequired__c) {
                      eachOpportunity.PolarisDetailsRequired__c = false;
                      updateOpportunity = true;
              }
              if(hasPolarisOppIdSet.contains(eachOpportunity.Id) && !eachOpportunity.Has_Polaris_Product__c){
                  eachOpportunity.Has_Polaris_Product__c = true;
                  updateOpportunity = true;
              }
              if(!requiredPolarisOppIdSet.contains(eachOpportunity.Id) && !hasPolarisOppIdSet.contains(eachOpportunity.Id) && eachOpportunity.Has_Polaris_Product__c){
                  eachOpportunity.Has_Polaris_Product__c = false;
                  updateOpportunity = true;
              }
              //SAL23-429 - END
              if (Trigger.isAfter && (Trigger.isInsert || Trigger.isDelete)) {
                  if (opportunityWithBundleFeatures.containsKey(eachOpportunity.Id)) {
                      //converting bundle features to string to update on the opportunity
                      List<String> bundleFeatures = new List<String>();
                      bundleFeatures.addAll(opportunityWithBundleFeatures.get(eachOpportunity.Id));
                      String bundleFeature = string.join(bundleFeatures, ';');
                      Integer bundleFeatureLength = Integer.valueOf(Label.BundleFeaturesLength); // to make sure length of the value doesn't exceed the field length
                      eachOpportunity.BundleFeatures__c = bundleFeature.length() > bundleFeatureLength ? bundleFeature.substring(0, bundleFeatureLength): bundleFeature;
                      updateOpportunity = true;
                  } else {
                      eachOpportunity.BundleFeatures__c = '';
                      updateOpportunity = true;
                  }
              }
              
              if (updateOpportunity) {
                  opportunities.add(eachOpportunity);
              } 
          }
      //CS21-865- End
      return opportunities;
  }
  public static Boolean checkRequiredPolaris(OpportunityLineItem oli){
      Boolean requiredPolaris = false;
      if(subTypeSaasSet.contains(oli.Product2.Product_Subtype__c) 
         || oli.Product2.Product_Subtype__c == 'E1000' 
         || productTypeCompleteSet.contains(oli.Product2.Product_Type__c) 
         || (oli.Product2.License_Type__c == 'Life of Device' || (oli.Product2.License_Type__c == 'Perpetual' && oli.Product2.Product_Type__c == 'RCDM'))
         || ((oli.Product2.Product_Level__c == 'Onprem' || oli.Product2.Family == 'Rubrik Scale') && productTypeEditionSet.contains(oli.Product2.Product_Type__c))
         || oli.Product2.ProductCode == 'RS-BT-RCDM-T' 
         || oli.Product2.Product_Type__c == 'Cloud Edition' 
         || familyThridpartySet.contains(oli.Product2.Family)
         || productTypeSwAddonsSet.contains(oli.Product2.Product_Type__c)){
             requiredPolaris = true;
         }
      return requiredPolaris;
  }
  public static Boolean opportunityHasPolarisProduct(OpportunityLineItem oli){
      Boolean hasPolarisProduct = false;
      if(productLevelSet.contains(oli.Product2.Product_Level__c) 
         || oli.PBE_Product_Family__c == 'POLARIS' 
         || (oli.Product2.Bundle_Features__c != null && (oli.Product2.Bundle_Features__c.containsIgnoreCase('Polaris Radar')
                                                        || oli.Product2.Bundle_Features__c.containsIgnoreCase('Polaris GPS')
                                                        || oli.Product2.Bundle_Features__c.containsIgnoreCase('SAP HANA')
                                                        || oli.Product2.Bundle_Features__c.containsIgnoreCase('Cloud Native Protection')))
        ){
             hasPolarisProduct = true;
         }
      return hasPolarisProduct;
  }

  //This method will populate "Program__c" - Multi-select field on Opportunity object based on Special_Program__c - picklist field on OpportunityLineItem
  public static List<Opportunity> populateSpecialProgram(List<Opportunity> oppList) {
      Map<Id,Opportunity> mapToUpdateOppList = new Map<Id,Opportunity>();

      for (Opportunity opp : oppList) {
          Set<String> oppSpecialProgram = new Set<String>();
          if (opp.Opportunity_Program__c != null) {
              oppSpecialProgram.addAll(opp.Opportunity_Program__c.split(';'));
          }

          for (OpportunityLineItem oppLineItemList : opp.OpportunityLineItems) {
              if(!string.isBlank(oppLineItemList.Special_Program__c) && (string.isBlank(opp.Opportunity_Program__c) || !opp.Opportunity_Program__c.contains(oppLineItemList.Special_Program__c))){
              oppSpecialProgram.add(oppLineItemList.Special_Program__c);
              mapToUpdateOppList.put(opp.Id,opp);
          }
          }

          opp.Opportunity_Program__c = String.join(new List<String>(oppSpecialProgram), ';');
      }
      return mapToUpdateOppList.Values();
  }
  
 //ARY-282, ARY-283, ARY-281, ARY-619
 /*Considering only Renewal type opplineitems for Arroyo 1.5 changes */
    public static List<Opportunity> renewalLineItemsOnChange(List<OpportunityLineItem> newList, Map<Id,OpportunityLineItem> oldopptyMap,List<Opportunity> opptyList,set<Id> OpportunityIdSet){
    List<Opportunity> updateOppRTACVList = new List<Opportunity>();
    List<OpportunityLineItem> updateOppLineItemList = new List<OpportunityLineItem>();
    Map<Id,double> earlyACVMap = new Map<Id,double>();
    Map<Id,double> lateACVMap = new Map<Id,double>();
    Map<Id,double> ontimeACVMap = new Map<Id,double>();
    Map<Id,Id> scOppIdMap = new Map<Id,Id>();
    Set<Id> opportunityIds = new Set<Id>();
    Set<Id> rddOpportunityIds = new Set<Id>();
    Map<Id,string> deletedRTAMap = new Map<Id,string>();
    List<string> tempList = new List<string>();
    List<string> tempList1 = new List<string>();
    Double sum = 0;
    String tempStr = '';
    Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
    //ARY-281, ARY-619
    Map<Id,double> lodStandACVMap = new Map<Id,double>();
    Map<Id,double> subscriptionACVMap = new Map<Id,double>();
    Map<Id,double> hwSupportACVMap = new Map<Id,double>();
    Map<Id,double> swSupportACVMap = new Map<Id,double>();
    Map<Id,double> subscriptionAddonACVMap = new Map<Id,double>();
    Set<String> lodStandaloneGroup = new Set<String>{'Life of Device Standalone','Perpetual','Perpetual Add-On','Perpetual Standalone'};
    Set<String> subscriptionGroup = new Set<String>{'Subscription ELA','Subscription Standalone','Subscription','Consumption','Consumption Add-On','Consumption Standalone'};
    Set<String> hwSupportGroup = new Set<String>{'HW Support'};
    Set<String> swSupportGroup = new Set<String>{'SW Support'};
    Set<String> subscriptionAddonGroup = new Set<String>{'Subscription Add-On'};
    try{
    if(newList != null){
        for(OpportunityLineItem newoli : newList) {
            if(newoli.Line_Type__c =='Renewal'){
                if((newoli.Renewal_Due_Date__c != null && (oldopptyMap == null || newoli.Renewal_Due_Date__c != oldopptyMap.get(newoli.Id).Renewal_Due_Date__c))
                || (newoli.ACV_Amount__c != null && (oldopptyMap == null || newoli.ACV_Amount__c != oldopptyMap.get(newoli.Id).ACV_Amount__c))
                ){
                    rddOpportunityIds.add(newoli.OpportunityId);
                }
            }
            if(Trigger.isAfter && Trigger.isDelete){
                rddOpportunityIds.add(newoli.OpportunityId);
            }   
        }
    }
   if(OpportunityIdSet != null && !OpportunityIdSet.isEmpty()){
       rddOpportunityIds.addAll(OpportunityIdSet);
   }
   for(Id oppId : rddOpportunityIds){
       earlyACVMap.put(oppId,0);
       lateACVMap.put(oppId,0);
       ontimeACVMap.put(oppId,0);
       //ARY-281, ARY-619
       lodStandACVMap.put(oppId,0);
       subscriptionACVMap.put(oppId,0);
       hwSupportACVMap.put(oppId,0);
       swSupportACVMap.put(oppId,0);
       subscriptionAddonACVMap.put(oppId,0);
   }
        for(Opportunity opp : opptyList){
            if(!rddOpportunityIds.isEmpty() && rddOpportunityIds.contains(opp.Id)){
            if(opp.SBQQ__PrimaryQuote__r.Amended_Renewed_Service_Contract__c != null){
                scOppIdMap.put(opp.Id,opp.SBQQ__PrimaryQuote__r.Amended_Renewed_Service_Contract__c);
            }
            opp.Deleted_RTA__c = opp.Deleted_RTA__c != null ? opp.Deleted_RTA__c : 0;                                        
            opp.Deleted_line_ContractId_RTA__c = opp.Deleted_line_ContractId_RTA__c != null ? opp.Deleted_line_ContractId_RTA__c : '';     
            oppMap.put(opp.Id,opp);  
       }
   }
    for(Opportunity oppty : opptyList){
        if(!rddOpportunityIds.isEmpty() && rddOpportunityIds.contains(oppty.Id)){
        	for(OpportunityLineItem objoppLine : oppty.opportunitylineitems){
                 Opportunity opp = new Opportunity();
                 opp = oppMap.get(objoppLine.OpportunityId);
                 opp.Id = objoppLine.OpportunityId;                                 
                 tempStr = '';
                 if(!string.isBlank(opp.Deleted_line_ContractId_RTA__c) && opp.Deleted_line_ContractId_RTA__c.contains(';')){
                     tempList = opp.Deleted_line_ContractId_RTA__c.split(';');
                     for(String str : tempList){
                         tempList1 = str.split(':');
                         deletedRTAMap.put(tempList1[0],tempList1[1]);      
                     }             
               }
                if(!Trigger.isDelete && (objoppLine.Renewal_Due_Date__c != null || (string.isBlank(objoppLine.Amended_Service_Contract_Id_Text__c) && objoppLine.Amended_Service_Contract_Id__c != null))){
                    if(objoppLine.Renewal_Due_Date__c != null) 
                        objoppLine.Renewal_Timing__c = populateRenewalTiming(objoppLine);
                   if(string.isBlank(objoppLine.Amended_Service_Contract_Id_Text__c) && objoppLine.Amended_Service_Contract_Id__c != null)
                       objoppLine.Amended_Service_Contract_Id_Text__c = objoppLine.Amended_Service_Contract_Id__c;
                       objoppLine.ContractLine_Id__c = objoppLine.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c;
                       updateOppLineItemList.add(objoppLine);
                 }
                    if(objoppLine.Line_Type__c == 'Renewal' && !string.isBlank(objoppLine.Renewal_Timing__c) && objoppLine.ACV_Amount__c != null){
                     if(objoppLine.Renewal_Timing__c == 'On-Time'){
                         sum = ontimeACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                         ontimeACVMap.put(objoppLine.OpportunityId,sum);
                     }else if(objoppLine.Renewal_Timing__c == 'Early'){
                         sum = earlyACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                         earlyACVMap.put(objoppLine.OpportunityId,sum);
                     }else if(objoppLine.Renewal_Timing__c == 'Late'){
                         sum = lateACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                         lateACVMap.put(objoppLine.OpportunityId,sum);
                     }
                     opp.On_Time_ACV__c = ontimeACVMap.get(objoppLine.OpportunityId);
                     opp.Early_ACV__c = earlyACVMap.get(objoppLine.OpportunityId);
                     opp.Late_ACV__c = lateACVMap.get(objoppLine.OpportunityId);  
                }
                if(!deletedRTAMap.isEmpty() && deletedRTAMap.containskey(objoppLine.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c)){
                    if(opp.Deleted_RTA__c != null && opp.Deleted_RTA__c != 0 ){
                        opp.Deleted_RTA__c = opp.Deleted_RTA__c - Decimal.valueOf(deletedRTAMap.get(objoppLine.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c));
                    }
                    deletedRTAMap.remove(objoppLine.SBQQ__QuoteLine__r.SBQQSC__RenewedContractLine__c);
                    if(!deletedRTAMap.isEmpty()){
                        for(Id contractlineId : deletedRTAMap.keySet()){
                            tempStr = tempStr+contractlineId+':'+deletedRTAMap.get(contractlineId)+';';
                        }
                        opp.Deleted_line_ContractId_RTA__c = tempStr;
                    }else{
                        opp.Deleted_line_ContractId_RTA__c = '';
                    }
                }
                //ARY-281, ARY-619
                    if(objoppLine.Line_Type__c == 'Renewal' && objoppLine.ACV_Amount__c != null){
                    String prdGroup = objoppLine.QuoteLine_Product_Group__c?.trim();
                    if(lodStandaloneGroup.contains(prdGroup)){
                        sum = lodStandACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                        lodStandACVMap.put(objoppLine.OpportunityId,sum);
                    }else if(subscriptionGroup.contains(prdGroup)){
                        sum = subscriptionACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                        subscriptionACVMap.put(objoppLine.OpportunityId,sum);
                    }else if(hwSupportGroup.contains(prdGroup)){
                        sum = hwSupportACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                        hwSupportACVMap.put(objoppLine.OpportunityId,sum);
                    }else if(swSupportGroup.contains(prdGroup)){
                        sum = swSupportACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                        swSupportACVMap.put(objoppLine.OpportunityId,sum);
                    } else if(subscriptionAddonGroup.contains(prdGroup)){
                        sum = subscriptionAddonACVMap.get(objoppLine.OpportunityId)+objoppLine.ACV_Amount__c;
                        subscriptionAddonACVMap.put(objoppLine.OpportunityId,sum);
                    }
                    opp.LOD_Standalone_ACV__c = lodStandACVMap.get(objoppLine.OpportunityId);
                    opp.Subscription_ACV__c = subscriptionACVMap.get(objoppLine.OpportunityId);
                    opp.HW_Support_ACV__c = hwSupportACVMap.get(objoppLine.OpportunityId);
                    opp.SW_Support_ACV__c = swSupportACVMap.get(objoppLine.OpportunityId);
                    opp.Subscription_Add_On_ACV__c = subscriptionAddonACVMap.get(objoppLine.OpportunityId);
                }
                oppMap.put(objoppLine.OpportunityId,opp);
        }
        }
   }
   system.debug('@@ oppMap '+oppMap);
   if(newList != null && Trigger.isAfter && Trigger.isDelete){
       for(OpportunityLineItem newoli : newList) {
           if(oppMap.containskey(newoli.OpportunityId)){
               Opportunity opp = new Opportunity();
               opp.Id = newoli.OpportunityId;
               opp = oppMap.get(newoli.OpportunityId);
               if(opp.SBQQ__PrimaryQuote__r.SBQQ__Type__c != System.Label.Arry_Quote_Type && ((opp.SBQQSC__RenewedServiceContract__c != null && opp.SBQQSC__RenewedServiceContract__r.Renew_to_Old_SKUs__c) || opp.SBQQ__PrimaryQuote__r.Polaris_Conversion__c) && opp.SBQQ__PrimaryQuote__c != null && opp.SBQQ__PrimaryQuote__r.SBQQ__Primary__c && newoli.Renewal_Target_Amount__c != null){
                   opp.Deleted_RTA__c = opp.Deleted_RTA__c != null ? opp.Deleted_RTA__c : 0;  
                   if(scOppIdMap.containskey(newoli.OpportunityId) && scOppIdMap.get(newoli.OpportunityId) != null && newoli.Amended_Service_Contract_Id_Text__c != null && scOppIdMap.get(newoli.OpportunityId) == Id.valueof(newoli.Amended_Service_Contract_Id_Text__c)){
                       opp.Deleted_RTA__c = opp.Deleted_RTA__c + newoli.Renewal_Target_Amount__c;
                       opp.Deleted_line_ContractId_RTA__c = opp.Deleted_line_ContractId_RTA__c+newoli.ContractLine_Id__c+':'+newoli.Renewal_Target_Amount__c+';';
                       oppMap.put(newoli.OpportunityId,opp);
                   }
               }
               if(!opp.SBQQ__PrimaryQuote__r.SBQQ__Primary__c){
                   opp.Deleted_RTA__c = 0;
                   opp.Deleted_line_ContractId_RTA__c = '';
                   opp.On_Time_ACV__c = 0;
                   opp.Early_ACV__c = 0;
                   opp.Late_ACV__c = 0; 
                   //ARY-281, ARY-619
                   opp.LOD_Standalone_ACV__c = 0;
                   opp.Subscription_ACV__c = 0;
                   opp.HW_Support_ACV__c = 0;
                   opp.SW_Support_ACV__c = 0;
                   opp.Subscription_Add_On_ACV__c = 0;   
                   oppMap.put(newoli.OpportunityId,opp);
               }
           }
       }
   }
   if(!Trigger.isDelete && !updateOppLineItemList.isEmpty()){
       FlowControll.opportunityTriggerHandler = false;
       FlowControll.opportunityLineItemHandler = false;
       update updateOppLineItemList;
       FlowControll.opportunityTriggerHandler = true;
       FlowControll.opportunityLineItemHandler = true;
    }
    }catch(Exception e){
        system.debug('@@ Exception occurred '+e.getMessage()+' at line '+e.getLineNumber());
   }
   system.debug('@@ oppMap '+oppMap);
    return oppMap.values();
}
 //ARY-283 
 /* This method is for populating Renewal Timing picklist on an individual opplineitem */
 public static string populateRenewalTiming(OpportunityLineItem objoppLine){
      String CloseQtr = getQuarter(objoppLine.Opportunity.CloseDate);
      String RenewalQtr = getQuarter(objoppLine.Renewal_Due_Date__c);
      Integer CloseQtrVal = Integer.ValueOf(CloseQtr.substring(1,2));
      Integer RenewalQtrVal = Integer.ValueOf(RenewalQtr.substring(1,2));
      String RenewalYear = String.ValueOf(objoppLine.Renewal_Due_Date__c.year()).substring(2,4);
      String CloseYear = String.ValueOf(objoppLine.Opportunity.CloseDate.year()).substring(2,4);
      Integer CloseYearVal = Integer.valueOf(CloseYear);
      Integer RenewalYearVal = Integer.valueOf(RenewalYear);
      if(CloseQtrVal == 4 && objoppLine.Opportunity.CloseDate.month() == 1)
          CloseYearVal = CloseYearVal -1;
      if(RenewalQtrVal == 4 && objoppLine.Renewal_Due_Date__c.month() == 1)
          RenewalYearVal = RenewalYearVal -1;
      
      if(RenewalYearVal == CloseYearVal){
          if(RenewalQtrVal == CloseQtrVal){
              objoppLine.Renewal_Timing__c = 'On-Time';
          }else if(RenewalQtrVal >  CloseQtrVal){
              objoppLine.Renewal_Timing__c = 'Early';
          }else{
              objoppLine.Renewal_Timing__c = 'Late';
          }
      }else if(RenewalYearVal > CloseYearVal){
          objoppLine.Renewal_Timing__c = 'Early';
      }else{
          objoppLine.Renewal_Timing__c = 'Late';
      }
      return objoppLine.Renewal_Timing__c;
 }
  public static String getQuarter(date selectedDate){
      String qtr= '';
      date dt = selectedDate;
      if(dt.month() >= 2 && dt.month() <= 4){
          qtr= 'Q1';
      }else if(dt.month() >= 5 && dt.month() <= 7){
          qtr= 'Q2';
      }else if(dt.month() >= 8 && dt.month() <= 10){
          qtr= 'Q3';
      }else{
          qtr= 'Q4';
      }
      return qtr;
  }
    public static Map<Id,Boolean> updateSOWRequiredOnOppty(List<Opportunity> opptyList){
        Map<Id,Boolean> sowOppIdMap = new Map<Id,Boolean>();
        Decimal overallConsultQuantity = 0;
        Set<String> ConsultQuantitySet = system.Label.ConsultSKUs != null ? new Set<String>(system.Label.ConsultSKUs.split(';')) : new Set<String>();
        Set<String> SOWRequiredSKUsSet = system.Label.SOWRequiredSKUs != null ? new Set<String>(system.Label.SOWRequiredSKUs.split(',')) : new Set<String>();
        Boolean isSOWRequiredSKUs = false; //SAL25-713
        for(Opportunity opp : opptyList){
            overallConsultQuantity = 0;
            for(OpportunityLineItem eachLineItem : opp.opportunityLineItems){
                if(SOWRequiredSKUsSet.contains(eachLineItem.ProductCode)){
                    isSOWRequiredSKUs = true;
                    if(opp.SOW_Required__c == true){
                        break;
                    }else{
                        sowOppIdMap.put(opp.Id,true);
                        break;
                    }
                }
                if(ConsultQuantitySet.contains(eachLineItem.ProductCode)){
                    overallConsultQuantity = overallConsultQuantity+eachLineItem.Quantity;
                }
            }
            if(overallConsultQuantity >= 10 && opp.SOW_Required__c == false && !isSOWRequiredSKUs){
                sowOppIdMap.put(opp.Id,true);
            }else if(opp.SOW_Required__c == true && overallConsultQuantity < 10 && (sowOppIdMap.isEmpty() || !sowOppIdMap.containskey(opp.Id)) && !isSOWRequiredSKUs){
                sowOppIdMap.put(opp.Id,false);
            }
        }
        return sowOppIdMap; 
    }  
//SAL24-359
    public static Set<Id> update3rdPartyHWonOppty(List<Opportunity> opptyList){ 
        Set<Id> oppIdSetWith3rdPartyProds = new Set<Id>();
        for(Opportunity opp : opptyList){
            for(OpportunityLineItem eachLineItem : opp.opportunityLineItems){
                if(familyThridpartySet.contains(eachLineItem.Product2.Family)){
                    oppIdSetWith3rdPartyProds.add(opp.Id);
                }
            }
        }
         return oppIdSetWith3rdPartyProds;
    }
    
    //OPPTYSPLIT-2, OPPTYSPLIT-5
    static void syncOppLineItems(List<OpportunityLineItem> newlineItems,Map<Id,OpportunityLineItem> opptyOldLineMap){
        List<OpportunityLineItem> childLineItems = new List<OpportunityLineItem>();
        
        if (Trigger.isInsert && newlineItems != null) {
            Set<Id> oppIds = new Set<Id>();
            for(OpportunityLineItem lineItem : newlineItems){
                if (lineItem.Parent_split_Opplineitem_Id__c == null && lineItem.Applied_Split__c != null && lineItem.Applied_Split__c < 100 && lineItem.ProductCode != 'OPTY-SPLIT' ) {
                    oppIds.add(lineItem.OpportunityId); //Parent split oppIds
                }
            }
            if(!oppIds.isEmpty()){
                for (Opportunity opp : [SELECT Id, Split_percentage__c FROM Opportunity WHERE Opportunity_Split_Parent__c IN :oppIds AND Split_percentage__c != null AND Split_percentage__c != 0]) { //query child split opps
                    for (OpportunityLineItem lineItem : newlineItems) {
                        if(lineItem.Parent_split_Opplineitem_Id__c == null && lineItem.Line_Type__c != 'Renewal' && lineItem.productCode != 'OPTY-SPLIT'){ //inserted parent opp's opplineitem
                            OpportunityLineItem clonedLineItem = lineItem.clone(false, true, false, false);
                            clonedLineItem.OpportunityId = opp.Id;
                            clonedLineItem.Parent_split_Opplineitem_Id__c = lineItem.Id;
                            clonedLineItem.Applied_Split__c = opp.Split_percentage__c;
                            clonedLineItem.TotalPrice = null;
                            clonedLineItem.Line_Type_Text__c = lineItem.Line_Type__c;
                            clonedLineItem.SBQQ__QuoteLine__c = null;
                            childLineItems.add(clonedLineItem);
                        }
                    }
                }
            }
        }else if(Trigger.isUpdate && newlineItems != null && opptyOldLineMap != null) {
            Set<string> fieldNameSet = new Set<string>();
            ShGl_QueryConstants__mdt metaQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OppLineValuesComparison'];
            List<String> fieldNames = metaQuery.Query_String__c.split(',');
            fieldNameSet.addAll(fieldNames); //SAL25-568
            addCustomFields(fieldNameSet);
            Map<Id,List<OpportunityLineItem>> ChildlineItemMap = new Map<Id,List<OpportunityLineItem>>();
            Set<Id> parentLineItemIds = new Set<Id>();
            
            for(OpportunityLineItem lineItem:newlineItems) {
                for(string fieldName:fieldNameSet){
                    if (fieldName == 'Id' || 
                        fieldName == 'Parent_split_Opplineitem_Id__c' ||
                        fieldName == 'SBQQ__QuoteLine__c' ||
                        fieldName == 'Applied_Split__c' ||
                        fieldName == 'sbaa__ApprovalStatus__c' ||
                        fieldName == 'Original_OpplineitemId__c' ||
                        fieldName == 'SBQQ__ParentID__c' ||
                        fieldName == 'SBQQ__SubscriptionType__c') {
                        continue;
                    }
                    OpportunityLineItem oldlineitem = opptyOldLineMap.get(lineItem.Id);
                    if(lineItem.Line_Type__c != 'Renewal' && lineItem.Parent_split_Opplineitem_Id__c == null && lineItem.Applied_Split__c != null && lineItem.Applied_Split__c < 100 && 
                        lineItem.productCode != 'OPTY-SPLIT' && lineItem.get(fieldName) != oldlineitem.get(fieldName)){ //Split Parent opp's opplineitems
                        parentLineItemIds.add(lineItem.Id);
                        break;
                    }
                }
            }
            if(parentLineItemIds.isEmpty()) return;
            string soqlFields = String.join(new List<String>(fieldNameSet),',');
            for(OpportunityLineItem ChildOpplineItem : database.query('SELECT ' +soqlFields + ' FROM ' + 'OpportunityLineItem' + ' WHERE Parent_split_Opplineitem_Id__c IN:parentLineItemIds')){
                if(!ChildlineItemMap.containsKey(ChildOpplineItem.Parent_split_Opplineitem_Id__c)){
                    ChildlineItemMap.put(ChildOpplineItem.Parent_split_Opplineitem_Id__c,new List<OpportunityLineItem>());
                }
                ChildlineItemMap.get(ChildOpplineItem.Parent_split_Opplineitem_Id__c).add(ChildOpplineItem);
            }
            for(OpportunityLineItem lineItem:newlineItems){
                if(ChildlineItemMap.containsKey(lineItem.Id)){
                    for(OpportunityLineItem childLineItem : ChildlineItemMap.get(lineItem.Id)){
                        OpportunityLineItem childLineItemToUpdate = new OpportunityLineItem(Id = childLineItem.Id);
                        for(string fieldName:fieldNameSet){
                            if (fieldName == 'Id' || 
                                fieldName == 'Parent_split_Opplineitem_Id__c' ||
                                fieldName == 'SBQQ__QuoteLine__c' ||
                                fieldName == 'Applied_Split__c' ||
                                fieldName == 'sbaa__ApprovalStatus__c' ||
                                fieldName == 'Original_OpplineitemId__c' ||
                                fieldName == 'SBQQ__ParentID__c' ||
                                fieldName == 'SBQQ__SubscriptionType__c') {
                                continue;
                            }
                            childLineItemToUpdate.put(fieldName,lineItem.get(fieldName));
                        }
                        system.debug(childLineItemToUpdate);
                        childLineItems.add(childLineItemToUpdate);
                    }
                }
            }
        }
        if(!childLineItems.isEmpty()){
            FlowControll.opportunityTriggerHandler = false;
            FlowControll.opportunityLineItemHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = true; //skip ACV calculation class
            UPSERT childLineItems;
        }
        OppAnnualContractValueUtil.OppACVRecursion = false;
        FlowControll.opportunityTriggerHandler = true;
        FlowControll.opportunityLineItemHandler = true;
    }
    
    static void addCustomFields(Set<String> fields){
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get('OpportunityLineItem');
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        for(String fieldName : MapofField.keySet())
        {
            Schema.SObjectField field = MapofField.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            if(F.isCustom() && F.isUpdateable() && !fields.contains(F.getName())) {
                fields.add(F.getName());
            }
        }
    }
    
    //Deleting related child items after parent OpportunityLineItems are deleted | OPPTYSPLIT-26
    public static void OppLineItemsAfterDelete(List<OpportunityLineItem> oldlineItems){
        list<OpportunityLineItem> childItems = new list<OpportunityLineItem>();
        set<Id> deleteChildItems = new set<Id>();
        if(!oldlineItems.isEmpty() && !deletedParentsplitLineItemsMap.isEmpty()){
            for(OpportunityLineItem oli: oldlineItems){
                if(deletedParentsplitLineItemsMap.containsKey(oli.Id)){
                    childItems.addAll(deletedParentsplitLineItemsMap.get(oli.Id));
                    }
                }
            
                FlowControll.opportunityTriggerHandler = false;
                FlowControll.opportunityLineItemHandler = false;
                OppAnnualContractValueUtil.OppACVRecursion = true; //skip ACV calculation class
                    //SAL25-590 - START
                    /*if(!childItems.isEmpty()){
                        Delete childItems;
                    }*/
                    for(OpportunityLineItem oli : childItems){
                        deleteChildItems.add(oli.Id);
                    }
                    if(!deleteChildItems.isEmpty()){
                        system.enqueueJob(new DeleteOLIsQueueable(deleteChildItems));
                    }
                    //SAL25-590 - END
                    if(!childItems.isEmpty()){
                        Delete childItems;
                    }
                OppAnnualContractValueUtil.OppACVRecursion = false;    
                FlowControll.opportunityTriggerHandler = true;
                FlowControll.opportunityLineItemHandler = true;
            }
        }
}