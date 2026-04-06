({ 
    doInit : function(component, event, helper) {
        /*var currentId2 = location.search.substring(1);
        var caseId = currentId2.split("=")[1];*/
        var url_string = window.location.href;	
        var url = new URL(url_string);	
        var caseId = url.searchParams.get("id");	
        var isEscalated = url.searchParams.get("isEscalated");	
        var isComment = url.searchParams.get("isComment");	
        if(!!isEscalated && isEscalated == 'true'){	
            component.set("v.isEscalated",true);	
            component.set("v.addComments",true);	
        }	
        if(!!isComment  && isComment == 'true'){	
            component.set("v.isEscalated",false);	
            component.set("v.addComments",true);	
        }
        component.set("v.caseId",caseId);
        var action = component.get("c.getCaseDetails");
        action.setParams({
            recordId:caseId
        });
        action.setCallback(component, function(response) {
            var state =  response.getState();
            if(state == "SUCCESS"){
                var res = response.getReturnValue();
                
                var RSC_G_Allowed_Values = $A.get("$Label.c.FedRAMP_RSC_G_For_Case_Creation");
                // CS21-2005: When Account RSC-G Support is RSC Only
                if(!res.caseDetail.Account.RSC_G_Support__c 
                    || res.caseDetail.Account.RSC_G_Support__c.includes(RSC_G_Allowed_Values)){
                    // Display disable case creation prompt
                    component.set("v.isDisplayFeedback", true);
                }

                component.set("v.toggleSpinner", false);
                component.set("v.isLoaded",true);  
                component.set("v.myCase",res.caseDetail);    
                component.set("v.articleattr",res.caseArticle);
                component.set("v.caseEscStatus",res.caseDetail.IsEscalated);
                component.set("v.caseattchmnt",res.caseAttachmnt[0].Attachments);
                component.set("v.AttachedContentDocuments",res.caseAttachmnt[0].AttachedContentDocuments);
                // CS21-1071: Support Portal: Read only user profile
                component.set("v.isEditAccess",res.isEditAccess);
                //CS21-1071:Ends
                
                //CS21-1562: Disallow support case reopening after 30 days from Status change to Closed
                if(!res.isReopenAccess){
                    component.set("v.disableReopenTitle",'Case '+res.caseDetail.CaseNumber+' has been closed over 30 days. Please open a new case.');
                 }
                 //CS21-1562: Ends  

                //CS21-3825
                if(res.caseDetail.RSCInstance__r){
                    helper.getRSCUrl(component);
                }
                
            } else if (state=="ERROR") {
                var errorMsg = action.getError()[0].message;
                console.log('ERROR caught in getCaseDetails: ',errorMsg);
            }
        });
        $A.enqueueAction(action);
    },
    
    showComment : function(component, event, helper) {
        component.set("v.showcommentBox",true);
    },
    Cancel : function(component, event, helper) {
        component.set("v.commentText");
        component.set("v.showcommentBox",false);
    },
    addComment : function(component, event, helper) {
        var url_string = window.location.href;
        var url = new URL(url_string);
        var caseId = url.searchParams.get("id");
        //console.log('All  searchParams',url.searchParams.get("id"));
        var action = component.get("c.addMyComment");
        var commentbody = component.get("v.commentText");
        action.setParams({
            parentId : caseId,
            body : commentbody
        });
        action.setCallback(this, function(response) {
            // console.log('response=========='+JSON.stringify(response.getReturnValue()));
        });
        $A.enqueueAction(action);
        component.set("v.showcommentBox",false);
    },
    init : function(component, event, helper) {
        var currentId2 = location.search.substring(1);
        var splited = currentId2.split("=");
        
        var action = component.get("c.getAttachmentDetails");
        action.setParams({recordId:splited[1]});
        action.setCallback(component, function(response) {
            $A.get("e.force:refreshView").fire();
            // console.log('All cases result',response.getReturnValue())
            component.set("v.myCase1",response.getReturnValue());
            
        });
        $A.enqueueAction(action);
    },
    closeCase  : function(component, event, helper) {
        component.set("v.toggleSpinner", true);
        component.set("v.isError", false)
        component.set("v.showEditView", false);
        component.set("v.errorMsg", "");
        
        var action = component.get("c.getCaseDetails");
        action.setParams({
            caseId1  : component.get("v.recordId")
        });
        
        action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                component.set("v.record", a.getReturnValue());
                helper.getStatusPickListValue(component);
            }
            component.set("v.toggleSpinner", false);
        });
        
        $A.enqueueAction(action);
    },
    handleUploadFinished : function (component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    addcommentwith: function (component, event, helper) {
        console.log("isEscalated");
        component.set("v.isEscalated",true);
        component.set("v.addComments",true);
    },
    
    addcommentwithout: function (component, event, helper) {
        component.set("v.isEscalated",false);
        component.set("v.addComments",true);
    },
    
    reopenCase: function (component, event, helper) {
        component.set("v.isReopen",true);
        component.set("v.addComments",true);
    },
    
    closeCase1 : function (component, event, helper) {
        // console.log("caseid: ", component.get("v.caseId"));
        component.set("v.toggleSpinner", true);
        component.set("v.isError", false)
        component.set("v.showEditView", false);
        component.set("v.errorMsg", "");
        
        var action = component.get("c.statusclosed");
        //var Status = component.get("v.record.Status") //get value of field
        action.setParams({recId :  component.get("v.caseId")});
        action.setCallback(this, function(a) {
            $A.get("e.force:refreshView").fire();
            if (a.getState() === "SUCCESS") {
                //console.log('closed sucessfully'+a.getReturnValue());
            }
        });
        
        $A.enqueueAction(action);
    },
    openFiles : function (component, event, helper) {
        // console.log(event.target.id);
        $A.get('e.lightning:openFiles').fire({
            recordIds: [event.target.id]
        });
    },
    uploadFiles: function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/uploadfile?id='+ component.get("v.myCase.Id")+'&casenumber='+ component.get("v.myCase.CaseNumber")
        });
        urlEvent.fire();
    },
    openFullBody: function (component, event, helper) {
        var CaseComments = component.get("v.CaseComments");
        component.set("v.CommentBody",CaseComments[event.target.id].Body);
        component.set("v.isRichText",CaseComments[event.target.id].hasBreak);
        component.set("v.ShowModal",true);
    },
    CloseModal : function(component, event, helper) {
        component.set("v.CommentBody",'');
        component.set("v.ShowModal",false);
    }		    
})