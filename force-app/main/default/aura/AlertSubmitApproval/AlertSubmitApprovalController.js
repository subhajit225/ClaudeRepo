({
    handleNoEvent : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleYesEvent : function(component, event, helper) {
        component.set("v.showSpinner", true);  // FY26WL-534 spinner start
        
         var approveQuote = component.get("v.ApproveQuote")
         console.log('in Child>>'+approveQuote);
        if(approveQuote){
         helper.submitQuoteRec(component, event, helper,approveQuote);
       //  $A.get("e.force:closeQuickAction").fire();
            // $A.get('e.force:refreshView').fire();
        }else {
        var compEvent = component.getEvent("sendForApprovalEvt");
        compEvent.setParams({
            "isApproval" : true 
        });
        compEvent.fire();
    }
    }
})