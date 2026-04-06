({
	fireSearchEvent : function(component,event) {
		var searchEventFire = component.getEvent("searchEventName");
        searchEventFire.setParams({"searchText":component.get("v.searchText")});
        searchEventFire.fire();
	}
})