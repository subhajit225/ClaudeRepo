({ 
    doInit : function(component, event, helper) {
        //Comment here
        var value = component.get('v.value');
        var searchText = component.get('v.searchString');
        component.set("v.callcluster",true);
        var quoteQuery = 'select Id,StartDate,EndDate,AccountId,(select  Id,Start_Date__c,End_Date__c,createdDate,Warranty_Status__c,Warranty_Compliant__c,CEM_Notes__c,CEM_Health_Check_Date__c,Entitlement__c,Entitlement__r.AccountId,Entitlement__r.StartDate,Entitlement__r.EndDate, Cluster__c,Cluster__r.Name from Entitlement_Warrenty_Details__r order by createddate Desc limit 1) from entitlement where  Id = \''+ component.get("v.recordId") + '\'';
        helper.executeQuery(component, event, helper, quoteQuery, 'entitlementSupportRec');

    },
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault(); //Prevent default submit
        helper.handleOnSubmit(component, event, helper);
    },
    goToRec : function(component, event, helper) {
        helper.gotoRec(component, component.get("v.entitlementSupportRec").Id);
    },
    
    handleCancel : function(component, event, helper) {
         component.set("v.reloadForm", false);
        component.set("v.reloadForm", true);
        component.set("v.isReadOnly", true);
        if(component.get("v.entitlementSupportRec")!= null && component.get("v.entitlementSupportRec").Cluster__c != null){
           component.set("v.clusterid",component.get("v.entitlementSupportRec").Cluster__c);
           component.set("v.searcht",component.get("v.entitlementSupportRec").Cluster__r.Name);
            component.set("v.selectedLabel",component.get("v.entitlementSupportRec").Cluster__r.Name);
        }else{
            component.set("v.clusterid",null);
            component.set("v.searcht",null);
            component.set("v.selectedLabel",null);
        }
    },
    
    checkUploadField : function(component, event, helper) {
        component.set("v.renderCluster", false);
        component.set("v.openmodel",true);
        
        
    },
    
    hidePicklist : function(component, event, helper) {
        if(component.get("v.isReadOnly")) return;
         window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showpicklist",false);
            }), 500
        );
        if(component.get("v.selectedLabel") != component.get("v.searcht")  ){
        component.set("v.clusterid",null);
        component.set("v.searcht",null);
        }  
        
        
        
    },
    
    searchField : function(component, event, helper) {
        console.log("searchField is called103");
        component.set("v.clusterid",null);
        var searchedString = component.get("v.searcht");
         var options = component.get("v.options");
        var minChar = component.get('v.minChar');
        if(searchedString!=null && searchedString.length>=minChar && options!= null ){
            options.forEach( function(element,index) {
                if(element.Name.toLowerCase().trim().includes(searchedString.toLowerCase().trim())) {
                    element.isVisible = true;
                } else {
                    element.isVisible = false;
                }
            });
            component.set("v.options",options);
            if(options.length>=1){
                component.set("v.showpicklist",true);
            }
        }
    },
    
    itemSelected : function(component, event, helper) {
        	    var clusterid = event.target.getAttribute("data-name");
        	    var label = event.target.getAttribute("label");
				component.set("v.clusterid",event.currentTarget.id);
                component.set("v.searcht",event.currentTarget.name);
        		component.set("v.selectedLabel",event.currentTarget.name);
        	    component.set("v.showpicklist",false);
    },
    closeModal : function(component,event,helper){
       component.set('v.openmodel',false);
        
    },
    upload: function(component, event, helper) {
       component.set('v.openmodel',false);
       component.set('v.showButton',false);
      component.set('v.setUploadAttribute',true);  
       
    },    
    
    
    
    editableForm : function(component, event, helper) {
        component.set("v.renderCluster", false);
        component.set("v.renderCluster", true);
        component.set("v.isReadOnly", false);
    },
    handleCreateLoad: function(component, event, helper) {
        component.set("v.showSpinner", false);
    },
})