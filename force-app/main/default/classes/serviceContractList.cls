/**This class is called when Create Quote button is hit for  Arroyo */
    /***********************************************************************************************************
    * Class Name          : ServiceContractList
    * Date Created/Modified: 5/20/2023
    * @description         : Controller class for Service Contract List component
    /**********************************************************************************************************/
    Global without sharing class serviceContractList{   
    //SOX start
    /************************************************************************************************************
    * Method Name          : checkUserAccess
    * @description         : checks if user has access to create quote
    * @return              : Boolean
    /**********************************************************************************************************/
    @AuraEnabled
    public static Boolean checkUserAccess() {
        return (Schema.SObjectType.SBQQ__Quote__c.isCreateable() && 
                		!FeatureManagement.checkPermission('Renewal_Specialists_Cannot_Create_New_Quote'));
    }
   //SOX end
    /***********************************************************************************************************
    * Method Name          : fetchQuoteForSMSUI
    * Date Created/Modified: 01/10/2025
    * @description         : returns quoteId for SMS enabled UI (Story : FY25SR-2251)
    * @return              : Id
    * @param oppId
    * @param oppSubType
    * @param oppPriceBookId
    * @param oppContactId
    * @param oppOwnerId
    * @param oppAccId
    /**********************************************************************************************************/
    @AuraEnabled
    Webservice static Id fetchQuoteForSMSUI(Id oppId, 
                                            String oppSubType, 
                                            Id oppPriceBookId, 
                                            Id oppContactId, 
                                            Id oppOwnerId, 
                                            Id oppAccId) {
        Id quoteId;
        quoteId = ReplacementCreateQuote.renewalCustomContract(oppId, oppSubType, oppPriceBookId, oppContactId, oppOwnerId, oppAccId);
        return quoteId;
    }
    /***********************************************************************************************************
    * Method Name          : fetchContracts
    * Date Created/Modified: 01/10/2025
    * @description         : returns List<ServiceContract> for old framework of quote lines creation
    * @return              : List<ServiceContract>
    * @param accId
    * @param oppId
    /**********************************************************************************************************/
    @AuraEnabled
    Webservice static List<ServiceContract> fetchContracts (String accId, String oppId) {
        /** Opportunity and Entitlement Query has been removed as a part of optimisation for the story FY25SR-2251 **/
        ServiceContract listToShow = new ServiceContract();
        Set<Id> Ids = new Set<Id>();
        Opportunity oppRec = [Select id, Sell_to_Partner__c, Sell_to_Partner__r.Name, Opportunity_Sub_Type__c, Contract_Renewal_Term__c from Opportunity where Id =: oppId];
        Date dpast = System.today().addDays(-90);
            List<AggregateResult> groupedResults = [SELECT ServiceContract.AccountID, ServiceContractId, ServiceContract.Name,
                                                    ServiceContract.StartDate,ServiceContract.Status, ServiceContract.EndDate,
                                                    max(EndDate) FROM 
                                                    ContractLineItem WHERE ServiceContract.AccountID = :accId 
                                                    //AND EndDate <= :dfuture Commented for Dynamic Term logic
                                                    AND EndDate >= :dpast
                                                    AND (ServiceContract.SBQQSC__Quote__c = null OR (ServiceContract.SBQQSC__Quote__c != null 
                                                                                                     AND ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c = 0)) /*AND SBQQSC__RenewalQuantity__c > 0*/
                                                    AND ServiceContract.GPL_Deal__c != 'True'
                                                    AND (NOT SBQQSC__ProductName__c LIKE '%RZTDP%') //Excluding RZTDP SKUs as part of CPQ22-4352
                                                    AND (ServiceContract.SBQQSC__Quote__c = null OR (ServiceContract.SBQQSC__Quote__c != null //AND ServiceContract.SBQQSC__Quote__r.OpportunitySubType__c != null 
                                                                                                     AND ServiceContract.SBQQSC__Quote__r.OpportunitySubType__c != 'CSAT'
                                                                                                     AND ServiceContract.SBQQSC__Quote__r.OpportunitySubType__c != 'GC Offer' 
                                                                                                     AND ServiceContract.SBQQSC__Quote__r.OpportunitySubType__c != 'GC Renewal' 
                                                                                                     AND ServiceContract.SBQQSC__Quote__r.OpportunitySubType__c != 'GC OnDemand'))//ARY-955:Added this condition to ensure that any CLIs of ScaleUtility quote are not to be pulled in
                                                    GROUP BY ServiceContractId, ServiceContract.Name, ServiceContract.StartDate,
                                                    ServiceContract.Status, ServiceContract.EndDate,ServiceContract.AccountID,Id];
            
            //List<AggregateResult> groupedResults = Database.query(Query);
            
            //Dynamic Term logic starts
            list<date> AllDates = new list<date>(); 
            Date MaxDate;
            
            for(AggregateResult ar : groupedResults){
                AllDates.add((Date)ar.get('expr0'));
                AllDates.sort(); 
            }
            date MaxEndDate;
            if (allDates != null && !allDates.isEmpty()) {
                MaxEndDate = allDates[Alldates.size()-1];
            }
            if (oppRec != null && oppRec.Contract_Renewal_Term__c != null) {
                MaxDate = System.today().addMonths(Integer.valueOf(oppRec.Contract_Renewal_Term__c));
            }
            else {
                MaxDate = MaxEndDate;
            }
            //Dynamic Term logic Ends
            
            for(AggregateResult ar : groupedResults){
                if ((Date)ar.get('expr0') <= MaxDate) { 
                    Ids.add((Id)ar.get('ServiceContractId'));
                }
            }
        return [SELECT Id, Name, ContractNumber, StartDate, EndDate, Status FROM ServiceContract WHERE Id IN : Ids];  
    }
    /***********************************************************************************************************
    * Method Name          : renewalContracts
    * Date Created/Modified: 01/10/2025
    * @description         : returns List<ServiceContract> for old framework of quote lines creation
    * @return              : String
    * @param str
    * @param oppId
    /**********************************************************************************************************/
    @AuraEnabled
    Webservice static String renewalContracts(String str, String oppId){
        List<Id> renewalId = new List<Id>();
        String quoteId ;
        List<contrctWrapper> contractList = new  List<contrctWrapper>();
        try{
            if(!string.isBlank(str) && str != '[]'){
                contractList = (List<contrctWrapper>)System.JSON.deserialize(str,List<contrctWrapper>.class);
                CreateRenewalContext context = new CreateRenewalContext();
                context.masterContractId = contractList[0].Id;
                
                for(contrctWrapper wrap: contractList){
                    renewalId.add(wrap.Id); 
                }
                List<Servicecontract> updatelist = new List<ServiceContract>();
                
                context.renewedContracts = [SELECT Id,ContractNumber, Expansion_Opportunity__c,Renew_to_Old_SKUs__c , SBQQSC__RenewalOpportunity__c, AccountId, 
                                            StartDate,EndDate,Term,OwnerId,SBQQSC__Opportunity__c,SBQQSC__Opportunity__r.OwnerId, SBQQSC__RenewalOpportunity__r.OwnerId FROM ServiceContract WHERE Id IN: renewalId];
                String jsonContext = JSON.serialize(context);
                
                TriggerHandler.bypass('OpportunityObjectTriggerHandler');
                TriggerHandler.bypass('ServiceContractMain');
                TriggerHandler.bypass('SBQQ_QuoteLineTriggerHandler');
                
                SBQQ__QuoteLineGroup__c qlg = new  SBQQ__QuoteLineGroup__c();
                serviceContractList cn = new serviceContractList();
                quoteId  = customRenewal.renewalCustomContract(context.renewedContracts,oppId);
                if (quoteId != null && quoteId.startsWith('a6')) {
                    SBQQ__Quote__c newQ = new SBQQ__Quote__c(id = quoteId);
                    CallCalculateAPIBatch batchInstance  = new CallCalculateAPIBatch(new List<SBQQ__Quote__c>{newQ});
                    Database.executeBatch(batchInstance, 1);
                }
                else {
                    return quoteId;
                }
            }
        }
        catch(Exception e) {
            quoteId = e.getMessage(); 
            System.debug(LoggingLevel.DEBUG, e.getMessage() + '--' + e.getLineNumber() + '=quoteId='+quoteId);  
        } 
        return quoteId;
    }
    
    /***********************************************************************************************************
    * Method Name          : customShareOpp
    * Date Created/Modified: 06/10/2025
    * @description         : customShareOpp
    * @param                userIds
    * @param                OppId    
    * Test Class           :
    /**********************************************************************************************************/
    public static void customShareOpp(Set<Id> userIds, String OppId){
        List<OpportunityShare> oppShareList = new List<OpportunityShare>();
        
        for(Id userId : userIds){
            OpportunityShare oppShr  = new OpportunityShare();
            oppShr.opportunityId  = OppId;
            oppShr.UserOrGroupId = userId;
            oppShr.OpportunityAccessLevel = 'Edit';
            oppShr.RowCause = Schema.OpportunityShare.RowCause.Manual;
            oppShareList.add(oppShr);
        }
        Database.SaveResult[] sr = Database.insert(oppShareList,false);
        
        if(sr[0].isSuccess()){
            System.debug(LoggingLevel.DEBUG, 'custom sharing completed'); 
        }
        else {
            Database.Error err = sr[0].getErrors()[0];
            if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
               err.getMessage().contains('AccessLevel')){
                   System.debug(LoggingLevel.DEBUG, 'custom sharing completed');
               }
            else{
                System.debug(LoggingLevel.DEBUG, 'Error in custom sharing');
            }
        }
    }
    
    /***********************************************************************************************************
    * Method Name          : load
    * Date Created/Modified: 23/06/2025
    * @description         : load
    * @return              : quotesJSON
    * @param                masterContractId
    * @param                serializedContext    
    * Test Class           :
    /**********************************************************************************************************/
    public QuoteModel[] load(String masterContractId, String serializedContext) {
        String quotesJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractRenewer', 
                                                    					masterContractId, serializedContext);
        return (QuoteModel[]) JSON.deserialize(quotesJSON, List<QuoteModel>.class);
    }
    
    /***********************************************************************************************************
    * Method Name          : getBusinessLogicSetting
    * Date Created/Modified: 23/06/2025
    * @description         : returns custom setting
    * @return              : Boolean
    * Test Class           :
    /**********************************************************************************************************/
    @AuraEnabled
    Webservice static Boolean getBusinessLogicSetting() {
        // For hierarchy custom setting:
        ShGl_DisableBusinessLogic__c userSetting = ReplacementQueryController.fetchBusinessLogicSetting();
        if (userSetting != null) {
            	return userSetting.Disable_Replacement_Framework__c;
        }
        return false;
    }

    /***********************************************************************************************************
    * Method Name          : getQuoteName
    * Date Created/Modified: 12/01/2026
    * @description         : returns Quote Name
    * @param qtId          : Quote Id
    * @return              : String
    /**********************************************************************************************************/

    @AuraEnabled
    Webservice static String getQuoteName(String qtId) {
        if(String.isBlank(qtId)) return null;
        
        try {
            SBQQ__Quote__c q = [SELECT Name, SBQQ__Account__r.Name FROM SBQQ__Quote__c WHERE Id = :qtId LIMIT 1];
            String quoteName = q.Name != null ? q.Name : ''; 
            String accName = (q.SBQQ__Account__r != null && q.SBQQ__Account__r.Name != null) ? '&accName=' + q.SBQQ__Account__r.Name : '';
            return quoteName + accName;
        } catch (Exception e) {return null;}
    }

}