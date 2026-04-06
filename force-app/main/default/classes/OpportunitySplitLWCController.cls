/**
* @description 'Manage Split' button's controller
*/
public without sharing class OpportunitySplitLWCController {
    private static final string AMOUNTERROR = 'Parent Opportunty must have an Amount.';
    private static final string EXCEPTIONMSG = 'Error occured while splitted Opportunity. Please contact System Administrator.';
    private static final string CANNOTSPLITERROR = 'Current Split opportunity record cannot be split further';
    private static final string RenewalRECORDTYPEERROR = 'Cannot do Manage Split on Renewal Opportunity';
    private static final string CLOSEDOPPERROR = 'Cannot do Manage Split on Closed Opportunity';
    private static final Set<String> closedStages = new Set<String>{'7 Closed Won','7 Closed Lost','7 Closed Admin'};
    public static Boolean skipOpplineItemTriggerCreationLogic = false;
    private static Map<Id,Decimal> OldchildoppIdStageMap = new Map<Id,Decimal>(); //SAL26-258
    public static Boolean createOptySPlitLine = true;
    private static final List<String> coOwnerFields = new List<String>{ 'Co_Owner__c', 'NCD_Co_Owner__c', 'SaaS_Co_Owner__c' }; //SAL26-1340

/**
* @description to getOppDetails
* @param recId
* @return wrapClassList
*/
    @AuraEnabled
    public static List<primaryOppWrap> getOppDetails(string recId){
        opportunity primaryOpportunity = new opportunity();
        List<wrapClass> wrapClassList = new List<wrapClass>();
        List<primaryOppWrap> primaryOppWrapList = new List<primaryOppWrap>();
        Double optyTotalValue;
        Double newoptyTotalValue;
        Double newoptyACVValue;
        Decimal staticAmount;
        Integer count = 1;
        Boolean isglobal = false;
        try{
            ShGl_QueryConstants__mdt [] opptySplitQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OpportunitySplit_CopyQuery'];
            // Use bind variable to prevent SOQL injection
            String queryString = opptySplitQuery.get(0).Query_String__c + ' WHERE Id = :recId';
            primaryOpportunity = Database.query(queryString);
            Id renewalRectypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
            
            optyTotalValue = 0.00;
            staticAmount = 0.00;
            newoptyTotalValue = 0.00;
            newoptyACVValue = 0.00;
            for(OpportunityLineItem vLineItem : primaryOpportunity.OpportunityLineItems){
                System.debug(LoggingLevel.DEBUG,'@@vLineItem: '+vLineItem+'\n\n\n');
                if(vLineItem.ProductCode == 'OPTY-SPLIT'){
                    if(vLineItem.TotalPrice > 0){
                        optyTotalValue = optyTotalValue+vLineItem.TotalPrice;
                        newoptyTotalValue = newoptyTotalValue+vLineItem.TotalPrice;
                        staticAmount = vLineItem.TotalPrice;
                        if(vLineItem.ACV_Amount__c != null)
                        	newoptyACVValue = newoptyACVValue+vLineItem.ACV_Amount__c;
                    } 
                } else {
                    if(vLineItem.Line_Type__c != 'Renewal'){
                    	newoptyTotalValue = newoptyTotalValue+vLineItem.TotalPrice;
                        if(vLineItem.ACV_Amount__c != null)
                        	newoptyACVValue = newoptyACVValue+vLineItem.ACV_Amount__c;
                    }
                    optyTotalValue = optyTotalValue+vLineItem.TotalPrice;
                }
            }
            if(primaryOpportunity.Account.Coverage__c == 'Global')
                isglobal = true;
            if(optyTotalValue == 0.00){
                newoptyTotalValue = primaryOpportunity.Amount;
                optyTotalValue = primaryOpportunity.Amount;
            }
            if(newoptyTotalValue == null){
                primaryOppWrapList.add(new primaryOppWrap(AMOUNTERROR,'error',primaryOpportunity,optyTotalValue,staticAmount,isglobal,newoptyTotalValue,newoptyACVValue)); 
            }
            if(primaryOpportunity.RecordTypeId == renewalRectypeId){
                primaryOppWrapList.add(new primaryOppWrap(RenewalRECORDTYPEERROR,'error',primaryOpportunity,optyTotalValue,staticAmount,isglobal,newoptyTotalValue,newoptyACVValue)); 
            }
            if(primaryOpportunity.Opportunity_Split_Parent__c != null){
                 primaryOppWrapList.add(new primaryOppWrap(CANNOTSPLITERROR,'error',primaryOpportunity,optyTotalValue,staticAmount,isglobal,newoptyTotalValue,newoptyACVValue)); 
            }
             if(closedStages.contains(primaryOpportunity.StageName)){
                 primaryOppWrapList.add(new primaryOppWrap(CLOSEDOPPERROR,'error',primaryOpportunity,optyTotalValue,staticAmount,isglobal,newoptyTotalValue,newoptyACVValue)); 
            }
            if(primaryOppWrapList.isEmpty()){
                primaryOppWrapList.add(new primaryOppWrap('','',primaryOpportunity,optyTotalValue,staticAmount,isglobal,newoptyTotalValue,newoptyACVValue)); 
            }
        }catch (exception e) {
            primaryOppWrapList.add(new primaryOppWrap(e.getMessage()+' at line '+e.getLineNumber(),'error',null,optyTotalValue,staticAmount,isglobal,newoptyTotalValue,newoptyACVValue)); 
        }
        System.debug(LoggingLevel.DEBUG,'@@optyTotalValue: '+optyTotalValue);
        return primaryOppWrapList;
    }
 /**
* @description to getSplitOppDetails
* @param recId
* @return wrapClassList
*/   
    @AuraEnabled
    public static List<wrapClass> getSplitOppDetails(string recId){
        opportunity primaryOpportunity = new opportunity();
        List<wrapClass> wrapClassList = new List<wrapClass>();
        Integer count = 1;
        try{
            ShGl_QueryConstants__mdt [] opptySplitQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OpportunitySplit_CopyQuery'];
            // Use bind variable to prevent SOQL injection
            String queryString = opptySplitQuery.get(0).Query_String__c + ' WHERE Id = :recId';
            primaryOpportunity = Database.query(queryString);
            
            for(Integer i = 0; i < primaryOpportunity.Split_Opportunities__r.size(); i++) {
                wrapClass tempInst = new wrapClass(primaryOpportunity.Split_Opportunities__r.get(i),i+2);
                count = i+2;
                wrapClassList.add(tempInst);
            }
        }catch (exception e) {
             System.debug(LoggingLevel.DEBUG,'@@Exception occurred :: '+e.getMessage());
        }
        return wrapClassList;
    }
/**
* @description to validateManager
* @param ownerIdSet
* @return errorMsg
*/      
    public static string validateManager(set<string> ownerIdSet){
        string errorMsg = 'Below Split opportunity owner\'s Manager is either Blank or Inactive';
        Boolean isError = false;
        if(!ownerIdSet.isEmpty()){
            for(User usr : [select Id,Name,ManagerId,Manager.isActive from User where Id IN: ownerIdSet]){
                if(usr.ManagerId == null || usr.Manager.isActive == false){
                    errorMsg = errorMsg+'\n'+usr.Name;
                    isError = true;
                }
            }
        }
        if(isError){
            return errorMsg;
        }else{
            return '';
        }
    
    }
 /**
* @description to saveItem
* @param primaryOpp
* @param jsonwrapperList
* @param newoptyTotalValue
* @param staticAmount
* @param prevOwnerIdList
* @param isglobal
* @param isSplitException
* @return successSave
*/         
    @AuraEnabled
    public static Boolean saveItem(opportunity primaryOpp, string jsonwrapperList, Double newoptyTotalValue, Decimal staticAmount, List<Id> prevOwnerIdList, Boolean isglobal, Boolean isSplitException) {
            Boolean successSave = false;
            //ETM-182: TART update on Opp Splits
            Map<Id, UserTerritory2Association> ownerTerrIdMap = new Map<Id, UserTerritory2Association>();
            Set<Id> SEterrIds = new Set<Id>();
            Map<Id, Id> terrIdSEMap = new Map<Id,Id>();
            List<string> SERoles; // sales engineer role
            Set<Id> prevOwnerIdSet = new Set<Id>();
            string errorMsg = '';
            set<string> ownerIdSet = new set<string>();
            //SF-8995
            Map<Id,Id> terrToRegionSETerrIdMap = new Map<Id,Id>();
    
            //SAL25-166
            List<string> plsAERoles = new List<string>();
            List<string> plsSERoles = new List<string>();
            Map<Id,String> uIdToPLSRoleMap = new Map<Id,String>();
            Map<String,Id> adaptiveIdRolePLSSEMap = new Map<String,Id>();
            String accAdaptiveId;
            String accTerrId;
            Set<Id> deleteOppOLIset = new Set<Id>(); //SAL26-258
            Set<Id> createOppOLIset = new Set<Id>(); //SAL26-258
            List<Opportunity> createOppInst = new List<Opportunity>(); //SAL26-258
    
            Map<id,opportunity> existingSplitsMAp = new Map<id,opportunity>([select id from opportunity where Opportunity_Split_Parent__c=:primaryOpp.Id]);
            Id[] emailAddresses = new Id[]{};
	     Map<Id, Opportunity> primaryOpportunityMap = new Map<Id, Opportunity>(); //SAL26-72 
	     Map<Id, Opportunity> splitOppMap = new Map<Id, Opportunity> ();	//SAL26-72 	
                
            flowControll.opportunityTriggerHandler = false;
            
            if(!prevOwnerIdList.isEmpty()){
                prevOwnerIdSet.addAll(prevOwnerIdList);
            }
            ShGl_QueryConstants__mdt [] opptySplitQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OpportunitySplit_CopyQuery'];
            // Use bind variable to prevent SOQL injection
            String primaryOppId = primaryOpp.Id;
            String queryString = opptySplitQuery.get(0).Query_String__c + ' WHERE Id = :primaryOppId';
            opportunity primaryOpportunity = Database.query(queryString);
            primaryOpportunity.Split_percentage__c = primaryOpp.Split_percentage__c;
            primaryOpportunity.Commission_Credit_Split_Split_screen__c = primaryOpp.Commission_Credit_Split_Split_screen__c;
			
            for(Opportunity childOpp : primaryOpportunity.Split_Opportunities__r){ //SAL26-258
                OldchildoppIdStageMap.put(childOpp.Id,childOpp.Split_Percentage__c);
            }
            //SAL25-668
            /*if(isSplitException){
                primaryOpportunity.Split_Exception_CCR_is_Pending__c = true;
            }else{
                primaryOpportunity.Commission_Credit_Split__c = primaryOpportunity.Commission_Credit_Split_Split_screen__c;
            }*/
            ownerIdSet.add(primaryOpportunity.ownerId);
            system.debug(LoggingLevel.DEBUG,'@@Processing Start');
    
            List <wrapClass> wrapperList = ( List <wrapClass> )JSON.deSerialize( jsonwrapperList, List <wrapClass>.class );
            for(wrapClass wrapIns : wrapperList){
                Opportunity oppInst = wrapIns.splitopp;  
                ownerIdSet.add(oppInst.ownerId);
            }
            //SAL25-668
            /*if(isSplitException){
                errorMsg = validateManager(ownerIdSet);
                if(string.isNotBlank(errorMsg) && !Test.isRunningTest()){
                     throw new AuraHandledException(errorMsg);
                }
            }
            Boolean isValid = validatePendingCCR(primaryOpportunity);
            if(!isValid){
                throw new AuraHandledException('There are already Split Exception CCR record which is submitted for Approval');
            }*/
            if(staticAmount>0){
                OpportunitySplitHelper.createAmountProduct(primaryOpportunity, staticAmount);
                newoptyTotalValue=staticAmount;
            }
    
            List<Opportunity> updateList = new List<Opportunity>();
            List<Opportunity> updateListNEw = new List<Opportunity>();
            Set<Id> assignOppTeamUserIds = new Set<Id>();
            Set<Id> removeOppTeamUserIds = new Set<Id>();
        
            //calculate the number of users that have an amount defined
            Double splitAmounts=0.00;
          
            //splitAmounts=User2Opty.split_amount__c + User3Opty.split_amount__c + User4Opty.split_amount__c;  
            
            if(primaryOpportunity.Split_percentage__c != null)
                primaryOpportunity.Split_percentage__c = primaryOpportunity.Split_percentage__c.setScale(2);
    
            List<OpportunitySplitMapping__c> oppSplitMapping = [SELECT Skip_Update_if_child_has_value__c,Default_Value__c,Field__c,From_Field__c,Id,Name,Prefix__c,Suffix__c FROM OpportunitySplitMapping__c];
    
          if(primaryOpportunity.Split_percentage__c == 100){
                  createOptySPlitLine = false;
            }
            for(wrapClass wrapIns : wrapperList){
                
                Opportunity oppInst = wrapIns.splitopp;
                system.debug(LoggingLevel.DEBUG,'test value '+oppInst.OwnerId);
                if(wrapIns.index != null && oppInst != null && oppInst.OwnerId != null ){
                    oppInst.Split_percentage__c = oppInst.Split_percentage__c.setScale(2);
                    //system.debug('@@ oppInst.id == null '+string.isblank(oppInst.id));
                    if(oppInst.id == null)
                        oppInst = OpportunitySplitHelper.copyOpportunityFieldToSplit(oppInst, primaryOpportunity, oppSplitMapping);
                    else
                        existingSplitsMAp.remove(oppInst.id);
                    if(oppInst.split_amount__c > 0) {
                        oppInst.Amount = oppInst.split_amount__c;
                        oppInst.Split_percentage__c = null;
                    } else {
                        oppInst.Amount = newoptyTotalValue * (oppInst.Split_percentage__c / 100);
                        oppInst.split_amount__c = null;
                    }
                    //SAL25-668
                    /*if(!isSplitException){
                        oppInst.Commission_Credit_Split__c = oppInst.Commission_Credit_Split_Split_screen__c;
                    }*/
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
    
            newoptyTotalValue = newoptyTotalValue-splitAmounts;
            
            //SAL25-166
            //ETM-182: TART update on Opp Splits
            /*List<Territory_Management_Setup__mdt> fielSalesMdt = [select Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName='Role_of_Sales_Engineer'];
            if(!fielSalesMdt.isEmpty() && fielSalesMdt[0].Field_Value__c!=null){
                SERoles = fielSalesMdt[0].Field_Value__c.split(';');
            }*/
            accAdaptiveId = primaryOpportunity?.Account?.Adaptive_Territory_Id__c;
            for(Territory_Management_Setup__mdt fielSalesMdt : [select Field_Value__c,Field_Type__c,Operator__c,DeveloperName from Territory_Management_Setup__mdt where DeveloperName IN('Role_of_Sales_Engineer','Role_of_PLS_AE','Role_of_PLS_SE')]){ //SAL23-720 //SAL24-798 //SAL24-735 //SAL25-48
                if(fielSalesMdt.Field_Value__c!=null){
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Role_of_Sales_Engineer'))
                        SERoles = fielSalesMdt.Field_Value__c.split(';');
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Role_of_PLS_AE'))
                        plsAERoles = fielSalesMdt.Field_Value__c.split(';');
                    if(fielSalesMdt.DeveloperName.equalsIgnoreCase('Role_of_PLS_SE'))
                        plsSERoles = fielSalesMdt.Field_Value__c.split(';');
                }
            }
            //SAL25-166
            if(accAdaptiveId != null && accAdaptiveId != ''){
                for(Territory2 terr :[SELECT Id,Adaptive_Territory_Id__c FROM Territory2 WHERE Adaptive_Territory_Id__c =:accAdaptiveId AND Territory2Model.state='Active' LIMIT 1]){
                    accTerrId = terr.Id;
                    SEterrIds.add(terr.Id);
                }
            } 

            for(UserTerritory2Association UTA : [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,
                                                    territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,  
                                                    territory2.Channel_Territory__c,territory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c, Territory2.ParentTerritory2Id, Territory2.ParentTerritory2.Adaptive_Territory_Id__c //SF-8995
                                                    from UserTerritory2Association 
                                                     where Territory2.Territory2Model.state='Active' 
                                                     AND User.IsActive=true 
                                                     AND Territory2.Territory2Type.DeveloperName ='territory' 
                                                     AND UserId IN : ownerTerrIdMap.keyset() AND (RoleInTerritory2 ='Account Executive' OR RoleInTerritory2 IN :plsAERoles) //SAL25-166
                                                     order by lastmodifieddate
                                                    ]){
                    ownerTerrIdMap.put(UTA.UserId, UTA);
                    SEterrIds.add(UTA.Territory2Id);
    
                    //SF-8995:
                    SEterrIds.add(UTA.Territory2.ParentTerritory2Id);
                    terrToRegionSETerrIdMap.put(UTA.Territory2Id, UTA.Territory2.ParentTerritory2Id);

                    //SAL25-166
                    if(plsAERoles.contains(UTA.RoleInTerritory2)){
                        uIdToPLSRoleMap.put(UTA.UserId,UTA.RoleInTerritory2);
                    }
            }
            for(UserTerritory2Association UTA : [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2,territory2.Internal_Territory_Name__c,territory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c,territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c  from UserTerritory2Association 
                                                    where Territory2.Territory2Model.state='Active' 
                                                    AND User.IsActive=true 
                                                    //AND Territory2.Territory2Type.DeveloperName ='territory' //SF-8995
                                                    AND Territory2.Id IN: SEterrIds 
                                                    AND (RoleInTerritory2 IN : SERoles OR RoleInTerritory2 IN :plsSERoles) //SAL25-166
                                                    order by lastmodifieddate
                                                ]){    
                if(SERoles.contains(UTA.RoleInTerritory2) && !terrIdSEMap.containskey(UTA.Territory2Id)){
                    terrIdSEMap.put(UTA.Territory2Id,UTA.UserId);
                }

                //SAL25-166
                if(plsSERoles.contains(UTA.RoleInTerritory2)){
                    adaptiveIdRolePLSSEMap.put(UTA.Territory2.Adaptive_Territory_Id__c+UTA.RoleInTerritory2,UTA.UserId); //Key:AdaptiveIdRole Value: UserId 
                } 
            }
            
            if(!updateListNEw.isEmpty() || !existingSplitsMAp.isEmpty()) {
                /*upsert child split opportunities*/
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.allowSave = true;
                dml.DuplicateRuleHeader.runAsCurrentUser = true; 
                
                //sort the updates and insert - upsert won't work with the DML options
                List<Opportunity> insertOpt = new List<Opportunity>();
                List<Opportunity> updateOpt = new List<Opportunity>();
                //SF-11236
                List<Opportunity> splitOppList = new List<Opportunity>();
                //SAL26-1340 START
                Set<Id> coOwnerUserIds = new Set<Id>();
                Set<Id> oppETMOverridesSetIds = new Set<Id>();
                //SAL26-1340
                Map<String, List<String>> overrideToPLSFields = new Map<String, List<String>>{
                    'CLOUD ETM Override' => new List<String>{'Co_Owner__c', 'Opp_PLS_ETM_Area__c', 'Opp_PLS_ETM_Region__c', 'Opp_PLS_ETM_Territory__c', 'Opp_PLS_ETM_Theatre__c', 'Rubrik_Co_Sales_Engineer__c'},
                    'SaaS ETM Override' => new List<String>{ 'SaaS_Co_Owner__c', 'Opp_PLS_SaaS_ETM_Area__c', 'Opp_PLS_SaaS_ETM_Region__c', 'Opp_PLS_SaaS_ETM_Territory__c', 'Opp_PLS_SaaS_ETM_Theatre__c'},
                    'NCD ETM Override' => new List<String>{'NCD_Co_Owner__c', 'Opp_PLS_NCD_ETM_Area__c', 'Opp_PLS_NCD_ETM_Region__c', 'Opp_PLS_NCD_ETM_Territory__c', 'Opp_PLS_NCD_ETM_Theatre__c'}
                };
                Map<Id, Opportunity> coOwnerOppSplitMap = new Map<Id, Opportunity> ();
                //SAL26-1340 END
                for(Opportunity vOpt : updateListNEw) {
                    // Prevent updating child split opportunities if they are in "7 Closed Lost" stage
                    if(!(vOpt.split_percentage__c == 0 && vOpt.stagename == '7 Closed Lost')){ //SAL26-258 
                        System.debug(LoggingLevel.DEBUG,'@@Processing vOpt: '+vOpt.Id + ' with stage: ' + vOpt.StageName);
                        //SAL25-166
                        String plsAERole = uIdToPLSRoleMap != null && uIdToPLSRoleMap.containsKey(vOpt.OwnerId) ? uIdToPLSRoleMap.get(vOpt.OwnerId) : null;
                        //vOpt.PLS_AE_ETM_Role_Name__c = plsAERole; //removed for PL26-21
                        //ETM-182: TART update on Opp Splits
                        vOpt.Territory2Id = vOpt.Territory2Id__c = vOpt.ETM_Theatre__c = vOpt.ETM_Area__c = vOpt.ETM_Region__c = vOpt.ETM_Territory__c = vOpt.CDM_Theatre__c = vOpt.CDM_Area__c = vOpt.CDM_Region__c = vOpt.CDM_Territory__c = null;
                        if(ownerTerrIdMap.containsKey(vOpt.OwnerId) && ownerTerrIdMap.get(vOpt.OwnerId) != null){
                            UserTerritory2Association utaTemp = ownerTerrIdMap.get(vOpt.OwnerId);
                            //SAL25-166
                            vOpt.Territory2Id = plsAERole!=null ? accTerrId : utaTemp.Territory2Id;
                            vOpt.Territory2Id__c = plsAERole!=null ? accTerrId : utaTemp.Territory2Id;
                            vOpt.ETM_Theatre__c = plsAERole!=null ? primaryOpportunity.Account.ETM_Theatre__c : utaTemp.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            vOpt.ETM_Area__c = plsAERole!=null ? primaryOpportunity.Account.ETM_Area__c : utaTemp.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                            vOpt.ETM_Region__c = plsAERole!=null ? primaryOpportunity.Account.ETM_Region__c : utaTemp.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                            vOpt.ETM_Territory__c = plsAERole!=null ? primaryOpportunity.Account.ETM_Territory__c : utaTemp.Territory2.Internal_Territory_Name__c;
                            //SAL24-245
                            //vOpt.CDM_Theatre__c = utaTemp.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c;
                            //vOpt.CDM_Area__c = utaTemp.Territory2.ParentTerritory2.ParentTerritory2.Channel_Territory__c;
                            //vOpt.CDM_Region__c = utaTemp.Territory2.ParentTerritory2.Channel_Territory__c;
                            //vOpt.CDM_Territory__c = utaTemp.Territory2.Channel_Territory__c;
                        }
                        if(!vOpt.SE_Misaligned__c){
                            //SAL25-166
                            String plsSEOpptyRoleNameKey = accAdaptiveId + plsAERole?.replace('AE','SE');
                            String plsSEGenericRoleNameKey = accAdaptiveId + 'PLS SE';
                            String plsRSE = adaptiveIdRolePLSSEMap.containsKey(plsSEOpptyRoleNameKey) ? adaptiveIdRolePLSSEMap.get(plsSEOpptyRoleNameKey) :
                                            adaptiveIdRolePLSSEMap.containsKey(plsSEGenericRoleNameKey) ? adaptiveIdRolePLSSEMap.get(plsSEGenericRoleNameKey) : null;
                            //SF-8995
                            //vOpt.Rubrik_Sales_Engineer__c = terrIdSEMap.get(vOpt.Territory2Id); 
                            String parentSETerrId = vOpt.Territory2Id != null ? terrToRegionSETerrIdMap.get(vOpt.Territory2Id) : null;
                            //SAL25-166
                            vOpt.Rubrik_Sales_Engineer__c = plsAERole!=null ? plsRSE : vOpt.Territory2Id != null && terrIdSEMap.get(vOpt.Territory2Id) != null ? 
                                                            terrIdSEMap.get(vOpt.Territory2Id) : 
                                                            parentSETerrId != null && terrIdSEMap.get(parentSETerrId) != null ? terrIdSEMap.get(parentSETerrId) : null ;
                        }
                        //PL26-40 start//PL26-122 added Non_Core_Adaptive_Id__c
                        // SAL26-1340 - Start
                        Set<String> primaryOverrides = String.isBlank(vOpt.PLS_ETM_Overrides__c) ? new Set<String>() : new Set<String>(vOpt.PLS_ETM_Overrides__c.split(';'));
                        Set<String> splitOverrides = String.isBlank(primaryOpportunity.PLS_ETM_Overrides__c) ? new Set<String>() : new Set<String>(primaryOpportunity.PLS_ETM_Overrides__c.split(';'));
        
                        if (vOpt.ETM_Theatre__c == primaryOpportunity.ETM_Theatre__c) {
                            for (String overrideKey : overrideToPLSFields.keySet()) {
                                if (primaryOverrides.contains(overrideKey) || splitOverrides.contains(overrideKey)) continue; //SAL26-1340
                                vOpt = OpportunityUtil.setPLSCoOwnerFields(vOpt, primaryOpportunity, overrideToPLSFields.get(overrideKey));
                                oppETMOverridesSetIds.add(vOpt.Id);
                                coOwnerOppSplitMap.put(vOpt.Id,vOpt);
                            }
                            for (String coOwnerField : coOwnerFields) {
                                Id userId = (Id) vOpt.get(coOwnerField);
                                if (userId != null) {
                                    coOwnerUserIds.add(userId);
                                }
                            }






                        }
                        // SAL26-1340 - End
                        if(vOpt.Id != null) {
                            updateOpt.add(vOpt);
                            //SF-11236
                            splitOppList.add(vOpt);
                            //SAL26-258
                            if(!OldchildoppIdStageMap.isEmpty() && OldchildoppIdStageMap.containskey(vOpt.Id)){
                                if(OldchildoppIdStageMap.get(vOpt.Id) == 0 && vOpt.split_percentage__c > 0){
                                    createOppOLIset.add(vOpt.Id);
                                    createOppInst.add(vOpt); //create opplineitem
                                }else if(OldchildoppIdStageMap.get(vOpt.Id) > 0 && vOpt.split_percentage__c == 0){
                                    deleteOppOLIset.add(vOpt.Id); //delete opplineitems
                                }
                            }
                            //SAL26-258
                            } else {
                                insertOpt.add(vOpt);
                            }
                    }
                }
                //SAL26-1340 START
                if(!coOwnerUserIds.isEmpty()){
                    Map<Id, List<UserTerritory2Association>> userToUTAListMap = OpportunityObjectTriggerHelper.buildUserToUTAMap(coOwnerUserIds);
                    if (!oppETMOverridesSetIds.isEmpty()){
                        OpportunityObjectTriggerHelper.setPLSForETMOverridesAndSplitOpp(userToUTAListMap, oppETMOverridesSetIds, coOwnerOppSplitMap, true);
                    }
                }
                //SAL26-1340 END
                List<Database.SaveResult> saveResult;
                //SF-10455
                Integer i= 0;
                Set<Id> oppIds = new Set<Id>();
                
                if(!insertOpt.isEmpty()) {
                    String errMsg = 'Error - ';
                    saveResult = Database.insert(insertOpt, dml);
                    for(Database.SaveResult sResult: saveResult){
                        if(!sResult.isSuccess()){
                            for(Database.Error err : sResult.getErrors()) {
                                errMsg = errMsg+err.getMessage()+' at Fields : '+err.getFields()+'. ';
                                System.debug(LoggingLevel.DEBUG,'Error - '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields());
                            }
                            throw new AuraHandledException(errMsg);
                            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, sResult.getErrors().get(0).getMessage()));
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
                    
                }

                primaryOpportunity.split__c = true;
                if(primaryOpportunity.split_amount__c > 0) {
                    primaryOpportunity.Split_percentage__c = null;
                } else {
                    primaryOpportunity.split_amount__c = null;
                }
                updateOpt.add(primaryOpportunity);
                if(!updateOpt.isEmpty()) {
                    String errMsg = 'Error -at Id ';
                    Integer k=0;
                    saveResult = Database.update(updateOpt, dml);
                    for(Database.SaveResult sResult: saveResult){
                        if(!sResult.isSuccess()){
                            for(Database.Error err : sResult.getErrors()) {
                                errMsg = errMsg+updateOpt.get(k).Id+' value: '+updateOpt.get(k).split_percentage__c+' '+err.getMessage()+' at Fields : '+err.getFields()+'. ';
                                System.debug(LoggingLevel.DEBUG,'Error - '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields());
                            }
                            throw new AuraHandledException(errMsg);
                            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, sResult.getErrors().get(0).getMessage()));
                        }
                    }
                }
                
                if(!assignOppTeamUserIds.isEmpty() || !removeOppTeamUserIds.isEmpty() || !prevOwnerIdSet.isEmpty())
                    assignOppTeam(assignOppTeamUserIds,removeOppTeamUserIds,primaryOpportunity.Id,prevOwnerIdSet);
                if(existingSplitsMAp != null && existingSplitsMAp.size()>0){
                    delete existingSplitsMAp.values();
                }
                flowControll.opportunityTriggerHandler = true;
		if(!oppIds.isEmpty()) {
	              splitOppMap.putAll(splitOppList);
	                primaryOpportunityMap.put(primaryOpportunity.Id, primaryOpportunity);
	                createPartnerRelation(splitOppMap, primaryOpportunityMap,'Sales Split');
	                /*if(!insertOptMap.isEmpty()){ //SAL26-72
	                    OpportunityObjectTriggerHelper.syncOpportunityPartnerRelations(insertOptMap,null);   
	                }*/
            	}
                //Insert Opportunity Line Item
                List<OpportunityLineItem> optySplitProductList = OpportunitySplitHelper.manageOptySplitLineItem(primaryOpportunity, splitAmounts);
                //SF-11236 : To create positive OPPTY-SPLIT productlines for child split opportunities
                Id pbeId = !optySplitProductList.isEmpty() ? optySplitProductList[0].PricebookEntryId : null;
                optySplitProductList.addAll(createOpptySplitProduct(splitOppList,pbeId));
                //OPPPTYSPLIT-2,OPPPTYSPLIT-5
                skipOpplineItemTriggerCreationLogic = true;
                oppIds.addAll(createOppOLIset); //SAL26-258
                insertOpt.addAll(createOppInst); //SAL26-258
                if(!insertOpt.isEmpty()){ //SAL26-258
                    System.enqueueJob(new salesSplitChildOpplinesCreation(primaryOpportunity,insertOpt, oppIds));
                }
                if(!updateOpt.isEmpty()){
                    system.enqueueJob(new salesSplitPopulateAppliedsplitController(updateOpt));
                }
                if(!deleteOppOLIset.isEmpty()){ //SAL26-258
                    delete [Select Id,OpportunityId from OpportunityLineItem where OpportunityId IN :deleteOppOLIset AND ProductCode != 'OPTY-SPLIT'];
                }
                upsert optySplitProductList;
            }
            
            emailAddresses.add(primaryOpportunity.OwnerId);
            EmailTemplate vEmailTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName ='Notify_Opty_Split_Owners'];
            if(vEmailTemplate.Id != null){
                EmailHelper.sendEmail(vEmailTemplate.Id, emailAddresses, primaryOpportunity.Id);
            }
            System.debug(LoggingLevel.DEBUG,'@@END SAVE ITEM:\n\n\n');
            //SAL25-668
            /*if(isSplitException){
                createCCRrecord(primaryOpp,wrapperList,primaryOpportunity,isglobal);
            }*/
            successSave = true;
            return successSave;
        }
    /*public static void createCCRrecord(opportunity primaryOpp,List<wrapClass> wrapperList,opportunity primaryOpportunity,Boolean isglobal){
        string comments = '';
        Id salesrectypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Sales CCR').getRecordTypeId();
        set<string> ownerIdSet = new set<string>();
        Map<string,string> userMgrMap = new Map<string,string>(); 
        
        CCR__c ccr = new CCR__c(Opportunity__c=primaryOpportunity.Id,CCR_Split_Exception__c=true,Affective_Person__c=primaryOpportunity.ownerId,recordTypeId=salesrectypeId);
        ccr.CCR_Type__c = 'Compensation Exception';
        if(isglobal){
            ccr.Justifications__c = 'Global Commissionable Credit Exception';
        }else{
            ccr.Justifications__c = 'Commissionable credit exception';
        }
        ccr.Effective_Date__c = system.today();
        ccr.User__c = 'Pending';
        comments = 'Commission/Credit Splits are : '+primaryOpp.Commission_Credit_Split_Split_screen__c+'%, ';
        
        ownerIdSet.add(primaryOpportunity.ownerId);
        for(wrapClass wrapIns : wrapperList){
            Opportunity oppInst = wrapIns.splitopp;
            ownerIdSet.add(oppInst.ownerId);
        }
        if(!ownerIdSet.isEmpty()){
            for(User usr : [select Id,Name,ManagerId,Manager.isActive from User where Id IN: ownerIdSet]){
                userMgrMap.put(usr.Id,usr.ManagerId);
            }
        }
        if(!userMgrMap.isEmpty()){
            ccr.Affected_Person_Manager__c = userMgrMap.get(primaryOpportunity.ownerId);
               for(Integer i = 0; i< wrapperList.size(); i++){
                  Opportunity oppInst = wrapperList[i].splitopp; 
                   if(i == 0){
                       ccr.Affected_Person_2__c = oppInst.ownerId;
                       ccr.Affected_Person_2_Manager__c = userMgrMap.get(oppInst.ownerId);
                   }
                   if(i == 1){
                       ccr.Affected_Person_3__c = oppInst.ownerId; 
                       ccr.Affected_Person_3_Manager__c = userMgrMap.get(oppInst.ownerId);
                   }
                   if(i == 2){
                       ccr.Affected_Person_4__c = oppInst.ownerId; 
                       ccr.Affected_Person_4_Manager__c = userMgrMap.get(oppInst.ownerId);
                   }
                   if(i == 3){
                       ccr.Affected_Person_5__c = oppInst.ownerId; 
                       ccr.Affected_Person_5_Manager__c = userMgrMap.get(oppInst.ownerId);
                   }
                   if(i == 4){
                       ccr.Affected_Person_6__c = oppInst.ownerId; 
                       ccr.Affected_Person_6_Manager__c = userMgrMap.get(oppInst.ownerId);
                   }
                   comments = comments+oppInst.Commission_Credit_Split_Split_screen__c+'%, ';
                   ownerIdSet.add(oppInst.ownerId);
            } 
        }
        if(comments.endsWith(', ')){
            comments = comments.removeEnd(', ');
        }
        ccr.Comment__c = comments;
        insert ccr;
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(ccr.Id);
        req.setSubmitterId(UserInfo.getUserId());
        
        Approval.ProcessResult result = Approval.process(req);
    }
    public static Boolean validatePendingCCR(opportunity primaryOpportunity){
        Boolean isValid = true;
        for(CCR__c ccr : [select Id,Opportunity__c,User__c from CCR__c where Opportunity__c =:primaryOpportunity.Id and (User__c ='Pending' OR User__c ='Submitted')]){
            isValid = false;
        }
        return isValid;
    }*/
