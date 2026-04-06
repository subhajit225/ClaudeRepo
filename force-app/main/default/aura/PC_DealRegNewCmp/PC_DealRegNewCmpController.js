({
    doInit: function(component, event, helper) {
        helper.doInit(component, event, helper);
    },
    //PRIT24-776
    setService: function(component, event, helper){
        var buttonLabel = event.srcElement.innerText;
        if(buttonLabel.toUpperCase().includes("MANAGED SERVICE")){
            component.set("v.dealRegFields.Dedicated_Managed_Service__c",true);
        }
        $A.util.addClass(component.find("managedServBox"), "slds-hide");
    },
    /*getPartnerAccount: function(component, event, helper) {
        helper.getPartnerAccount(component, event, helper);
    },*/
    checkValidateFields : function(component, event, helper) {
        if(component.get("v.dealRegFields.End_User_attend_a_Marketing_Event__c") != 'Yes'){
           var allValid = component.find('dealRegField').reduce(function (validFields, inputCmp) {
               if(inputCmp.get("v.label") == 'Date of Event'){
                	inputCmp.showHelpMessageIfInvalid();
               }
                return validFields && inputCmp.get('v.validity').valid;
            }, true);
        }
        if(component.get("v.dealRegFields.Save_the_Data_Event__c") != 'Yes'){
            var allValid = component.find('dealRegField').reduce(function (validFields, inputCmp) {
                if(inputCmp.get("v.label") == 'Date of Event'){
                     inputCmp.showHelpMessageIfInvalid();
                }
                 return validFields && inputCmp.get('v.validity').valid;
             }, true);
         }

    },
    handleSaveDealReg: function(component, event, helper) {
        var isFormValid = helper.validateForm(component);
        var isInputFieldsValid = helper.validateFormInputFields(component);
        //var validateEmail = helper.validateEmail(component,event, helper);

        if(isFormValid && isInputFieldsValid){
            helper.saveDealReg(component, event,helper);
        }
    },
    handleSaveRecord: function(component, event, helper) {
        if($A.util.isEmpty(component.get("v.dealRegFields.Customer_Category__c"))){
            helper.showErrorField(component, event, "Customer_Category__c");
        }else if(helper.validateForm(component)) {
            helper.saveForm(component, event);
        }
    },
    handleSelectedAccount : function(component, event, helper){
        let accountRec = event.getParams();
        if(accountRec){
            component.set("v.dealRegFields.Company_Name__c",accountRec.Id);
            component.set("v.dealRegFields.Company__c",accountRec.Name);
        }
    },
    handleDistiSelect : function(component, event, helper){
        let distiMap = component.get("v.optionsDistributor__c");
        let distiRecId = event.getSource().get("v.value");
        var distiName;
        if(distiMap){
            distiMap.forEach(function(ele){
                if(ele.value == distiRecId){
                    distiName = ele.label;
                }
            });
        }
        if(distiRecId && distiName){
            component.set("v.dealRegFields.Distributor__c", distiRecId);
            component.set("v.dealRegFields.Distributor_Company_Name__c", distiName);
        }
    },
    handleSelectedPartnerAccount : function(component, event, helper){
        let accountRec = event.getParams();
        if(accountRec){
            component.set("v.dealRegFields.Partner_Lookup__c",accountRec.Id);
            component.set("v.dealRegFields.Partner__c",accountRec.Name);
        }
    },
    handleClearPartnerAccount : function(component, event, helper){
        let accountRec = event.getParams();
        console.log('handleClearPartnerAccount'+JSON.stringify(accountRec));
        if(accountRec){
            component.set("v.dealRegFields.Partner_Lookup__c",'');
            component.set("v.dealRegFields.Partner__c",'');
        }
    },
    //PRIT24-445-Start
    handleSelectedPartnerRepContact : function(component, event, helper){
        let contactRec = event.getParams();
        if(contactRec){
            for(var i = 0 ; i < contactRec.conList.length; i ++){
                if(contactRec.conList[i].Id == contactRec.Id){
                    component.set('v.dealRegFields.Partner_Rep__c', contactRec.conList[i].Name);
                    component.set('v.dealRegFields.Partner_Rep_Email_Address__c', contactRec.conList[i].Email);
                    component.set('v.dealRegFields.Partner_Rep_Title__c',contactRec.conList[i].Title);
                    component.set('v.dealRegFields.Partner_Rep_Phone_Number__c',contactRec.conList[i].Phone);
                }
            }
        }
    },
    handleSelectedPartnerRepContactSearch : function(component, event, helper){
        let contactRec = event.getParams();
        if(contactRec){
            $A.util.removeClass(component.find('Partner_Rep__c'), "slds-has-error");
            $A.util.addClass(component.find('Partner_Rep__c'+"_help"), "none");
            component.set('v.dealRegFields.Partner_Rep__c', contactRec.searchText);
        }
    },
    handleClearPartnerRepContact : function(component, event, helper){
        let contactRec = event.getParams();
        console.log('handleClearPartnerAccount'+JSON.stringify(contactRec));
        if(contactRec){
            component.set('v.dealRegFields.Partner_Rep__c', '');
            component.set('v.dealRegFields.Partner_Rep_Email_Address__c', '');
            component.set('v.dealRegFields.Partner_Rep_Title__c','');
            component.set('v.dealRegFields.Partner_Rep_Phone_Number__c','');
        }
    },
    handleSelectedPartnerSEContact : function(component, event, helper){
        let contactRec = event.getParams();
        if(contactRec){
            for(var i = 0 ; i < contactRec.conList.length; i ++){
                if(contactRec.conList[i].Id == contactRec.Id){
                    component.set('v.dealRegFields.Partner_SE_Name__c', contactRec.conList[i].Name);
                    component.set('v.dealRegFields.Partner_SE_Email__c', contactRec.conList[i].Email);
                    component.set('v.dealRegFields.Partner_SE_Phone__c',contactRec.conList[i].Phone);
                }
            }
        }
    },
    handleSelectedPartnerSEContactSearch : function(component, event, helper){
        let contactRec = event.getParams();
        if(contactRec){
            $A.util.removeClass(component.find('Partner_SE_Name__c'), "slds-has-error");
            $A.util.addClass(component.find('Partner_SE_Name__c_help'), "none");
            component.set('v.dealRegFields.Partner_SE_Name__c', contactRec.searchText);
        }
    },
    handleClearPartnerSEContact : function(component, event, helper){
        let contactRec = event.getParams();
        console.log('handleClearPartnerAccount'+JSON.stringify(contactRec));
        if(contactRec){
            component.set('v.dealRegFields.Partner_SE_Name__c','');
            component.set('v.dealRegFields.Partner_SE_Email__c', '');
            component.set('v.dealRegFields.Partner_SE_Phone__c','');
        }
    },
    //PRIT24-445-End
    //PRIT26-548-Start
    handleCustomerCategoryChange : function(component, event, helper){
        helper.evaluateDistributorLogic(component);
    },
    //PRIT26-548-End
    //PRIT26-680-Start
    handleOppSpecificsChange : function(component, event, helper) {
        helper.handleOppSpecificsChange(component,event);
    }
    //PRIT26-680-End
})