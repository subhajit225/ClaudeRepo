({
    changeOwner : function(component, event, helper) {
        component.find("record").reloadRecord(true);
        //component.find("record2").reloadRecord(true);
        var oldOwner = component.get("v.currentOwner");
        var caseRecordView = component.get("v.caseViewRecord");
        if (
            caseRecordView &&
            caseRecordView.Account &&
            caseRecordView.Account.Tabs_Visibility__c &&
            caseRecordView.Account.Tabs_Visibility__c.includes('Predibase')
        ) {
            component.set("v.showPredibasetext",true);
        }else{
            component.set("v.showPredibasetext",false);
        }
        try{
            if(oldOwner != null){
                if(oldOwner != component.get("v.caseViewRecord").OwnerId && component.get("v.initalOwner") != null){
                    component.set("v.currentOwner",component.get("v.caseViewRecord").OwnerId);
                    if(oldOwner.startsWith("005"))
                        component.set("v.ownerChanged",true);
                    var caseRecord = Object.assign({}, component.get("v.caseRecord")); 
                    caseRecord.OwnerId = component.get("v.caseViewRecord").OwnerId;
                    component.set("v.caseRecord",caseRecord);
                    component.set("v.initalOwner", caseRecord.OwnerId);
                }else if(oldOwner != component.get("v.caseViewRecord").OwnerId && component.get("v.initalOwner") == null){
                    component.set("v.initalOwner",  component.get("v.caseViewRecord").OwnerId);
                }
            }else{
                //set on initial load
                component.set("v.currentOwner",component.get("v.caseViewRecord").OwnerId);
                component.set("v.initalOwner",component.get("v.caseViewRecord").Initial_Case_Owner__c);
            }
        }catch(error){
            console.error("Error occurred: ", error.message);
        }
    },
    onChange: function (component, evt, helper) {
        var caseRecord = component.get("v.caseRecord");
        caseRecord.CaseTransferType__c = component.find('select').get('v.value');
        component.set("v.caseRecord",caseRecord);
    },
    saveCase : function(component, event, helper) {
        component.find("record2").reloadRecord(true);
        component.find("record").reloadRecord(true);
        component.find("record").saveRecord($A.getCallback(function(saveResult) {
            var message; 
            if (saveResult.state === "SUCCESS") {
                message = 'Record updated successfully.';
            } else {
                message = 'Record error.'+ JSON.stringify(saveResult.error);
            }
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "info",
                "message": message
            });
            resultsToast.fire();
            component.set("v.ownerChanged",false);
        }));
    },
    closeModal : function(component, event, helper) {
        component.set("v.ownerChanged",false);
    }
})