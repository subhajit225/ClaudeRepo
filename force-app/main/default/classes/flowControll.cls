/**
 * @description       : 
 * @author            : Harshit Garg
 * @group             : 
 * @last modified on  : 02-04-2026
 * @last modified by  : Harshit Garg
**/
public with sharing class flowControll { 
    public static boolean opportunityTriggerHandler=true;
    public static boolean leadTriggerHandler=true;
    public static boolean deleteOptySplitAmount=true;
    public static boolean dealRegistrationTrigger=true;
    public static boolean accountTrigger=true;
    public static boolean taskTrigger=true;
    public static boolean campaignTrigger=true;
    public static boolean contactTrigger=true;
    public static boolean pocRequestTriggerHandler=true;
    public static boolean RMATriggerHandler=true;
    public static boolean POBTriggerHandler=true;
    public static boolean opportunityLineItemHandler=true;
    public static boolean UserTriggerHandler=true;
    public static boolean MIPElementTrigger=true;
    public static boolean ScaleUtilityOverageTrigger=true; 
    public static boolean AARTrigger=true; 
    public static boolean SnowflakeFeedTrigger = true;
    public static boolean operationRequestTrigger = true;
    public static boolean POSReportTrigger = true;
    public static boolean PSEscalationTrigger = true;
    public static boolean MIPAccContriTrigger = true;
    public static boolean PartnerRelationTrigger=true;
    public static boolean PartnerRegRequestTrigger = true;
    public static boolean CVEOpportunityContactTriggerHandler = true;
    public static boolean partnerOnBoardRequestTrigger = true;
    public static boolean partnerFundRequestTrigger = true;

    /**This method is used only for Mass Email Masking process during Sandbox refresh.  */
    public static void disableAllTriggers(){
        opportunityTriggerHandler = false;
        leadTriggerHandler = false;
        deleteOptySplitAmount = false;
        dealRegistrationTrigger = false;
        accountTrigger = false;
        taskTrigger = false;
        campaignTrigger = false;
        contactTrigger = false;
        pocRequestTriggerHandler = false;
        RMATriggerHandler = false; 
        POBTriggerHandler = false;
        opportunityLineItemHandler = false;
        UserTriggerHandler = false;
        MIPElementTrigger=false;
        ScaleUtilityOverageTrigger = false;
        AARTrigger = false;
        SnowflakeFeedTrigger =  false;
        operationRequestTrigger =  false; 
        POSReportTrigger =  false;
        PSEscalationTrigger = false;
        MIPAccContriTrigger = false;
        PartnerRelationTrigger = false;
        PartnerRegRequestTrigger = false;
        partnerOnBoardRequestTrigger = false;
        partnerFundRequestTrigger = false;
    }
}