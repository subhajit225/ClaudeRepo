({
    doInit: function(component, event, helper) {
        // CS21-2005
        var RSC_G_Allowed_Values = $A.get("$Label.c.FedRAMP_RSC_G_For_Case_Creation");
        let device = $A.get("$Browser.formFactor");
        let isPhone =  device == 'PHONE' ? true : false;
        component.set("v.isPhone", isPhone);
       var govCloudLink=$A.get("$Label.c.Admin_Panel_Link_GovCloud");
       var userId = $A.get("$SObjectType.CurrentUser.Id");
       var adminLink=govCloudLink+userId; 
       component.set("v.adminPanelLink",adminLink);
       var rubrikGovSupportEmail=$A.get("$Label.c.GovCloud_Support_Email");
       var emailMailTo="mailto:"+rubrikGovSupportEmail;
       component.set("v.govSupportEmail",emailMailTo);
       
        var action = component.get("c.getPickListValuesIntoList");
        action.setCallback(this, function(a) {
            let res = a.getReturnValue();
            // CS21-2005: [FedRAMP] Enable case creation on the Rubrik Support Portal for hybrid RSC-G/RSC/CDM customers 
            // 1: When Account RSC-G Support is blank
            if(!res.rscSupport){
                // User navigates to case submission form
            }
            // 2: When Account RSC-G Support contains CDM in multipicklist values
            else if(res.rscSupport.includes(RSC_G_Allowed_Values)){
                // Display case creation prompt and proceed to case submission form
                component.set("v.isRscgConnectedCdmCustomer", true);
            }
            // 3: When Account RSC-G Support is RSC Only
            else if(!res.rscSupport.includes(RSC_G_Allowed_Values)){
                // Display disable case creation prompt
                component.set("v.isRscOnly", true);
            }
            if(res.accDetail != null && res.accDetail.Tabs_Visibility__c != null && res.accDetail.Tabs_Visibility__c.includes('Predibase')){
                component.set("v.isPredibaseCustomer", true);
                component.set("v.newCase.Platform__c",'Predibase');
                component.set("v.newCase.Type",'Software');
                component.set("v.newCase.Sub_Component__c",'Other (specify)');
                component.set("v.newCase.If_Other__c",'Predibase');
            }
            component.set("v.toggleSpinner", false);
            component.set("v.priorityOptions", res.priorityOptions);
            component.set("v.hasAccess", res.hasAccess);
            component.set("v.accDetail", res.accDetail);
            component.set("v.typeOptions", res.typeOptions);
            component.set("v.contactOptions", res.ContactMethodOptions);
            component.set("v.OnCaseSubmit", true);
            let filterForCluster = 'For Portal';
            let rscInstanceFilter= 'For Portal';
            component.set("v.clusterfilter", filterForCluster);
            component.set("v.clusterfieldHelptext", res.clusterHelptext);
            component.set("v.rscInstanceFilter", rscInstanceFilter);
        });
        $A.enqueueAction(action);
    },

    // CS21-2005: [FedRAMP] Enable case creation on the Rubrik Support Portal for hybrid RSC-G/RSC/CDM customers 
    handleCaseSubmission: function(component, event, helper) {
        component.set("v.isRscgConnectedCdmCustomer", false);
        component.set("v.isRscOnly", false);
    },

    onPicklistChange: function(component, event, helper) {
        //get the value of select option
        var selectedpriority = component.find("Inputcasepriority");
        alert(selectedpriority.get("v.value"));
    },

    createCase : function(component, event, helper) {
        component.set("v.toggleSpinner", true);
        helper.checkValidation(component, helper, false);
    },

    createCasewithAtt : function(component, event, helper) {
        component.set("v.toggleSpinner", true);
        helper.checkValidation(component, helper, true);
    },

    cancel : function(component, event, helper) {
        component.set('v.FieldChangeCheck',false);
        window.location.href='./my-cases';
    },

    getArticles : function(component, event, helper) {
        component.set("v.ttimeout", null);
        console.log('event', event);
        var searchstring = component.find("sub").get("v.value");
        /* SU CODE */
        var data = {
            "searchString":searchstring,
            "pageSize": "5"
        };
        var child = component.find("listResults");
        child.suggestedResult(data);
        /* SU CODE */
    },
    
    handleChange : function(component, event, helper) {     
        helper.HelperFieldChange(component, event);
    },
    
    generateResults : function(component, event, helper) {
        helper.HelperFieldChange(component, event);
        var ttimeout = component.get("v.ttimeout");
        if(ttimeout != null) {
            clearTimeout(ttimeout);
        }
        var a = component.get('c.getArticles');

        component.set("v.ttimeout", setTimeout($A.getCallback(function() {$A.enqueueAction(a)}) , 1000));
    },

    handleComponentEvent: function(component, event, helper){
         /* SU CODE for component */
        var componentAttr = event.getParam("searchObject");
        var data = JSON.parse(JSON.stringify(componentAttr));
        component.set("v.conversionData", data);
        if(componentAttr.conversionString)
            component.set("v.conversionString", componentAttr.conversionString); 
        if(componentAttr.conversion)
            component.set("v.conversion", true);
    },

    // Added by Vijay Kumar K R: CS21-1206
    getSelectedValue : function(component, event, helper) {
        let selectedClusterId = event.getParam('selectedRecord').Id;
        var action = component.get("c.checkClusterSoftwareVersion");
        action.setParams({ "clusterId": selectedClusterId });
        action.setCallback(this, function(a) {
            let res = a.getReturnValue();
            console.log('res:: ',res);
            if(res == 'Unsupported CDM software version'){
                component.set("v.isUnSupportedCluster", true);
            }else{
                component.set("v.isUnSupportedCluster", false);
            }
        });
        $A.enqueueAction(action);
        
        component.set("v.newCase.Cluster__c", event.getParam('selectedRecord').Id);
    },

    getSelectedRscInstance : function(component, event, helper) {
        component.set("v.newCase.RSCInstance__c", event.getParam('selectedRecord').Id);
    },
    
    closeModal : function(component, event, helper){
        component.set("v.createCaseComment", true);
    	component.set("v.isUnSupportedCluster",false);
    },
    
    handleRemoveSelected: function(component, event, helper){
        component.set("v.createCaseComment", false);
    	component.set("v.isUnSupportedCluster",false);
    },
})