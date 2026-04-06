({
    getValue: function(component,event,helper) {
        
        console.log('enter--') ;
        var custNo = component.get("v.custNo");
        var action = component.get("c.getTopVideos");   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {       
                var custs = [];
                var conts = response.getReturnValue();
                 console.log('test===' , "v.VideosLinks", conts);
                //debugger;
                for ( var key in conts ) {
                    var url;
                    if(conts[key].Video_URL__c != null){
                        url = conts[key].Video_URL__c;
                        url= "https://img.youtube.com/vi/"+url.substr(url.length - 11)+"/hqdefault.jpg";
                        console.log('url---' , url);
                    }
                    custs.push({value:conts[key], key: url});
                    
                    
                }
                component.set("v.VideosLinks", custs);
                console.log('test===' , "v.VideosLinks", custs);
                
            } 
        });           
        $A.enqueueAction(action); 
    }
})