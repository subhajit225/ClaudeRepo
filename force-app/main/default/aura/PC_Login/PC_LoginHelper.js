({
    
    
    handleLogin: function (component, event, helper) {
        
        var username = component.get("v.username");
        var password = component.get("v.password");
        var action = component.get("c.login");
        var startUrl = component.get("v.startUrl");
        username =  document.getElementById('username').value;
        password = document.getElementById('password').value;
        component.set("v.username",username);   
        component.set("v.password",password);
        component.set("v.errorMessage","");
        component.set("v.showError",false);
        component.set("v.optIn",false);
        startUrl = decodeURIComponent(startUrl);
        //alert(password);
        action.setParams({username:username, password:password, startUrl:startUrl});
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set("v.showTerms",rtnValue);
                console.log('@@ handleLogin - component.get("v.showTerms") '+component.get("v.showTerms"));
                if(component.get("v.showTerms") != "Terms" && component.get("v.showTerms") != "Both"){
                    component.set("v.errorMessage",rtnValue);
                    component.set("v.showError",true);
                }
               if(component.get("v.showTerms").indexOf('Terms') > -1 || component.get("v.showTerms").indexOf('Both') > -1){
                    if(component.get("v.showTerms").indexOf('Terms') > -1){ 
                   		component.set("v.showTerms","Terms");
                    }
                    if(!$A.util.hasClass(component.find("termsDiv"),'slds-show')){
                        $A.util.addClass(component.find("termsDiv"),'slds-show');
                        $A.util.removeClass(component.find("termsDiv"),'slds-hide');
                    }
                    if(!$A.util.hasClass(component.find("loginDiv"),'slds-hide')){
                        $A.util.addClass(component.find("loginDiv"),'slds-hide');
                        $A.util.removeClass(component.find("loginDiv"),'slds-show');
                    }
                    if(!$A.util.hasClass(component.find("conductDiv"),'slds-hide')){
                        $A.util.addClass(component.find("conductDiv"),'slds-hide');
                        $A.util.removeClass(component.find("conductDiv"),'slds-show');
                    }
                }else if(component.get("v.showTerms").indexOf('Conduct') > -1){
                    if(!$A.util.hasClass(component.find("conductDiv"),'slds-show')){
                        $A.util.addClass(component.find("conductDiv"),'slds-show');
                        $A.util.removeClass(component.find("conductDiv"),'slds-hide');
                    }
                    if(!$A.util.hasClass(component.find("termsDiv"),'slds-hide')){
                        $A.util.addClass(component.find("termsDiv"),'slds-hide');
                        $A.util.removeClass(component.find("termsDiv"),'slds-show');
                    }
                    if(!$A.util.hasClass(component.find("loginDiv"),'slds-hide')){
                        $A.util.addClass(component.find("loginDiv"),'slds-hide');
                        $A.util.removeClass(component.find("loginDiv"),'slds-show');
                    }
                }
                else{
                    if(!$A.util.hasClass(component.find("loginDiv"),'slds-show')){
                        $A.util.addClass(component.find("loginDiv"),'slds-show');
                        $A.util.removeClass(component.find("loginDiv"),'slds-hide');
                    }
                    if(!$A.util.hasClass(component.find("termsDiv"),'slds-hide')){
                        $A.util.addClass(component.find("termsDiv"),'slds-hide');
                        $A.util.removeClass(component.find("termsDiv"),'slds-show');
                    }
                    if(!$A.util.hasClass(component.find("conductDiv"),'slds-hide')){
                        $A.util.addClass(component.find("conductDiv"),'slds-hide');
                        $A.util.removeClass(component.find("conductDiv"),'slds-show');
                    }
                }
            }
            
        });
        $A.enqueueAction(action);
    },
    handlesubmit : function (component, event, helper) {
        var username = component.get("v.username");
        var password = component.get("v.password");
        var OptIn = component.get("v.optIn");
        var startUrl = component.get("v.startUrl");
        component.set("v.errorMessage","");
        component.set("v.showError",false);
        startUrl = decodeURIComponent(startUrl);
        
        var action = component.get("c.continueAfterOptInCheck");
        
        action.setParams({username:username, password:password, OptIn:component.get("v.optIn"), conductCheck:component.get("v.conductCheck"), startUrl:startUrl});
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set("v.showTerms",rtnValue);
                if(component.get("v.showTerms") != "Terms" && component.get("v.showTerms") != "Both"){
                    component.set("v.errorMessage",rtnValue);
                    component.set("v.showError",true);
                }
                if(component.get("v.showTerms").indexOf('Terms') > -1){
                    component.set("v.showTerms","Terms");
                    if(!$A.util.hasClass(component.find("termsDiv"),'slds-show')){
                        $A.util.addClass(component.find("termsDiv"),'slds-show');
                        $A.util.removeClass(component.find("termsDiv"),'slds-hide');
                    }
                    if(!$A.util.hasClass(component.find("loginDiv"),'slds-hide')){
                        $A.util.addClass(component.find("loginDiv"),'slds-hide');
                        $A.util.removeClass(component.find("loginDiv"),'slds-show');
                    }
                    if(!$A.util.hasClass(component.find("conductDiv"),'slds-hide')){
                        $A.util.addClass(component.find("conductDiv"),'slds-hide');
                        $A.util.removeClass(component.find("conductDiv"),'slds-show');
                    }
                }else if(component.get("v.showTerms").indexOf('Conduct') > -1 || component.get("v.showTerms").indexOf('Both') > -1){
                    if(!$A.util.hasClass(component.find("conductDiv"),'slds-show')){
                        $A.util.addClass(component.find("conductDiv"),'slds-show');
                        $A.util.removeClass(component.find("conductDiv"),'slds-hide');
                    }
                    if(!$A.util.hasClass(component.find("termsDiv"),'slds-hide')){
                        $A.util.addClass(component.find("termsDiv"),'slds-hide');
                        $A.util.removeClass(component.find("termsDiv"),'slds-show');
                    }
                    if(!$A.util.hasClass(component.find("loginDiv"),'slds-hide')){
                        $A.util.addClass(component.find("loginDiv"),'slds-hide');
                        $A.util.removeClass(component.find("loginDiv"),'slds-show');
                    }
                }
                else{
                    if(!$A.util.hasClass(component.find("loginDiv"),'slds-show')){
                        $A.util.addClass(component.find("loginDiv"),'slds-show');
                        $A.util.removeClass(component.find("loginDiv"),'slds-hide');
                    }
                    if(!$A.util.hasClass(component.find("termsDiv"),'slds-hide')){
                        $A.util.addClass(component.find("termsDiv"),'slds-hide');
                        $A.util.removeClass(component.find("termsDiv"),'slds-show');
                    }
                    if(!$A.util.hasClass(component.find("conductDiv"),'slds-hide')){
                        $A.util.addClass(component.find("conductDiv"),'slds-hide');
                        $A.util.removeClass(component.find("conductDiv"),'slds-show');
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    getIsUsernamePasswordEnabled : function (component, event, helper) {
        var action = component.get("c.getIsUsernamePasswordEnabled");
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.isUsernamePasswordEnabled',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getIsSelfRegistrationEnabled : function (component, event, helper) {
        var action = component.get("c.getIsSelfRegistrationEnabled");
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.isSelfRegistrationEnabled',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getCommunityForgotPasswordUrl : function (component, event, helper) {
        var action = component.get("c.getForgotPasswordUrl");
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.communityForgotPasswordUrl',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getCommunitySelfRegisterUrl : function (component, event, helper) {
        var action = component.get("c.getSelfRegistrationUrl");
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.communitySelfRegisterUrl',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getCodeofConduct : function (component, event, helper) {
        var action = component.get("c.getpdf");
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            console.log(rtnValue);
            if (rtnValue !== null) {
                component.set('v.doc',rtnValue);
                console.log(component.get('v.doc'));
            }
        });
        $A.enqueueAction(action);
    },

    getDisableSync : function (component, event, helper){
        console.log('in helper get confid');
        var action = component.get("c.getOktaCustomStng");
        action.setCallback(this, function(a){
            var rtnValue = a.getReturnValue();
            console.log('disable sync',rtnValue);
            if (rtnValue !== null) {
                component.set('v.disableSync',rtnValue.disableSync);
                component.set('v.loginPortalUrl',rtnValue.baseUrl+'/home/salesforce/'+rtnValue.partnerApplicationId+'/46');
                component.set('v.forgotPasswordLink',rtnValue.baseUrl + rtnValue.forgotPasswordUrl);
                
            }
        });
        $A.enqueueAction(action);
    }
})