/**
* @description insert Opportunity contact role for split opportunity-SF-10455
* @param OppIds
*/
        public static void createOpportunityContactRole(Set<Id> OppIds){
            List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
            for(Opportunity opp : [Select Id, Initial_Contacts_Name__c from Opportunity where Id in :OppIds and Initial_Contacts_Name__c != null]) {
                ocrList.add(new OpportunityContactRole(isPrimary = true, OpportunityId = opp.Id, ContactId = opp.Initial_Contacts_Name__c));
            }
            if(!ocrList.isEmpty()){
                insert ocrList;
            }
        }
        
/**
* @description insert Opportunity team memer to opportunity-SAL23-229 
* @param assignOppTeamIds
* @param removeOppTeamIds
* @param oppId
* @param prevOwnerIdSet
*/
         public static void assignOppTeam(Set<Id> assignOppTeamIds, Set<Id> removeOppTeamIds, Id oppId, Set<Id> prevOwnerIdSet){
            List<OpportunityTeamMember> removemembersList = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> insertmembersList = new List<OpportunityTeamMember>();
            
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
/**
* @description create split opportunity product- SF-11236
* @param SplitOpps
* @param pbeId
* @return List<OpportunityLineItem>
*/
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
                                                                                    //Applied_Split__c = null,
                                                                                    isSplit__c = true,
                                                                                    TotalPrice = opp.Amount);
                    splitOppLines.add(splitOppLineItem);
                }
            }
            else {delete oppToOLIMap.values();}
            return splitOppLines;
        }
        
