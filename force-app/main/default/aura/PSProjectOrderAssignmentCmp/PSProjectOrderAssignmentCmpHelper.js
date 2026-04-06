({
    getColumnAndAction : function(component) {
        var actions = [
            {label: 'Edit', name: 'edit'},
            {label: 'Delete', name: 'delete'},
            {label: 'View', name: 'view'}
        ];
        component.set('v.columns', [
            {label: 'Order Number', fieldName: 'orderNumber', sortable: true, type: 'url', 
             typeAttributes: {label: { fieldName: 'OrderNumber' }, target: '_blank'}, cellAttributes: { alignment: 'center' } , sortable: true},
            {label: 'Account Name', fieldName: 'accName', sortable: true, type: 'url', 
             typeAttributes: {label: { fieldName: 'AccountName' }, target: '_blank'}, cellAttributes: { alignment: 'center' } , sortable: true},
            {label: 'Project', fieldName: 'projName', sortable: true, type: 'url', 
             typeAttributes: {label: { fieldName: 'ProjectName' }, target: '_blank'}, cellAttributes: { alignment: 'center' }, sortable: true},
            
            {label: 'Order Status', fieldName: 'Order_Status__c', type: 'text', cellAttributes: { alignment: 'center' }, sortable: true}
            
        ]);
    },
    getOrders : function(component, helper, projectId) {
        var action = component.get("c.getOrders");
        var pageSize = component.get("v.pageSize").toString();
        var pageNumber = component.get("v.pageNumber").toString();
        
        action.setParams({
            'pageSize' : pageSize,
            'pageNumber' : pageNumber,
            'projectId' : projectId
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
                    if (record.Account.Name != null && typeof record.Account.Name !== 'undefined') {
                        record.AccountName = record.Account.Name;
                        record.accName = '/'+record.AccountId;
                    }
                    if (typeof record.PS_Project__c !== 'undefined') {
                        record.ProjectName = record.PS_Project__r.Name;
                        record.projName = '/'+record.PS_Project__c;
                    }
                });
                
                component.set("v.data", resultData);
                component.find("accDT").set("v.selectedRows",component.get("v.selection"));
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
    getAccounts : function(component, helper) {
        var action = component.get("c.getAccountsWithOffset");
        action.setStorable();
        var pageSize = component.get("v.pageSize").toString();
        var pageNumber = component.get("v.pageNumber").toString();
        
        action.setParams({
            'pageSize' : pageSize,
            'pageNumber' : pageNumber
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Response Time: '+((new Date().getTime())-requestInitiatedTime));
                if(response.getReturnValue().length < component.get("v.pageSize")){
                    component.set("v.isLastPage", true);
                } else{
                    component.set("v.isLastPage", false);
                }
                
                //Modify response to include the page number as well 
                //in the id attribute of each row
                //This will help us to filter out the rows displayed on each page
                response.getReturnValue().forEach(function(row) {
                    row.Id = row.Id+'-'+pageNumber;
                });
                console.log('response.getReturnValue()=='+response.getReturnValue());
                component.set("v.resultSize", response.getReturnValue().length);
                component.set("v.data", response.getReturnValue());
                //Set selected rows with our selection attribute which has id of each attribute -->s
                component.find("accountDataTable").set("v.selectedRows",component.get("v.selection"));
            }
        });
        var requestInitiatedTime = new Date().getTime();
        $A.enqueueAction(action);
    },
    assignOrders : function(component, event, helper) {
        var projectId = component.get('v.projectId');	
        if(!projectId){	
            var pageReference = window.location.href;	
            console.log(pageReference);	
            var url = new URL(pageReference);	
            var projectId = url.searchParams.get("projectId");	
        }
        console.log(projectId);
        if(projectId == null || projectId == '') {
            component.set("v.Message", true);
            component.set("v.messageString", 'No Project Id mentioned in URL. Please retry from Project');
        }
        else {
            console.log('save-'+component.get("v.selection"));
            var action = component.get("c.assignOrdersToProject");
            var orderIds =component.get("v.selection");
            if(orderIds == null || orderIds == '') {
                component.set("v.Message", true);
                component.set("v.messageString", 'No Orders selected. Please select atleast one.');
            }
            else {
                var ids=new Array();
                for (var i= 0 ; i < orderIds.length ; i++){
                    ids.push(orderIds[i]);
                }
                
                action.setParams({
                    'projectId' : projectId,
                    'orderIDs' : ids
                });
                console.log('before call-');  
                
                action.setCallback(this,function(response) {
                    console.log('response.getState-'+response.getState());  
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var resultData = response.getReturnValue();
                        component.set("v.Message", true);
                        component.set("v.messageString", 'Order(s) assigned to Project successfully');
                        window.location.href="/"+projectId;
                        
                        setTimeout(function(){
                            $A.get("e.force:closeQuickAction").fire(); 
                        }, 2000);
                        
                    }
                    else {
                        component.set("v.messageString", "Error occured while saving! Please try again");
                        component.set("v.Message", true);
                    }
                });
                console.log('before call-');    
                $A.enqueueAction(action);
            } 
        }
    },
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.data", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
    
})