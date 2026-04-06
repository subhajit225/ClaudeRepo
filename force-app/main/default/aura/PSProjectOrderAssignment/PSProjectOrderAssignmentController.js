({
    doInit : function(component, event, helper) { 
        //console.log(component.get("v.pageReference").state.projectId);
        var pageReference = window.location.href;
        console.log(pageReference);
        var url = new URL(pageReference);
        var projectId = url.searchParams.get("projectId");
        console.log(projectId);
        helper.getColumnAndAction(component);
        helper.getOrders(component, helper,projectId);
    },
     
    handleNext : function(component, event, helper) { 
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber+1);
        var projectId = url.searchParams.get("projectId");
        helper.getOrders(component, helper, projectId);
    },
     
    handlePrev : function(component, event, helper) {        
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber-1);
        var projectId = url.searchParams.get("projectId");
        helper.getOrders(component, helper, projectId);
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
})