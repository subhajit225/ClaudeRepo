({
    /*Invokes component event */
	handleSearch : function(component, event, helper) {
        console.log('component.get("v.searchText") '+component.get("v.searchText"));
        helper.fireSearchEvent(component, event);
	},
    onKeyUp : function(component, event, helper) {
        console.log(event.getParams().keyCode);
        if(event.getParams().keyCode == '13'){
            helper.fireSearchEvent(component, event);
        }
    }
})