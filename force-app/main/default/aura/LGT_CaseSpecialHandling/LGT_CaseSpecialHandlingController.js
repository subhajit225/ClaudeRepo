({
    doInit : function(component, event, helper) {
        var action = component.get("c.getCaseRecord");
        action.setParams({
            caseId: component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var result = response.getReturnValue();
            if(result != null && result != ''){
                component.set("v.currentCase",result);
                component.set("v.CaseSpclHandlingSectionHide",false);
                /*if(component.get("v.currentCase.Account.Heads_Up_to_Support_Team__c").length>20){
                    var spclHandlingLength = component.find('spclHandlingField');
                    $A.util.addClass(descriptionLength, 'commentsFull');
                    $A.util.removeClass(descriptionLength, 'commentsLess');  
                }*/
            }
            if(component.get("v.currentCase.Account.Heads_Up_to_Support_Team__c") == null || component.get("v.currentCase.Account.Heads_Up_to_Support_Team__c") == ''){
                component.set("v.CaseSpclHandlingSectionHide",true);
            }
        });
        $A.enqueueAction(action);
    },
    
    //Case Special Handling Section When Heads Up to Support Field Is not empty
    showCaseSpecialHandlingWhenNotEmpty : function(component, event, helper) {
       // if(component.find("CSH_Div")){
       		console.log('showCaseSpecialHandlingWhenNotEmpty------->');
            var dropArrow1 = component.find("CSH_DownArrowForNotEmpty");
            var rightArrow1 = component.find("CSH_RightArrowForNotEmpty");
            $A.util.addClass(dropArrow1, 'slds-show');
            $A.util.removeClass(dropArrow1, 'slds-hide');
            $A.util.addClass(rightArrow1, 'slds-hide');
            $A.util.removeClass(rightArrow1, 'slds-show');
            
        //}
        setTimeout(function(){
            component.set("v.CaseSpclHandlingSectionHide",false);
        }, 200);
    },
    hideCaseSpecialHandlingWhenNotEmpty: function(component, event, helper) {
        	console.log('hideCaseSpecialHandlingWhenNotEmpty------->');
        //if(component.find("CSH_Div")){
            var dropArrow1 = component.find("CSH_DownArrowForNotEmpty");
        	var rightArrow1 = component.find("CSH_RightArrowForNotEmpty");
            $A.util.removeClass(dropArrow1, 'slds-show');
            $A.util.addClass(dropArrow1, 'slds-hide');
            $A.util.removeClass(rightArrow1, 'slds-hide');
            $A.util.addClass(rightArrow1, 'slds-show');    
        //}
        setTimeout(function(){
            component.set("v.CaseSpclHandlingSectionHide",true);
        }, 200);
    },
    //Case Special Handling Section When Heads Up to Support Field Is not empty
    showCaseSpecialHandling : function(component, event, helper) {
        //if(component.find("CSH_Div")){
        	console.log('showCaseSpecialHandling------->');
            var dropArrow2 = component.find("CSH_DownArrowForEmpty");
            var rightArrow2 = component.find("CSH_RightArrowForEmpty");
            $A.util.addClass(dropArrow2, 'slds-show');
            $A.util.removeClass(dropArrow2, 'slds-hide');
            $A.util.addClass(rightArrow2, 'slds-hide');
            $A.util.removeClass(rightArrow2, 'slds-show');
            
        //}
        setTimeout(function(){
            component.set("v.CaseSpclHandlingSectionHide",false);
        }, 200);
    },
    hideCaseSpecialHandling: function(component, event, helper) {
        console.log('hideCaseSpecialHandling------->');
        //if(component.find("CSH_Div")){
            var dropArrow2 = component.find("CSH_DownArrowForEmpty");
            var rightArrow2 = component.find("CSH_RightArrowForEmpty");
            $A.util.removeClass(dropArrow2, 'slds-show');
            $A.util.addClass(dropArrow2, 'slds-hide');
            $A.util.removeClass(rightArrow2, 'slds-hide');
            $A.util.addClass(rightArrow2, 'slds-show');    
        //}
        setTimeout(function(){
            component.set("v.CaseSpclHandlingSectionHide",true);
        }, 200);
    },
})