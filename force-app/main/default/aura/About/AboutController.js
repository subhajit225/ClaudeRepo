({
	init : function(component, event, helper) {
        var today = $A.localizationService.formatDate(new Date(), "MMMM YYYY");
    	component.set('v.today', today);
        
		helper.responseTotal(component);
        helper.blasts(component);
        helper.hapiness(component);
        helper.temprature(component);
	}
})