/**
* @description get mapping details from wrapper- SF-11236
* @param isglobal
* @return List<mappingtblwrapClass>
*/
   @AuraEnabled     
   public static List<mappingtblwrapClass> getmappingDetails(Boolean isglobal){
        List<mappingtblwrapClass> commisionSplitWrapList = new  List<mappingtblwrapClass>();
        for(Auto_populate_Commission_Split__mdt meta : [select Id,Split__c,Commission_Credit_Split__c,isGlobal__c from Auto_populate_Commission_Split__mdt where isGlobal__c =:isglobal]){
            commisionSplitWrapList.add(new mappingtblwrapClass(meta.Split__c,meta.Commission_Credit_Split__c,meta.isGlobal__c));
        } 
        return commisionSplitWrapList;   
     }
/**
* @description create partner relation on split opportunities- SAL26-72
* @param splitOppMap
* @param primaryOpportunityMap
* @param oppType
*/
    public static void createPartnerRelation(Map<Id, Opportunity> splitOppMap, Map<Id, Opportunity>  primaryOpportunityMap, string oppType) {
        List<Partner_Relation__c> relationsToUpsert = new List<Partner_Relation__c>();
        List<Partner_Relation__c> parentRelationList = new List<Partner_Relation__c>();
        Map<Id, List<Partner_Relation__c>> childRelationMap = new Map<Id,List<Partner_Relation__c>>();
        Map<Id,Id> parentchildOppIdMap = new Map<Id,Id>();
        Set<Id> oppIdSet = new Set<Id> ();
        Set<String> noDupInvoTypes = new Set<String> {'Transacting Partner','Distributor','Sourcing Partner'};
        Id parentdebookOppId;
        
        for(Id oppId : primaryOpportunityMap.keyset()) { //Debook happens only for 1 Opp at any time
            parentdebookOppId = oppId;
        }
        for(Opportunity opp : splitOppMap.values()) {
            oppIdSet.add(opp.Id);
            if(oppType == 'Sales Split'){
                if(opp.Opportunity_Split_Parent__c != null){
                    parentchildOppIdMap.put(opp.Id,opp.Opportunity_Split_Parent__c);
                }
            }else if(oppType == 'Debooking' && parentdebookOppId != null){
                parentchildOppIdMap.put(opp.Id,parentdebookOppId);
            }
         }
        oppIdSet.addAll(primaryOpportunityMap.keySet());
        // Fetch existing Partner_Relation__c records related to the given opportunities
        for(Partner_Relation__c relation : [SELECT Id, Opportunity__c, Involvement_Type__c, Partner_Account__c, Parent_Partner_Relation__c,Opportunity__r.Opportunity_Split_Parent__c, Influence_Sub_Type__c  FROM Partner_Relation__c WHERE Opportunity__c IN :oppIdSet  AND Involvement_Type__c != 'Incumbent Partner']) {
            if(primaryOpportunityMap.containsKey(relation.Opportunity__c)){
                parentRelationList.add(relation);
            }else{
                if (!childRelationMap.containsKey(relation.Opportunity__c)) {
                    childRelationMap.put(relation.Opportunity__c, new List<Partner_Relation__c>());
                }
                childRelationMap.get(relation.Opportunity__c).add(relation);
            }
        }
        Boolean isExists = false;
        for(Partner_Relation__c parentPR : parentRelationList){
            for(Id childOppId : parentchildOppIdMap.keyset()){
                isExists = false;
                if(parentchildOppIdMap.get(childOppId) == parentPR.Opportunity__c){
                    if(childRelationMap.containskey(childOppId)){
                        for(Partner_Relation__c childPR : childRelationMap.get(childOppId)){
                            if(childPR.Partner_Account__c == parentPR.Partner_Account__c && childPR.Involvement_Type__c == parentPR.Involvement_Type__c && childPR.Influence_Sub_Type__c == parentPR.Influence_Sub_Type__c ){
                                isExists = true;
                            }else if(childPR.Involvement_Type__c == parentPR.Involvement_Type__c && noDupInvoTypes.contains(parentPR.Involvement_Type__c) && childPR.Partner_Account__c != parentPR.Partner_Account__c){
                                relationsToUpsert.add(new Partner_Relation__c(Id=childPR.Id, Partner_Account__c = parentPR.Partner_Account__c, Influence_Sub_Type__c = parentPR.Influence_Sub_Type__c));
                                isExists = true;
                            }
                        }
                    }
                    if(!isExists){ //No matching PR record with Parent found
                        relationsToUpsert.add(new Partner_Relation__c(Opportunity__c = childOppId, Parent_Partner_Relation__c=parentPR.Id, Partner_Account__c = parentPR.Partner_Account__c, Involvement_Type__c = parentPR.Involvement_Type__c, Influence_Sub_Type__c = parentPR.Influence_Sub_Type__c));
                    }
                }
            }
        }
        try{
            // Perform upsert operation to update or insert partner relations
            if (!relationsToUpsert.isEmpty()) {
                Database.upsert(relationsToUpsert, false);
            }
        }catch(Exception e){
            system.debug(LoggingLevel.DEBUG, e.getMessage()+' at line '+e.getLineNumber()+'Exception/error PR record creation createPartnerRelation method in splitlwc failed');
        }
    }
