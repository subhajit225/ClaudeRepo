({  
    doInit: function(component, event, helper) {
        var action = component.get("c.fetchIncentiveDetails"); 
        action.setCallback(this, function(response) { 
            if(response.getState() === "SUCCESS") {
                component.set("v.incentiveList",response.getReturnValue());
            }
        });
        $A.enqueueAction(action); 
    },
    
    handleClick : function(component, event, helper) {
        
        var Incentive = component.get("v.incentiveList").find(record => record.Id === event.target.id);
        //Navigation url is present it will redirect to that page
        if(!$A.util.isEmpty(Incentive.Navigate_Url__c)){
            var url= Incentive.Navigate_Url__c;
            //var url= "/"+Incentive.Navigate_Url__c;
            //Need to check whether we can get '/incentive' through window.location.pathname
            //if we get that then we can call gotoURL method in helperCmp component
            helper.gotoURL(component, event, url);
        }
        else
        {
            var incentiveid = event.target.id;
            if($A.util.isEmpty(incentiveid)){
                incentiveid = event.getSource().get("v.value");            
            }
            
            var url= "/incentivesclaim?id=" + incentiveid;  
            helper.gotoURL(component, event, url);  
        }
        
    },
    handleClick1 : function(component, event, helper) {
        
        var Incentive = component.get("v.incentiveList").find(record => record.Id === event.target.id);
        var url;
        
        if(Incentive.Link_Type__c == "Community Page"){            
            var incentiveid = event.target.id;
            if($A.util.isEmpty(incentiveid)){
                incentiveid = event.getSource().get("v.value");            
            }
            url= "/incentivesclaim?id=" + incentiveid; 
        }
        else if(Incentive.Link_Type__c == "File" ){
            var pageurl = window.location.href;
            pageurl = pageurl.split('/s');
            url = pageurl[0]+Incentive.Navigate_Url__c;            
        }else if(Incentive.Link_Type__c == "External URL" ){
            url = Incentive.Navigate_Url__c;
        }
        if(!$A.util.isEmpty(url)){
            helper.gotoURL(component, event, url);
            //helper.navigateToURL(component, event, url,true);
        }
    }
})