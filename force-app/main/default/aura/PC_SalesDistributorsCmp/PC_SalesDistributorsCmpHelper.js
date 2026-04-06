({
    resetAttr : function(component, event) {
        component.set("v.accountName","");
        component.set("v.country","");
        component.set("v.distributorList",[]);
    },
    /* Get Distributors list*/
    getDistributorsList : function(component, event) {
        var params = {
            "accountName" : component.get("v.accountName"),
            "country" : component.get("v.country"),
            //"territory" : component.get("v.territory")
        };
        
        this.callServer(component, "c.getDistributorsList",params,function(response){            
            if(!$A.util.isEmpty(response)){
                component.set("v.showNoRecords",false);
                component.set("v.distributorList",response);                
            }else{
                component.set("v.showNoRecords",true);
                component.set("v.distributorList",[]);
            }
        },false);
    },
    /* Get Distributors Country list*/
    getCountryList : function(component, event) {
        var params = {
           /* "objectName" : "Partner_Onboarding_Request__c",
            "field" : "Country__c"*/
        };
        
        this.callServer(component,"c.getCountryOptions",params,function(response){                    
            if(!$A.util.isEmpty(response)){
                var countryList = [];
                var conts = response;
                for(var key in response){
                    countryList.push({label:response[key], value:response[key]});
                }
                component.set("v.countryList",countryList);
            }
        },false);
    },
    /* Get Distributors Territory list*/
    /*getTerritoryList : function(component, event) {
        var params = {
        };
        
        this.callServer(component,"c.getTerritoryOptions",params,function(response){                    
            if(!$A.util.isEmpty(response)){
                var territoryList = [];
                var conts = response;
                for(var key in response){
                    territoryList.push({label:response[key], value:key});
                }
                component.set("v.territoryList",territoryList);
            }
        },false);
    },*/
    /*
     * Call Apex method.
     */
    callServer : function(component, actionName,params,callback,cacheable) { 
        
        var action = component.get(actionName);
        if(params){
            action.setParams(params); 
        }
        if (cacheable) {
            action.setStorable();
        }
        action.setCallback(this,function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") { 
                // pass returned value to callback function
                callback.call(this,response.getReturnValue());
            } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    if (errors[0] && errors[0].message) {
                        throw new Error("Error" + errors[0].message);
                    }
                } else {
                    throw new Error("Unknown Error");
                } 
            }
        });
        $A.enqueueAction(action);
        
    } ,
})