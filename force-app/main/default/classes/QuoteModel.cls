/*
* Class Name :- QuoteModel
* Author :- Rubrik Dev
* Created Date :- July 5th ,2023
* Description : SBQQ Quote Wrapper
* TestClass   : CPQ_CSATUtilityTest
// ********************Mofification Log *****************************************************************************
*     
* Modified By          Date             Description (Include Jira Details)
* 
*    
* 
// ********************Modification Log *****************************************************************************
*/
public class QuoteModel {
    public SBQQ__Quote__c record;
    public QuoteLineModel[] lineItems;
    public QuoteLineGroupModel[] lineItemGroups;
    public Integer nextKey;
    public Boolean applyAdditionalDiscountLast;
    public Boolean applyPartnerDiscountFirst;
    public Boolean channelDiscountsOffList;
    public Decimal customerTotal;
    public Decimal netTotal;
    public Decimal netNonSegmentTotal;
}