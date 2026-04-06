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
                {label: 'Partner Fund Claim Name', fieldName: 'linkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'Title' }, target: '_self'}},
                {label: 'Claim Approval Status', fieldName: 'Status', type: 'text', sortable : true},
                {label: 'Activity Id', fieldName: 'reqlinkId', type: 'text', sortable : true},
                {label: 'Activity Name', fieldName: 'reqlinkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'reqTitle' }, target: '_blank'}},
                {label: 'Claim Amount', fieldName: 'Amount', type: 'text', sortable : true},
                {label: 'Description', fieldName: 'Description', type: 'text', sortable : true}
            ]);
    },
    /* When a field is sorted. It invokes this method which captured field api name of sorted field and its direction*/
     handleColumnSorting : function(component, event, helper) {
		var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
         component.set("v.sortedBy", fieldName);
         if(fieldName == 'linkName'){
             component.set("v.sortedBy", "Title");
         }
         if(fieldName == 'reqlinkName'){
             component.set("v.sortedBy", "Request.Title");
         }
         if(fieldName == 'reqlinkId'){
             component.set("v.sortedBy", "Request.Request_Number__c");
         }
        component.set("v.sortedDirection", sortDirection);
        console.log('@@ fieldName '+fieldName+' sortDirection '+sortDirection);  
        component.set("v.pfList", []);
        component.set("v.IdSet",[]); 
        component.set("v.sortedByValue",null);
        helper.initData(component, event, helper,'');
	},

})