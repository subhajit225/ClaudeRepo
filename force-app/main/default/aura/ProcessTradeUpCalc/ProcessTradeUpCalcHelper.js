({  
    setupTable : function(component) {
        var action = component.get("c.fetchQuoteLineRecords");
        action.setParams({
            'quoteId' : component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS"){
                var allRecords = response.getReturnValue();
                allRecords.forEach(rec => {
                    rec.accountLink = '/'+rec.Id;
                });
                var result = response.getReturnValue();
                var qlLst = [];
                // code added by Prasenjeet start 
                
                result.forEach(function(Item){
                    
                     /*if(Item.SBQQ__Product__r.Tradeup_Pattern__c!= null && Item.SBQQ__Product__r.Tradeup_Pattern__c!='' && Item.SBQQ__Product__r.Tradeup_Pattern__c.includes('Sales Rep Exception') &&  (Item.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c== null || Item.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c== 'undefined'  || !Item.SBQQ__Quote__r.RWD_Sales_Rep_Exception__c.includes('Trade Up - FE - Exceptions'))){
                        component.set("v.hasFE", true);
                        console.log('HAS FE');
                    }else{*/
                     qlLst.push(Item);
                      console.log('Not FE');
                //}
                }); 
                component.set("v.data", qlLst);
                component.set("v.isLoading", false);
            }else{
                var errors = response.getError();
                var message = "Error: Unknown error";
                if(errors && Array.isArray(errors) && errors.length > 0)
                    message = "Error: "+errors[0].message;
                component.set("v.error", message);
                console.log("Error: "+message);
            }
        });
        $A.enqueueAction(action);
    },
   
    getNumberOfBundles : function(component) {
        var action = component.get("c.getNumberOfBundles");
        action.setParams({
            'quoteId' : component.get("v.recordId")
        });
        
        action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS"){
                var result = response.getReturnValue();
                // code added by Prasenjeet start 
                //console.log('result to check',result);
                result.forEach(function(Item){
                    if(Item.Trade_Up_Serial_Number__c){
                  		Item.TradeUpSerialNumbers = Item.Trade_Up_Serial_Number__c.split(",");
                    }
                    
                });
                // code added by Prasenjeet End 
                component.set("v.numberOfBundles", result);
                component.set("v.isLoading", false);
            }else{
                var errors = response.getError();
                var message = "Error: Unknown error";
                if(errors && Array.isArray(errors) && errors.length > 0)
                message = "Error: "+errors[0].message;
                component.set("v.error", message);
                console.log("Error: "+message);
            }
        });
        var evt = $A.get("e.c:Result");
        evt.setParams({ "Pass_Result": component.get("v.numberOfBundles") });
        evt.fire();
        $A.enqueueAction(action);
    },
    
    callCalcConfirmationFromMap : function(component, event, helper){
        console.log('component.get("v.numberOfAssets")-->'+JSON.stringify((component.get("v.mapOfBundleIdvsNumberOfAssets"))));
        console.log('component.get("v.mapOfBundleIdvsAssetIds") ==',JSON.stringify(component.get("v.mapOfBundleIdvsAssetIds")));
        if (component.get("v.mapOfBundleIdvsNumberOfAssets") != undefined) {
            var action = component.get("c.callCalcConfirmationFromMap"); 
            action.setParams({ 
                quoteId : component.get("v.recordId"),
                mapOfReqByVsEnt : component.get("v.mapOfBundleIdvsAssetIds")
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('callCalcConfirmationFromMap val ==',response.getReturnValue());
                    var QLIList = [];
                    response.getReturnValue().forEach(function(QliData){
                        QLIList.push(QliData.Quoteline);
                    });
                    component.set('v.customQLIList', response.getReturnValue());  
                     console.log(' v.customQLIList ====',JSON.stringify(component.get("v.customQLIList")));
                    component.set('v.recordsToUpdate', QLIList);
                    console.log('component.get-->'+JSON.stringify((component.get('v.recordsToUpdate'))));
                    var toastEvent = $A.get("e.force:showToast");
                    if (component.get('v.recordsToUpdate') != '') {
                        
                         component.set('v.validated', true);
                        if (toastEvent != undefined) {
                        toastEvent.setParams({ 
                             title: "Success!", 
                             type: "success", 
                             message: "The Assets are successfully validated. Please find calculated values and click Save." 
                         });
                         toastEvent.fire();
                        
                    }
                    else {
                        alert('The Assets are successfully validated. Please find calculated values and click Save.');
                    }
                        
                    }
                    component.set("v.isLoading", false);
                    
                }
                else {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            alert('Failed');
                        }
                    }
                }
            });
            $A.enqueueAction(action);  
        }
        component.set("v.isLoading", false);
    },
    lastSave :  function(component, event, helper) {
        
        var recordToUpdate = component.get('v.recordsToUpdate');
        var action = component.get("c.callFinalUpdate");
        console.log('component.get("v.customQLIList") ====',JSON.stringify(component.get("v.customQLIList")));
        action.setParams({ 
            quoteLinesToUpdateString : JSON.stringify(component.get("v.customQLIList")),
            mapOfReqByVsEnt : component.get("v.mapOfBundleIdvsAssetIds"),
            quoteId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
             var state = response.getState();
             if (state === "SUCCESS") {
             	component.set("v.isLoading", true);
                 var toastEvent = $A.get("e.force:showToast");
                if (toastEvent != undefined) {
                    toastEvent.setParams({ 
                         title: "Success!", 
                         type: "success", 
                         message: "The Quote Lines are successfully updated." 
                     });
                     toastEvent.fire();
                    component.set("v.isLoading", false);
                }
                else {
                    alert('The Quote Lines are successfully updated.');
                }
                 component.set("v.isLoading", true);
                  //$A.get("e.force:closeQuickAction").fire();
                //MS Change Start
                var url = window.location.href;
                //console.log('url '+url);
                if (url.includes('/lightning/r/')) {
                    // Close the Quick Action modal window
                    var closeQuickAction = $A.get("e.force:closeQuickAction");
                    closeQuickAction.fire();
                } else {
                    var urlString = window.location.origin;
                    //console.log('origin url '+urlString);
                    var quoteId = component.get("v.recordId");
                    urlString = urlString.replace('c.','sbqq.');
                    urlString = urlString + '/apex/sb?scontrolCaching=1&id='+quoteId;
                    
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
                }

                //MS Change End
                
             }
             else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        alert('Failed');
                    }
                }
             }
         });
         $A.enqueueAction(action);
    },              
})