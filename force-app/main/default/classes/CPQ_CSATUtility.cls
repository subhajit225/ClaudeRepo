/*
* Class Name :- CPQ_CSATUtility
* Author :- Rubrik Dev
* Created Date :- July 5th , 2023
* Description : CPQ22-3109 :- Utility class for CSAT related functionalities
* TestClass   : CPQ_CSATUtilityTest
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
*   
* 
// ********************Modification Log *****************************************************************************
*/
public class CPQ_CSATUtility {
    

    //Initiate all Constants
    public static final String OPPSUBTYPE_CSAT = 'CSAT';


    /*
    *********************************************************
    @Method Name    : createCSATQuote
    @author         : Rubrik Dev
    @description    : Method to call Renewal Service for CAT Oppty and Quote Generation
    @param          : List<ServiceContract> , Map<ID,ServiceContract>
    @return         : void
    ********************************************************
    */
    public static void createCSATQuote(List<ServiceContract> triggerNew, Map<ID,ServiceContract> tiggerOldMap){
        
        //Check if this needs bulkification or would it be waste of effort to bulkify
        try{
            if(triggerNew.size() == 1 && triggerNew[0].CSAT_Quoted__c == true && tiggerOldMap.get(triggerNew[0].ID).CSAT_Quoted__c == false){
                RenewServiceContractForCSAT(new Set<Id>{triggerNew[0].ID},null);
            }
        }
        catch(Exception Ex){

            system.debug('Exception during CSAT process is as follows :-  ' + ex);
        }
    }
    

