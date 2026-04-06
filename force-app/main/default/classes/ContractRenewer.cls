/*
* Class Name :- ContractRenewer
* Author :- Rubrik Dev
* Created Date :- July 5th , 2023
* Description : SBQQ Renewal API Class
* TestClass   : CPQ_CSATUtilityTest
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
*       
*      
* 
// ********************Modification Log *****************************************************************************
*/
public with sharing class ContractRenewer{
    public QuoteModel[] load(String masterContractId, String serializedContext) {

        String quotesJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractRenewer', masterContractId, serializedContext);
        
        return (QuoteModel[]) JSON.deserialize(quotesJSON, List<QuoteModel>.class);
    }
}