/*
* Class Name :- PAGServiceUtility
* Author :- Rubrik Dev
* Created Date :- Aug 29th , 2023
* Description : PAG- :- Utility Class for PAGService API and PQLService api
* TestClass   : PAGServiceTest
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
* Rubrik Dev           01/10/2025       SAL25-819 added methods for PQL service
* ********************Modification Log *****************************************************************************
*/
public class PAGServiceUtility2{

    public static ID pagID = null;
    /*
    *********************************************************
    @Method Name    : createUpdatePAGDetails
    @author         : Rubrik Dev
    @description    : Method to control sequence of PAG,Oppty and Entitlement Creation
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */
    public static PAGResponseWrapper createUpdatePAGDetails(PAGRequestWrapper pagReqWrapper,String requestBody){

        PAGResponseWrapper pagResponse = new PAGResponseWrapper();
        
        if(pagReqWrapper != null){


            //Declare all non collection variables below

            //Declare all collection variables below
            Set<String> setTrialID = new Set<String>();
            Set<String> setPQLExternalID = new Set<String>();//SAL25-819 PQL Service
            Map<String,Opportunity> trialIdOpportunityMap = new Map<String,Opportunity>();
            Map<String,Product_Assisted_Growth__c> trialIDPagMap = new Map<String,Product_Assisted_Growth__c>();
            Map<String,Product_Assisted_Growth__c> externalIDPqlMap = new Map<String,Product_Assisted_Growth__c>();// SAL25-819
            Map<String,Product_Assisted_Growth__c> existingtrialIDPagMap = new Map<String,Product_Assisted_Growth__c>();
            Map<String,Account> mapAccount = new Map<String,Account>();


            //Loop1 on PAG Wrapper to collect Trial IDs and account IDs, also add errors for pagResponse wherever necessary
            if(pagReqWrapper.pags != null && !pagReqWrapper.pags.isEmpty()){
                for(PAGRequestWrapper.PAGs pagWrapperIns : pagReqWrapper.pags){
                    Product_Assisted_Growth__c pagRequestRecord = pagWrapperIns.pagWrapper.pagRecord;
                    //Below if is added to check if it's a PQL request or not SAL25-819
                    if(pagRequestRecord.Request_Type__c == PAGServiceConstants.PQL){
                         //Both PQL External ID and PQL ID are present
                         if(String.isNotBlank(pagRequestRecord.PQL_External_Id__c) && String.isNotBlank(pagRequestRecord.Id)){
                            
                            if(pagResponse.pqlExternalIDErrorMap == null){
                                pagResponse.pqlExternalIDErrorMap = new Map<String,String>();
                            }
                            pagResponse.pqlExternalIDErrorMap.put(pagRequestRecord.PQL_External_Id__c,PAGServiceConstants.MSG_SEND_EXTERNALORPQL_ID);

                        }//Use Case 2 from Design Doc . External Id is present but Account ID is not. 
                        else if(String.isBlank(pagRequestRecord.Account__c) && String.isNotBlank(pagRequestRecord.PQL_External_Id__c)){
                            if(pagResponse.pqlIDErrorMap == null){
                                pagResponse.pqlIDErrorMap = new Map<String,String>();
                            }
                            pagResponse.pqlIDErrorMap.put(pagRequestRecord.PQL_External_Id__c,PAGServiceConstants.MSG_SEND_ACCOUNT_ID_CAN_NOT_BE_BLANK);                            

                        }
                        //Use Case 2 from Design Doc . External ID is present but PQL ID is not. This will be applicable for Post Request
                        else if(String.isNotBlank(pagRequestRecord.PQL_External_Id__c) && String.isBlank(pagRequestRecord.Id)){

                            //setTrialID.add(pagRequestRecord.PQL_External_Id__c);
                            setPQLExternalID.add(pagRequestRecord.PQL_External_Id__c);
                            mapAccount.put(pagRequestRecord.Account__c,null);

                        }
                        //Use Case 3 from Design Doc . PQL ID is present but External ID is not. This will be applicable for Patch Request
                        else if(String.isBlank(pagRequestRecord.PQL_External_Id__c) && String.isNotBlank(pagRequestRecord.Id)){

                            //create PQL ID PQL MAP
                            externalIDPqlMap.put(pagRequestRecord.Id,pagWrapperIns.pagWrapper.pagRecord);
                        }

                    }else{
                        //Both Trial ID and PAG ID are present
                        if(String.isNotBlank(pagRequestRecord.Trial_ID__c) && String.isNotBlank(pagRequestRecord.Id)){
                            
                            if(pagResponse.trialIDErrorMap == null){
                                pagResponse.trialIDErrorMap = new Map<String,String>();
                            }
                            pagResponse.trialIDErrorMap.put(pagRequestRecord.Trial_ID__c,PAGServiceConstants.MSG_SEND_TRIALORPAG_ID);

                        }
                        //Use Case 1 from Design Doc . Trial ID is present but PAG ID is not. This will be applicable for Post Request
                        else if(String.isNotBlank(pagRequestRecord.Trial_ID__c) && String.isBlank(pagRequestRecord.Id)){

                            setTrialID.add(pagRequestRecord.Trial_ID__c);
                            mapAccount.put(pagRequestRecord.Account__c,null);

                        }
                        //Use Case 2 from Design Doc . PAG ID is present but Trial ID is not. This will be applicable for Patch Request
                        else if(String.isBlank(pagRequestRecord.Trial_ID__c) && String.isNotBlank(pagRequestRecord.Id)){

                            //create PAG ID PAG MAP
                            trialIDPagMap.put(pagRequestRecord.Id,pagWrapperIns.pagWrapper.pagRecord);
                        }
                    }
                }
            }

             //Query Existing PQL Details SAL25-819
            if(setPQLExternalID != null && !setPQLExternalID.isEmpty()){

                existingtrialIDPagMap = PAGSOQLUtility.getPQLDetails(setPQLExternalID);
            }
            //Query Existing PAG  Details
            if(setTrialID != null && !setTrialID.isEmpty()){

                existingtrialIDPagMap = PAGSOQLUtility.getPAGDetails(setTrialID);
            }
            //Query Account details
            if(mapAccount != null && !mapAccount.isEmpty()){
                mapAccount = PAGSOQLUtility.getAccountDetails(mapAccount);
            }
            //system.debug('setTrialID   '+setTrialID);
            //system.debug('existingtrialIDPagMap    '+existingtrialIDPagMap);


            //Loop 2 : Separate existing PAGs with new PAG requests. For New PAGs , create opportunity map. For Existing, return back trialIDPAG map with PAG Details
            if(pagReqWrapper.pags != null && !pagReqWrapper.pags.isEmpty()){
                for(PAGRequestWrapper.PAGs pagWrapperIns : pagReqWrapper.pags){
                    Product_Assisted_Growth__c pagRequestRecord = pagWrapperIns.pagWrapper.pagRecord;
                    //Below if is added to check if it's a PQL request or not SAL25-819
                    if(pagRequestRecord.Request_Type__c == PAGServiceConstants.PQL && setPQLExternalID != null && !setPQLExternalID.isEmpty() && String.isNotBlank(pagRequestRecord.PQL_External_Id__c) && setPQLExternalID.contains(pagRequestRecord.PQL_External_Id__c)){
                        if(existingtrialIDPagMap == null || (existingtrialIDPagMap != null && !existingtrialIDPagMap.containsKey(pagRequestRecord.PQL_External_Id__c))){

                            externalIDPqlMap.put(pagRequestRecord.PQL_External_Id__c,pagWrapperIns.pagWrapper.pagRecord);
                            trialIdOpportunityMap = createOpportunity(trialIdOpportunityMap,pagWrapperIns,mapAccount);
                        }else{
                            if(pagResponse.externalIdPqlMap == null){
                                pagResponse.externalIdPqlMap = new Map<String,Product_Assisted_Growth__c>();
                            }
                            pagResponse.externalIdPqlMap.put(pagRequestRecord.PQL_External_Id__c,existingtrialIDPagMap.get(pagRequestRecord.PQL_External_Id__c));

                        }
                    }
                    //system.debug('pagRequestRecord.Trial_ID__c   '+pagRequestRecord.Trial_ID__c);
                    else if(setTrialID != null && !setTrialID.isEmpty() && String.isNotBlank(pagRequestRecord.Trial_ID__c) && setTrialID.contains(pagRequestRecord.Trial_ID__c)){
                        if(existingtrialIDPagMap == null || (existingtrialIDPagMap != null && !existingtrialIDPagMap.containsKey(pagRequestRecord.Trial_ID__c))){

                            trialIDPagMap.put(pagRequestRecord.Trial_ID__c,pagWrapperIns.pagWrapper.pagRecord);
                            trialIdOpportunityMap = createOpportunity(trialIdOpportunityMap,pagWrapperIns,mapAccount);
                            //system.debug('trialIdOpportunityMap   '+trialIdOpportunityMap);
                        }else{
                            //add existingtrialIDPagMap to responsewrapper
                            if(pagResponse.trialIdPagMap == null){
                                pagResponse.trialIdPagMap = new Map<String,Product_Assisted_Growth__c>();
                            }
                            pagResponse.trialIdPagMap.put(pagRequestRecord.Trial_ID__c,existingtrialIDPagMap.get(pagRequestRecord.Trial_ID__c));

                        }
                    }
                }
            }
            //system.debug('trialIdOpportunityMap   '+trialIdOpportunityMap);
            // SAL25-819 PQL API Service
            if(externalIDPqlMap != null && !externalIDPqlMap.isEmpty()){
                pagResponse = insertOpportunity(externalIDPqlMap,trialIdOpportunityMap,pagResponse,'PQL',mapAccount);
            }
            if(trialIDPagMap != null && !trialIDPagMap.isEmpty()){
                pagResponse = insertOpportunity(trialIDPagMap,trialIdOpportunityMap,pagResponse,'',null);
            }

            //Upsert Entitlements
            if(pagReqWrapper.Entitlements != null && !pagReqWrapper.Entitlements.isEmpty()){
                pagResponse = upsertEntitlement(pagReqWrapper,pagResponse); 
            }
        }
        pagResponse.errorCode = PAGServiceConstants.MSG_SUCCESSFULL_UPSERT_DATA_CODE;
        //pagResponse.message = PAGServiceConstants.MSG_SUCCESSFULL_UPSERT_DATA;
        system.debug(LoggingLevel.DEBUG,'pagResponse     '+pagResponse);
        return pagResponse;
    }
    /** 
     * @description SAL25-819 Created separeted method to insert opportunity
     * @param trialIDPagMap
     * @param trialIdOpportunityMap
     * @param pagResponse
     * @param requestType
     * @param accMap
     * @return pagResponse
     */
    public static PAGResponseWrapper insertOpportunity(Map<String,Product_Assisted_Growth__c> trialIDPagMap,Map<String,Opportunity> trialIdOpportunityMap, PAGResponseWrapper pagResponse, String requestType,Map<String,Account> accMap){
        List<Opportunity> opptyList = new List<Opportunity>();
        if(trialIDPagMap != null && !trialIDPagMap.isEmpty()){
            //Insert Opportunity
            List<String> trialIDList = new List<String>();
            List<Opportunity> opportunityList = new List<Opportunity>();
            //Create the lists so that indices can be matched between both lists after database dml
            for(String trialID : trialIdOpportunityMap.keyset()){
                trialIDList.add(trialID);
                opportunityList.add(trialIdOpportunityMap.get(trialID));

            }
            // SAL25-819 PQL API Service
            if(requestType == 'PQL'){
                for(Opportunity opp : opportunityList){
                    If(opp.PLS_AE_ETM_Role_Name__c == 'SaaS AE' || opp.PLS_AE_ETM_Role_Name__c == 'NAS AE'){
                        opptyList.add(opp);
                    }
                }
                if(!opptyList.isEmpty() && accMap != null){
                    getCoOwnerDetails(accMap,opptyList);
                    
                }                
            }
            List<string> opptyIds = new List<string>();
            List<Database.SaveResult> optyResults = Database.insert(opportunityList,false);
            for (Integer i = 0; i < optyResults.size(); i++ ) {
                if (!optyResults[i].isSuccess() ) {
                    if(requestType == 'PQL'){
                        if(pagResponse.pqlIDErrorMap == null){
                            pagResponse.pqlIDErrorMap = new Map<String,String>();
                        }
                        pagResponse.pqlIDErrorMap.put(trialIDList[i],optyResults[i].getErrors()[0].getMessage());
                    }else{
                        if(pagResponse.pagIDErrorMap == null){
                            pagResponse.pagIDErrorMap = new Map<String,String>();
                        }
                        pagResponse.pagIDErrorMap.put(trialIDList[i],optyResults[i].getErrors()[0].getMessage());
                    }
                    trialIDPagMap.remove(trialIDList[i]);
                }else{
                    /////////////////////////////////// SAL25-819
                    if(requestType == 'PQL'){
                        opptyIds.add(optyResults[i].getId());
                    }
                }
            }

            for(String trialID : trialIDPagMap.keySet()){
                if(trialIdOpportunityMap != null && trialIdOpportunityMap.containsKey(trialID)){
                    if(trialIdOpportunityMap.get(trialID).ID != null){
                        trialIDPagMap.get(trialID).Opportunity__c = trialIdOpportunityMap.get(trialID).ID;
                    }
                    //system.debug('entered here @ opportunity stamping');
                }
            }
            //system.debug('trialIDPagMap    before upsert' +trialIDPagMap);

            //Upsert PAGs
            if(trialIDPagMap != null && !trialIDPagMap.isEmpty()){
                pagResponse = upsertPAG(trialIDPagMap,pagResponse,requestType);
            }
            // SAL25-819 PQL API Service
            if(!opptyIds.IsEmpty()){
                List<OpportunityTeamMember> oppTeamMemberLstToInsert = new List<OpportunityTeamMember>(); 
                Map<Id,Opportunity> OpptyMap = new Map<Id,Opportunity>([Select Id,Name, Account.Name,Owner.Name, Owner.ManagerId,Owner.Manager.Email, OwnerId,Owner.Email,Rubrik_Sales_Engineer__r.Email,Account.Owner.Email,Account.Adaptive_Territory_Id__c,Co_Owner__c,Co_Owner__r.Email,(select id,Overage_Product_Type__c,Total_Used_Capacity__c,Usage_Dashboard__c from Product_Based_DealType__r) from opportunity where Id IN : opptyIds]);
                for(Opportunity opp : OpptyMap.values()){
                    if(opp.Co_Owner__c != null){
                    oppTeamMemberLstToInsert.add(new OpportunityTeamMember(OpportunityId = opp.Id,
                                                                            UserId = opp.Co_Owner__c,
                                                                            TeamMemberRole = 'Co-Owner',
                                                                            OpportunityAccessLevel = 'Edit'
                                                                            ));
                    }   
                }
                if(!oppTeamMemberLstToInsert.isEmpty()){
                    Database.insert(oppTeamMemberLstToInsert, false);
                }
                PQLOpptyCreationNotification.sendPQLCreationEmail(OpptyMap);
            }
        }
        return pagResponse;
    }
    /*
    *********************************************************
    @Method Name    : upsertPAG
    @author         : Rubrik Dev
    @description    : Creates PAG based on Polaris Request
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */

