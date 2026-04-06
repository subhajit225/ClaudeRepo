({
    execute : function(component, event, helper) {
        // TODO: Review the migrated code
        if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' == 'Approved' && ''+component.get('v.sObjectInfo.Deal_Registration_Type__c')+'' == 'Partner Initiated Deal') 
        {
            component.set("v.showok",true);
            //alert('\'Partner Initiated Deal Reg\' already approved so your request cannot be submitted');
            component.set("v.content","\'Partner Initiated Deal Reg\' already approved so your request cannot be submitted");
            
        }else if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' == 'Approved' && ''+component.get('v.sObjectInfo.Deal_Registration_Type__c')+'' == 'Rubrik Initiated Deal') 
        {
            component.set("v.showok",true);
            //alert('\'Rubrik Initiated Deal Reg\' already approved so your request cannot be submitted ');
            component.set("v.content","\'Rubrik Initiated Deal Reg\' already approved so your request cannot be submitted ");
        }else if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' == 'Approved' && ''+component.get('v.sObjectInfo.Deal_Registration_Type__c')+'' == 'Joint Initiated Deal') 
        {
            component.set("v.showok",true);
            //alert('\'Joint Initiated Deal\' already approved so your request cannot be submitted');
            component.set("v.content","\'Joint Initiated Deal\' already approved so your request cannot be submitted");
        }
        else if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' == 'Approved') 
        {
            component.set("v.showok",true);
            //alert('Deal Reg Approval Status is already approved');
            component.set("v.content","Deal Reg Approval Status is already approved");
         }
         else if (''+component.get('v.sObjectInfo.Deal_Reg_Approval_Status__c')+'' != 'Approved') 
         {
             helper.gotoURL(component, '/apex/Opp_RubrikInitiatedDealPage?Id='+component.get('v.sObjectInfo.Id')+'&type=RID');
         }
        
        
    },
    handleClick :  function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();   
    }
})