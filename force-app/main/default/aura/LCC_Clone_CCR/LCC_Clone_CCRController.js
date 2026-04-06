({
    doInit: function(component, event, helper) {
        var action = component.get("c.getRecord");
        action.setParams({ recId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
				component.set("v.ccrRec",response.getReturnValue());
                console.log('---- CCR Rec ---');
                console.log(component.get("v.ccrRec"));                                               
                
                var result = response.getReturnValue();
                result.Id = null;
                result.RecordType = null;
                result.User__c = 'Pending';
                
                var createAcountContactEvent = $A.get("e.force:createRecord");
                createAcountContactEvent.setParams({
                    "entityApiName": "CCR__c",
                    "recordTypeId":result.RecordTypeId,
                    "defaultFieldValues": result
                });
                createAcountContactEvent.fire();
                
                
                $A.get("e.force:closeQuickAction").fire();
				/*
                var workspaceAPI = component.find("workspace");
                workspaceAPI.isConsoleNavigation().then(function(response) {
                    if(response){
                        console.log('response..!', response);
                        workspaceAPI.getFocusedTabInfo().then(function(response) {
                            var focusedTabId = response.tabId;
                            workspaceAPI.openSubtab({
                                parentTabId: focusedTabId,
                                url: '/lightning/o/CCR__c/new?defaultFieldValues=User__c=Pending,RecordTypeId='+result.RecordTypeId,
                                focus: true
                            });
                        })
                        .catch(function(error) {
                            console.log(error);
                        });                        
                    } else {
                        var createAcountContactEvent = $A.get("e.force:createRecord");
                        createAcountContactEvent.setParams({
                            "entityApiName": "CCR__c",
                            "defaultFieldValues": result
                        });
                        createAcountContactEvent.fire();
                    }
                });
                */
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
        $A.enqueueAction(action);
        
        /*
        var action1 = component.get("c.getsectionVisibility");
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
				component.set("v.showInternalSection",response.getReturnValue());
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
        $A.enqueueAction(action1);     
        */
    },
    /*
    handleSaveRecord: function(component, event, helper) {
      
       var action = component.get("c.saveRecord");
        action.setParams({ ccrRecord : component.get("v.ccrRec") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            var temparr = response.getReturnValue();
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                if(temparr[0].message == 'success'){
					var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                       "type": "success",
                       "duration": 10000,
                       "mode" : "pester",
                        message: 'This is a required message',
                        messageTemplate: 'Record {1} got created',
                        messageTemplateData: ['CCR', {
                            url: '/'+temparr[0].recId,
                            label: temparr[0].recName,
                        }
                                              ]
                    });
                    toastEvent.fire(); 
                    $A.get("e.force:closeQuickAction").fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot create the record",
                        "duration": 10000,
                        "type": "error",
                        "message": temparr[0].message
                    });
                    toastEvent.fire(); 
                }
                	
            }
            else if (state === "ERROR") {
                 var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot create the record",
                        "duration": 10000,
                        "type": "error",
                        "message": response.getError()
                    });
                    toastEvent.fire(); 
            }
        });
        $A.enqueueAction(action);  
    },  
	handleCancelRecord: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }, 
    */
})