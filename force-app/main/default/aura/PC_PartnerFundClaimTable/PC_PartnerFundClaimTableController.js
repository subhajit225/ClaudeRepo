({
	/* Search event handler which captures value of searched text */
    handlesearchEvent :  function(component, event, helper) {
        var searchEventVal = event.getParam("searchText");
        component.set("v.searchText",searchEventVal);
        component.set("v.pfcList", []);
        component.set("v.IdSet",[]); 
        component.set("v.sortedByValue",null);
        helper.initDatapfc(component, event, helper,'');
    },
    
    handleDestroy : function(component, event, helper) {
        component.set("v.screenHeightCss", '');
    },
    /* This method is inoked at load of the component. Used for setting columns and fetching records from backend */
    doInitpfc : function(component, event, helper) {
        var styleString = "<style>.primaryFieldRow .slds-has-flexi-truncate {flex: initial !important; } .primaryFieldRow .slds-button--neutral { background-color: #0070d2; border-color: #0070d2;} .primaryFieldRow .forceActionLink {color: #fff !important;}  <style>"
		component.set("v.screenHeightCss", styleString); 
        
        console.log(component.get("v.sortedDirection")+' Field '+component.get("v.sortedBy"));
        helper.initDatapfc(component, event, helper,'doInit');
            component.set('v.col', [
                {label: 'Fund Claim ID', fieldName: 'linkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'Claim_Number__c' }, target: '_self'}},
                {label: 'Claim Approval Status', fieldName: 'Status', type: 'text', sortable : true},
                {label: 'Claim Amount', fieldName: 'Amount', type: 'text', sortable : true, initialWidth: 135},
                {label: 'Description', fieldName: 'Description', type: 'text', sortable : true}
            ]);
    },
    /* When a field is sorted. It invokes this method which captured field api name of sorted field and its direction*/
     handleColumnSortingpfc : function(component, event, helper) {
		var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
         component.set("v.sortedBy", fieldName);
         if(fieldName == 'linkName'){
             component.set("v.sortedBy", "Title");
         }
        component.set("v.sortedDirection", sortDirection);
        console.log('@@ fieldName '+fieldName+' sortDirection '+sortDirection);  
        component.set("v.pfcList", []);
        component.set("v.IdSet",[]); 
        component.set("v.sortedByValue",null);
        helper.initDatapfc(component, event, helper,'');
	},

})