({
	doInit : function(component, event, helper) {
        helper.getCountryList(component, event);
        //helper.getTerritoryList(component, event);
	},
    handleSearch : function(component, event, helper) {
		helper.getDistributorsList(component, event);
	},
    handleReset : function(component, event, helper) {
        helper.resetAttr(component, event);
	}
})