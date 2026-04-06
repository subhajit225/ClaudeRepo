({
    doInit : function(component, event, helper) {
        var url_string = window.location.href;
        var url = '';
        var Id = '';
        try{
            url = new URL(url_string);
            Id = url.searchParams.get("id");
        }catch(e){
            url = window.location.href;
            Id = url.split("=")[1];
            console.log(Id);
        }
        if(Id.startsWith("a41")){
            var action = component.get("c.getReleaseAttachments");
            action.setParams({
                "releaseId" : Id
            });
            action.setCallback(this, function(response){
                component.set("v.toggleSpinner", false);
                if(response.getState()==="SUCCESS" && component.isValid()){
                    var result = response.getReturnValue();
                    component.set("v.AttachmentDocslist",result.docAttachmentList);
                    component.set("v.pageTitle",result.docName);
                    component.set("v.showRelease",true);
                    component.set("v.isLoaded",true);
                    component.set("v.isProduction", result.isProduction); //added for CS21-706
                }  
            });
            $A.enqueueAction(action);
        }else{
            var action = component.get("c.getReleaseSoftware");
            action.setParams({
                "releaseId" : Id
            });
            action.setCallback(this, function(response){
                component.set("v.toggleSpinner", false);
                if(response.getState()==="SUCCESS" && component.isValid()){
                    var result = response.getReturnValue();
                    component.set("v.Attachmentlist",result.relDocList);
                    component.set("v.AttachmentDocslist",result.docAttachmentList);
                    component.set("v.pageTitle",result.docName);
                    component.set("v.isLoaded",true);
                    component.set("v.isProduction", result.isProduction); //added for CS21-706
                }
                
            });
            $A.enqueueAction(action);            
        }
        
    },
    openSingleFile: function(component, event, helper) {
        var currentUrl =window.location.href;
        window.open(currentUrl+'');
    }, 
    handleOpenFiles: function(cmp, event, helper) {
        alert('Opening files: ' + event.getParam('recordIds').join(', ') 
              + ', selected file is ' + event.getParam('selectedRecordId')); 
    },
    closeModal:function(component,event,helper){  
        //commented for CS21-706  
        /* var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'modalstyleopen');
        component.set("v.showContract",false); //added for CS21-706
        $A.get('e.force:refreshView').fire();  */
        window.location.reload(); //added for CS21-706
    },
    refreshModal:function(component,event,helper){    
        component.set("v.FileAccepted",true);
    },
    openModal:function(component,event,helper) {
        component.set("v.toggleSpinner", true);
        //component.set("v.showContract",true); //added for CS21-706
        var releaseSoft1 = event.target.id;
        var releaseType = event.target.name;
        let softwareName = event.target.getAttribute("data-label"); //added for CS21-706
        component.set("v.releaseType",releaseType);
        component.set("v.releaseId",releaseSoft1);
        component.set("v.softwareName", softwareName);//added for CS21-706
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.addClass(cmpTarget, 'modalstyleopen');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');  
        /* CS21-2046: Added by Ashish, Open contract in new page to fix pop-ups issue*/
        const softwareDetails = {
            "releaseType": releaseType,
            "releaseId": releaseSoft1,
            "softwareName": softwareName,
            "pageTitle": document.title,
            "pageURL": window.location.href,
            "pagePath": window.location.pathname,
            "isProduction": component.get("v.isProduction")
        }
        sessionStorage.setItem('softwareDetails', JSON.stringify(softwareDetails));
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/ironcladcontract"
        });
        urlEvent.fire();
        /* CS21-2046: Added by Ashish, Open contract in new page to fix pop-ups issue*/
       
    },
    Downloadfile : function(component,event,helper) {
		//commented for CS21-706  
        /*var Check8cahr = component.find("checkbox").get('v.checked');
        if(Check8cahr !== undefined  && Check8cahr !== null &&  Check8cahr === false){
            component.set("v.IsEulaAccepted", true);
            component.set("v.FileAccepted",false);
            
        }
        else{
            var releaseSoft = component.get("v.releaseId");
            var releaseType = component.get("v.releaseType");
            if(releaseType == 'Direct Availability (DA)' || releaseType == 'Early Access (EA)'){
                var action2 = component.get("c.getLink");
                console.log('__action21__'+action2);
                action2.setParams({
                    "Id":releaseSoft
                });
                action2.setCallback(this, function(response){
                    if(response.getState()==="SUCCESS" && component.isValid()){
                        var result = response.getReturnValue();
                        component.set("v.ReleaseSoftWare",result);
                        component.set("v.IsEulaAccepted", false);  
                        component.set("v.FileAccepted",true);
                    }
                });
                $A.enqueueAction(action2);
            }else{
                var action2 = component.get("c.gets3Link");
                action2.setParams({
                    "Id":releaseSoft,
                    "isName":false
                });
                action2.setCallback(this, function(response){
                    if(response.getState()==="SUCCESS" && component.isValid()){
                        component.set("v.IsEulaAccepted", false);  
                        component.set("v.FileAccepted",true);
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": response.getReturnValue()
                        });
                        urlEvent.fire();
                        var cmpTarget = component.find('Modalbox');
                        var cmpBack = component.find('Modalbackdrop');
                        $A.util.removeClass(cmpTarget, 'modalstyleopen');
                        $A.util.removeClass(cmpBack, 'slds-backdrop--open'); 
                        $A.get('e.force:refreshView').fire(); 
                    }
                });
                $A.enqueueAction(action2);
            //}
        }*/
    },
    handleSoftwareDownload: function(component, event, helper) {
        //added for CS21-706  
        var releaseSoft = event.getParam("releaseId");
        var embeddedContract = event.getParam("embeddedContract");
        
        var action = component.get("c.gets3Link");
        
        action.setParams({
            "Id": releaseSoft,
            "isName": false,
            "ironcladResponse": embeddedContract
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": response.getReturnValue()
                });
                urlEvent.fire();
                window.location.reload();
            } else if (state === "INCOMPLETE") {
                component.set("v.showSpinner", false);
                console.log("Error :: please contact your system admin");
            } else if (state === "ERROR") {
                component.set("v.showSpinner", false);
                let errors = response.getError();
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
})