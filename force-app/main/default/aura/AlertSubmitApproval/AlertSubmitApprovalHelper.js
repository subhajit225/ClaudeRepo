({
	submitQuoteRec : function(component, event, helper, approveQuote) {
		var action = component.get("c.onSubmitLtng");
        var quote = component.get("v.quoteRec");
       // console.log('Quote'+quote);
       // component.set("v.showGenericSpinner", true);
        action.setParams({
            "quote": quote,
            "markApproved": approveQuote
        });
        action.setCallback(this, function(response){
            console.log('>>>>response.getState()'+response.getState());
            console.log('>>response.getReturnValue()'+response.getReturnValue());
            if(response.getReturnValue()==''){
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
	},
})