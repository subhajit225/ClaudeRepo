({
	doInit : function(component, event, helper) {
        var action = component.get("c.ApprovalValidation");
        action.setParams({
            'CCRId': component.get("v.sObjectInfo.Id")
        });
        action.setCallback(this,function(response){
              var state = response.getState();
              if(state === "SUCCESS"){
              	  component.set("v.validate",response.getReturnValue()); 
              }else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("v.content","Error message: " + 
                                            errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                   } 
            /*if(component.get("v.validate") == 'No error'){
                if(component.get("v.sObjectInfo.Justifications__c") == 'Cohesity Specific Situation' && component.get("v.sObjectInfo.Number_of_Attchments__c") < 2){
                    component.set("v.showcancel",true);
                    component.set("v.content",'CCR must be have 2 attachments before submitting for approval when Justification is Cohesity Specific Situation');
                }
                else{*/
            alert('in1');
                    var actionAPI = component.find("quickActionAPI");
            		var fields = { Id : { value : component.get("v.sObjectInfo.Id")}};
                    var args = {actionName: "CCR__c.Submit", entityName : "CCR__c",
                     targetFields : fields };
            		
                    actionAPI.selectAction(args).then(function(result){
                        actionAPI.invokeAction(args);
                        //Action selected; show data and set field values
                    }).catch(function(e){
                        if(e.errors){
                            alert(e.errors);
                            //If the specified action isn't found on the page, show an error message in the my component
                        }
                    });
                //}
           /* }else{
                component.set("v.showcancel",true);
                component.set("v.content",component.get("v.validate"));
            }*/
        }); 
        $A.enqueueAction(action);
    },
    gotoRec : function(component, recId){
        var urlEvent = $A.get("e.force:navigateToSObject");
        urlEvent.setParams({"recordId": recId,"slideDevName": "detail"});        
        urlEvent.fire();
    }
})