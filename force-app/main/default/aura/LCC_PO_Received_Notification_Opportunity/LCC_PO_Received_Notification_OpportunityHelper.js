({
	handlesaveOpp : function(component, event, helper) {
        helper.showSpinner(component, event, helper);
		var action = component.get("c.saveRecord");
        action.setParams({ rec : component.get("v.sObjectInfo") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state..!', state);
            console.log('result..!', response.getReturnValue());
            helper.hideSpinner(component, event, helper);
            if (state === "SUCCESS") {
                var str = response.getReturnValue();
                if(str != '' && str.includes('Exception occurred')){
                    component.set("v.content",str);
                }else{
                    component.set("v.content","Email Sent");
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                component.set('v.content', errors[0].message);
            }
            $A.get('e.force:refreshView').fire();
        });
        // Send action off to be executed
        $A.enqueueAction(action);
	},

    
    // Update Primary Quote using EXISTING QUOTE LIST
    updatePrimary : function(component, selectedQuoteId) {
        var map = component.get("v.quoteMap");               
        var selectedQuote = map[selectedQuoteId]; // <-- GET VALUE FROM MAP
        console.log('selectedQuote ' + JSON.stringify(selectedQuote));
        var action = component.get("c.updateQuoteAndCreatePoStageError");
        component.set("v.spinner", true); 
        action.setParams({ quote : selectedQuote});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state..!', state);
            console.log('result..!', response.getReturnValue());
            component.set("v.isOpen", false);
            component.set("v.spinner", false); 

            if (state === "SUCCESS") {
                var str = response.getReturnValue();
                console.log('result PK ', response.getReturnValue());
				component.set('v.content',str);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                component.set('v.content', errors[0].message);
            }
            console.log('content ' + JSON.stringify(component.get("v.content")));
            $A.get('e.force:refreshView').fire();
        });
        // Send action off to be executed
        $A.enqueueAction(action);
    },
    
    loadQuotes : function(component, event, helper) {
        var queryToGetAllQuotesOnOppty = ''; 
        if(component.get("v.sObjectInfo.Id")!=null )
        queryToGetAllQuotesOnOppty =
        'SELECT Id, Name, SBQQ__Primary__c, SBQQ__Opportunity2__c, ' +
        'SBQQ__Opportunity2__r.Name ' +
        'FROM SBQQ__Quote__c ' +
        'WHERE ApprovalStatus__c = \'Approved\' ' +
        'AND SBQQ__Opportunity2__c = \'' + component.get("v.sObjectInfo.Id") + '\' ' +
        'AND SBQQ__Opportunity2__r.Opportunity_Sub_Type__c = \'Renewal\' ' +
        'AND SBQQ__Opportunity2__r.Renewals_Forecast_Risk__c = \'Subscription\' ' +
        'AND SBQQ__Opportunity2__r.StageName NOT IN  (\'6 PO With Channel\', \'7 Closed Lost\',\'7 Closed Won\') ' +
        'ORDER BY SBQQ__Primary__c DESC';
        helper.showSpinner(component, event, helper);
        var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": queryToGetAllQuotesOnOppty
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            helper.hideSpinner(component, event, helper);
            if (state === "SUCCESS") {
                var str = response.getReturnValue();
                console.log(' str ' + JSON.stringify(str));
                var quotes = response.getReturnValue();
                var quoteMap = {};
                quotes.forEach(q => {
                    quoteMap[q.Id] = q;
                });
                    component.set("v.quoteMap", quoteMap);
                    component.set("v.approvedQuotes",quotes);
               if (quotes && quotes.length > 0) {
                    component.set("v.isOpen", true);
                } else {
                    var sObjectInfo = JSON.parse(JSON.stringify(component.get("v.sObjectInfo")));
                    sObjectInfo.Send_Hold_Off_Email__c = true;
                    
                    if (sObjectInfo.StageName !== '6 PO With Channel') {
                    sObjectInfo.PO_Received_Notification_Sent__c = true;
                }
                    component.set("v.sObjectInfo", sObjectInfo);
                    helper.handlesaveOpp(component, event, helper);
                }     



            }else if (state === "ERROR") {
                    var errors = response.getError();
                    component.set('v.content', errors[0].message);
                }
        });
                    // Send action off to be executed
            $A.enqueueAction(action);
    },    

    // function automatic called by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
     
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    }
})