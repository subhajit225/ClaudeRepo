({
	/* get url parameter */
    getUrlParameter : function(component, event) {
        var getUrlParameter = function getUrlParameter(sParam) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;            
            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        var parentPageName =  getUrlParameter('parentPage');
        if(parentPageName){
          component.set("v.parentPageName",parentPageName);  
        }
        
        var pathName = decodeURIComponent(window.location.pathname);
        var paths = pathName.split('/');
        if($A.util.isArray(paths)){
            var pageName =  paths[paths.length-1];
            if(pageName){
                component.set("v.pageName",pageName);  
            }  
        }        
    },
})