({
    init : function(component, event, helper) {
        
        component.set('v.mycolumns', [
            {label: 'Version', fieldName: 'Name', type: 'text', sortable: true},
            {label: 'Release Date', fieldName: 'Release_Date__c', type: 'date', sortable: true}
            
        ]);
        
        var action = component.get("c.getReleaseVersions");
        action.setParams({ "polaris" : false }); 
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            if(result == null){
                component.set("v.pageNum",1);
                component.set("v.totalPages",1);
            }else{
                console.log('==> ',result);
                component.set("v.alldocuments",result);
                component.set("v.pageNum",1);
                component.set("v.totalPages",Math.ceil(result.length/component.get("v.recordsPerPage")));
                helper.setdata(component);
            }
        });
        $A.enqueueAction(action);
        
    },
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    redirect : function(component, event, helper){
        console.log('@@@@--->' + event.target.id);
        var result = event.target.id;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/documentationdetail?id=" + result
        });
        urlEvent.fire();
    },
    next : function(component, event, helper){
        component.set("v.pageNum",component.get("v.pageNum")+1);
        helper.setdata(component);
    },
    previous : function(component, event, helper){
        component.set("v.pageNum",component.get("v.pageNum")-1);
        helper.setdata(component);
    }
})