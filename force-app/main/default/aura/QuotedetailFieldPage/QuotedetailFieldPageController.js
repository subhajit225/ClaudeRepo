({
	handleRecordUpdated : function(component, event, helper) {
     var query = 'select Id, Name,SBQQ__Quantity__c,  SBQQ__ProductCode__c, Quote_Line_Type__c, SBQQ__SubscriptionPricing__c,SBQQ__NetTotal__c,  SBQQ__Optional__c, Product_Level__c, Product_Type__c,Special_Program__c,Arroyo_Subscribed_Asset_Name__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = \''+ component.get("v.recordId") + '\'';
	helper.executeQuery(component, event, helper, query, 'quoteLineItemsRecds');
	
	}
})