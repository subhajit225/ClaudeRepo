({   
    doInit : function(component, event, helper) {
       /* $('iframe.vfFrame').on('load', function(){
            alert('hi');
            
        });*/
        
        component.find("PartnerOnboardRecordCreator").getNewRecord(
            "Partner_Onboarding_Request__c", // sObject type (entityAPIName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newpartnerOnboard");
                var error = component.get("v.newPartnerOnboardError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }
                else {
                    console.log("Record template initialized: " + rec.sobjectType);
                }
            })
        );
        helper.getPicklist(component, event,'Vendors_your_Org_works_with_today__c');
        helper.getPicklist(component, event,'Country__c');
        helper.getPicklist(component, event,'PartnerType__c');
        helper.getPicklist(component, event,'Referral_Source__c');
        helper.getPicklist(component, event,'Territory__c');
        //helper.getPicklist(component, event,'Partner_Selling_Countries__c');
        helper.getPicklist(component, event,'Segment__c');
        //helper.fetchPicklistValues(component,'Territory__c', 'Distributor__c');
        helper.fetchPicklistValues(component,'Country__c', 'StateProvince__c');
        //helper.fetchPicklistValues(component,'Country__c', 'Territory__c');
        var arr = [
            { value: "", label: "--None--" }
        ];
        component.set("v.optionsStateProvince__c",arr);
        //component.set("v.optionsTerritory__c",arr);
        //component.set("v.optionsDistributor__c",arr);
        
        var currenturl = window.location.href;
        if(currenturl.search('/s') >= 0){
            var temp = currenturl.split('/s');
            component.set("v.vfHost",temp[0]);
        }
        
        var firstInput = component.find("one");
        var secondInput = component.find("two");
        var thirdInput = component.find("three");
        var fourInput = component.find("four");
        var fiveInput = component.find("five");
        $A.util.addClass(firstInput,"none");
        $A.util.addClass(secondInput,"none");
        $A.util.addClass(thirdInput,"none");
        $A.util.addClass(fourInput,"none");
        $A.util.addClass(fiveInput,"none");
        
    },
    onCountryControllerFieldChange : function(component, event, helper) {
        // call the helper function
        var controllerValueKey = event.getSource().get("v.value");
        if(controllerValueKey != '' && controllerValueKey != '--- None ---'){
            var DependentFieldMapStateProvince__c = component.get("v.DependentFieldMapStateProvince__c");
            var stateListOfDependentFields = DependentFieldMapStateProvince__c[controllerValueKey];
            //var DependentFieldMapTerritory__c = component.get("v.DependentFieldMapTerritory__c");
            //var territoryListOfDependentFields = DependentFieldMapTerritory__c[controllerValueKey];  
            console.log(stateListOfDependentFields);
            if(stateListOfDependentFields.length > 0){
                component.set("v.disableStateProvince__c" , false);  
                helper.fetchDepValues(component,'StateProvince__c', stateListOfDependentFields);    
            }else{
               //component.find('StateProvince__c').set("v.value",""); 
               helper.resetPicklistValues(component,event,'StateProvince__c');
               
            }
           /* if(territoryListOfDependentFields.length > 0){
                component.set("v.disableTerritory__c" , false);  
                helper.fetchDepValues(component,'Territory__c', territoryListOfDependentFields);    
            }else{
                component.find('Territory__c').set("v.value","");
                helper.resetPicklistValues(component,event,'Territory__c');
            }*/
            
        }else {
            //component.find('StateProvince__c').set("v.value","");
            //component.find('Territory__c').set("v.value","");
            //component.find('Distributor__c').set("v.value","");
            helper.resetPicklistValues(component,event,'StateProvince__c');
            //helper.resetPicklistValues(component,event,'Territory__c');
            //helper.resetPicklistValues(component,event,'Distributor__c');

        } 
        helper.partnerSellingChange(component, event, helper);
    },
    onTerritoryControllerFieldChange : function(component, event, helper) {
        // call the helper function
        var controllerValueKey = component.get("v.selectedLookUpRecords");
        
        if(!$A.util.isEmpty(controllerValueKey)){
          /*  var DependentFieldMapDistributor__c = component.get("v.DependentFieldMapDistributor__c");
            var distributorListOfDependentFields = DependentFieldMapDistributor__c[controllerValueKey];
            
            if(distributorListOfDependentFields.length > 0){
                component.set("v.disableDistributor__c" , false);  
                helper.fetchDepValues(component, 'Distributor__c',distributorListOfDependentFields);    
            }else{
               //component.find('Distributor__c').set("v.value",""); 
               helper.resetPicklistValues(component,event,'Distributor__c');
            }*/
            helper.fetchDistributorValues(component,event,controllerValueKey,helper);
            var options = '';
            for(var i=0;i<controllerValueKey.length;i++){
                options = options+controllerValueKey[i]+';';
            }
            component.set("v.selectedTerritory",options);
        }else {            
            //component.find('Distributor__c').set("v.value","");
            helper.resetPicklistValues(component,event,'Distributor__c');
        }      
    },
    
    onPartnerTypeChange : function(component, event, helper) {
        var controllerValueKey = event.getSource().get("v.value");
        if(controllerValueKey != 'Alliance Partner' && controllerValueKey != '' ){
            component.set("v.showBusinessSection",true);
        }else{
            component.set("v.showBusinessSection",false);
        }
        component.set("v.masterCheckValue",false);
        component.set("v.SecondaryCheckValue",false);
        component.set("v.TertiaryCheckValue",false);
    },
    handleCheck : function(component, event, helper) {
        console.log(component.get("v.checkboxValue"));       
    },
    handleSaveForm : function(component, event, helper) {
      
        var checkArr = component.get("v.checkboxValue");
        var checkstr;
        for(var i=0;i<checkArr.length;i++){
            if(checkstr != null && checkstr != ''){
                checkstr = checkstr+';'+checkArr[i];
            }else{
                checkstr = checkArr[i];
            }
        }
        var rec = component.get("v.simplePartnerOnboard");
        rec.Vendors_your_Org_works_with_today__c = checkstr;
        component.set("v.simplePartnerOnboard",rec);
               
        //helper.concatenateSelectedCountries(component,event);
        var isFormValid = helper.validateForm(component);
        var isInputFieldsValid = helper.validateFormInputFields(component);        
        //alert(isFormValid && isInputFieldsValid);
        
        var termschecked = true;
        var mastc = component.find("masterCheckValue_help");
        var sectc = component.find("SecondaryCheckValue_help");
        var tertc = component.find("TertiaryCheckValue_help");
        console.log(component.get("v.masterCheckValue"));
                if(component.get("v.masterCheckValue") == false && component.get("v.simplePartnerOnboard").PartnerType__c != 'Alliance Partner' ){
            $A.util.removeClass(mastc,"none"); 
            termschecked = false;
        }else{
            $A.util.addClass(mastc,"none"); 
        }
        if(component.get("v.SecondaryCheckValue") == true && component.get("v.simplePartnerOnboard").PartnerType__c != 'Alliance Partner' && component.get("v.simplePartnerOnboard").PartnerType__c != 'Distributor' &&  component.get("v.simplePartnerOnboard").PartnerType__c != ''){
            $A.util.addClass(sectc,"none");
            
        }else if(component.get("v.SecondaryCheckValue") == false && component.get("v.simplePartnerOnboard").PartnerType__c != 'Alliance Partner'  && component.get("v.simplePartnerOnboard").PartnerType__c != 'Distributor' && component.get("v.simplePartnerOnboard").PartnerType__c != ''){
            $A.util.removeClass(sectc,"none");
            termschecked = false;
        }
        if(component.get("v.TertiaryCheckValue") == false && component.get("v.simplePartnerOnboard").PartnerType__c == 'MSP-Reseller'){
            $A.util.removeClass(tertc,"none"); 
            termschecked = false;
        }else if(component.get("v.TertiaryCheckValue") == true && component.get("v.simplePartnerOnboard").PartnerType__c == 'MSP-Reseller'){
            $A.util.addClass(tertc,"none"); 
           
        }
        console.log("isFormValid-->"+isFormValid +  isInputFieldsValid + termschecked);
        if(isFormValid && isInputFieldsValid && termschecked){
                helper.savePOB(component, event,helper); 
        }
    },
    openMasterModel : function(component, event, helper) {
         var height =  document.documentElement.scrollHeight + document.documentElement.clientHeight;
       //  component.set("v.iframeheight", height);
        if(!$A.util.isEmpty(component.get("v.simplePartnerOnboard.PartnerType__c")) &&  !$A.util.isEmpty(component.get("v.simplePartnerOnboard.Email__c"))){
             component.set("v.isOpenMaster", true);
              var vfOrigin =  component.get("v.vfHost");
             window.addEventListener("message", function(event) {
                console.log(event.data.name);
               
                // Only handle messages we are interested in
                if (event.data.name === "Master") {
                    // Handle the message
                    if(event.data.payload == 'agreed'){
                        component.set("v.masterCheckValue",true);
                    }else{
                        component.set("v.masterCheckValue",false);
                    }
                    component.set("v.isOpenMaster", false);
                }
            }, false);
        }else{
            alert('Please enter values in Email and Partner Type');
        }
        //jQuery("document").ready(function(){
          //alert('hi');
       /* var iFrameDOM = $("iframe#vfFrame").contents();
        console.log('loaded'+JSON.stringify(iFrameDOM.find(".ps-contract-scroll")));
        iFrameDOM.find(".ps-contract-scroll").css("max-height", "unset !important");
        iFrameDOM.find(".ps-contract-scroll").css("min-height", "unset !important");
        iFrameDOM.find(".ps-contract-scroll").css("overflow", "hidden !important");*/
        
    
          //  $(this).find('iframe.vfFrame').removeClass("ps-contract-scroll");
       //   console.log('hii');
     // });
    },
    closeMasterModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpenMaster" attribute to "Fasle"  
      component.set("v.isOpenMaster", false);
   },
   openSecondaryModel : function(component, event, helper) {
         var height =  document.documentElement.scrollHeight + document.documentElement.clientHeight;
         //alert(height);
         component.set("v.iframeheight", height);
       if(!$A.util.isEmpty(component.get("v.simplePartnerOnboard.PartnerType__c")) &&  !$A.util.isEmpty(component.get("v.simplePartnerOnboard.Email__c"))){
         component.set("v.isOpenSecondary", true);
          var vfOrigin = component.get("v.vfHost");
         window.addEventListener("message", function(event) {
            console.log(event.data.name);
            // Only handle messages we are interested in
            if (event.data.name === "Secondary") { 
                // Handle the message
                if(event.data.payload == 'agreed'){
                    component.set("v.SecondaryCheckValue",true);
                }else{
                    component.set("v.SecondaryCheckValue",false);
                }
                component.set("v.isOpenSecondary", false);
            }
            
        }, false);
       }else{
           alert('Please enter values in Email and Partner Type');
       }
    },
    closeSecondaryModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpenSecondary" attribute to "Fasle"  
        component.set("v.isOpenSecondary", false);
    },
    openTertiaryModel : function(component, event, helper) {
         var height =  document.documentElement.scrollHeight + document.documentElement.clientHeight;
         //alert(height);
         component.set("v.iframeheight", height);
       if(!$A.util.isEmpty(component.get("v.simplePartnerOnboard.PartnerType__c")) &&  !$A.util.isEmpty(component.get("v.simplePartnerOnboard.Email__c"))){
         component.set("v.isOpenTertiary", true);
          var vfOrigin = component.get("v.vfHost");
         window.addEventListener("message", function(event) {
            console.log(event.data.name);
            console.log(event.data.filetext);
            component.set("v.filecontent",event.data.filetext);  
            // Only handle messages we are interested in
            if (event.data.name === "Tertiary") {
                // Handle the message
                if(event.data.payload == 'agreed'){
                    component.set("v.TertiaryCheckValue",true);
                }else{
                    component.set("v.TertiaryCheckValue",false);
                }
                component.set("v.isOpenTertiary", false);
            }
            
        }, false);
       }else{
           alert('Please enter values in Email and Partner Type');
       }
    },
   
    closeTertiaryModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpenTertiary" attribute to "Fasle"  
        component.set("v.isOpenTertiary", false);
    },
    handleQueChange: function (component, event, helper) {
        var changeValue = event.getSource().get("v.value");
        console.log('event');
        console.log(event.getSource().get("v.name"));
        var quename = event.getSource().get("v.name");
        var temp = quename.split('_');
        var divname = 'div_'+temp[1];
        var divcmp = component.find(divname);
        var reqflag = 'v.faq_'+temp[1];
        if(changeValue == 'Yes'){
            if($A.util.isArray(divcmp)){
                $A.util.removeClass(divcmp[0],"none");
                $A.util.addClass(divcmp[1],"none");
            }else{
                $A.util.removeClass(divcmp,"none");
            }
            //$A.util.removeClass(divcmp,"none");
            component.set(reqflag,true);
        }
        if(changeValue == 'No'){
            if($A.util.isArray(divcmp)){
                $A.util.addClass(divcmp[0],"none");
                $A.util.removeClass(divcmp[1],"none");
            }else{
                $A.util.addClass(divcmp,"none");
            } 
           //$A.util.addClass(divcmp,"none");
            component.set(reqflag,false);
        }
    },
    emailonchange : function (component, event, helper) {
        component.set("v.masterCheckValue",false);
        component.set("v.SecondaryCheckValue",false);
        component.set("v.TertiaryCheckValue",false);
    },
    onSegmentControllerFieldChange : function(component, event, helper) {
        // call the helper function
        var options = '';
        var controllerValueKey = component.get("v.selectedLookUpRecords");
        component.set("v.simplePartnerOnboard.Distributor__c","");
        if(!$A.util.isEmpty(controllerValueKey)){
            for(var i=0;i<controllerValueKey.length;i++){
                options = options+controllerValueKey[i]+';';
            }
            component.set("v.selectedSegment",options);
        }else{
            component.set("v.selectedSegment","");
        }  
        var distArr = component.get("v.optionsPSDistributor__c");
        var distmap = new Object();
        var action = component.get("c.getUSDistributorNames");
        distArr.forEach(function(dist){
            distmap[dist['value']] = dist['label'];
        });
        action.setParams({
            'segment': component.get("v.selectedSegment")
        });
        action.setCallback(this, function(response) {
            distArr = [];
            //Added for SF-13400-Start
            distArr = [
                { value: "", label: "--None--" }
            ];
            //Added for SF-13400-End
            var state = response.getState();
            if (state === "SUCCESS") {
                if(!$A.util.isEmpty(response.getReturnValue())){
                    response.getReturnValue().forEach(function(accIdName){
                        var temp = accIdName.split(';');
                        var temparr = [];
                        temparr['label'] = temp[0];
                        temparr['value'] = temp[1];
                        //Added for SF-13400-Start
                        distArr.push(temparr);
                        //distmap[temp[1]] = temp[0];
                        //Added for SF-13400-End
                    });
                    //Commented for SF-13400
                    /*Object.keys(distmap).forEach(function(key){
                        var temparr = [];
                        temparr['label'] = distmap[key];
                        temparr['value'] = key;
                        distArr.push(temparr);
                    });*/
                    component.set("v.optionsDistributor__c",distArr);
                    component.set("v.disableDistributor__c" , false);
                }
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        if(!$A.util.isEmpty(component.get("v.selectedSegment"))){
            $A.enqueueAction(action);
        }else{
            component.set("v.optionsDistributor__c",component.get("v.optionsPSDistributor__c"));
        }
    },
   
})