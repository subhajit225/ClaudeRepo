({
    onTabFocused : function(component, event, helper) {
        var focusedTabId = event.getParam('currentTabId'); 
        var workspaceAPI = component.find("workspace"); 
        workspaceAPI.getFocusedTabInfo().then(function(tab) {
            workspaceAPI.getEnclosingTabId().then(function(tabId) {
                if(tab.recordId.startsWith("500")){
                    if (focusedTabId == tabId) {
                       // alert('Case Refreshed!');
                        workspaceAPI.refreshTab({
                            tabId: focusedTabId,
                            includeAllSubtabs: true
                        });
                    }
                }
            }).catch(function(error) {
                console.log(error);
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    init: function (cmp, event, helper) {
        var action = cmp.get('c.getRecType');
        action.setParams({'recId':cmp.get("v.recordId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                var cmpEvent = cmp.getEvent("RecTypeEvent"); 
                cmpEvent.setParams({"recordType" : response.getReturnValue()}); 
                cmpEvent.fire();
            }
            
        });
        $A.enqueueAction(action);
        var action = cmp.get('c.getFields');
        action.setParams({'recordId':cmp.get("v.recordId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log('result..!',result);
                cmp.set("v.caseRecord",result.recordDetail);
                var caseRecord = cmp.get("v.caseRecord");
                if (caseRecord && !$A.util.isEmpty(caseRecord.EscalationManagerOwner__r)) {
                    cmp.set("v.escalationOwnerManagerName",caseRecord.EscalationManagerOwner__r.Name);
                } else {
                    cmp.set("v.escalationOwnerManagerName", '');
                }
                
                cmp.set("v.EscalationManagerFlag", caseRecord.HotCriticalIssue__c);
                cmp.set("v.fieldsList",result.wrapperList);
            }
            else {
                var errors = response.getError();
                console.log('errors..!', errors);
                cmp.set("v.exception",true);
                if(errors[0].message.includes('There is No Customer Success')){
                    cmp.set("v.createCustomerSuccess",true);
                }
                cmp.set("v.exceptionMsg",errors[0].message);
                //cmp.set("v.caseInfoSectionHide",true);
            }
        });
        $A.enqueueAction(action);
        var action = cmp.get('c.isSupportManager');
        action.setCallback(this, function(response){
            var result = response.getReturnValue();
            cmp.set("v.isCurrentUserSupportManager", result);
            
        });
        $A.enqueueAction(action);
    },
    createRecord :  function(component, event, helper) {
        var action = component.get('c.createdSuccessRecord');
        action.setParams({
            'caseId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var result = response.getReturnValue();
            component.set("v.recordId",result);
            component.set("v.exception",false);
            component.set("v.caseInfoSectionHide",false);
            window.location.reload();

        });
        $A.enqueueAction(action);
    },
    showCaseInfoSection : function(component, event, helper) {
        if(component.find("TC_Div")){
            var dropArrow1 = component.find("TC_DownArrow");
            var rightArrow1 = component.find("TC_RightArrow");
            $A.util.addClass(dropArrow1, 'slds-show');
            $A.util.removeClass(dropArrow1, 'slds-hide');
            $A.util.addClass(rightArrow1, 'slds-hide');
            $A.util.removeClass(rightArrow1, 'slds-show');
            
        }
        setTimeout(function(){
            component.set("v.caseInfoSectionHide",false);
        }, 200);
    },
    
    hideCaseInfoSection: function(component, event, helper) {
        if(component.find("TC_Div")){
            var rightArrow1 = component.find("TC_RightArrow");
            var dropArrow1 = component.find("TC_DownArrow");
            $A.util.removeClass(dropArrow1, 'slds-show');
            $A.util.addClass(dropArrow1, 'slds-hide');
            $A.util.removeClass(rightArrow1, 'slds-hide');
            $A.util.addClass(rightArrow1, 'slds-show');    
        }
        setTimeout(function(){
            component.set("v.caseInfoSectionHide",true);
        }, 200);
    },
    handleSuccess: function(cmp, event, helper) {
        //For modal Save
        cmp.set('v.showSpinner', false);
        cmp.set('v.isOpen',false);
        cmp.set('v.saved',true);
        $A.get('e.force:refreshView').fire();
        //location.reload();
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';
    },
    closeModal: function(component,event,helper){
        component.set('v.isOpen',false);
        component.set('v.saved',true);
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';
    },
    handleHotSectionSuccess: function(cmp, event, helper) {
        //For modal Save
        cmp.set('v.showSpinner', false);
        cmp.set('v.isHotSectionOpen',false);
        cmp.set('v.isHotSectionSaved',true);

        var action = cmp.get('c.getFields');
        action.setParams({'recordId':cmp.get("v.recordId")});
        action.setCallback(this, function(response){
            var result = response.getReturnValue();
            cmp.set("v.caseRecord",result.recordDetail);

            var caseRecord = cmp.get("v.caseRecord");
            if (caseRecord && !$A.util.isEmpty(caseRecord.EscalationManagerOwner__r)) {
                cmp.set("v.escalationOwnerManagerName",caseRecord.EscalationManagerOwner__r.Name);
            } else {
                cmp.set("v.escalationOwnerManagerName", '');
            }

            cmp.set("v.EscalationManagerFlag", caseRecord.HotCriticalIssue__c);
            cmp.set("v.fieldsList",result.wrapperList);
            
        });
        $A.enqueueAction(action);

        $A.get('e.force:refreshView').fire();
        //location.reload();
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';
    },
    closeHotSectionModal: function(component,event,helper){
        component.set('v.isHotSectionOpen',false);
        component.set('v.isHotSectionSaved',true);
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';

        var caseRecord = component.get("v.caseRecord");
        component.set("v.EscalationManagerFlag", caseRecord.HotCriticalIssue__c);
    },
    handleEscalationManagerField: function(component,event,helper){
        component.set("v.EscalationManagerFlag", event.getParam("checked"));

        if(!event.getParam("checked")) {
            component.find("HotCriticalOwner").set("v.value", null)
        }

    },
    checkSubPhase:function(component,event,helper){
        console.log('working');
        console.log('value --', event.getSource().get("v.value"));
        var subPhase = event.getSource().get("v.value");
        if(subPhase == "Snooze"){
            component.set("v.isSnooze", true);
        }
        else{
            component.set("v.isSnooze", false);
        }
    },
    handleLoad:function(component,event,helper){
        var subPhase = component.find("subPhase").get("v.value");
        if(subPhase == 'Snooze'){
            component.set("v.isSnooze", true);
        }
    }  
})