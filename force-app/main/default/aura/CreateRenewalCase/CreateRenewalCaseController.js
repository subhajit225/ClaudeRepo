({
    doInit : function(component, event, helper) {
        component.set('v.columns', [{label: 'Contract Name', fieldName: 'Name', type: 'text'},
                                    {label: 'Contract Number', fieldName: 'ContractNumber', type: 'text'},
                                    {label: 'Status', fieldName: 'Status', type: 'text'},
                                    {label: 'Start Date', fieldName: 'StartDate', type: 'date'},
                                    {label: 'End Date', fieldName: 'EndDate', type: 'date'},
                                    {label: 'Case Number', fieldName: 'CaseNumber', type: 'text'}
                                   ]);
        var recId  = component.get("v.recordId");
        var action = component.get("c.checkStatus");
        action.setParams({
            accId: recId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                if(!resp ){
                    component.set("v.data",[]);
                    component.set("v.loadComplete",true);
                    window.setTimeout(
                        $A.getCallback(function() {
                            window.history.back();
                        }), 3000
                    );
                }else{
                    if(!!resp.serviceContrList && resp.serviceContrList.length == 1){
                        component.set('v.csNumber',resp.serviceContrList[0].CaseNumber);
                    }
                    if(resp.csId != null){
                        component.set('v.showSuccessNotification',true);
                        component.set('v.showData',false);
                        window.setTimeout(
                            $A.getCallback(function() {
                                window.open('/'+resp.csId,'_self');
                            }), 3000
                        );
                    }
                    else{
                        console.log('False');
                        console.log(resp.serviceContrList);
                        component.set("v.data",resp.serviceContrList);
                        component.set("v.showData",true);
                        component.set("v.loadComplete",true);
                    }
                }
                
            }
            else if (state === "ERROR") {
                component.set("v.showError",true);
                window.setTimeout(
                    $A.getCallback(function() {
                        window.history.back();
                    }), 3000
                );
            }
        });
        $A.enqueueAction(action);
    },
    createSelCase : function(component, event, helper) {
        component.set("v.disabledButton",true);
        var action = component.get("c.createCase");
        action.setParams({
            sc: JSON.stringify(component.get("v.scRec"))
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                component.set('v.csNumber',response.getReturnValue().csNum);
                component.set('v.showSuccessNotification',true);
                component.set('v.showData',false);
                window.setTimeout(
                    $A.getCallback(function() {
                        window.open('/'+response.getReturnValue().csId,'_self');
                    }), 3000
                );
                
            }
            else if (state === "ERROR") {
                component.set("v.disabledButton",false);
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);
    },
    cancel : function(component, event, helper){
        window.history.back();
    },
    onChange : function(component, event, helper){
        var selectedRows = event.getParam('selectedRows');
        for(var i = 0 ;i<selectedRows.length;i++){
            if(selectedRows[i].scId != null){
                component.set("v.scRec",selectedRows[i]);
            }
        }
    }
})