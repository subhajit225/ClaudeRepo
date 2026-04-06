({
    
    execute : function(component, event, helper) {
        if(component.get("v.sObjectInfo.Holdover_Extension__c") == true){
            component.set("v.content","Opportunity Holdover Extension can only be requested once.");
        }else if(component.get("v.sObjectInfo.Holdover_Extension__c") != true){
            if(component.get("v.recordUserFields.Holdover_Count__c") == 5) {
                component.set("v.content","Opportunity Owner can have only max of 5 Opportunity on hold.");
            }else {
                component.set("v.content","Are you sure you want to request holdover on this Opportunity?");
                component.set("v.updateholdoverReq",true);
                component.set("v.showcancel",true);
            }
        }else if(component.get("v.recordUserFields.Holdover_Requested__c") == true ) {
            if(component.get("v.recordUserFields.Holdover_Count__c") == 5) {
                component.set("v.content","Opportunity Owner can have only max of 5 Opportunity on hold.");
            }else {
                component.set("v.content","Are you sure you want to request holdover extension on this Opportunity?");
                component.set("v.updateholdoverExtn",true);
                component.set("v.sObjectInfo.Holdover_Extension__c",true);
                component.set("v.showcancel",true);
            }
            
        }
        component.set("v.showok",true);
    },
    
    handleRecordUpdated1 :  function(component, event, helper) {
        component.get("v.simpleRecordUser.Holdover_Count__c");
    }, 
    
    handleClick :  function(component, event, helper) {
       
        if(component.get("v.updateholdoverReq") == true){
            component.set("v.sObjectInfo.Holdover_Requested__c",true);
            helper.handlesaveOpp(component, event, helper);
        }
        if(component.get("v.updateholdoverExtn") == true){
            component.set("v.sObjectInfo.Holdover_Extension__c",true);
            helper.handlesaveOpp(component, event, helper);
        }
        if(component.get("v.updateholdoverReq") == false && component.get("v.updateholdoverExtn") == false){
            helper.closeQuickAction(component, event, helper); 
        }
        
    },
    handleCancel : function(component, event, helper) {
        helper.closeQuickAction(component, event, helper);    
    }
})