    /*
    *********************************************************
    @Method Name    : RenewServiceContractForCSAT
    @author         : Rubrik Dev
    @description    : Carries out end to end functionality for CSAT Term Extension process.
    @param          : Set<Id> , ID 
    @return         : void
    ********************************************************
    */
    //@future
    public static void RenewServiceContractForCSAT(Set<Id> ServiceContractIdSet, ID masterContractId) {
        System.debug('check ServiceContractRenew:::::' + ServiceContractIdSet);
        
        //Collect Existing Contract Details
        Map<Id,ServiceContract> mapServiceContracts = new Map<Id,ServiceContract>([SELECT Id,SBQQSC__RenewalForecast__c,SBQQSC__RenewalQuoted__c,SBQQSC__RenewalOpportunity__c,Name FROM ServiceContract WHERE Id IN :ServiceContractIdSet]);

        updateRenOppOnServiceContract(mapServiceContracts);

        //Creates Renewal Context,Sets Master Contract ID, and  Calls EBQQ Renewal API to create a renewal opp and quote
        QuoteModel renewedQuoteModel = initiateRenewalAPI(ServiceContractIdSet, masterContractId);

        //Update ServiceContract to Older State, ie revert the values of Renewal Forecast/Renewal Quoted/Renewal Oppty Fields
        updateServiceContractToOlderState(mapServiceContracts);

        //updateCSATDetailsonQuote
        updateCSATQuote(renewedQuoteModel.record.ID);

        //Update Renewal Oppty SubType
        updateCSATOpp(renewedQuoteModel.record.SBQQ__Opportunity2__c);

        //UpdateTermonQuoteLines
        //updateQuoteLines(renewedQuoteModel.record.ID);
        
    }
    /*
    *********************************************************
    @Method Name    : initiateRenewalAPI
    @author         : Rubrik Dev
    @description    : Calls SBQQ Renewal API. Used for a set of service contracts to be merged and renewed with a single master contract amongst them.
    @param          : Set<Id> , ID 
    @return         : QuoteModel
    ********************************************************
    */
    public static QuoteModel initiateRenewalAPI(set<Id> ServiceContractIdSet, ID masterContractId){

        CreateRenewalContext context = new CreateRenewalContext();
        context.masterContractId = masterContractId;
        context.renewedContracts = new List<ServiceContract>();
        for(ID serviceContractID : ServiceContractIdSet){

            ServiceContract serviceContractToBeRenewed = new ServiceContract(ID = serviceContractID);
            context.renewedContracts.add(serviceContractToBeRenewed);
        }
        // Set returnOnlyQuoteId to true if you only want the Quote ID and not the entire Quote model.
        context.returnOnlyQuoteId = false; 
        system.debug('check renewedContracts:'+context.renewedContracts);
        
        String jsonContext = JSON.serialize(context);
        system.debug('check jsonContext'+ jsonContext);
        
        // renew the contracts
        ContractRenewer renewer = new ContractRenewer();
        
        QuoteModel[] quotes = renewer.load(null, jsonContext);  
        system.debug('check quotes ID:'+ (quotes[0].record.Id));
        system.debug('check quotes oppo:'+ (quotes[0].record.SBQQ__Opportunity2__c));

        return quotes[0];
    }
    /*
    *********************************************************
    @Method Name    : updateRenOppOnServiceContract
    @author         : Rubrik Dev
    @description    : Update Renewal Opty on Service Contract as Null on temporary basis so that Renewal API creates a new Oppty which can be marked as CSAT
    @param          : Map<Id,ServiceContract>
    @return         : void
    ********************************************************
    */
    public static void updateRenOppOnServiceContract(Map<Id,ServiceContract> mapServiceContracts){

        TriggerControl.stopSCTrigger = true;
        List<ServiceContract> serviceContractToBeUpdatedList = new List<ServiceContract>();
        for(ID serviceContractID : mapServiceContracts.keySet()){
            ServiceContract serviceContractToBeUpdated = new ServiceContract();
            serviceContractToBeUpdated.SBQQSC__RenewalOpportunity__c = null;
            serviceContractToBeUpdated.ID = serviceContractID;
            serviceContractToBeUpdatedList.add(serviceContractToBeUpdated);
        }
        System.debug('check scListToUpdate:'+serviceContractToBeUpdatedList);
        update serviceContractToBeUpdatedList;
        TriggerControl.stopSCTrigger = false;
    }
    /*
    *********************************************************
    @Method Name    : updateServiceContractToOlderState
    @author         : Rubrik Dev
    @description    : Revert Service Contract to Original state. ie Revert values of fields - Renewal Opportunity, Renewal Quoted
    @param          : Map<Id,ServiceContract>
    @return         : void
    ********************************************************
    */
    public static void updateServiceContractToOlderState(Map<Id,ServiceContract> mapServiceContracts){
 
        TriggerControl.stopSCTrigger = true;
        List<ServiceContract> serviceContractToBeUpdatedList = new List<ServiceContract>();
        for(ServiceContract serviceContactIns : mapServiceContracts.values()){

            ServiceContract serviceContractToBeUpdated = new ServiceContract(
                ID = serviceContactIns.ID,
                SBQQSC__RenewalForecast__c = serviceContactIns.SBQQSC__RenewalForecast__c,
                SBQQSC__RenewalQuoted__c = serviceContactIns.SBQQSC__RenewalQuoted__c,
                SBQQSC__RenewalOpportunity__c = serviceContactIns.SBQQSC__RenewalOpportunity__c
            );
            
            System.debug('check sc :' + serviceContractToBeUpdated.SBQQSC__RenewalOpportunity__c);

            serviceContractToBeUpdatedList.add(serviceContractToBeUpdated);
            system.debug('check scListToUpdateNext:'+serviceContractToBeUpdatedList);
            update serviceContractToBeUpdatedList; 
        }
        TriggerControl.stopSCTrigger = false;

    }
    /*
    *********************************************************
    @Method Name    : updateCSATOpp
    @author         : Rubrik Dev
    @description    : Update oppty as CSAT
    @param          : ID 
    @return         : void
    ********************************************************
    */
    public static void updateCSATOpp(ID oppID){
        
        Opportunity oppRecord = [Select ID,Name from Opportunity Where ID = : oppID];
        if(oppRecord != null){
            Opportunity csatOppToBeUpdated = new Opportunity(ID = oppID);
            csatOppToBeUpdated.Opportunity_Sub_Type__c = OPPSUBTYPE_CSAT;
            if(String.isNotBlank(oppRecord.name)){
                csatOppToBeUpdated.Name = oppRecord.name.substringBeforeLast('Renewal') + ' CSAT';
            }
            update csatOppToBeUpdated;
        }
    }
    /*
    *********************************************************
    @Method Name    : updateCSATQuote
    @author         : Rubrik Dev
    @description    : Update Quote as CSAT
    @param          : ID 
    @return         : void
    ********************************************************
    */
    public static void updateCSATQuote(ID quoteID){

        SBQQ__Quote__c csatQuote = new SBQQ__Quote__c(

            ID = quoteID,

            /*Discounted_Units_due_to_CSAT_or_Sizing__c = true,
            CSAT_Reason__c = 'Incorrect Shipment (Swap)',
            Discounted_Units_Justification__c = 'Test',
            Is_The_Box_Open__c = 'No',
            Root_Fault__c = 'Customer',
            Swap_Asset_Numbers__c = '1234567890'*/
            RWD_Deal_Ops_Exception__c = 'Minimum Term Policy Violation',
            RWD_Deal_Ops_Exception_Justification__c = 'This is a CSAT Quote'
        );
        update csatQuote;
    }
    /*
    *********************************************************
    @Method Name    : updateQuoteLines
    @author         : Rubrik Dev
    @description    : Default Term on CSAT Quote Lines. 
    @param          : ID 
    @return         : void
    ********************************************************
    
    public static void updateQuoteLines(ID quoteID){

        List<SBQQ__QuoteLine__c> listQuoteLinesToBeUpdated = new List<SBQQ__QuoteLine__c>();

        system.debug('csat line details'+[Select ID,SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quoteID]);

        for(SBQQ__QuoteLine__c quoteLineIns : [Select ID,SBQQ__SubscriptionTerm__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: quoteID]){

            SBQQ__QuoteLine__c quoteLineToBeUpdated = new SBQQ__QuoteLine__c(
                ID = quoteLineIns.ID,
                SBQQ__SubscriptionTerm__c = 1
            );

            listQuoteLinesToBeUpdated.add(quoteLineToBeUpdated);
        }

        update listQuoteLinesToBeUpdated;
    }*/
    /*
    *********************************************************
    @Method Name    : updateRenewalQuoteLines
    @author         : Rubrik Dev
    @description    : CPQ22-3347 - Update Start Date of existing renewal quotelines. 
    @param          : Set<ID>
    @return         : void
    ********************************************************
    */
    public static void updateRenewalQuoteLines(Set<ID> serviceContractIDSet){
        
        system.debug('serviceContractIDSet.     '+serviceContractIDSet);
        List<SBQQ__QuoteLine__c> quoteLinesToBeUpdated = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c quoteLineRecord : [Select ID,SBQQSC__RenewedContractLine__r.Related_End_Date__c From SBQQ__QuoteLine__c where SBQQ__Quote__r.Amended_Renewed_Service_Contract__c IN : serviceContractIDSet and SBQQ__Quote__r.OpportunitySubType__c != 'CSAT' and SBQQ__Quote__r.SBQQ__Primary__c = true and SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName IN ('1 Discovery','2 Consensus','3 Technical Validation','4 Business Justification','5 Negotiate & Close','0 Nurture')]){
            system.debug('quoteLineRecord.     '+quoteLineRecord);
            if(quoteLineRecord.SBQQSC__RenewedContractLine__c != null && quoteLineRecord.SBQQSC__RenewedContractLine__r.Related_End_Date__c != null){
                SBQQ__QuoteLine__c quoteLineRecToBeUpdated = new SBQQ__QuoteLine__c();
                quoteLineRecToBeUpdated.ID = quoteLineRecord.ID;

                quoteLineRecToBeUpdated.SBQQ__StartDate__c = quoteLineRecord.SBQQSC__RenewedContractLine__r.Related_End_Date__c + 1;
                quoteLinesToBeUpdated.add(quoteLineRecToBeUpdated);
            }
        }
        if(!quoteLinesToBeUpdated.isEmpty()){
            Database.SaveResult[] updateResults = Database.update(quoteLinesToBeUpdated,false);
        }
    }

}