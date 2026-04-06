({
    attachfileHelper: function(component, event, helper,caseid, fileSize, fileName, fullPath, uploadStatus) {
        /*
        var attach = {
            'Name' : fileName,
            'ParentId' : caseid,
            'Description' : fullPath,
            'ContentType' : 'html',
            'Body' : new Blob([fullPath])
        };
        component.set('v.Attachments',attach);
        
        var recordLoader = component.find("recordLoader");
        recordLoader.saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "ERROR") {
                var errMsg = "";
                // saveResult.error is an array of errors, 
                // so collect all errors into one message
                for (var i = 0; i < saveResult.error.length; i++) {
                    errMsg += saveResult.error[i].message + "\n";
                }
                component.set("v.recordSaveError", errMsg);
            } else {
                component.set("v.recordSaveError", "");
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/viewcase?id="+caseid
                });
                urlEvent.fire();
            }
        }));
        */
        var action = component.get("c.Customer_Case_Attach2");
        action.setParams({
            'caseID' :caseid,
            'fileSize' : fileSize,
            'fileName' : fileName,
            'fileKey' : fullPath,
            'uploadStatus' : uploadStatus
            
        });
        action.setCallback(this, function(a) {
            if(component.get("v.isUploaded")  == true){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": "/viewcase?id="+caseid
                });
                urlEvent.fire();
            }else{
                component.set("v.isUploaded",true);
            }
        });
        $A.enqueueAction(action);
    }
   
})