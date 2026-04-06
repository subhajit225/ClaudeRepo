({  
    setupTableForSaas : function(component) {
        var action = component.get("c.fetchSaasRecords");
        action.setParams({
            'quoteId' : component.get("v.recordId")
        }); 
        action.setCallback(this,function(response){
            this.getRecordsforTable(component, response , 'saas');
        });
        $A.enqueueAction(action);
    },   
      
    setupTableForGo : function(component) {
        var action = component.get("c.fetchGoRecords");
        action.setParams({
            'quoteId' : component.get("v.recordId"),
            'category' : "Go to Scale replacement"
        });
        action.setCallback(this,function(response){
            this.getRecordsforTable(component, response , 'goRep');
        });
        $A.enqueueAction(action);
    },
    
    setupTableForLoD : function(component) {
        var action = component.get("c.fetchLoDRecords");
        action.setParams({
            'quoteId' : component.get("v.recordId"),
            'category' : ""
        });
        action.setCallback(this,function(response){
            this.getRecordsforTable(component, response , 'lodRep');
        });
        $A.enqueueAction(action);
    },
    
    setupTableForRSCG : function(component) {
        var action = component.get("c.fetchGoRecords");
        action.setParams({
            'quoteId' : component.get("v.recordId"),
            'category' : 'RSC to RSC-G'
        });
        action.setCallback(this,function(response){
            this.getRecordsforTable(component, response , 'rscgRep');
        });
        $A.enqueueAction(action);
    },
    
    setupTableForSSG : function(component) {
        var action = component.get("c.fetchGoRecords");
        action.setParams({
            'quoteId' : component.get("v.recordId"),
            'category' : 'SAAS-SAAS-G'
        });
        action.setCallback(this,function(response){
            this.getRecordsforTable(component, response , 'ssgRep');
        });
        $A.enqueueAction(action);
    },
    
    setupTableForLoDRscG : function(component) {
        var action = component.get("c.fetchLoDRecords");
        action.setParams({
            'quoteId' : component.get("v.recordId"),
            'category' : 'LOD-RSC-G'
        });
        action.setCallback(this,function(response){
            this.getRecordsforTable(component, response , 'lodrscgRep');
        });
        $A.enqueueAction(action);
    },   

    // CPQ22-3773 Starts
    
    showToastEvent : function(component){
        var valueMap = component.get("v.mapOfBundleIdvsAssetIds");
        var eligibleSkus = component.get("v.dsaasSKUs");
        console.log('valueMap== '+JSON.stringify(valueMap)); 
	console.log('eligibleSkus',eligibleSkus);
        console.log('is current sku eligible',eligibleSkus.includes(valueMap[component.get("v.selectedRecordId")]));
        if(eligibleSkus.includes(valueMap[component.get("v.selectedRecordId")])){
            component.set("v.isModalOpen", true);       
            component.set("v.isLoading", false);  
        }
    },
    // CPQ22-3773 Ends
    createReplaceSKUs : function(component, event, helper) {
    	var action = component.get("c.replaceSKUs");
        var valueMap = component.get("v.mapOfBundleIdvsAssetIds");
        if ((Object.keys(valueMap).length == 1 && valueMap[component.get("v.selectedRecordId")] == '') || Object.keys(valueMap).length == 0) {
            component.set("v.showmsg", true);
            component.set("v.buttonsDisabled", true);
            component.set("v.errorMessage", "Please select a Replacement SKU and then hit on Save");
            component.set("v.isLoading", false);
        }
        else {
            component.set("v.showmsg", false);
            component.set("v.buttonsDisabled", false);
            action.setParams({
                quoteId : component.get("v.recordId"), 
                saasRecs : component.get("v.saasToShow"),
                goRecs : component.get("v.goToShow"),
                assetRecs : component.get("v.lodToShow"),
                rscgRecs : component.get("v.rscGToShow"),
                ssgRecs : component.get("v.ssGToShow"),
                lodRsgRecs : component.get("v.lodrsgToShow"),
                selectedRecords : component.get("v.mapOfBundleIdvsAssetIds")
            });
            action.setCallback(this,function(response){
                if(response.getState() === "SUCCESS"){
                    helper.navigateToQLEScreen(component);
                }else{
                    var errors = response.getError();
                    
                    if(errors && Array.isArray(errors) && errors.length > 0)
                    var message = "Error: "+errors[0].message;
                    component.set("v.error", message);
                    console.log("Error: "+message+" Please contact your system administrator.");
                    component.set("v.showmsg", true);
                    component.set("v.buttonsDisabled", true);
                    component.set("v.errorMessage", message);
                    component.set("v.isLoading", false);
                }
            });
            $A.enqueueAction(action);
        }
	},
        
    navigateToQLEScreen : function(component) {
        component.set("v.isLoading", false);
        var urlString = window.location.origin;
        var callingSource = component.get("v.callingSource");
        var quoteId = component.get("v.recordId");
        urlString = urlString.replace('c.', 'sbqq.');
        urlString = urlString + '/apex/sb?scontrolCaching=1&id=' + quoteId;
        if (callingSource == 'QuoteDetail') {
            urlString = '/' + quoteId;
        }
        console.log('urlString-'+urlString);
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            // Do something for Lightning Experience
            //sforce.one.navigateToURL(link);
            //sforce.one.navigateToURL(urlString);
            window.location.replace(urlString);
        } else {
            // Use classic Visualforce
            window.location.href = urlString;
        }
    },
    
    getRecordsforTable : function(component, response, source) {
        if(response.getState() === "SUCCESS"){
            var allRecords = response.getReturnValue();
            if (source == 'saas') {
                component.set("v.saasToShow", allRecords);
            } else if (source == 'goRep') {
                component.set("v.goToShow", allRecords);
            } else if (source == 'lodRep') {
                component.set("v.lodToShow", allRecords);
            } else if (source == 'rscgRep') {
                component.set("v.rscGToShow", allRecords);
            } else if (source == 'ssgRep') {
                component.set("v.ssGToShow", allRecords);
            } else if (source == 'lodrscgRep') {
                component.set("v.lodrsgToShow", allRecords);
            }
            component.set("v.isLoading", false);
        }else{
            var errors = response.getError();
            
            if(errors && Array.isArray(errors) && errors.length > 0)
            var message = "Error: "+errors[0].message;
            component.set("v.error", message);
            console.log("Error: "+message+" Please contact your system administrator.");
            component.set("v.showmsg", true);
            component.set("v.buttonsDisabled", true);
            component.set("v.errorMessage", message);
            component.set("v.isLoading", false);
        }
    },
    getRunningProf: function(component, event, helper) {
        var loggedProfileName = '';
        var action = component.get("c.getQuoteFieldValuesFromApex");
        action.setParams({
            quoteId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            loggedProfileName = response.getReturnValue().Running_User_Profile__c;
            
            if ($A.get("$Label.c.Replacement_Access_Profiles").includes(loggedProfileName)) {
                component.set("v.accessGiven", true);
                component.set("v.isLoading", false);
            }
            else {
                component.set("v.accessGiven", false);
                //component.set("v.showmsg", true);
                //component.set("v.buttonsDisabled", true);
                //component.set("v.errorMessage", "You do not have access to perform Replacement. Please contact Deal Ops for assistance");
                //component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    }
})