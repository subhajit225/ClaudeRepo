({
	processData : function(component, event, helper) { 
        if(!component.get("v.quoteLineItemsRecds")) return;
        var quotelinequeryresult = component.get("v.quoteLineItemsRecds");
         var quoteLinesrecords = quotelinequeryresult;
        var AspentotalHWCost=0;
        var nonAspentotalHWCost=0;
          if(quoteLinesrecords!=null && quoteLinesrecords!=undefined){
                    for (var i = 0; i < quoteLinesrecords.length; i++) 
                    {
                        var quoteLine = quoteLinesrecords[i];
                         if(quoteLine.SBQQ__SubscriptionPricing__c==null &&  quoteLine.Quote_Line_Type__c=='New' && quoteLine.Product_Level__c !=null
                            && (quoteLine.Product_Type__c=='Add-On Node' || quoteLine.Product_Type__c=='Hardware' || quoteLine.Product_Type__c=='Accessories' || quoteLine.Product_Type__c=='Spares')
                           )
                         {
                             if(quoteLine.SBQQ__Optional__c==true){
                               AspentotalHWCost+=quoteLine.SBQQ__NetTotal__c;   
                             }
                             else
                             {
                             nonAspentotalHWCost+=quoteLine.SBQQ__NetTotal__c; 
                             }
                         }
                    }
           }
        component.set("v.AspenHardwareCost",AspentotalHWCost.toFixed(2));
        component.set("v.NonAspenHardwareCost",nonAspentotalHWCost.toFixed(2));
    },
    executeQuery : function(component, event, helper, query, attributeName) {
		var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": query
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS" && component.isValid()){
                var queryResult = response.getReturnValue();
                if(attributeName == 'quoteLineItemsRecds'){
                    component.set("v."+attributeName, queryResult);
                    helper.processData(component, event, helper); 
                }
                $A.get('e.force:refreshView').fire();
            } 
            else{ 
                console.error("fail:" + response.getError()[0].message); 
                var toastEvent = $A.get("e.force:showToast");
    		toastEvent.setParams({
        		"title": "Error",
                        "duration": 10000,
                        "type": "error",
        		"message": "Something went wrong in your org: " + response.getError()[0].message
    		});
    		toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },
})