({
    doInit : function(component, event, helper) {
        var action = component.get("c.getCaseRecForCaseDescription");
        action.setParams({
            caseId: component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var result = response.getReturnValue();
            if(result != null && result != ''){
                component.set("v.caseRecord",result);
            }
            
        });
        $A.enqueueAction(action);
        
    },
    doneRendering : function(component, event, helper) {
        /*var temp= document.getElementById('comments__id');
        //debugger;
        if((document.getElementById('comments__id') != null || document.getElementById('comments__id') != undefined) && document.getElementById('comments__id').value != ''){
            temp.classList.add("uiInput uiInputTextArea uiInput--default uiInput--textarea");
            var linesCount=document.getElementById('comments__id').value.split(/\r*\n/).length;
            if(linesCount >5){
                document.getElementById('comments__id').setAttribut("rows","5");
            }else{
                document.getElementById('comments__id').setAttribut("rows",linesCount);
            }
        }*/
    },
    //Case Description Section
    showCaseDescription : function(component, event, helper) {
        if(component.find("CD_Div")){
            var dropArrow1 = component.find("CD_downArrow");
            var rightArrow1 = component.find("CD_rightArrow");
            $A.util.addClass(dropArrow1, 'slds-show');
            $A.util.removeClass(dropArrow1, 'slds-hide');
            $A.util.addClass(rightArrow1, 'slds-hide');
            $A.util.removeClass(rightArrow1, 'slds-show');
            
        }
        setTimeout(function(){
            component.set("v.CaseDescriptionSectionHide",false);
        }, 200);
    },
    hideCaseDescription: function(component, event, helper) {
        if(component.find("CD_Div")){
            var rightArrow1 = component.find("CD_rightArrow");
            var dropArrow1 = component.find("CD_downArrow");
            $A.util.removeClass(dropArrow1, 'slds-show');
            $A.util.addClass(dropArrow1, 'slds-hide');
            $A.util.removeClass(rightArrow1, 'slds-hide');
            $A.util.addClass(rightArrow1, 'slds-show');    
        }
        setTimeout(function(){
            component.set("v.CaseDescriptionSectionHide",true);
        }, 200);
    },
    openEditModalForCaseDescription: function(component,event,helper){
        component.set('v.isOpen',true);
        var blurBackground = component.find("CD_BackgroundBlur");
        $A.util.addClass(blurBackground, 'blurBackgroundForModalForCD');
        document.body.style.overflowX = 'hidden';
        document.body.style.overflowY = 'hidden';
    },
    closeModal: function(component,event,helper){
        component.set('v.isOpen',false); 
        var blurBackground = component.find("CD_BackgroundBlur");
        $A.util.removeClass(blurBackground, 'blurBackgroundForModalForCD');
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';
    },
    handleSuccess : function(component, event, helper) {
        var descriptionVal = component.find("CD_DescriptionId").get("v.value");
        var subjectVal = component.find("CD_SubjectId").get("v.value");
        var caseRec = component.get("v.caseRecord");
        caseRec.Description = descriptionVal;
        caseRec.Subject = subjectVal;
        component.set("v.caseRecord",caseRec);
        component.set('v.isOpen',false);
        $A.get('e.force:refreshView').fire();
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';
        
        //location.reload();        
    },
    saveRecord : function(component, event, helper) {
        var caseSubjectValue = component.find("CD_SubjectId").get("v.value");
        var caseDescriptionValue = component.find("CD_DescriptionId").get("v.value");
       
        
        var action = component.get("c.saveCaseRecordForCaseDescription");
        action.setParams({
            caseId: component.get("v.recordId"),
            caseSubjectVal: caseSubjectValue,
            caseDescriptionVal: caseDescriptionValue
        });
        action.setCallback(this,function(response){
            var result = response.getReturnValue();
            if(result == null){
                //location.reload();
                $A.get('e.force:refreshView').fire();
            }
            else if(result != null && result != ''){
                component.set("v.errorMessage", result);
                component.set("v.showError", true);
            }
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component, event, helper) {        
        component.set("v.Spinner", true); 
    },
    
    hideSpinner : function(component,event,helper){        
        component.set("v.Spinner", false);
    },
})