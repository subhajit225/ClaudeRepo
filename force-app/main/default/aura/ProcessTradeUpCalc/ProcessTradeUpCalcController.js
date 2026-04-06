({         
    doInit : function(component, event, helper) {
        component.set("v.isLoading", true);
        var trueUpWarningMsg = $A.get("$Label.c.TradeUp_Sales_Rep_Exception_Warning");  
        component.set("v.trueUpWarningMsg",trueUpWarningMsg);
        helper.setupTable(component);
        helper.getNumberOfBundles(component);
    },
    
    saveTableRecords : function(component, event, helper) {
        var recordsData = event.getParam("recordsString"); 
        var tableAuraId = event.getParam("tableAuraId");
        var action = component.get("c.updateRecords");
        action.setParams({
            jsonString: recordsData
        });
        action.setCallback(this,function(response){
            var datatable = component.find(tableAuraId);
            datatable.finishSaving("SUCCESS");
        });
        $A.enqueueAction(action);        
    },
    getValueFromApplicationEvent : function(component, event) {
        var ShowResultValue = event.getParam("Pass_Result");
       	var bundleRecordId = event.getParam("bundleRecordId");
        var numberOfAssets = event.getParam("numberOfAssets");
        // set the handler attributes based on event data
        component.set("v.selectedRecords", ShowResultValue);
        component.set("v.bundleRecordId", bundleRecordId);
        component.set("v.numberOfAssets", numberOfAssets);
        if (component.get("v.bundleRecordId") != undefined) {
            var newMap = component.get("v.mapOfBundleIdvsAssetIds");
        	newMap[component.get("v.bundleRecordId")] =  component.get("v.selectedRecords");
        	component.set("v.mapOfBundleIdvsAssetIds", newMap);
            var mapOfCount = component.get("v.mapOfBundleIdvsNumberOfAssets");
            mapOfCount[component.get("v.bundleRecordId")] =  component.get("v.numberOfAssets");
            component.set("v.mapOfBundleIdvsNumberOfAssets", mapOfCount);
        }
    },
    validate : function(component, event, helper) {
        component.set("v.isLoading", true);
        component.set('v.validated', false);
        var selectedRecords = component.get('v.selectedRecords');
        console.log('selected val:'+selectedRecords);
        var action = component.get("c.validateAssets"); 
        action.setParams({ 
            quoteId : component.get("v.recordId"),
            mapOfReqByVsEnt : component.get("v.mapOfBundleIdvsAssetIds"),
            mapOfReqByVsCount : component.get("v.mapOfBundleIdvsNumberOfAssets")
        });
        action.setCallback(this, function(response){
             var state = response.getState();
             if (state === "SUCCESS") {
                //helper.calcConfirmation(component, event, helper);
                var validationMessages = response.getReturnValue();
                 var errorMessages = JSON.stringify(validationMessages);
                 console.log("Sumedha validationMessages : " + validationMessages);
                 if (validationMessages == '') {
                     helper.callCalcConfirmationFromMap(component, event, helper);
                 }
                 else {
                     var toastEvent = $A.get("e.force:showToast");
                     if (toastEvent != undefined) {
                         toastEvent.setParams({ 
                         title: "Error!", 
                         type: "error", 
                         message: errorMessages 
                         });
                         toastEvent.fire();
			 			component.set("v.isLoading", false);
                     }
                     else {
                         alert(validationMessages);
                         component.set("v.isLoading", false);
                     }
                 }
             }
             else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Sumedha Error message: " + errors[0].message);
                        alert('Failed');
                    }
                }
             }
         });
        /*component.set("v.comeBack", false);
        console.log('Selected Next-->'+JSON.stringify(component.get("v.mapOfBundleIdvsAssetIds")));
        
        var currentTab = component.get("v.selTabId");
         
        if(currentTab == 'tab1'){
            component.set("v.selTabId" , 'tab2');   
        }*/
         $A.enqueueAction(action);
	},
    goBack :  function(component, event, helper) {
         var urlString = window.location.origin;
        var callingSource = component.get("v.callingSource");
        var quoteId = component.get("v.recordId");
        urlString = urlString.replace('c.','sbqq.');
        console.log('urlString>>',urlString);
        urlString = urlString + '/apex/sb?scontrolCaching=1&id='+quoteId;
        
        console.log('FinalurlString>>',urlString);
        
        if(callingSource == 'QuoteDetail'){
            urlString = '/'+quoteId;
        }
        if((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            // Do something for Lightning Experience
            console.log('testing lightning exp');
            sforce.one.navigateToURL(urlString);
        }
        else {
            // Use classic Visualforce
            console.log('testing classic exp');
            window.location.href =  urlString ;
        }
    },
    lastSave : function(component, event, helper) {
        component.set("v.isLoading", true);
        let validAmts = true;
        
        var recordToUpdate = component.get('v.recordsToUpdate');
        recordToUpdate.forEach(function(ql) {
            console.log('Pradeep >> '+ ql);
            console.log('Madhura >> '+ ql.Trade_Up_Discount__c);
            if(ql.Expected_Trade_Up_Discount__c!=null && ql.Expected_Trade_Up_Discount__c < ql.Trade_Up_Discount__c){
                console.log('Pradeep In ERROR ');
                validAmts = false;
                
                var toastEvent = $A.get("e.force:showToast");
                    if (toastEvent != undefined) {
                        toastEvent.setParams({ 
                            title: "Error!", 
                            type: "error", 
                            message: 'Trade Up Discount($'+ql.Trade_Up_Discount__c+') should be less than Expected Trade Up Discount($'+ql.Expected_Trade_Up_Discount__c+')' 
                        });
                        toastEvent.fire();
                    }
                    else {
                        alert('Trade Up Discount($'+ql.Trade_Up_Discount__c+') should be less than Expected Trade Up Discount($'+ql.Expected_Trade_Up_Discount__c+')');
                    }
                
                
                 }
        });
        if(validAmts){
            helper.lastSave(component, event, helper);
        }else{
            component.set("v.isLoading", false);
        }
        
    },
    clearValues : function(component, event, helper) {
        component.set("v.isLoading", true);
        var field = event.getSource();
        var recordId = field.get("v.value").toString();
	// added by madhura to clear out the initialisation 
        component.set("v.mapOfBundleIdvsAssetIds",{});
        component.set("v.mapOfBundleIdvsNumberOfAssets",{});
        console.log('recordId-->'+recordId);
        var action = component.get("c.clearRecords");
        action.setParams({
            quoteId: component.get("v.recordId"),
            bundleId: field.get("v.value").toString()
        });
        action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS"){
                var result = response.getReturnValue();
                component.set("v.recordsToUpdate", result);
                component.set("v.isLoading", false);
                
            }else{
                var errors = response.getError();
                var message = "Error: Unknown error";
                if(errors && Array.isArray(errors) && errors.length > 0)
                message = "Error: "+errors[0].message;
                component.set("v.error", message);
                console.log("Error: "+message);
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action); 
        component.updateAcc(); 
    }
})