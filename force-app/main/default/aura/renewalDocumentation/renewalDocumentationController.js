({
    doInit : function(component, event, helper) {
        component.set('v.columns', [
            {label: 'Title', fieldName: 'Name', type: 'text'},
            {label: 'Owner', fieldName: 'Owner'},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date'}
        ]);
        var recId = component.get('v.recordId');
        console.log('RecId'+recId);
        var action = component.get("c.getDocs");
        action.setParams({ recId : recId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(!response.getReturnValue().hasOpporutnity){
                    component.set("v.hasError",true);
                    component.set('v.showSpinner',false);
                    component.set("v.errorMess",'There is no Opportunity and quote attached to this Case');
                    window.setTimeout(
                        $A.getCallback(function() {
                            window.history.back();
                        }), 3000
                    );
                }else if(response.getReturnValue().quoteExpired){
                    component.set("v.hasError",true);
                    component.set('v.showSpinner',false);
                    component.set("v.errorMess",'Quote('+response.getReturnValue().quoteNumber+') is expired');
                    window.setTimeout(
                        $A.getCallback(function() {
                            window.history.back();
                        }), 3000
                    );
                }else if(!response.getReturnValue().hasQuote){
                    component.set("v.hasError",true);
                    component.set('v.showSpinner',false);
                    component.set("v.errorMess",'There is no quote attached to this Case');
                    window.setTimeout(
                        $A.getCallback(function() {
                            window.history.back();
                        }), 3000
                    );
                }else if(!response.getReturnValue().isApproved){
                    component.set("v.hasError",true);
                    component.set('v.showSpinner',false);
                    component.set("v.errorMess",'Quote('+response.getReturnValue().quoteNumber+') is not Approved');
                    window.setTimeout(
                        $A.getCallback(function() {
                            window.history.back();
                        }), 3000
                    );
                }else{
                    component.set("v.oppId",response.getReturnValue().oppId);
                    component.set('v.options', [
                        {'label': "Partner: "+response.getReturnValue().partnerLabel+"", 'value': 'Partner'},
                        {'label': "Distributer: "+response.getReturnValue().distrLabel+"", 'value': 'Distributer'}
                    ]);
                    component.set('v.ccOptions', [
                        {'label': "Case Owner: "+response.getReturnValue().caseOwner+"", 'value': 'cOwner'},
                        {'label': "Opportunity Owner: "+response.getReturnValue().oppOwner+"", 'value': 'Owner'},
                        {'label': "Sales Engineer: "+response.getReturnValue().saleEngineer+"", 'value': 'Engineer'},
                        {'label': "Renewal Owner: "+response.getReturnValue().renewalOwner+"", 'value': 'ROwner'}
                    ]);
                    component.set('v.retryCount',component.get('v.retryCount')+1);
                }
                
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
        
    },
    cancel : function(component, event, helper){
        window.history.back();
    },
    sendEmail : function(component, event, helper){
        if(component.get("v.attachmentId") != null && (component.get('v.emails') != null || component.get('v.value').length)){
            component.set("v.showButton",true);
            var action = component.get("c.sendMail");
            action.setParams({ attId : component.get("v.attachmentId"),
                              emails: component.get('v.emails'),
                              partDist: component.get('v.value'),
                              recId : component.get('v.recordId'),
                              ccList : component.get('v.ccValue')
                             });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.showSuccessNotification',true);
                    component.set('v.showData',false);
                    window.setTimeout(
                        $A.getCallback(function() {
                            window.history.back();
                        }), 3000
                    );
                }
                else if (state === "ERROR") {
                    component.set("v.showButton",false);

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
        }
        else if(component.get("v.attachmentId") == null && component.get('v.emails') == null && !component.get('v.value').length){
            console.log('Please Select document and recepient');
            component.set('v.showBothNotification',true);
            window.setTimeout(
                $A.getCallback(function() {
                    component.set('v.showBothNotification',false);
                }), 5000
            );
        }
            else if(component.get("v.attachmentId") == null){
                console.log('Please select a Document');
                component.set('v.showDocNotification',true);
                window.setTimeout(
                    $A.getCallback(function() {
                        component.set('v.showDocNotification',false);
                    }), 5000
                );
            }
                else if(component.get('v.emails') == null && !component.get('v.value').length){
                    component.set('v.showEmailNotification',true);
                    window.setTimeout(
                        $A.getCallback(function() {
                            component.set('v.showEmailNotification',false);
                        }), 5000
                    );
                }
        
    },
    onChange : function(component, event, helper){
        var selectedRows = event.getParam('selectedRows');
        console.log(selectedRows);
        for(var i = 0 ;i<selectedRows.length;i++){
            if(selectedRows[i].Id != null){
                component.set("v.attachmentId",selectedRows[i].Id);
                console.log('selectedRows[i].Id '+selectedRows[i].Id);
            }
        }
    },
    getAttach : function(component, event, helper){
        helper.getAttachment(component, event, helper);
    }
})