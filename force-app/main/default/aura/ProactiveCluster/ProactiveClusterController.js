({
    doinit : function(component, event, helper) {
        var url_string = window.location.href;
        var spinner = component.find("clusSpinner");
        var url = new URL(url_string);
        var country ='';
        helper.PhoneCode(component, event, helper);
        var recordId = url.searchParams.get("id");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var label = $A.get("$Label.c.ClusterInfo_Main");
        var labelRMA = $A.get("$Label.c.RMA_Address_label");
        var linkt = '<a href="myproducts?selectedtab=clusters">My Products page</a>';
        label = label.replace('[link]',linkt);
        labelRMA = labelRMA.replace('[link]',linkt);
        component.set("v.MainLabel",label);
        component.set("v.RMAMainLabel",labelRMA);
        if(component.get("v.recordId") == null || component.get("v.recordId") == '' ){
            component.set("v.recordId",recordId);
        }
        console.log('recordId',component.get("v.recordId"));
        var action2 = component.get("c.fetchCountryToStatesMap");	
        action2.setCallback(this,function(res2){	
            var response2 =res2.getReturnValue();	
            var keys = Object.keys(response2);	
            component.set("v.countryStateMap",response2);	
            component.set("v.countryList",keys);
            var action = component.get("c.getProactiveInfo");
            action.setParams({'recordId':component.get("v.recordId")});
            action.setCallback(this,function(res){
                var response =res.getReturnValue();
                console.log(response);
                component.set("v.Caseinfo",res.getReturnValue());
                $A.util.addClass(spinner,'slds-hide');
                if(!response.isParent){
                    
                    var clusterLabel = $A.get("$Label.c.ClusterInfo_Child");
                    if(!response.account.tag__c){response.account.tag__c= 'Not Available';}
                    var tag = '<div style="display:inline-flex;"><b>Cluster name: </b> <div style="font-family:gotham-light;">&nbsp;'+response.account.tag__c+'</div>&nbsp;';
                    
                    var uuid = '<b>&nbsp;UUID: </b> <div style="font-family:gotham-light;">&nbsp;'+response.account.uuid__c+'</div></div>';
                    clusterLabel = clusterLabel.replace('[tag]',tag).replace('[uuid]',uuid);
                    component.set("v.clusterLabel",clusterLabel);
                }
                if(!response.isParent && !!response.parent.Working_Day__c){
                    component.set("v.parentValues",response.parent.Working_Day__c.split(";"));
                }
                
                if(!!response.account.Working_Day__c){
                    component.set("v.values",response.account.Working_Day__c.split(";"));
                }
                if(!!response.account.Shipping_Address_Contact_for_RMA_handlin__c){
                    var addresses = response.account.Shipping_Address_Contact_for_RMA_handlin__c.split('\n');
                    if(!!addresses[5]){
                        component.set("v.stateInput",false);
                    }
                    else{
                        component.set("v.stateInput",true);
                    }
                    var conMobile = '';
                    if(addresses[2].includes('-')){
                        var spitPhone = addresses[2].split(/-(.+)/);
                        conMobile = spitPhone[0] +' '+spitPhone[1];
                    }else{
                        conMobile = addresses[2];
                    }
                    var obj = {rName: addresses[0], conEmail: addresses[1], conMob: conMobile, street: addresses[3], city: addresses[4], province: addresses[5], postalCode: addresses[6], country: addresses[7]};
                    component.set('v.shippingAddress',obj);
                    component.set("v.Street",addresses[3]);
                    component.set("v.City",addresses[4]);
                    component.set("v.Country",addresses[7]);
                    component.set("v.Province",addresses[5]);
                    component.set("v.PostalCode",addresses[6]);
                    component.set("v.receiverName",addresses[0]);
                    component.set("v.ContactEmail",addresses[1]);
                    if(addresses[2].includes('-')){
                        
                        var spitPhone = addresses[2].split(/-(.+)/);
                        component.set("v.ContactMobile",spitPhone[1]);
                        component.set("v.CountryCode",spitPhone[0]);
                    }else{
                        component.set("v.ContactMobile",addresses[2]);
                    }
                    country = addresses[7];
                }
                if(!!component.get("v.Caseinfo.parent.Shipping_Address_Contact_for_RMA_handlin__c")){
                    var parentLeveladdresses = component.get("v.Caseinfo.parent.Shipping_Address_Contact_for_RMA_handlin__c").split('\n');
                    var conMobile = '';
                    if(parentLeveladdresses[2].includes('-')){
                        var spitPhone = parentLeveladdresses[2].split(/-(.+)/);
                        conMobile = spitPhone[0] +' '+spitPhone[1];
                    }else{
                        conMobile = parentLeveladdresses[2];
                    }
                    var obj1 = {rName: parentLeveladdresses[0], conEmail: parentLeveladdresses[1], conMob: conMobile, street: parentLeveladdresses[3], city: parentLeveladdresses[4], province: parentLeveladdresses[5], postalCode: parentLeveladdresses[6], country: parentLeveladdresses[7]};
                    component.set('v.parentShippingAddress',obj1);
                }
                if(country != null){	
                    var countryStateMap = component.get("v.countryStateMap");	
                    var selectedCountryVal = country;	
                    var values = countryStateMap[selectedCountryVal];
                    if(values != 'None'){	
                        component.set('v.stateList',values);	
                    }	
                }	
                var specldelvryInst = response.account.Special_Delivery_Instruction__c;	
                if(specldelvryInst == null){	
                    component.set("v.spclDelInst",'');	
                }	
                if(!!specldelvryInst){	
                    component.set("v.spclDelInst",specldelvryInst);	
                }
            });
            $A.enqueueAction(action);
        });
        $A.enqueueAction(action2);
    },
    shownonBOHModal : function(component, event, helper) {
        component.set("v.showmodal",true);
        component.set("v.isBusinessHours",false);
    },
    showBOHModal : function(component, event, helper) {
        component.set("v.showmodal",true);
        component.set("v.isBusinessHours",true);
        
    },
    showBHModal : function(component, event, helper) {
        component.set("v.showBHmodal",true);
        
    },
    showAddressModal : function(component, event, helper) {
        component.set("v.showAddressModal",true);
        
    },
    cancel : function(component, event, helper) {
        component.set("v.showmodal",false);
        component.set("v.showBHmodal",false);
        component.set("v.showAddressModal",false);
        $A.get('e.force:refreshView').fire();
        
    },
    UpdateContact : function(component, event, helper) {
        var recordId  = event.getSource().get("v.value");
        var isBusinessHours = component.get("v.isBusinessHours");
        var action = component.get("c.updateProactiveInfo");
        action.setParams({'recordId':recordId,'isBusinessHours':isBusinessHours,'record':component.get("v.Caseinfo") });
        action.setCallback(this,function(res){
            $A.get('e.force:refreshView').fire();
            
        });
        $A.enqueueAction(action);
    },
    updateBuisnessHour: function(component, event, helper) {
        var hasError = false;
        var to = component.get("v.toTime");
        helper.validateField(component, event, helper,'to',function(isValid){if(isValid){hasError = true;}},to);
        var from = component.get("v.fromTime");
        helper.validateField(component, event, helper,'from',function(isValid){if(isValid){hasError = true;}},from);
        var wdays = component.get("v.values");
        helper.validateField(component, event, helper,'wdays',function(isValid){if(isValid){hasError = true;}},wdays);
        
        
        
        if(hasError == false){
            var timeSlot = from.substring(0, 5)+'-'+to.substring(0, 5);
            var action = component.get("c.updateBusinessHourInfo");
            console.log(component.get("v.Caseinfo"));
            action.setParams({
                'record':component.get("v.Caseinfo"),
                'timeString':timeSlot ,
                'wdays':component.get("v.values")
            });
            action.setCallback(this,function(res){
                var response =res.getReturnValue();
                component.set("v.Caseinfo",res.getReturnValue());
                $A.get('e.force:refreshView').fire();
            });
            $A.enqueueAction(action);
        }
    },
    updateAddress: function(component, event, helper){
        var hasError = false;
        var hasStateError = false;
        var Street;
        var tempStreet = component.get("v.Street");
        if(!!tempStreet){
            Street= tempStreet.replace(/\n/g,', ');
        }
        //helper.validateField(component, event, helper,'address',function(isValid){if(isValid){hasError = true;}},Street);
        var City = component.get("v.City");
        //helper.validateField(component, event, helper,'address',function(isValid){if(isValid){hasError = true;}},City);
        var deliveryInst = component.find('speclDeliveryInst').get("v.value");
        var Country = component.get("v.Country");
        if(!Country){
            component.set("v.CountryError",true);
            hasError = true;
        }else{
            component.set("v.CountryError",false);
        }
        //helper.validateField(component, event, helper,'address',function(isValid){if(isValid){hasError = true;}},Country);
        var Province = component.get("v.Province");
        // helper.validateField(component, event, helper,'address',function(isValid){if(isValid){hasError = true;}},Province);
        if(!!Country && !Province && component.get("v.stateInput") == false){	
            component.set("v.StateError",true);	
            hasStateError = true;	
        }	
        else{	
            component.set("v.StateError",false);
            hasStateError = false;
        }
        var CountryCode = component.get("v.CountryCode");
        helper.validateField(component, event, helper,'CountryCode',function(isValid){if(isValid){hasError = true;}},CountryCode);
        var ContactMobileID = component.find("ContactMobile");
        if(CountryCode != '+47' && !ContactMobileID.checkValidity() ){hasError = true;ContactMobileID.reportValidity();}
        // helper.validateField(component, event, helper,'address',function(isValid){if(isValid){hasError = true;}},Province);
        var PostalCode = component.get("v.PostalCode");
        helper.validateField(component, event, helper,'address',function(isValid){if(isValid){hasError = true;}},PostalCode);
        var ContactEmail = component.get("v.ContactEmail");
        helper.validateField(component, event, helper,'ContactEmail',function(isValid){if(isValid){hasError = true;}},ContactEmail);
        var ContactMobile = component.get("v.ContactMobile");
        //helper.validateField(component, event, helper,'ContactMobile',function(isValid){if(isValid){hasError = true;}},ContactMobile);
        var receiverName = component.get("v.receiverName");
        helper.validateField(component, event, helper,'receiverName',function(isValid){if(isValid){hasError = true;}},receiverName);
        
        if(hasError == false && hasStateError == false && component.get("v.StateError") == false){
            var contactInfo = receiverName+'\n'+ContactEmail+'\n'+CountryCode+'-'+ContactMobile+'\n'+Street+'\n'+City+'\n'+Province+'\n'+PostalCode+'\n'+Country;
            var action = component.get("c.updateRecordAddress");
            action.setParams({
                'record':component.get("v.Caseinfo"),
                'address':contactInfo,
                'spclDelvryInstr':deliveryInst
            });
            action.setCallback(this,function(res){
                var response =res.getReturnValue();
                component.set("v.Caseinfo",res.getReturnValue());
                component.set("v.showmodal",false);
                component.set("v.showBHmodal",false);
                component.set("v.showAddressModal",false);
                if(!!contactInfo){
                    var addresses = contactInfo;
                    var obj = {rName: addresses[0], conEmail: addresses[1], conMob: addresses[2], street: addresses[3], city: addresses[4], province: addresses[5], postalCode: addresses[6], country: addresses[7]};
                    if(component.get("v.Caseinfo").isParent){
                        component.set('v.parentShippingAddress',obj);
                    }else{
                        component.set('v.shippingAddress',obj);
                    }
                    
                }
                $A.get('e.force:refreshView').fire();
                location.reload();
            });
            $A.enqueueAction(action);
        }
        
    },
    sendBack: function(component, event, helper) {
        var isParent = component.get("v.Caseinfo").isParent ? 'settings/' : 'myproducts?selectedtab=clusters';
        var url = component.get("v.Caseinfo").isParent ?'/s/'+isParent+component.get("v.recordId") : '/s/'+isParent;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    fetchStates: function(component, event, helper) {	
        component.set('v.Province',null);	
        var countryStateMap = component.get("v.countryStateMap");	
        var selectedCountryVal = component.find("selectedCountry").get("v.value");	
        var values = countryStateMap[selectedCountryVal];	
        if(values == null || values == ''){
            component.set("v.stateInput",true);
            component.set("v.Province",'');
        }
        else{
            component.set("v.stateInput",false);
        }
        component.set('v.stateList',values);	
    },	
    /*showSpinner: function(component, event, helper) {	
        component.set("v.Spinner", true); 	
    },	
    
    hideSpinner : function(component,event,helper){
        component.set("v.Spinner", false);	
    }*/
    updateCountryCode: function(component, event, helper) {	
        var CountryCode = component.find("CountryCode").get("v.value");
        component.set("v.CountryCode",CountryCode);
    },
    updatePhone: function(component, event, helper) {	
        if(event.keyCode >= 48 && event.keyCode <= 57){
            var ContactMobile = component.find("ContactMobile").get("v.value");
            if(ContactMobile.length ==3){
                ContactMobile = component.find("ContactMobile").set("v.value","("+ContactMobile+") ");
            }
            if(ContactMobile.length ==9){
                ContactMobile = component.find("ContactMobile").set("v.value",ContactMobile+"-");
            }
        }else{
            event.preventDefault();
        }
    },
})