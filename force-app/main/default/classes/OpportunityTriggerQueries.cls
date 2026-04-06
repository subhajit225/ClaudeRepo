public class OpportunityTriggerQueries {
    public static Map<Id,ServiceContract> getServiceContracts(Set<Id> scIdSet){
        Map<Id,ServiceContract> scMap;
        if(!scIdSet.isEmpty()){ 
          scMap = new Map<ID, ServiceContract>([Select Id, Name, EndDate, Account.Name, Account.ETM_Theatre__c, Account.Sum_of_Opportunities__c,SBQQSC__Opportunity__c, SBQQSC__Opportunity__r.Initial_Contacts_Name__c, SBQQSC__Opportunity__r.Alliance_Partner_Name__c,SBQQSC__Opportunity__r.Alliance_Source_Type_SW__c, SBQQSC__Opportunity__r.Alliance_HW_Partner__c, SBQQSC__Opportunity__r.Compelling_Bus_Driver__c, 
                                      //SAL22-260 
                                      SBQQSC__Opportunity__r.Distributor_Lookup__c, SBQQSC__Opportunity__r.Distributor_Lookup__r.Contract_Status__c, SBQQSC__Opportunity__r.Partner_Lookup__r.Distributor__c, 
                                      SBQQSC__Opportunity__r.Partner_Lookup__c, SBQQSC__Opportunity__r.Partner_Lookup__r.Name, SBQQSC__Opportunity__r.Partner_Lookup__r.RecordType.Name, SBQQSC__Opportunity__r.Partner_Lookup__r.Contract_Status__c, SBQQSC__Opportunity__r.Partner_Lookup__r.Distributor__r.Contract_Status__c,
                                      SBQQSC__Opportunity__r.Partner_Rep_Email_Address__c, SBQQSC__Opportunity__r.Primary_Competitor__c, SBQQSC__Opportunity__r.Cloud_Type__c, SBQQSC__Opportunity__r.Cloud_Environment__c, SBQQSC__Opportunity__r.Rubrik_CDM_Release_on_source_cluster__c, SBQQSC__Opportunity__r.Polaris_Portal_Contact__c, //SAL22-348
                                      SBQQSC__Opportunity__r.Partner_Rep_Phone_Number__c, SBQQSC__Opportunity__r.Fed_SI_Partner_Name__c, SBQQSC__Opportunity__r.Fed_SI_Initiated_Deal__c, //SAL24-228
                                      SBQQSC__Opportunity__r.Partner_Representative__c, SBQQSC__Opportunity__r.MSP_End_User_Lookup__c, SBQQSC__Opportunity__r.MSP_End_User__c, //SAL24-479
                                      SBQQSC__Opportunity__r.Partner_SE_Email__c,
                                      SBQQSC__Opportunity__r.Partner_SE_Name__c,
                                      SBQQSC__Opportunity__r.Partner_SE_Phone__c,
                                      SBQQSC__Opportunity__r.Distributor_Rep_Email__c,
                                      SBQQSC__Opportunity__r.Distributor_Rep_Name__c,
                                      SBQQSC__Opportunity__r.Distributor_Secondary_Email_Address__c,
                                      SBQQSC__Opportunity__r.Distributor_Rep_Phone_Number__c,
                                      SBQQSC__Quote__r.MSP_SKUs_Count__c,
                                      SBQQSC__Quote__c,SBQQSC__Opportunity__r.Opportunity_Sub_Type__c,
                                SBQQSC__Opportunity__r.Name, SBQQSC__Order__c, SBQQSC__Order__r.Order_Sub_Type__c, 
                                SBQQSC__Quote__r.OpportunitySubType__c,SBQQSC__Opportunity__r.Managed_Services_Deal_type__c,SBQQSC__Opportunity__r.Account.Type
                                      from ServiceContract where Id IN:scIdSet]);
        }
        return scMap;
    } 
  
    public static Map<Id,Opportunity> getOppMapTrgAfterUpdate(Map<Id,Opportunity> newOppMap){
        Map<Id,Opportunity> oppMapTrgAfterUpdate;
        oppMapTrgAfterUpdate = new Map<Id,Opportunity>([SELECT Id,Initial_Contacts_Name__c,Hold_Code__c, StageName, Account.name, Account.Id, Partner_Lookup__c, Distributor_Lookup__c, Distributor_lookup__r.Payment_Term__c, OwnerId, Owner.email, Rubrik_Sales_Engineer__c,Rubrik_Sales_Engineer__r.Email,
                                                        Partner_Lookup__r.Shipping_Carrier__c , Partner_Lookup__r.Shipping_Method__c , Partner_Lookup__r.Shipping_Account_Number__c,Partner_Lookup__r.IncoTerms__c,
                                                        Distributor_Lookup__r.Shipping_Carrier__c , Distributor_Lookup__r.Shipping_Method__c , Distributor_Lookup__r.Shipping_Account_Number__c,Distributor_Lookup__r.IncoTerms__c,
                                                        Partner_Lookup__r.Distributor__r.Shipping_Carrier__c,Partner_Lookup__r.Distributor__r.Shipping_Method__c,Partner_Lookup__r.Distributor__r.Shipping_Account_Number__c,Partner_Lookup__r.Distributor__r.IncoTerms__c,
                                                        Partner_Lookup__r.Payment_Term__c, Partner_Lookup__r.Distributor__r.Payment_Term__c,Partner_Lookup__r.Distributor__c, CloseDate,Pricebook2Id,
                                                        (SELECT Id, Opportunity__c, Opportunity_Escalation_Stage__c from Issue_Trackers__r), 
                                                        (SELECT Id,Aha_Ideas__c from Aha_Idea_Links__r),
                                                        (SELECT Id, name,Unitprice,ProductCode, TotalPrice, Valooto_Sales_Price__c ,Description, Discount, PriceBookEntryId, SBQQ__QuoteLine__c,SBQQ__QuoteLine__r.SBQQ__Quote__c,List_Total__c,Quantity,Product2Id,Subscription_Term__c,SBQQ__QuoteLine__r.SBQQ__ListTotal__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c,SBQQ__QuoteLine__r.SBQQ__Product__c,SBQQ__QuoteLine__r.SBQQ__Quantity__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,
                                                         SBQQ__QuoteLine__r.SBQQ__Quote__r.OpportunitySubType__c, SBQQ__QuoteLine__r.SBQQ__EffectiveQuantity__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Status__c,
                                                         OpportunityId, Product2.Name,Product2.Category__c,Opportunity.Order_Sub_Type__c,opportunity.Opportunity_Sub_Type__c,
                                                         opportunity.Opportunity_Type__c, Product2.Item_Type__c, Product2.Product_Type__c, Product2.Product_Subtype__c, Product2.License_Type__c,Product2.Product_Level__c,SBQQ__QuoteLine__r.Licensing_Model__c,PricebookEntry.Product2.IsActive FROM OpportunityLineItems),
                                                        (SELECT Id,Request_Status__c from  Deal_Desk_Cases__r),
                                                        (SELECT Id, Hold_Code__c  , Is_Released__c, Release_Date_Time__c, Related_Opportunity__c,Related_Order__c from Hold_Off_Tracking__r where Is_Released__c = false),
                                                        (SELECT Role, ContactId, Contact.Email, IsPrimary, OpportunityId from OpportunityContactRoles)
                                                        FROM Opportunity where Id IN:newOppMap.keySet()]);
        
        return oppMapTrgAfterUpdate;
    }
}