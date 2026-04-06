({
    getColumnAndAction : function(component) {
        var actions = [
            {label: 'Edit', name: 'edit'},
            {label: 'Delete', name: 'delete'},
            {label: 'View', name: 'view'}
        ];
        
       /* var columns = [
            {label: 'Order Number', fieldName: 'ordernumber', sortable: true, type: 'url', 
            typeAttributes: {label: { fieldName: 'orderNumber' }, target: '_blank'}, cellAttributes: { alignment: 'center' }},
            /*{label: 'Account Name', fieldName: 'AccountName', type: 'text', sortable: true},
            {label: 'Account Name', fieldName: 'accName', sortable: true, type: 'url', 
            typeAttributes: {label: { fieldName: 'AccountName' }, target: '_blank'}, cellAttributes: { alignment: 'center' }},
            {label: 'Status', fieldName: 'Project_Status__c', type: 'text', sortable: true, cellAttributes: { alignment: 'center' }},
            {label: 'Actuall Billable Hours logged', fieldName: 'Actual_Billable_hours_logged__c', type: 'number', sortable: true, cellAttributes: { alignment: 'center' }},
            {label: 'Total Billable Hours Remaining', fieldName: 'Total_Billable_Hours_Remaining__c', type: 'number', sortable: true, cellAttributes: { alignment: 'center' }},
            {label: 'View', type: 'button',  typeAttributes: { label: 'View Sub-Tasks', name: 'view_details', title: 'View Sub Tasks'}, cellAttributes: { alignment: 'center' }},
            
        ];*/
        component.set('v.columns', [
            {label: 'Order Number', fieldName: 'orderNumber', sortable: true, type: 'url', 
            typeAttributes: {label: { fieldName: 'OrderNumber' }, target: '_blank'}, cellAttributes: { alignment: 'center' }},
            /*{label: 'Account Name', fieldName: 'AccountName', type: 'text', sortable: true},*/
            {label: 'Account Name', fieldName: 'accName', sortable: true, type: 'url', 
            typeAttributes: {label: { fieldName: 'AccountName' }, target: '_blank'}, cellAttributes: { alignment: 'center' }},
            
            {label: 'Order Status', fieldName: 'Order_Status__c', type: 'text', cellAttributes: { alignment: 'center' }},
            /*{label: 'Order Number', fieldName: 'OrderNumber', type: 'text'},
            {label: 'Account Name', fieldName: 'Account Name', type: 'text'},
             * ,{label: 'Phone', fieldName: 'Phone', type: 'phone'}
            {type: 'action', typeAttributes: { rowActions: actions } } */
        ]);
    },
     
    getOrders : function(component, helper, projectId) {
        var action = component.get("c.getOrders");
        var pageSize = component.get("v.pageSize").toString();
        var pageNumber = component.get("v.pageNumber").toString();
        var currentProjectId = component.get("v.projectId"); 
           alert('currentProjectId--'+currentProjectId); 
        action.setParams({
            'pageSize' : pageSize,
            'pageNumber' : pageNumber,
            'projectId' : currentProjectId
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                if(resultData.length < component.get("v.pageSize")){
                    component.set("v.isLastPage", true);
                } else{
                    component.set("v.isLastPage", false);
                }
                component.set("v.dataSize", resultData.length);
              resultData.forEach(function(record){
            record.orderNumber = '/'+record.Id;
            if (record.Account.Name) record.AccountName = record.Account.Name;
            record.accName = '/'+record.AccountId;
            });
                component.set("v.data", resultData);
            }
        });
        $A.enqueueAction(action);
    },
     
    viewRecord : function(component, event) {
        var row = event.getParam('row');
        var recordId = row.Id;
        var navEvt = $A.get("event.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
     
    deleteRecord : function(component, event) {
        var action = event.getParam('action');
        var row = event.getParam('row');
         
        var action = component.get("c.deleteAccount");
        action.setParams({
            "acc": row
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS" ) {
                var rows = component.get('v.data');
                var rowIndex = rows.indexOf(row);
                rows.splice(rowIndex, 1);
                component.set('v.data', rows);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The record has been delete successfully."
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
     
    editRecord : function(component, event) {
        var row = event.getParam('row');
        var recordId = row.Id;
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": recordId
        });
        editRecordEvent.fire();
    }, 
})