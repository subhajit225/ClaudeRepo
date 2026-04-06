({
    doInit: function(component, event, helper) {
        var action = component.get("c.getAccountRec");
        action.setParams({ 
            accId: component.get("v.sObjectInfo.AccountId"),
            legacyQuote: component.get("v.showCmp")
        });
        action.setCallback(this,function(response){
              var state = response.getState();
              if(state === "SUCCESS"){
	          if (response.getReturnValue() == null ) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "duration": 10000,
                        "type": "error",
                        "message": "You do not have access to use this button. Please use Create Quote Button to proceed"
                    });
                    toastEvent.fire();
                	$A.get("e.force:closeQuickAction").fire();   
                }
                else {
                    component.set("v.accountRec", response.getReturnValue());
                }
                console.log(component.get("v.accountRec"));
                if (component.get("v.accountRec") != null) {
                    helper.handleRecordUpdated(component, event, helper);
                }
              }else if (state === "ERROR") {
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
    
    handleRecordUpdated: function(component, event, helper) {
        var query = 'select id from SBQQ__Quote__c where SBQQ__Opportunity2__c= \''+ component.get("v.recordId") + '\'';
        helper.executeQuery(component, event, helper, query,false);
        var acc = component.get('v.accountRec');
        console.log(component.get('v.accountRec'));
        var opp = component.get('v.sObjectInfo');
        var isRefreshedIdentifier = false;
        if(opp.Opportunity_Program__c == 'Go Refresh' || opp.Opportunity_Program__c ==  'Go Refresh - No Email')
            isRefreshedIdentifier = true;
        /******************* CPQ22-4922 starts ******************/
        var action = component.get("c.getQuoteInsert");
        action.setParams({ 
            		 oppId : opp.Id,
                     oppOwnerId : opp.OwnerId,
                     oppInitialConName : opp.Initial_Contacts_Name__c,
                     oppAccountId : opp.AccountId,
                     oppPartnerLookup :    opp.Partner_Lookup__c,
                     oppDistributorLookup :    opp.Distributor_Lookup__c,
                     priceBookId   : '01s1W0000003MzoQAE',
                     PriceBook__c : '01s1W0000003MzoQAE',
                     accBillingCountry: acc.BillingCountry,
                     accName : acc.Name,
                     accBillingStreet : acc.BillingStreet,
                     accBillingCity : acc.BillingCity,
                     accBillingState : acc.BillingState,
                     accBillingPostalCode : acc.BillingPostalCode,
                     accShippingPostalCode: acc.ShippingPostalCode,
                     accShippingCountry : acc.ShippingCountry,
                     accShippingStreet : acc.ShippingStreet,
                     accShippingState:  acc.ShippingState,
                     accShippingCity :   acc.ShippingCity,
                     oppOpportunitySubType : opp.Opportunity_Sub_Type__c,
                     oppInstallationAss : opp.Installation_Assigned_To__c,
                     oppacRef :  acc.Is_Refreshed__c,
                     accRefreshIndicator: isRefreshedIdentifier
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS" && component.isValid()){
                if (response.getReturnValue() != null ) {
                    console.log('return value is :'+response.getReturnValue());
                    var query = 'select id from SBQQ__Quote__c where SBQQ__Opportunity2__c= \''+ component.get("v.recordId") + '\' ORDER BY CreatedDate DESC NULLS FIRST';
            		helper.executeQuery(component, event, helper, query,true,isRefreshedIdentifier);
                 }
              }else {
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
        /******************* CPQ22-4922 ends ******************/
	},
    
	navigatetoQuote : function(component, event, helper,isRefreshedIdentifier) {
        var urlEvent = $A.get("e.force:navigateToURL");
        if(isRefreshedIdentifier){
            urlEvent.setParams({
              "url": '/apex/DisplayAllAssetsClone2_v4?newid='+component.get("v.QuotesRecds")[0].Id
            });
        }else{
            urlEvent.setParams({
                "url": '/apex/sbqq__sb?newid='+component.get("v.QuotesRecds")[0].Id
            });
        }
        $A.get("e.force:closeQuickAction").fire();  // CPQ22-4922
        urlEvent.fire();
    },
    navigatetoOpp : function(component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": component.get("v.recordId"),
          "slideDevName": "detail"
        });
        $A.get("e.force:closeQuickAction").fire();  // CPQ22-4922
        navEvt.fire();
    },
    executeQuery : function(component, event, helper, query,afterSave,isRefreshedIdentifier) {
        var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": query
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS" && component.isValid()){
                var queryResult = response.getReturnValue();
                component.set("v.QuotesRecds", queryResult);
                if(afterSave == false){
                    component.set("v.quoteCount",component.get("v.QuotesRecds").length);
                    console.log(component.get("v.quoteCount"));
                }
               
                if(afterSave == true && !$A.util.isEmpty(component.get("v.QuotesRecds")) && component.get("v.QuotesRecds").length > component.get("v.quoteCount")){
                    helper.navigatetoQuote(component, event, helper,isRefreshedIdentifier);
                }else if(afterSave == true){
                   helper.navigatetoOpp(component, event, helper);
                }
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
               // $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    }
})