    public static PAGResponseWrapper upsertPAG(Map<String,Product_Assisted_Growth__c> trialIDPagMap,PAGResponseWrapper pagResponse, String requestType){
        
        List<String> trialIDList = new List<String>();
        List<Product_Assisted_Growth__c> pagList = new List<Product_Assisted_Growth__c>();
        Id pagRecordTypeId = Schema.SObjectType.Product_Assisted_Growth__c.getRecordTypeInfosByName().get(PAGServiceConstants.PAG).getRecordTypeId(); // SAL25-819
        Id pqlRecordTypeId = Schema.SObjectType.Product_Assisted_Growth__c.getRecordTypeInfosByName().get(PAGServiceConstants.PQL).getRecordTypeId(); // SAL25-819

        //Create the lists so that indices can be matched between both lists after database dml
        for(String trialID : trialIDPagMap.keyset()){
            trialIDList.add(trialID);
            Product_Assisted_Growth__c productBasedDealTypeObj = trialIDPagMap.get(trialID);// SAL25-819
            productBasedDealTypeObj.RecordTypeId = productBasedDealTypeObj.Request_Type__c == PAGServiceConstants.PQL ? pqlRecordTypeId : pagRecordTypeId;// SAL25-819
            pagList.add(productBasedDealTypeObj);// SAL25-819

        }     
        List<Database.upsertResult> pagResults = Database.upsert(pagList,false);

            for (Integer i = 0; i < pagResults.size(); i++ ) {
                if (!pagResults[i].isSuccess() ) {
                    if(trialIDList[i].length() > 18){
                        if(requestType == 'PQL'){
                            if(pagResponse.pqlExternalIDErrorMap == null){
                                pagResponse.pqlExternalIDErrorMap = new Map<String,String>();
                            }
                            pagResponse.pqlExternalIDErrorMap.put(trialIDList[i],pagResults[i].getErrors()[0].getMessage());
                        }else{
                            if(pagResponse.trialIdErrorMap == null){
                                pagResponse.trialIdErrorMap = new Map<String,String>();
                            }
                            pagResponse.trialIdErrorMap.put(trialIDList[i],pagResults[i].getErrors()[0].getMessage());
                        }
                        
                    }else if(trialIDList[i].length() == 18){
                        if(requestType == 'PQL'){
                            if(pagResponse.pqlIDErrorMap == null){
                                pagResponse.pqlIDErrorMap = new Map<String,String>();
                            }
                            pagResponse.pqlIDErrorMap.put(trialIDList[i],pagResults[i].getErrors()[0].getMessage());
                        }else{
                            if(pagResponse.pagIdErrorMap == null){
                                pagResponse.pagIdErrorMap = new Map<String,String>();
                            }
                            pagResponse.pagIdErrorMap.put(trialIDList[i],pagResults[i].getErrors()[0].getMessage());
                        }
                    }
                }else{
                    //system.debug('trialIDList[i]    '+trialIDList[i]);
                    //system.debug('pagList[i].Trial_ID__c    '+pagList[i].Trial_ID__c);
                    if(trialIDList[i].length() > 18 && requestType == 'PQL'){
                        if(pagResponse.externalIdPqlMap == null){
                            pagResponse.externalIdPqlMap = new Map<String,Product_Assisted_Growth__c>();
                        }
                        pagResponse.externalIdPqlMap.put(trialIDList[i],pagList[i]);
                        
                    }else if(trialIDList[i].length() > 18){
                        if(pagResponse.trialIdPagMap == null){
                            pagResponse.trialIdPagMap = new Map<String,Product_Assisted_Growth__c>();
                        }
                        pagResponse.trialIdPagMap.put(trialIDList[i],pagList[i]);
                    }/*else if(trialIDList[i].length() == 18){

                        //this should be moved to trial id and only in case of trial id received
                        pagResponse.trialIdPagMap.put(trialIDList[i],pagList[i]);
                    }*/
                }
            }

        return pagResponse;
    }
    /*
    *********************************************************
    @Method Name    : upsertEntitlement
    @author         : Rubrik Dev
    @description    : Creates/Updates Entitlment based on Polaris Request
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */
    public static PAGResponseWrapper upsertEntitlement(PAGRequestWrapper pagReqWrapper,PAGResponseWrapper pagResponse){

        List<Entitlement> entitlementList = new List<Entitlement>();
        List<String> rscIDList = new List<String>();
        Set<String> productNameSet = new Set<String>();

        for(PAGRequestWrapper.Entitlements entitlementWrapper : pagReqWrapper.entitlements){
            if(String.isNotBlank(entitlementWrapper.entWrapper.SKU)){
                productNameSet.add(entitlementWrapper.entWrapper.SKU.trim());
            }
        }

        Map<String,Entitlement> entitlementMap = PAGSOQLUtility.getEntitlementDetails(pagReqWrapper);
        Map<String,Product2> productMap = PAGSOQLUtility.getProductDetails(productNameSet);

        for(PAGRequestWrapper.Entitlements entitlementWrapper : pagReqWrapper.entitlements){
            Entitlement entRequestRec = entitlementWrapper.entWrapper.entitlementRecord;
            String SKU = entitlementWrapper.entWrapper.SKU;

            if(entRequestRec.RSC_Entitlement_Id__c != null){
                if(entitlementMap.containsKey(entRequestRec.RSC_Entitlement_Id__c)){
                    entRequestRec.Id = entitlementMap.get(entRequestRec.RSC_Entitlement_Id__c).Id;
                }
                if(String.isNotBlank(SKU) && productMap.containsKey(SKU.trim())){
                    entRequestRec.Product__c = productMap.get(SKU.trim()).Id;
                }
                entRequestRec.Type = PAGServiceConstants.ENTITLEMENT_TYPE;
                entRequestRec.Entitlement_Subtype__c = PAGServiceConstants.ENTITLEMENT_SUBTYPE;
                //TODO : if(pagResponse.pagIDErrorMap){ whenever pag id feild is created, check for this
                    //Create the lists so that indices can be matched between both lists after database dml
                    entitlementList.add(entRequestRec);
                    rscIDList.add(entRequestRec.RSC_Entitlement_Id__c);
                //}else{

                    //
                //}
                
            }            
            //system.debug('entWrapper.  '+entitlementWrapper.entWrapper.entitlementRecord);
        }
        List<Database.upsertResult> entResults = Database.upsert(entitlementList,false);

        for(Integer i = 0; i < entResults.size(); i++) {
            if(!entResults[i].isSuccess() ) {
                if(pagResponse.entitlementIDErrorMap == null){
                    pagResponse.entitlementIDErrorMap = new Map<String,String>();
                }
                pagResponse.entitlementIDErrorMap.put(rscIDList[i],entResults[i].getErrors()[0].getMessage());
            }
        }
        return pagResponse;
    }
    /** 
     * @description  Creates Polaris PAG Request
     * @param trialIdOpportunityMap
     * @param pagWrapperIns
     * @param mapAccount
     * @return trialIdOpportunityMap
     */
    public static Map<String,Opportunity> createOpportunity(Map<String,Opportunity> trialIdOpportunityMap,PAGRequestWrapper.PAGs pagWrapperIns,Map<String,Account> mapAccount){
        
        //Create Opty Instance and set field values
        Opportunity oppRecord = new Opportunity();
        oppRecord.RecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(PAGServiceConstants.OPPORTUNITY_SALES_RECORD_TYPE).getRecordTypeId();
        oppRecord.AccountID = pagWrapperIns.pagWrapper.pagRecord.Account__c;
        oppRecord.StageName = PAGServiceConstants.OPPORTUNITY_STAGE_NURTURE;
        //SAL25-819
        oppRecord.Name = pagWrapperIns.pagWrapper.pagRecord.Request_Type__c == PAGServiceConstants.PQL ? mapAccount.get(oppRecord.AccountID).Name + '-' + PAGServiceConstants.PRODUCT_QUALIFIED_LEAD : mapAccount.get(oppRecord.AccountID).Name + '-' + PAGServiceConstants.PRODUCT_ASSISTED_GROWTH_TRIAL; 
        oppRecord.Opportunity_Type__c = PAGServiceConstants.OPPORTUNITY_TYPE_EXISTING_CUST;
        oppRecord.Opportunity_Sub_Type__c = PAGServiceConstants.OPPORTUNITY_SUBTYPE_REGULAR;
        //SAL25-819
        oppRecord.LEADSOURCE = pagWrapperIns.pagWrapper.pagRecord.Request_Type__c != PAGServiceConstants.PQL ? PAGServiceConstants.OPPORTUNITY_LEADSOURCE_PAG : PAGServiceConstants.OPPORTUNITY_LEADSOURCE_PQL;
        oppRecord.Amount = PAGServiceConstants.OPPORTUNITY_AMOUNT_ZERO;
        //oppRecord.Opty Source
        //SAL25-819 Below if is for PQL
        if(pagWrapperIns.pagWrapper.pagRecord.Request_Type__c != PAGServiceConstants.PQL){
            if(pagWrapperIns.pagWrapper.pagRecord.End_Date__c != null){
                oppRecord.CloseDate = pagWrapperIns.pagWrapper.pagRecord.End_Date__c + PAGServiceConstants.PAG_END_DATE_BUFFER;
            }else{
                oppRecord.CloseDate = System.Today() + PAGServiceConstants.PAG_END_DATE_BUFFER;
            }
        }

        //ByPass Opty Triggers
        FlowControll.opportunityTriggerHandler = false;
        //Below if is the part of SAL25-819
        if(pagWrapperIns.pagWrapper.pagRecord.Request_Type__c == PAGServiceConstants.PQL){
            oppRecord.Time_of_Last_Stage_Change__c = SYSTEM.NOW();
            oppRecord.OwnerId = mapAccount.get(oppRecord.AccountID).OwnerId;
            oppRecord.Rubrik_Sales_Engineer__c = mapAccount.get(oppRecord.AccountID) != null && mapAccount.get(oppRecord.AccountID).Rubrik_Sales_Engineer__c != null ? mapAccount.get(oppRecord.AccountID).Rubrik_Sales_Engineer__c : null;
            oppRecord.CloseDate = System.Today() + PAGServiceConstants.PQL_END_DATE_BUFFER;
            oppRecord.PLS_AE_ETM_Role_Name__c = pagWrapperIns.pagWrapper.pagRecord.Overage_Product_Type__c == 'SaaS' ? 'SaaS AE' : pagWrapperIns.pagWrapper.pagRecord.Overage_Product_Type__c == 'Unstructured' ? 'NAS AE' : '';
            trialIdOpportunityMap.put(pagWrapperIns.pagWrapper.pagRecord.PQL_External_Id__c,oppRecord);
        }else{
            trialIdOpportunityMap.put(pagWrapperIns.pagWrapper.pagRecord.Trial_ID__c,oppRecord);
        }

        return trialIdOpportunityMap;
    }
    /*
    *********************************************************
    @Method Name    : createPAGStaging
    @author         : Rubrik Dev
    @description    : Creates PAG based on Polaris Request
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */

