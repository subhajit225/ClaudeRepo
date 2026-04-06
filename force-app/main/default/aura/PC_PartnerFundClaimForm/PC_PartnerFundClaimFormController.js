({

    doInIt : function(component, event, helper){
        
        var baseURL = component.get("c.getBaseURL");
        baseURL.setCallback(this,function(response){
            var state = response.getState();    
            if (state === "SUCCESS") { 
                if(!$A.util.isUndefined(response.getReturnValue())){
                    component.set("v.vfHost",response.getReturnValue());
                }
            }
        });        
        $A.enqueueAction(baseURL);
        var fileURL = component.get("c.getfileBaseURL");
            fileURL.setCallback(this,function(response){
                var state = response.getState();    
                if (state === "SUCCESS") { 
                    if(!$A.util.isUndefined(response.getReturnValue())){
                        component.set("v.fileURL",response.getReturnValue());
                    }
                }
            });        
            $A.enqueueAction(fileURL);
        
        var action = component.get("c.getTotalAmount");
        action.setParams({
            'mdfId': component.get("v.recordId")
        });
            action.setCallback(this,function(response){
                var state = response.getState();    
                if (state === "SUCCESS") { 
                    if(!$A.util.isUndefined(response.getReturnValue())){
                        component.set("v.totalAmount",response.getReturnValue());
                    }
                }
            });        
        $A.enqueueAction(action);
        
        var reqaction = component.get("c.getRequestDetails");
        reqaction.setParams({
            'mdfId': component.get("v.recordId")
        });
            reqaction.setCallback(this,function(response){
                var state = response.getState();    
                if (state === "SUCCESS") { 
                    if(!$A.util.isUndefined(response.getReturnValue()))
                    {
                        var pfr = response.getReturnValue();
                        component.set("v.RequestName",pfr.Request_Number__c+' - '+pfr.Title);
                        
                        if(pfr.Activity == 'Dedicated Resource')
                        {
                            component.set('v.Measurements_of_Success_Q1__c',pfr.Measurements_of_Success_Q1__c);
                            component.set('v.Measurements_of_Success_Q2__c',pfr.Measurements_of_Success_Q2__c);
                            component.set('v.Measurements_of_Success_Q3__c',pfr.Measurements_of_Success_Q3__c);
                            component.set('v.Measurements_of_Success_Q4__c',pfr.Measurements_of_Success_Q4__c);
                            component.set('v.showDedicatedResourceSection',true);
                            var reqFields = component.get('v.requiredFields');
                            reqFields.push('Fiscal_Quarter__c');
                        }
                    }
                }
            });        
        $A.enqueueAction(reqaction);
        
        helper.getPicklist(component,event,'Fiscal_Quarter__c');
        
    },
	 handleUploadFinished: function (component, event) {
        var maxSize = component.get("v.maxFileSize"); //10GB Max File Size
        var arr = [];
        var totalfiles = [];
        console.log('On Change');
        var count = 0;
        var totalFileSize = component.get("v.uploadedFileSize");
        var remFileSizeVar = 0;

        if(!$A.util.isUndefined(component.get("v.fileList")) && !$A.util.isEmpty(component.get("v.fileList"))){
            for(var i=0;i<component.get("v.fileList").length;i++){
                arr.push(component.get("v.fileList")[i]);
            }
        }
        var files =  event.getParam("files"); //component.find("tempfile").getElement().files;//event.dataTransfer.files;
        if(!$A.util.isUndefined(component.get("v.AttList")) && !$A.util.isEmpty(component.get("v.AttList"))){
            for(var i=0;i<component.get("v.AttList").length;i++){
                totalfiles.push(component.get("v.AttList")[i]);
                count++;
            }
        }
        if(!$A.util.isUndefined(files) && !$A.util.isEmpty(files)){
            for(var i=0;i<files.length;i++){
                    totalFileSize = totalFileSize+files[i].size;
                    count++;
            }
            if(totalFileSize > maxSize){
                alert('Cannot exceed total size');
            }else if( count > 10){
                alert('Cannot exceed more than 10 files');
            }else{
                component.set("v.uploadedFileSize",totalFileSize);  
                remFileSizeVar = maxSize - totalFileSize;
                remFileSizeVar = remFileSizeVar/1000000;
                remFileSizeVar = remFileSizeVar.toFixed(2);
                component.set("v.remainingFileSize",remFileSizeVar);
                for(var i=0;i<files.length;i++){
                    var name = files[i].name;
                    arr.push(name);
                    totalfiles.push(files[i]);
                }
            }
                component.set("v.fileList",arr);
                console.log("OnDrop total up");
                component.set("v.AttList",totalfiles);
                //console.log("OnDrop total");
                event.stopPropagation();
                event.preventDefault();
        }
    },
     clearAttachmemt : function(component,event,helper)
    {
        var maxSize = component.get("v.maxFileSize"); //20MB Max File Size
        var item = event.currentTarget;
        var index = item.dataset.index;
        var totalFileSize = 0;
        var totalfiles = component.get("v.AttList");
        var options = component.get("v.fileList");
        //console.log('current target'+item);
        //console.log('index'+index);
        var Fileselected = totalfiles[index];
        var sizeToDeduce = Fileselected.size;
        options.splice(index, 1);
        totalfiles.splice(index,1)//(position,no of elements)      
        totalFileSize = component.get("v.uploadedFileSize");
   
        totalFileSize = totalFileSize - sizeToDeduce;
        var remFileSizeVar = maxSize - totalFileSize;
        remFileSizeVar = remFileSizeVar/1000000;
        remFileSizeVar = remFileSizeVar.toFixed(2);
        component.set("v.uploadedFileSize",totalFileSize);
        component.set("v.remainingFileSize",remFileSizeVar);
        component.set("v.fileList",options);
        component.set("v.AttList",totalfiles);
    },
     // File will be download ,On Click of file
    downloadFile :function(component, event, helper) {
        //console.log('@@ event.currentTarget.id '+event.currentTarget.id);
        var url = component.get("v.fileURL")+'/sfc/servlet.shepherd/version/download/'+event.currentTarget.id;
        component.set("v.downloadUrl",url);        
    },
    handleSaveForm : function(component, event, helper) {
        var isValid = true;
        var isValidForm = true;
        var requiredFields = component.get("v.requiredFields");
        requiredFields.forEach(function(field) {
            if($A.util.isEmpty(component.get("v."+field)) || $A.util.isUndefined(component.get("v."+field))){
                 isValid = false;
                 helper.showErrorField(component, event, field);
            }else{
                helper.hideErrorField(component, event, field);
            }
        });
        if(!$A.util.isEmpty(component.get("v.Amount")) && component.get("v.totalAmount") < component.get("v.Amount")){
            isValidForm = false;
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Error",
                "message": "Actual cost cannot cross unclaimed Amount on MDF which is "+component.get("v.totalAmount"),
                "type" : "error"
            });
            resultsToast.fire();
        }
        if($A.util.isEmpty(component.get("v.AttList"))){
            isValidForm = false;
            helper.showErrorField(component, event, "tempfile");
        }else{
            helper.hideErrorField(component, event, "tempfile");
        }
        if(!isValidForm){
           isValid = isValidForm;
        }
        if(isValid){
        	helper.save(component, event, helper);
        }
    }
})