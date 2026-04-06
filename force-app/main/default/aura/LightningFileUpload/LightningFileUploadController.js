({  
    doInit:function(component,event,helper){ 
        //Comment here
       helper.getuploadedFiles(component);
    },      
    
    previewFile :function(component,event,helper){  
        var rec_id = event.currentTarget.id;  
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [rec_id]
        });  
    },  
    
    
     upload :function(component,event,helper){  
       component.set("v.openmodel",true); 
    }, 
    
    closeModal : function(component,event,helper){
        console.log('close model is working');
       component.set('v.openmodel',false);
        
    },
    
    UploadFinished : function(component, event, helper) {
        component.set('v.openmodel',false);
        var uploadedFiles = event.getParam("files");  
        //var documentId = uploadedFiles[0].documentId;  
        //var fileName = uploadedFiles[0].name; 
        helper.getuploadedFiles(component);         
        component.find('notifLib').showNotice({
            "variant": "info",
            "header": "Success",
            "message": "File Uploaded successfully!!",
            closeCallback: function() {}
        });
    }, 
    
    delFiles:function(component,event,helper){
        component.set("v.Spinner", true); 
        var documentId = event.currentTarget.id;        
        helper.delUploadedfiles(component,documentId);  
    }
 })