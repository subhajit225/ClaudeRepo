({
	doInit : function(component, event, helper) {
        var id = component.get("v.recordId");
        if(id.startsWith("500"))
			window.location.href = '/s/viewcase?id='+id;
        if(id.startsWith("a40"))
			window.location.href = '/s/announcementdetail?Id='+id;
        if(id.startsWith("a5B") || id.startsWith("a41"))
			window.location.href = '/s/documentationdetail?id='+id;
	}
})