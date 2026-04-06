({
    fetchBaseUrl : function(component, event) {
        var url = window.location.href;
        var pathname = window.location.pathname;
        var index1 = url.indexOf(pathname);
        var index2 = url.indexOf("/", index1 );
        var baseUrl = url.substr(0, index2); 
        if(baseUrl!= null && baseUrl!=''){
            return baseUrl;
        }else{
            return null;
        }
    }
})