/**
* @description wrapper class mapping for split opportunity
*/
    public class mappingtblwrapClass{
        @AuraEnabled public decimal split;
        @AuraEnabled public decimal csplit;
        @AuraEnabled public boolean isgbl;
        /**
        * @description wrapper class contsructor
        * @param split1
        * @param csplit1
        * @param isglobal1
        */
        public mappingtblwrapClass(decimal split1,decimal csplit1,boolean isglobal1){
                split = split1;
                csplit = csplit1;
                isgbl = isglobal1;
        }
    }    
/**
* @description wrapper class mapping for split opportunity
*/
    public class wrapClass{
            @AuraEnabled public Opportunity splitopp;
            @AuraEnabled public integer index;
            /**
            * @description wrapper class contsructor
            * @param splitopp1
            * @param index1
            */           
            public wrapClass(Opportunity splitopp1,integer index1){
                splitopp = splitopp1;
                index = index1;
            }
        }
 /**
* @description wrapper class primary opportunity
*/
        public class primaryOppWrap{
            @AuraEnabled public string errMsg;
            @AuraEnabled public string variant;
            @AuraEnabled public Opportunity primaryopp;
            @AuraEnabled public Double optyTotalValue;
            @AuraEnabled public Decimal staticAmount;
            @AuraEnabled public Boolean isglobal;
            @AuraEnabled public Double newoptyTotalValue;
            @AuraEnabled public Double newoptyACVValue;
            /**
            * @description wrapper class contsructor
            * @param errMsg1
            * @param variant1
            * @param primaryopp1
            * @param optyTotalValue1
            * @param staticAmount1
            * @param isglobal1
            * @param newoptyTotalValue1
            * @param newoptyACVValue1
            */  
            public primaryOppWrap(string errMsg1,string variant1,opportunity primaryopp1,Double optyTotalValue1,Decimal staticAmount1, Boolean isglobal1, Double newoptyTotalValue1, Double newoptyACVValue1){
                errMsg = errMsg1;
                variant = variant1;
                primaryopp = primaryopp1;
                optyTotalValue = optyTotalValue1;
                staticAmount = staticAmount1;
                isglobal = isglobal1;
                newoptyTotalValue = newoptyTotalValue1;
                newoptyACVValue = newoptyACVValue1;
            } 
        }
    }