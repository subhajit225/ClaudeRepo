({
	 getPageName : function(){
        var pageName = '';
        var pathName = decodeURIComponent(window.location.pathname);
        if(!$A.util.isEmpty(pathName)){
            var paths = pathName.split('/');            
            if($A.util.isArray(paths)){
                pageName =  paths[paths.length-1];
            }
        } 
        return pageName;
    }
})