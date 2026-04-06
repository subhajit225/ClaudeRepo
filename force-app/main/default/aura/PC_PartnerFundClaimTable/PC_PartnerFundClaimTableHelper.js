({
	    /* This method calls backend apex method which fetches records that needs to be shown on table. 
       This is invoked via getMoreOnScroll function.
    */
    getRecordsHelperpfc : function(component, event) {
        return new Promise($A.getCallback(function(resolve, reject) {
        var action = component.get("c.getRecords");
        console.log('in helper');
        var data = component.get("v.pfcList");
        var dataSize;
        var lastId;
        if(component.get("v.sortedBy") == 'linkName'){
            component.set("v.sortedBy", "Title");
        } 
        if(component.get('v.flag')  == true){
            component.set('v.flag', false);
            if(component.get("v.pfcList") != null){
                var dataSize = component.get("v.pfcList").length;
                if(dataSize > 0 ){
                    component.set("v.sortedByValue", data[dataSize - 1][component.get("v.sortedBy")]);
                }
            } 
            console.log(component.get("v.sortedByValue"));
            action.setParams({"searchText" : component.get("v.searchText"),
                              "returnFields" : component.get("v.returnFieldsinQuery"),
                              "objType" : component.get("v.objTypeinQuery"),
                              "pageSize" : parseInt(component.get("v.pageSize")),
                              "fieldapiName" : component.get("v.sortedBy"),
                              "sortedDirection" : component.get("v.sortedDirection"),
                              "sortedByValue":component.get("v.sortedByValue"),
                              "IdSet" : component.get("v.IdSet"),
                              "parentrecId" : component.get("v.recordId")
                             });
           
            action.setCallback(this, function(a) {
                component.set('v.flag', true);
                resolve(a.getReturnValue());
                
            });
            $A.enqueueAction(action);
        }
            
        }));
           
    },
    /* This method is invoked on component load used for fetching records from backend and also initializes scroll event listener for table */
    initDatapfc : function (component, event,helper,callFrom) {
        var action = component.get("c.getRecords");
        var self = this;
        component.set('v.flag', false);
        if(component.get("v.sortedBy") == 'linkName'){
                 component.set("v.sortedBy", "Title");
        }
        action.setParams({"searchText" : component.get("v.searchText"),
                          "returnFields" : component.get("v.returnFieldsinQuery"),
                          "objType" : component.get("v.objTypeinQuery"),
                          "pageSize" : parseInt(component.get("v.pageSize")),
                          "fieldapiName" : component.get("v.sortedBy"),
                          "sortedDirection" : component.get("v.sortedDirection"),
                          "sortedByValue":component.get("v.sortedByValue"),
                          "IdSet" : component.get("v.IdSet"),
                          "parentrecId" : component.get("v.recordId")
                         });
        action.setCallback(this,function(response){
            console.log(response.getState());
            if(response.getState() == "SUCCESS"){
                var path = window.location.href;
                var pathname = helper.pathToSetpfc(component);
                var records = response.getReturnValue();
                records.forEach(function(record){
                    record.linkName = pathname+'/s/claimdetail?recordId='+record.Id+'&recordName='+record.Title;
                    
                    var idarr = component.get("v.IdSet");
                    idarr.push(record.Id);
                    component.set("v.IdSet",idarr);
                }); 
                 if(component.get("v.sortedBy") == 'Title'){
                 	component.set("v.sortedBy", "linkName");
            	}
                component.set('v.pfcList', records);
                console.log(component.get('v.pfcList'));
                component.set('v.flag', true);
                if(callFrom == 'doInit'){
                    var action1 = component.get("c.getTotalRecords");
                    action1.setParams({
                        "objType" : component.get("v.objTypeinQuery")
                    });
                    action1.setCallback(this,function(response){
                        if(response.getState() == "SUCCESS"){
                            component.set("v.totalSize",response.getReturnValue());
                            console.log('@@ totalSize '+component.get("v.totalSize"));
                            component.set("v.loadTable",true);
                           
                            var device = $A.get("$Browser.formFactor");
        					if( device == 'DESKTOP'){
                                window.addEventListener("scroll", getMoreOnScrollpfc);
                            }else if( device == 'PHONE' || device == 'TABLET' ){
                                document.getElementById("myDIV").addEventListener("touchmove", getMoreOnScrollpfc);
                            }
                            if((component.get('v.pfcList') != null && component.get('v.pfcList').length == component.get('v.totalSize')) || component.get('v.totalSize') == 0){
                            	component.set("v.loadMoreStatus","No more data to show");
                                var device = $A.get("$Browser.formFactor");
        						if(device == 'DESKTOP'){
                                    window.removeEventListener("scroll", getMoreOnScrollpfc);
                                }else if( device == 'PHONE' || device == 'TABLET' ){
                                     document.getElementById("myDIV").removeEventListener("touchmove", getMoreOnScrollpfc);
                                }
                            }else{
                                if(component.get('v.pfcList') != null && component.get('v.pfcList').length < component.get('v.pageSize')){
                              		component.set("v.loadMoreStatus","No more data to show");
                                }else{
                                	component.set("v.loadMoreStatus","");
                                }
                            }
                            
                        }
                    });
                    $A.enqueueAction(action1);  
                }else{
                     if((component.get('v.pfcList') != null && component.get('v.pfcList').length == component.get('v.totalSize')) || component.get('v.totalSize') == 0){
                         component.set("v.loadMoreStatus","No more data to show");
                         var device = $A.get("$Browser.formFactor");
                         if(device == 'DESKTOP'){
                             window.removeEventListener("scroll", getMoreOnScrollpfc);
                         }else if( device == 'PHONE' || device == 'TABLET' ){
                             document.getElementById("myDIV").removeEventListener("touchmove", getMoreOnScrollpfc);
                         }
                     }else{
                         if(component.get('v.pfcList') != null && component.get('v.pfcList').length < component.get('v.pageSize')){
                             component.set("v.loadMoreStatus","No more data to show");
                         }else{
                             component.set("v.loadMoreStatus","");
                         }
                     }
                }
            }
        });
        $A.enqueueAction(action);
        
        var previousPosition = 0;
        /*This method contains callback of getRecordsHelper helper method. 
        This function is invoked when there is scroll down event is fired on window */
        function getMoreOnScrollpfc(event) {
            var currentPosition = 0;
            var device = $A.get("$Browser.formFactor");
           
             //window.innerHeight+ window.scrollY) >= document.body.offsetHeight
            if(!$A.util.isUndefined(window.scrollY)){
               // if((window.innerHeight+ window.scrollY+20) >= document.body.offsetHeight){
                if((device == 'DESKTOP' && document.documentElement.scrollHeight - document.documentElement.clientHeight <= window.scrollY+200) || ((device == 'PHONE' || device == 'TABLET') )){
                    currentPosition = window.scrollY;
                   
                }
            }
            if(currentPosition > previousPosition){
                 if(component.get('v.flag') ==  true && component.get('v.pfcList') != null && component.get('v.pfcList').length < component.get('v.totalSize')){           
                    helper.getRecordsHelperpfc(component, event).then($A.getCallback(function (data) {
                        var records = data;
                        if(data != null && data.length > 0){
							var pathname = helper.pathToSetpfc(component);
                            records.forEach(function(record){
                                record.linkName = pathname+'/s/claimdetail?recordId='+record.Id+'&recordName='+record.Title;
                                var idarr = component.get("v.IdSet");
                                idarr.push(record.Id);
                                component.set("v.IdSet",idarr);
                            });
                            if(component.get("v.sortedBy") == 'Title'){
                                component.set("v.sortedBy", "linkName");
                            }
                            var currentData = component.get('v.pfcList');
                            var newData = currentData.concat(records);
                            component.set('v.pfcList', newData);
                            if((component.get('v.pfcList') != null && component.get('v.pfcList').length == component.get('v.totalSize')) || component.get('v.totalSize') == 0){
                                component.set("v.loadMoreStatus","No more data to show");
                            }else{
                                if(component.get('v.pfcList') != null && component.get('v.pfcList').length < component.get('v.pageSize')){
                                 	component.set("v.loadMoreStatus","No more data to show");
                                }else{
                                	component.set("v.loadMoreStatus","");
                                }
                            }
                                                      
                        }else{
                            component.set("v.loadMoreStatus","No more data to show");
                        }
                        
                           component.set('v.flag', true);
                    }));
                    
                } 
            }
            previousPosition = currentPosition;
        }
    },
    
       
    /* Used for Navigation to New record creation page of Deal Registration */
    gotoURLpfc : function (component, event, url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url,
            "isredirect": false
        });
        urlEvent.fire();
    },
    
    /* This method is used for capturing Community name */
    pathToSetpfc : function (component) {
        var path = window.location.href;
        var pathname = '';
        if(path.indexOf('.com') > 0){
            var patharr1 = path.split('.com');
            if(patharr1[1].indexOf('/s/') > 0){
                var patharr2 = patharr1[1].split('/s/');
                if (typeof patharr2[0] !== 'undefined'){
                	pathname = patharr2[0];
                }
            }
        }
        return pathname;
    }
})