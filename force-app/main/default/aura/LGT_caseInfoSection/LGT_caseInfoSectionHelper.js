({
	/*saveMethod : function(component,event,helper){
		var fieldName = event.target.id;
        console.log('fieldName@@@@@',fieldName);
        var caseRecord = component.get("v.caseRecord");
        caseRecord[fieldName] = component.get("v.fieldValue");
        console.log('@@@@$$$',component.get("v.fieldValue"));
        var action = component.get('c.saveRecordApex1');
        action.setParams({'fieldName':fieldName,'value':component.get("v.fieldValue"),'recordId':component.get("v.recordId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var result = response.getReturnValue();
            //cmp.set("v.caseRecord",result.recordDetail);
            //cmp.set("v.fieldsList",result.wrapperList);
            component.set("v.ratingEditMode", false);
            component.set("v.caseRecord",caseRecord);
            $A.get('e.force:refreshView').fire();
            }
            else if(state === "ERROR"){
                var errorsArr  = event.getParam("errors");
        alert("error " ,JSON.stringify(errorsArr));
            }

                /*var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert(errors[0].message);
                    }
                }
            }else if (status === "INCOMPLETE") {
                alert('No response from server or client is offline.');
            }
        });
        $A.enqueueAction(action);
	}*/
})