/*
@Class: GenerateEntitlementsForPOCOrders
@Author: Gaurav Jain (gaurav.j@rubrik.com)
@JIRA: https://rubrik.atlassian.net/browse/SF-753
*/
public class GenerateEntitlementsForPOCOrders implements Queueable {
	private Set<Id> orderIds = new Set<Id>();
	Map<Id, List<Entitlement>> existingEntitlementsMap = new Map<Id, List<Entitlement>>();

	public GenerateEntitlementsForPOCOrders(Set<Id> orderIds) {
		this.orderIds = orderIds;
	}

    public void execute(QueueableContext context) {
        Map<Id, OrderItem> orderItems = new Map<Id, OrderItem>([Select Id, Pricebookentry.Product2Id, Pricebookentry.Product2.Name, 
            SerialNumber__c, Pricebookentry.Product2.SBQQ__SubscriptionPricing__c, SBQQ__RequiredBy__c,SBQQ__RequiredBy__r.SerialNumber__c,  
            SBQQ__RequiredBy__r.Quantity, Quantity, Order.AccountId,order.Has_WelcomeLetter_Contact__c,order.Welcome_Letter_Contact__c,
            Support_Start_Date__c, Support_End_Date__c, Order.POC_Type__c, Order.BillingCity, Order.Actual_Order_Ship_Date__c, 
            Order.POC_Request__r.POC_completion_date__c, Pricebookentry.Product2.SBQQ__SubscriptionTerm__c, PricebookentryId
            from OrderItem where OrderId in :this.orderIds and Order.Type = 'POC']);

        Set<Id> orderItemIds = new Set<Id>();
        Set<String> assetSerialNumbers = new Set<String>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        List<Order> updateOrder = new List<Order>();
        set<id>updateOrderIds = new set<id>();
        for(OrderItem oi: orderItems.values()) {
            if(updateOrderIds.contains(oi.OrderId)== false && oi.order.Welcome_Letter_Contact__c!=null && oi.order.Has_WelcomeLetter_Contact__c == false){
               updateOrder.add(new order(id=oi.OrderId,Has_WelcomeLetter_Contact__c =true));
               updateOrderIds.add(oi.OrderId);
            }   
            //Update Dates at Order Items if missing
            if(oi.Pricebookentry.Product2.SBQQ__SubscriptionTerm__c != null){
            if(oi.Support_Start_Date__c == null || oi.Support_End_Date__c == null){
                oi.Support_Start_Date__c = oi.Order.Actual_Order_Ship_Date__c;
                if(oi.Order.POC_Request__r.POC_completion_date__c != null){
                    oi.Support_End_Date__c = oi.Order.POC_Request__r.POC_completion_date__c + 7;
                }

                orderItemsToUpdate.add(new OrderItem(Id=oi.Id, Support_Start_Date__c = oi.Support_Start_Date__c,
                    Support_End_Date__c = oi.Support_End_Date__c));
            }
            
            orderItemIds.add(oi.Id);
            if(oi.SerialNumber__c != null){
                assetSerialNumbers.addAll(getSerialNumbers(oi.SerialNumber__c));
            }
            else if(oi.SBQQ__RequiredBy__c != null && oi.SBQQ__RequiredBy__r.SerialNumber__c != null){
                assetSerialNumbers.addAll(getSerialNumbers(oi.SBQQ__RequiredBy__r.SerialNumber__c));
            }
           } 
        }
        if(!updateOrder.isEmpty()){
          update updateOrder;
        }
        //Update Dates at Order Items
        if(orderItemsToUpdate.size()>0){
            update orderItemsToUpdate;
        }

		Map<String, Asset> existingAssetsMap = new Map<String, Asset>();
		for(Asset ast : [Select Id, Serial_Number__c from Asset where Serial_Number__c in :assetSerialNumbers]){
			existingAssetsMap.put(ast.Serial_Number__c, ast);
		}

		checkExistingEntitlements(orderItemIds);

		System.debug(existingEntitlementsMap);
		List<Entitlement> entitlementsToCreate = new List<Entitlement>();
		for(OrderItem oi: orderItems.values()) {
			String entitlementType = '';
			if(oi.Order.POC_Type__c == 'Standard POC' || oi.Order.POC_Type__c == 'EA Unit') {
				entitlementType = 'Evaluation';
			}
			else if(oi.Order.POC_Type__c == 'Conditional PO') {
				entitlementType = 'Conditional PO';
			}
			else if(oi.Order.POC_Type__c == 'Business Loaner Unit' || oi.Order.POC_Type__c == 'Support Loaner Unit') {
				entitlementType = 'Loaner Unit';
			}

			if(existingEntitlementsMap.containsKey(oi.Id)){
				System.debug('delete');
				delete existingEntitlementsMap.get(oi.Id);
			}
			//else{
				List<String> serialNumbers = new List<String>();
				if(oi.SerialNumber__c != null){
					serialNumbers.addAll(getSerialNumbers(oi.SerialNumber__c));
				}
				else if(oi.SBQQ__RequiredBy__c != null && oi.SBQQ__RequiredBy__r.SerialNumber__c != null){
					serialNumbers.addAll(getSerialNumbers(oi.SBQQ__RequiredBy__r.SerialNumber__c));	
				}

				if(!serialNumbers.isEmpty()){
					for(String serialNumber : serialNumbers){
						Id assetId = null;
						if(existingAssetsMap.containsKey(serialNumber)){
							assetId = existingAssetsMap.get(serialNumber).Id;
						}

						Entitlement entToCreate = new Entitlement(
							AccountId = oi.Order.AccountId, 
							EndDate = oi.Support_End_Date__c, 
							Name = oi.Pricebookentry.Product2.Name, 
							Order_Service_Item__c = oi.Id, 
							Product__c = oi.Pricebookentry.Product2Id, 
							StartDate = oi.Support_Start_Date__c,
							Type = entitlementType,
							AssetId = assetId
							);

						entitlementsToCreate.add(entToCreate);
					}
				}
				else{
					for(Integer i = 0; i< oi.Quantity; i++){
						
						Entitlement entToCreate = new Entitlement(
							AccountId = oi.Order.AccountId, 
							EndDate = oi.Support_End_Date__c, 
							Name = oi.Pricebookentry.Product2.Name, 
							Order_Service_Item__c = oi.Id, 
							Product__c = oi.Pricebookentry.Product2Id, 
							StartDate = oi.Support_Start_Date__c,
							Type = entitlementType
							);

						entitlementsToCreate.add(entToCreate);
					}
				}
			//}
		}

		if(entitlementsToCreate.size() > 0){
			insert entitlementsToCreate;

			Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();
			for(Entitlement ent: entitlementsToCreate){
				if(ent.AssetId != null){
					OrderItem oi = orderItems.get(ent.Order_Service_Item__c);
					String assetStatus = '';
					if(oi.Order.POC_Type__c == 'Standard POC') {
						assetStatus = 'POC';
					}
					else if(oi.Order.POC_Type__c == 'Conditional PO') {
						assetStatus = 'Conditional';
					}
					else if(oi.Order.POC_Type__c == 'EA Unit'){
						assetStatus = 'EA Test';	
					}
					else if(oi.Order.POC_Type__c == 'Business Loaner Unit' || oi.Order.POC_Type__c == 'Support Loaner Unit') {
						assetStatus = 'Loaner';
					}

					Id orderServiceItemId = oi.SBQQ__RequiredBy__c != null ? oi.SBQQ__RequiredBy__c : oi.Id;

					Asset ast = new Asset(Id = ent.AssetId, Status = assetStatus, 
						Location__c = oi.Order.BillingCity, Support_Start_Date__c = oi.Support_Start_Date__c, 
						Premium_Support_End_Date__c = oi.Support_End_Date__c, Order_Service_Item__c = orderServiceItemId);

					assetsToUpdate.put(ent.AssetId, ast);
				}
			}

			if(assetsToUpdate.size()>0){
				update assetsToUpdate.values();
			}
		}
	}

	private void checkExistingEntitlements(Set<Id> orderItemIds) {
		if(orderItemIds == null || orderItemIds.isEmpty()){
			return;
		}
		for(Entitlement ent: [Select Id, Order_Service_Item__c from Entitlement 
			where Order_Service_Item__c in :orderItemIds]){
			if(existingEntitlementsMap.containsKey(ent.Order_Service_Item__c)){
				existingEntitlementsMap.get(ent.Order_Service_Item__c).add(ent);
			}
			else{
				List<Entitlement> entitlements = new List<Entitlement>();
				entitlements.add(ent);
				existingEntitlementsMap.put(ent.Order_Service_Item__c, entitlements);
			}
		}
	}

	private static List<String> getSerialNumbers(String field) {
        List<String> result = new List<String>();
        if(String.isNotBlank(field)) {
            for(String sn : field.split(System.Label.OrderItem_SplitChar)) {
                result.add(sn.trim());
            }
        }
        return result;
    }
}