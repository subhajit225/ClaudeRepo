({
	 handleClick1 : function(component, event, helper) {
           component.set("v.isLoading", true);
           var action = component.get("c.renewalContracts");
            action.setParams({ str : JSON.stringify(component.get("v.contrList")) ,
                             oppId : component.get("v.recordId") });
            console.log('here is the log>>>>>');
           
            action.setCallback(this, function(response){
                 var state = response.getState();
                console.log('response>>>>>', response.getError());
                console.log('State'+state);
          //  if(state == "SUCCESS")
           // {
                console.log('was a success');
                console.log("From server: " + response.getReturnValue());

                var quoteId = response.getReturnValue();
                if (quoteId != null) {
                    if (quoteId.toString().startsWith('a6')) {
                        component.set("v.isLoading", false);
                        component.set("v.quoteId",quoteId);
                        console.log('Entered if');
                        this.getQuoteName(component,event, helper); //MS CPQ22-6072
                        //this.navigateToQLE(component,event, helper);
                        $A.get("e.force:closeQuickAction").fire();
                    } else {
                        component.set("v.isLoading", false);
                        component.set("v.showtable",false);
                        component.set("v.showmsg",true);
                        var customMsg = 'An unexpected Error has occurred. Please contact System Administrator. Error: '
                        component.set("v.message",customMsg+JSON.stringify(quoteId));
                        console.log('Entered else');
                    }
                }
                
                if(quoteId!= null){
                    console.log('inside quote comp1')
                }else{
                    component.set("v.isLoading", false);
                    component.set("v.showcomp",true);
            }
         });
             $A.enqueueAction(action);
        
    },
    
        navigateToQLE : function(component, event, helper) {
            console.log('inside navigate'+component.get("v.quoteId"));
            component.set("v.isLoading", true);
            var quoteId = component.get("v.quoteId");
            //CPQ22-4068 Starts
            let currentUser = $A.get("$SObjectType.CurrentUser.Id");
            console.log('currentUser :: ', currentUser);
            let currentUserName = $A.get("$SObjectType.CurrentUser.Email");
            console.log('currentUserName ::', currentUserName);
            var today = new Date();
            console.log('today is ', today);
            var urlString = window.location.origin;
            var showSMSPage = component.get("v.showSMSPage");
            if(!showSMSPage){
				component.set("v.isLoading", false);
                urlString = urlString + '/apex/QLINewReplacement?quoteId=' + quoteId 
                + '&accId=' + component.get("v.opportunityRecord.AccountId") 
                + '&quoteDate=' + today
                + '&quoteName=' + component.get("v.quoteName"); // MS CPQ22-6072
            } else {
			component.set("v.isLoading", false);
            urlString = urlString + '/lightning/r/SBQQ__Quote__c/' + quoteId + '/view';
            }
            
            
            
            if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
                // Do something for Lightning Experience
                sforce.one.navigateToURL(urlString);
            } else {
                // Use classic Visualforce
                window.location.href = urlString;
            }
	    //CPQ22-4068 Ends
    },
    //SOX
    checkQuoteAccess : function(component, event, helper){
        window.setTimeout($A.getCallback(function(){component.set("v.visible",true);}),1000);//CPQ22-5028
        var act = component.get("c.checkUserAccess");
           console.log('calling method');
            act.setCallback(this, function(response){
               console.log('called method'); 
                var access=response.getReturnValue();
                console.log('access',access);
               var state = response.getState();
           if (state === "SUCCESS") {
               component.set("v.HasQuoteAccess",access);
               }
           else {
               console.log("Failed with state: " + state);
           }});
            $A.enqueueAction(act);
   }, 

   handleBusinesLogicSetting : function(component, event, helper){
    var action = component.get("c.getBusinessLogicSetting");
    action.setCallback(this, function(response){
        var state = response.getState();
        var userSetting = response.getReturnValue();
        if(state == "SUCCESS" ) {
            component.set("v.showSMSPage", userSetting);
        }else {
            console.log("Failed with state: ", state);
        }
    });
    $A.enqueueAction(action);
   },
   
   getQuoteName : function(component, event, helper){
    var action = component.get("c.getQuoteName");
        action.setParams({ qtId : component.get("v.quoteId")
                            });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var quoteName = response.getReturnValue();
            if (quoteName != null) {
                component.set("v.quoteName",quoteName);
            }

            this.navigateToQLE(component,event, helper);
        });
        $A.enqueueAction(action);
   }	 
})