({        
    //fetchcontract : function(component, event, helper) {
        
       
    //},
   
    handleRecordUpdated1: function(component, event, helper) {
    	var eventParams = event.getParams();
        component.set("v.showtable",true);
        component.set("v.showmsg",false);
        console.log('testing LOADED');
        //Sox
        helper.checkQuoteAccess(component, event, helper);
        helper.handleBusinesLogicSetting(component, event, helper);
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
          	var accessQuote= component.get("v.HasQuoteAccess");//SOX
        	var StageName = component.get("v.opportunityRecord.StageName");
	    	var BillingCountry = component.get("v.opportunityRecord.Billing_Country__c");
            var PartnerLookup = component.get("v.opportunityRecord.Partner_Lookup__c");
            var DistributorLookup = component.get("v.opportunityRecord.Distributor_Lookup__c");
            var opportunitySubType = component.get("v.opportunityRecord.Opportunity_Sub_Type__c");
            var oppType = component.get("v.opportunityRecord.Opportunity_Type__c");
            var oppPriceBookId = component.get("v.opportunityRecord.Pricebook2Id");
            var oppContactId = component.get("v.opportunityRecord.ContactId");
            var oppOwnerId = component.get("v.opportunityRecord.OwnerId");
            var oppQuotePriceBookId = component.get("v.opportunityRecord.SBQQ__QuotePricebookId__c");
            var oppSellPartner = component.get("v.opportunityRecord.Sell_to_Partner__c");
            var oppSellPartnerName = component.get("v.opportunityRecord.Sell_to_Partner__r.Name");
            var oppAccId = component.get("v.opportunityRecord.AccountId");
            if(accessQuote==false){
                component.set("v.isLoading", false);
                component.set("v.showmsg",true);
                component.set("v.message",'Access to create a quote has been disabled. Kindly reach out to Quoting team for assistance.');  
            }  
            else if(StageName =='6 PO With Channel' || StageName =='7 Closed Won' || StageName =='7 Closed Lost' || StageName == '7 Closed Admin'){
                component.set("v.isLoading", false);
            	component.set("v.showmsg",true);
                component.set("v.message",'You cannot create arroyo Quote when opportunity Stage is either 6 PO With Channel or closed');
            }
	  //Pankaj CPQ22-3230 start 
            else if((BillingCountry == 'Canada' || BillingCountry == 'United States' || BillingCountry == 'United Kingdom' || BillingCountry == 'Ireland' || BillingCountry == 'Netherlands' || BillingCountry == 'Belgium' || BillingCountry == 'Denmark' 
                    || BillingCountry == 'Finland' 
                    || BillingCountry == 'Norway' 
                    || BillingCountry == 'Sweden' 
                    || BillingCountry == 'France' 
                    || BillingCountry == 'Italy' 
                    || BillingCountry == 'Spain' 
                    || BillingCountry == 'Portugal'
                    || BillingCountry == 'United Arab Emirates'
                    || BillingCountry == 'Saudi Arabia'
                    || BillingCountry == 'South Africa'
                    || BillingCountry == 'Qatar') && (PartnerLookup==null || DistributorLookup==null) && opportunitySubType !='Renewal'){
                component.set("v.isLoading", false);
                   component.set("v.showmsg",true);
                   component.set("v.message",'A quote cannot be created with blank partner and distributor fields. To proceed, please select distributor and partner for this opportunity.');  
                }
            //Pankaj CPQ22-3230 end 
	    //Ankur CPQ22-3771 start 
            //disable quote creation for Renewal Opptys
            else if(opportunitySubType == 'Renewal'){
                component.set("v.isLoading", false);
                component.set("v.showmsg",true);
                component.set("v.message",'Quote cannot be created from Renewal Opportunity, please follow standard process.');  
            
            }
            //Ankur CPQ22-3771 end
             //CPQ22-4315 Madhura Start  
             else if(opportunitySubType =='GC Offer'){    
                component.set("v.isLoading", false);
                component.set("v.showcomp",true);    
                console.log('Inside GCOffer');    
           } //CPQ22-4315 MadhuraEnd  
            else{
                /**** FY25SR-2251 : Moved changes from Apex class to component as a part of optimisation and also added changes related to "Existing customer" ***/
                var isOppNetApp = false;
                var isOppScaleUtility = false;
                var netSellPartnerName = $A.get("$Label.c.NetApp_Account_Names");
                if(oppSellPartner != null && oppSellPartnerName != null){
            			if(netSellPartnerName.includes(oppSellPartnerName)){
                			isOppNetApp = true;
            			}
        		}
                if(opportunitySubType != null && (opportunitySubType == 'GC Offer' || opportunitySubType == 'GC Renewal' || opportunitySubType == 'GC OnDemand')){
            		isOppScaleUtility = true;
       			}
                if(!isOppNetApp && !isOppScaleUtility){
                    
                    var showSMSPage = component.get("v.showSMSPage");
                    console.log('opportunity block passed', showSMSPage);
            		if(!showSMSPage){
                        component.set("v.isLoading", true);
                        if(oppType == 'Existing Customer'){
                            var action = component.get("c.fetchQuoteForSMSUI");
                            action.setParams({oppId : component.get("v.recordId"),
                                             oppSubType : opportunitySubType,
                                             oppPriceBookId : oppPriceBookId,
                                             oppContactId : oppContactId,
                                             oppOwnerId : oppOwnerId,
                                             oppAccId : oppAccId});
                            action.setCallback(this, function(response){
                                var state = response.getState();
                                var quoteId = response.getReturnValue();
                                console.log('quoteId sms is ',quoteId);
                                if (quoteId != null) { 
                                    if (quoteId.toString().startsWith('a6')) {
                                        component.set("v.quoteId",quoteId);
                                        //helper.navigateToQLE(component,event, helper);
                                        helper.getQuoteName(component,event, helper); //MS 6072
                                        component.set("v.isLoading", false);
                                        $A.get("e.force:closeQuickAction").fire();
                                    } else {
                                        component.set("v.isLoading", false);
                                        component.set("v.showtable",false);
                                        component.set("v.showmsg",true);
                                        var customMsg = 'An unexpected Error has occurred. Please contact System Administrator. Error: '
                                        component.set("v.message",customMsg+JSON.stringify(quoteId));
                                    }
                                }
                            });
                            $A.enqueueAction(action);
                        }else{
                            component.set("v.isLoading", false);
                			component.set("v.showcomp",true);
                        }	
                    }else{
                        var action = component.get("c.fetchContracts");
                            action.setParams({accId : component.get("v.opportunityRecord.AccountId"), 
                                          	  oppId : component.get("v.recordId")});
                            action.setCallback(this, function(response){
                            let lst = [];
                            let contrctlst = response.getReturnValue();
                            
                            if(contrctlst != null){
                                console.log('contrctlst>>palak'+contrctlst);
                                for(var i=0;i<contrctlst.length;i++){
                                    lst.push(contrctlst[i].Id);
                                }
                            }
                            component.set("v.contrList", response.getReturnValue());
                         
                            helper.handleClick1(component, event, helper);                
                            });
                        	$A.enqueueAction(action);
                    }
                }else{
                    console.log('Opportunity check failed');
                    component.set("v.isLoading", false);
                    component.set("v.showcomp",true); 
                }
            }
        } 
     },
     handleClick1 : function(component, event, helper) {
         component.set("v.isLoading", true);
        console.log('recid'+component.get("v.recordId"));
        var action = component.get("c.renewalContracts");
         action.setParams({ str : JSON.stringify(component.get("v.contrList")) ,
                          oppId : component.get("v.recordId") });
         console.log('here is the log');
       
         action.setCallback(this, function(response){
              var state = response.getState();
             console.log('State'+state);
         if(state == "SUCCESS")
         {
            console.log('was a success');
            console.log("From server: " + response.getReturnValue());
            var quoteId = response.getReturnValue();
            if (quoteId.toString().startsWith('a6')) {
                component.set("v.isLoading", false);
                component.set("v.quoteId",quoteId);
            } else {
                component.set("v.isLoading", false);
                component.set("v.showtable",false);
                component.set("v.showmsg",true);
                var customMsg = 'An unexpected Error has occurred. Please contact System Administrator. Error: '
                component.set("v.message",customMsg+JSON.stringify(quoteId));
            }
             //var action = component.get('c.navigateToQLE');
              //$A.enqueueAction(action);
             //helper.navigateToQLE(component,);
              
         }else{
             var errors = response.getError();
             if(errors){
                 component.set("v.isLoading", false);
             console.log('it  somehow failed! state is: ' + state);
            console.log('here is the error > '+JSON.stringify(errors));
             //console.log('here is the error > '+JSON.stringify(errors[0].message));
             component.set("v.showtable",false);
              component.set("v.showmsg",true);
                 
              component.set("v.message",JSON.stringify(errors[0].message));
                 //alert(errors[0].message);
            }
             
            }
           
        });
          $A.enqueueAction(action);
     
     },
   
       navigateToQLE : function(component, event, helper) {
           console.log('inside navigate'+component.get("v.quoteId"));
           var quoteId = component.get("v.quoteId");
           console.log('inside navigate');
           //CPQ22-4068 Starts
           /*var urlEvent = $A.get("e.force:navigateToURL");
           urlEvent.setParams({
               "url": 'https://rubrikinc.lightning.force.com/lightning/r/SBQQ__Quote__c/'+quoteId+'/view'
           });
           urlEvent.fire();*/
           var urlString = window.location.origin;
           urlString = urlString + '/lightning/r/SBQQ__Quote__c/' + quoteId + '/view';
           if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
               // Do something for Lightning Experience
               sforce.one.navigateToURL(urlString);
           } else {
               // Use classic Visualforce
               window.location.href = urlString;
           }
           //CPQ22-4068 Ends
   }
})