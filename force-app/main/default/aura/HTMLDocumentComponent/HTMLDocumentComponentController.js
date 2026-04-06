({
	doinit : function(component, event, helper) {
        try{
            var url_string = window.location.href;
            var url = new URL(url_string);
            var docurl = url.searchParams.get("docurl");
            if(docurl.includes('5.0')){
                if(!docurl.includes('index.html')){
                    var urls = docurl.split("/");
                    docurl = urls[0]+'//'+urls[2]+'/'+urls[3]+'/topic.htm#t='+urls[4]+'/'+urls[5];
                }
            }
            if(docurl.includes('docs.rubrik') || docurl.includes('rubrik-docs')){
                component.set("v.url",docurl);
	    }
        }catch(e){console.log(e);}
        
	},
    resizeIframe : function(component, event, helper) {
        var obj = document.getElementById("myFrame");
        obj.style.height = obj.contentWindow.document.body.scrollHeight + 'px';
    }
})