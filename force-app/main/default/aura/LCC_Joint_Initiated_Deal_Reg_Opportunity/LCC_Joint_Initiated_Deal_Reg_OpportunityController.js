({
    execute : function(component, event, helper) {
        if (component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c') == 'Approved' && component.get('v.sObjectInfo.Deal_Registration_Type__c') == 'Joint Initiated Deal') 
        {
            component.set("v.content",'\'Joint Initiated Deal\' already approved so your request cannot be submitted');
        }
        else if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' == 'Approved' && ''+component.get('v.sObjectInfo.Deal_Registration_Type__c')+'' == 'Partner Initiated Deal') 
        {
            component.set("v.content",'\'Partner Initiated Deal\' already approved so your request cannot be submitted ');
        }
        else if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' == 'Approved' && ''+component.get('v.sObjectInfo.Deal_Registration_Type__c')+'' == 'Rubrik Initiated Deal') 
        {
            component.set("v.content",'\'Rubrik Initiated Deal\' already approved so your request cannot be submitted ');
        }
        else if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' != 'Approved') 
        {
            helper.gotoURL(component, "/apex/Opp_RubrikInitiatedDealPage?Id="+component.get("v.recordId")+"&type=JID");
        }
        else 
        {
            component.set("v.content",'Deal Reg Approval Status is already approved');
        }
        
        
    }
})