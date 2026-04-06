/************************************************************
* @description       : Order Item Extension Handler Class
* @author            : Ravi
* @last modified on  : 05-24-2024
* @last modified by  : Ravi
* Modifications Log
* Ver   Date          Author        Modification
* 1.0   05-24-2024   Ravi        Initial Version
**************************************************************/
public class OrderItemExtensionHandler extends TriggerHandler {
    private static OrderItemExtensionHandler extensionHandler = null;
    public OrderItemExtensionHelper extensionHelper;
    
    /**
    * @description Constructor for OrderItemExtensionHandler.
    * @author Ravi
    * @last modified on 24-04-2025
    */
    private OrderItemExtensionHandler(){
        extensionHelper = OrderItemExtensionHelper.getInstance();
    }
    
    /**
    * @description Initiate OrderItemExtensionHandler it instance is null else retuns the OrderItemExtensionHandler instance
    * @author Ravi
    * @last modified on 24-04-2025
    * @return OrderItemExtensionHandler Instance
    */
    public static OrderItemExtensionHandler getInstance() {
        if (extensionHandler == null){
            extensionHandler = new OrderItemExtensionHandler();
        }
        return extensionHandler;
    }
    
    /**
    * @description Method that implements logic after OrderItem Extension is created
    * @author Ravi
    * @last modified on 24-04-2025
    */
    public override void afterInsert() {
        extensionHelper.init();
        extensionHelper.calculateOIECreditAmounts();
    }
    
    /**
    * @description  Method that implements logic after OrderItem Extension is updated
    * @author Ravi
    * @last modified on 24-04-2025
    */
    public override void afterUpdate() {
        for(Order_Item_Extension__c newOrdItemExtn : (List<Order_Item_Extension__c>) Trigger.new){
            Order_Item_Extension__c oldOrdItemExtension = (Order_Item_Extension__c) Trigger.oldMap?.get(newOrdItemExtn.id);
            if(newOrdItemExtn.Order_Line_ID__c != null 
               && newOrdItemExtn.Credit_Calculation_Status__c != oldOrdItemExtension.Credit_Calculation_Status__c 
               && newOrdItemExtn.Credit_Calculation_Status__c == 'To process')
            {
            	extensionHelper.orderItemIds.add(newOrdItemExtn.Order_Line_ID__c);    
            }
        }
        if(!extensionHelper.orderItemIds.isEmpty()){
            extensionHelper.init();
            extensionHelper.calculateOIECreditAmounts();
        }
    }
}