    public static void createPAGStaging(String requestBody,String responseBody){
        
        insert new Product_Assisted_Growth_Staging__c(PAG_Request_JSON__c = requestBody,PAG_Response__c = responseBody);
    }
    /*
    *********************************************************
    @Method Name    : createUnhandledExceptionResponse
    @author         : Rubrik Dev
    @description    : Creates PAG based on Polaris Request
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */

    public static RestResponse createUnhandledExceptionResponse(RestRequest request,RestResponse res, Exception ex){
        
        PAGResponseWrapper pageResponse = new PAGResponseWrapper();
        pageResponse.errorCode = PAGServiceConstants.MSG_UNHANDLED_EXCEPTION_CODE;
        pageResponse.message = ex.getMessage() + '    ' + ex.getStackTraceString();
        String responseJSON = JSON.serializePretty(pageResponse,true);
        res.responseBody = Blob.valueOf(responseJSON);

        //Create PAG Staging Record capturing request and response
        createPAGStaging(request.requestbody.tostring(),responseJSON);

        return res;
    }
    
    /** 
     * @description SAL25-819 Created separeted method to insert opportunity
     * @param accMap
     * @param oppList
     */
    public static void getCoOwnerDetails(Map<string,Account> accMap, List<Opportunity> oppList){
        Set<String> PLSterritoryIds = new set<String>();
        map<id,List<String>> PLSaccToTerrMap = new  map<id,List<String>>(); 
        List<string> adaptiveId_TerrIds = new List<string>();
        map<id,UserTerritory2Association> PLSuserToUtaMap = new  map<id,UserTerritory2Association>();
        Map<string, string> nasUserMap = new Map<string, string>(); 
        Map<string, string> saasUserMap = new Map<string, string>(); 
        String adaptiveId;
        for(Account acc : accMap.values()){
            Set<String> accNonCoreAdaptiveIdSet = new Set<String>(String.isNotBlank(acc.Non_Core_Adaptive_Territory_Ids__c) && acc.Non_Core_Adaptive_Territory_Ids__c.contains(',') ?
                                                                  acc.Non_Core_Adaptive_Territory_Ids__c.split(',') : new List<String>{acc.Non_Core_Adaptive_Territory_Ids__c});
            adaptiveId_TerrIds.addAll(accNonCoreAdaptiveIdSet);
        }
        List<UserTerritory2Association> UTAListTrgInsert = [Select Id,UserId,Territory2Id,Territory2.Adaptive_Territory_Id__c,RoleInTerritory2, Territory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.Internal_Territory_Name__c, 
                                                                Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c, Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c from UserTerritory2Association
                                                                where Territory2.Territory2Model.state='Active' AND User.IsActive = true and Territory2.Territory2Type.DeveloperName = 'Territory'
                                                                AND Territory2.Adaptive_Territory_Id__c IN : adaptiveId_TerrIds AND RoleInTerritory2 IN ('NAS AE','SaaS AE')];
        for(opportunity opp : oppList){
            String oppPLSRoleName = Opp.PLS_AE_ETM_Role_Name__c;
            Account oppRelatedAcc = accMap.get(opp.AccountId);
            List<String> typeAndIdStrLst = new List<String>();
            if(oppRelatedAcc.Non_Core_Type_and_Adaptive_Id__c !=null){
                typeAndIdStrLst = oppRelatedAcc.Non_Core_Type_and_Adaptive_Id__c.contains(';') ? oppRelatedAcc.Non_Core_Type_and_Adaptive_Id__c.split(';') : new List<String>{oppRelatedAcc.Non_Core_Type_and_Adaptive_Id__c};
            } 
            
            String typeToCheck =oppPLSRoleName == 'NAS AE' ? 'PLS NAS' : oppPLSRoleName == 'SaaS AE' ? 'PLS SaaS' : '';
            for(String typeAndId : typeAndIdStrLst){
                if(typeAndId.contains(':') && typeAndId.split(':')[0] == typeToCheck){
                    adaptiveId = typeAndId.split(':')[1];
                }
            }
            
            
            for(UserTerritory2Association UTA : UTAListTrgInsert){
                if(UTA.RoleInTerritory2 =='NAS AE' && !nasUserMap.containsKey(UTA.UserId)){
                    nasUserMap.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
                }else if(UTA.RoleInTerritory2 =='SaaS AE' && !saasUserMap.containsKey(UTA.UserId)){
                    saasUserMap.put(UTA.Territory2.Adaptive_Territory_Id__c,UTA.UserId);
                }
                PLSuserToUtaMap.put(UTA.UserId,UTA);
            }
            if(oppPLSRoleName == 'NAS AE' && nasUserMap.containsKey(adaptiveId)){
                opp.Co_Owner__c = nasUserMap.get(adaptiveId);
                
            }else if(oppPLSRoleName == 'SaaS AE' && saasUserMap.containsKey(adaptiveId)){
                opp.Co_Owner__c = saasUserMap.get(adaptiveId);
                
            }
            if(opp.Co_Owner__c != null  && PLSuserToUtaMap.containsKey(opp.Co_Owner__c)){
                opp.Core_PLS_Source__c = 'PLS Sourced';
                opp.PLS_AE_ETM_Role_Name__c = PLSuserToUtaMap.get(opp.Co_Owner__c).RoleInTerritory2;
                opp.Non_Core_Adaptive_Id__c = PLSuserToUtaMap.get(opp.Co_Owner__c).Territory2.Adaptive_Territory_Id__c; 
                UserTerritory2Association uta = PLSuserToUtaMap.get(opp.Co_Owner__c);
                opp.Opp_PLS_ETM_Theatre__c = uta.Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                opp.Opp_PLS_ETM_Area__c = uta.Territory2.ParentTerritory2.ParentTerritory2.Internal_Territory_Name__c;
                opp.Opp_PLS_ETM_Region__c = uta.Territory2.ParentTerritory2.Internal_Territory_Name__c;
                opp.Opp_PLS_ETM_Territory__c = uta.Territory2.Internal_Territory_Name__c;
            }
        }
    }
    
}