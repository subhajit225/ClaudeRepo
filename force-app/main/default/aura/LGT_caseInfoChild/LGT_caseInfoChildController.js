({
    init: function (cmp, event, helper) {
        var caseRecord = cmp.get("v.caseRecord");
        if(cmp.get("v.fieldApi") == 'Current_Status__c' || cmp.get("v.fieldApi") == 'Next_Step__c'){
            var currentStatusVal = caseRecord[cmp.get("v.fieldApi")];
            if((currentStatusVal != null && currentStatusVal != '')){
                cmp.set("v.viewMoreButton",true);
            }
        }   
        try{            
            if(cmp.get("v.fieldApi").includes('EndDate') || cmp.get("v.fieldApi").includes('AnnualContractValue__c') ||
                cmp.get("v.fieldApi").includes('Customer_URL__c') || cmp.get("v.fieldApi").includes('Rubrik_Sales_Engineer__c') ||
               cmp.get("v.fieldApi").includes('Account_Preference__c') || cmp.get("v.fieldApi").includes('OwnerId') ||
               cmp.get("v.fieldApi").includes('AnnualContractValue__c') || cmp.get("v.fieldApi").includes('Sum_of_Opportunities__c') ||
               cmp.get("v.fieldApi").includes('.Id') || cmp.get("v.fieldApi").includes('EndDate') ||
               cmp.get("v.fieldApi").includes('Opportunity_lookup__')
              ){
                var fields = cmp.get("v.fieldApi").split(".");
                cmp.set("v.fieldLabel",fields[1].replaceAll("__c", "").replaceAll("_", " "));
                
                cmp.set("v.showLookupFields",true);
                var valueField;

                if(cmp.get("v.fieldApi") == 'Account.OwnerId'){
                    valueField = caseRecord[fields[0]]['Owner']['Name'];
                }else if(cmp.get("v.fieldApi") == 'Account.Rubrik_Sales_Engineer__c'){
                    valueField = caseRecord[fields[0]]['Rubrik_Sales_Engineer__r']['Name'];
                }else{
                    valueField = caseRecord[fields[0]][fields[1]];
                }
                cmp.set("v.fieldValue",valueField);
                if(fields[1] == 'Id'){
                    fields[1] = "Account Id";
                }if(fields[1] == 'Customer_URL__c'){
                    fields[1] = "Customer Polaris URL";
                }if(fields[1] == 'Sum_of_Opportunities__c'){
                    fields[1] = " Sum of Won Opportunities (TCV)";
                }if(fields[1] == 'Amount'){
                    fields[1] = "Amount (TCV)";
                    cmp.set("v.fieldLabel",fields[1]);
                }
                if(cmp.get("v.fieldApi") == 'Account.OwnerId'){
                    fields[1] = "Account Executive";
                    cmp.set("v.fieldLabel",fields[1]);
                }
                
                
            }
        }catch(e){
            console.log('e',e);
        }
    },
    
    inlineEditRating : function(component,event,helper){   
        // show the rating edit field popup 
        event.preventDefault();
        var fieldName = event.target.id;
        if(fieldName == 'Platform__c' || fieldName == 'Product_Area__c' 
           || fieldName == 'Problem_Type__c' || fieldName == 'Sub_Component__c' 
           || fieldName == 'Software_Version__c' || fieldName == 'If_Other__c'){
            component.set("v.isOpen",true);
            component.set("v.saved",false);
            document.body.style.overflowX = 'hidden';
            document.body.style.overflowY = 'hidden';
        }if(fieldName == 'Sub_Phase__c' || fieldName == 'Churn_Reason__c'){
            component.set("v.isOpen",true);
            component.set("v.saved",false);
            document.body.style.overflowX = 'hidden';
            document.body.style.overflowY = 'hidden';
        }
        else if (fieldName == 'HotCriticalIssue__c') {
            component.set("v.isHotSectionOpen",true);
            component.set("v.isHotSectionSaved",false);
            document.body.style.overflowX = 'hidden';
            document.body.style.overflowY = 'hidden';
        } else{
            component.set("v.ratingEditMode", true);  
        }
        
        var caseRecord = component.get("v.caseRecord");
        
    },
    
    closeRatingBox1 : function (component, event, helper) {
        if(component.get("v.ratingEditMode")){
            component.set("v.ratingEditMode", false);
            
        }
        if(component.find('field')!=undefined){
        	component.find('field').reset();
        }
        // on focus out, close the input section by setting the 'ratingEditMode' att. as false
        
    },
    openPop : function(component, event, helper) {
        component.set("v.showTextPopUp",true);
        
    },
    
    closePop : function(component, event, helper) {
        component.set("v.showTextPopUp",false);
        
    },
    saveRecord : function(component, event, helper){
        event.preventDefault();
        component.set("v.showSpinner",true);
        var fieldName = event.target.id;
        var caseRecord = component.get("v.caseRecord");
        caseRecord[fieldName] = component.get("v.fieldValue");
        var action = component.get('c.saveRecordApex1');
        //add for - CS21-504
        let message = 'Unknown error, Please contact your System Adminstrator.';
        
        action.setParams({'fieldName':fieldName, 
                          'value':component.get("v.fieldValue"), 
                          'recordId':component.get("v.recordId")
                         });
        
        action.setCallback(this, function(response){
            var result = response.getReturnValue();
            var State = response.getState();
            
            //added error logic as there is discrepency 
            //result is returning blank when there is exception
            //CS21-504 -Veera
            let errors = response.getError();
            
            if (errors && Array.isArray(errors) && errors.length > 0) {
                message = errors[0].message;
            } else {
                message = result;
            }
            //CS21-504 - End

            
            if(result == "SUCCESS") {    
                component.set("v.ratingEditMode", false);
                component.set("v.caseRecord",caseRecord);
                component.set("v.showSpinner",false);
                $A.get('e.force:refreshView').fire();
            } else {
                component.set("v.showSpinner",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": message,
                    "duration": 10000
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
});