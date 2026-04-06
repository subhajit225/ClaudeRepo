({
    /*
     * This finction defined column header
     * and calls getAccounts helper method for column data
     * editable:'true' will make the column editable
     * */
    doInit : function(component, event, helper) {  
        var pageReference = window.location.href;
        console.log(pageReference);
        var url = new URL(pageReference);
        var projectId = url.searchParams.get("projectId");
        if(!projectId){	
            var myPageRef = component.get("v.pageReference");	
            projectId = component.get("v.pageReference").attributes.attributes.projectId;	
        }
        component.set("v.projectId", projectId);
        console.log(projectId);
 /*       component.set('v.columns', [
            {label: 'Name', fieldName: 'Name', type: 'text', 
             actions:[
                 {label: 'All',
                  checked: false,
                  name:'All'},
                 {label: 'Active',
                  checked: false,
                  name:'Active'}]},
            {label: 'Phone', fieldName: 'Phone', type: 'phone'},
            {label: 'Active', fieldName: 'Industry', type: 'text'}
            // ,
            // {label: 'Custom Field', fieldName: 'My_Custom_Field__c', type: 'text'}
        ]);*/
        
        helper.getColumnAndAction(component);
        helper.getOrders(component, helper,projectId);
    },
    
    onNext : function(component, event, helper) { 
        //get current page numbe
        var pageNumber = component.get("v.pageNumber");
        //Setting current page number
        component.set("v.pageNumber", pageNumber+1);
        //Setting pageChange variable to true
        component.set("v.hasPageChanged", true);
        helper.getOrders(component, helper, component.get("v.projectId"));
    },
    
    onPrev : function(component, event, helper) {        
        //get current page number
        var pageNumber = component.get("v.pageNumber");
        //Setting current page number
        component.set("v.pageNumber", pageNumber-1);
        //Setting pageChange variable to true
        component.set("v.hasPageChanged", true);
        
        helper.getOrders(component, helper, component.get("v.projectId"));
        
    },
      handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        switch (action.name) {
            case 'edit':
                helper.editRecord(component, event);
                break;
            case 'delete':
                helper.deleteRecord(component, event);
                break;
            case 'view':
                helper.viewRecord(component, event);
                break;
        }
    },
    /**
     * This method will keep record of all selected rows
     * */
    onRowSelection : function(component, event, helper) {
        // Avoid any operation if page has changed
        // as this event will be fired when new data will be loaded in page 
        // after clicking on next or prev page
		var selectMap = {};
        var temparr = [];
        if(component.get("v.selectMap") != null){
        	selectMap = component.get("v.selectMap");
        }
        var pg = component.get("v.pageNumber");
        pg--;
        if(!component.get("v.hasPageChanged") || component.get("v.initialLoad")){
			//set initial load to false
            component.set("v.initialLoad", false);
            
            //Get currently select rows, This will only give the rows available on current page
            var selectedRows = event.getParam('selectedRows');
            if(selectMap != null && selectMap.length >= pg){
                selectMap[pg] = [];
            }
            selectedRows.forEach(function(row) {
                temparr.push(row);
            });
            selectMap[pg] = temparr;
            component.set("v.selectMap",selectMap);
            //Get all selected rows from datatable, this will give all the selected data from all the pages
            var allSelectedRows = [];
           	 for (var k in selectMap) {
                selectMap[k].forEach(function(row) {
                	allSelectedRows.push(row.Id);
                });
            }


            //Setting new value in selection attribute
            component.set("v.selection", allSelectedRows);
            console.log(component.get("v.selection"));
        } else{
             component.set("v.hasPageChanged", false);
        }
    },
     makeSelection: function(component, event, helper) {
         helper.assignOrders(component, event, helper);
     },
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    }
    
})