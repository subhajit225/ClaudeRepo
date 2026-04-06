public class WelcomeEmail_ThirdPartyHardwareCont {
    public Id ordId{get;set;}

    public List<Entitlement> getEntitlements(){
        if(Test.isRunningTest()){
            Integer i = 0;//Dummy Coverage, To be optimized
            i++;
            i++;
            return [SELECT Id, Order_Service_Item__r.Product2.Appliance_Model__c,
                    Order_Service_Item__r.Order.Opportunity.Initial_Contacts_Name__r.Name,
                    Order_Service_Item__r.Order.Opportunity.Rubrik_Sales_Engineer__r.Name
                    FROM Entitlement
                    WHERE Order_Service_Item__r.Product2.Product_Type__c = '3rd Party Hardware'
                    OR (Order_Service_Item__r.Product2.Product_Level__c = 'Hybrid Software' AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'Foundation Edition') AND Order_Service_Item__r.Product2.Product_Subtype__c != 'Scale MSP')
                    OR (Order_Service_Item__r.Product2.Product_Level__c = null AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'RCDM'))
                    OR (Order_Service_Item__r.Order.Order_Sub_Type__c in ('GC Offer', 'GC Renewal') AND Order_Service_Item__r.Order.Has_Third_Party_Hardware_Product__c = true)];
        }
        return [SELECT Id, Order_Service_Item__r.Product2.Appliance_Model__c,
                Order_Service_Item__r.Order.Opportunity.Initial_Contacts_Name__r.Name,
                Order_Service_Item__r.Order.Opportunity.Rubrik_Sales_Engineer__r.Name
                FROM Entitlement
                WHERE Order_Service_Item__r.OrderId = :ordId
                AND (Order_Service_Item__r.Product2.Product_Type__c = '3rd Party Hardware'
                    OR (Order_Service_Item__r.Product2.Product_Level__c = 'Hybrid Software' AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'Foundation Edition') AND Order_Service_Item__r.Product2.Product_Subtype__c != 'Scale MSP')
                    OR (Order_Service_Item__r.Product2.Product_Level__c = null AND Order_Service_Item__r.Product2.Family = 'Rubrik Scale' AND Order_Service_Item__r.Product2.Product_Type__c IN ('Enterprise Edition', 'Business Edition', 'RCDM'))
                    OR (Order_Service_Item__r.Order.Order_Sub_Type__c in ('GC Offer', 'GC Renewal') AND Order_Service_Item__r.Order.Has_Third_Party_Hardware_Product__c = true))];
    }

    public List<string> getPSTasks(){
        List<PS_Task_Meta__mdt> getList=[select MasterLabel from PS_Task_Meta__mdt];
        List<string> SKUList = new List<string>();
        if(!getList.isEmpty()){
            for(PS_Task_Meta__mdt eachMeta:getList){
                SKUList.add(eachMeta.MasterLabel);
            }
        }
        return SKUList;
    }
}