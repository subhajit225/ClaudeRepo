({
	doInit : function(component, event, helper) {
        var currenturl = window.location.href;
        if(currenturl.search('/s') >= 0){
            var temp = currenturl.split('/s');
            component.set("v.vfHost",temp[0]);
        }
        helper.doInit(component, event, helper);
	},
    
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault(); //Prevent default submit
        helper.handleOnSubmit(component, event, helper);
    },
    
    openAgreementModel : function(component, event, helper) {
        helper.openAgreementModel(component, event, helper);
    },
    
    closeAgreementModel: function(component, event, helper) {
        component.set("v.isOpenAgreement", false);
    },
    
    editAddress: function(component, event, helper) {
        component.set("v.isAddressEditable", true);
    },
})