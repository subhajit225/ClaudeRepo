({
	doInit : function(component, event, helper) {
		
        var search = location.href;
        console.log(search);
        if(!!search){
            if(search.includes('feed')){
                search = search.replace('feed','question');
                location.href =search;   
            }
            
        }
	}
})