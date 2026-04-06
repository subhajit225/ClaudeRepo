({
    handleRouteChange:function(component, event, helper) {
    	if(!window.su_url || window.su_url!=window.location.href){
            if(window.su_url && window.su_url!=window.location.href)
            	window.gza("pageView",{});
            window.su_url = window.location.href;
        }
	}
})