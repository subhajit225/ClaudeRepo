({
	/* Search event handler which captures value of searched text */
    handlesearchEvent :  function(component, event, helper) {
        var searchEventVal = event.getParam("searchText");
        component.set("v.searchText",searchEventVal);
        component.set("v.pfList", []);
        component.set("v.IdSet",[]); 
        component.set("v.sortedByValue",null);
        helper.initData(component, event, helper,'');
    },
    /* This method is inoked at load of the component. Used for setting columns and fetching records from backend */
    doInit : function(component, event, helper) {
        console.log(component.get("v.sortedDirection")+' Field '+component.get("v.sortedBy"));
        helper.initData(component, event, helper,'doInit');
            component.set('v.col', [
                {label: 'Name', fieldName: 'linkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'Title' }, target: '_self'}, cellAttributes: { class: 'custom-column'}},
                {label: 'Status', fieldName: 'Status', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label: 'Is Expired', fieldName: 'Is_Expired__c', type: 'boolean', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label: 'Start Date', fieldName: 'Activity_Start_Date__c', type: 'date-local', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label: 'End Date', fieldName: 'Activity_End_Date__c', type: 'date-local', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label: 'Type', fieldName: 'Activity', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label: 'Approved Amount', fieldName: 'Amount', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label: 'PO Number', fieldName: 'PO_Number__c',type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label: 'Submitted by', fieldName: 'Submitted_by_Partner_Contact__c', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
                {label:'Action', type: "button", typeAttributes: {
                label: 'Create Claim',name: 'Claim',title: 'Claim',disabled:{fieldName :'disableButton'},value: 'Claim',iconPosition: 'left'}, cellAttributes: { class: 'custom-column claim-button'}},
            ]);
        helper.getFiscalYearData(component, event, helper);
    },
    /* When a field is sorted. It invokes this method which captured field api name of sorted field and its direction*/
     handleColumnSorting : function(component, event, helper) {
		var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
         component.set("v.sortedBy", fieldName);
         if(fieldName == 'linkName'){
             component.set("v.sortedBy", "Title");
         }
        component.set("v.sortedDirection", sortDirection);
        console.log('@@ fieldName '+fieldName+' sortDirection '+sortDirection);  
        component.set("v.pfList", []);
        component.set("v.IdSet",[]); 
        component.set("v.sortedByValue",null);
        helper.initData(component, event, helper,'');
	},
    
    handleRowAction : function(component, event, helper) {
        var recId = event.getParam('row').Id;
        var actionName = event.getParam('action').name;
         var saveAction = component.get("c.getStatus");
        saveAction.setParams({
            mdfId: recId
             
        });
        saveAction.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state'+state);
            if(state === "SUCCESS") {
                if(response.getReturnValue() == false || response.getReturnValue() === 'false'){
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Error",
                        "message": "Claim can submit only for Approved MDF with past Activity End date",
                        "type" : "error"
                    });
                    resultsToast.fire();
                    
                }else{
                    helper.navigateToURL(component, event, "/fundclaimnew?recordId="+recId); 
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } 
        });
        $A.enqueueAction(saveAction);
        
    },

    handleFiscalYearChange : function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        var fiscalData = component.get('v.fiscalYearData');
        for(var i=0; i<fiscalData.length; i++){
            if(fiscalData[i].Name == selectedOptionValue){
                component.set("v.startDate",fiscalData[i].StartDate);
                component.set("v.endDate",fiscalData[i].EndDate);
            }
        }
        component.set("v.IdSet",[]);
        helper.initData(component, event, helper, 'handleFiscalYearChange');
    },
    
    handleAccountFilter : function(component, event, helper){
        var eventValues = event.mp;
        var accIds = [];
        for(let key in eventValues){
            accIds[key] = eventValues[key];
        }
        component.set("v.accIds",accIds);
        component.set("v.IdSet",[]);
        helper.initData(component, event, helper, 'handleAccountFilter');
    },

    handleReset : function(component, event, helper){
        component.set("v.fiscalYear",'');
        component.set("v.accIds",[]);
        component.set("v.searchText",'');
        component.find("accountHierarchy").reset();
        component.set("v.startDate",'');
        component.set("v.endDate",'');
        component.set("v.IdSet",[]);

        helper.initData(component, event, helper, 'handleReset');
    }
})