({
	doInit : function(component, event, helper) {
		var quoteQuery ='select Id,Polaris_Contact__c,Polaris_Contact_Email__c from order where id = \''+ component.get("v.recordId") + '\''+ ' order by createddate Desc limit 1';
        helper.executeQueryRec(component, event, helper, quoteQuery, 'orderRec'); 
	},
    
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault(); //Prevent default submit
        var validity = component.find("myinput").get("v.validity");
        if(!validity.valid)
            return;
            
        helper.handleOnSubmit(component, event, helper);
    },
    
    editableForm : function(component, event, helper) {
        component.set("v.isReadOnly", false);
    },
    
    handleCreateLoad: function(component, event, helper) {
        component.set("v.showSpinner", false);  
    },
})