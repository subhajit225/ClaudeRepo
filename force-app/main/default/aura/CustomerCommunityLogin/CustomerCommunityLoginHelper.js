({
    
    qsToEventMap: {
        'startURL'  : 'e.c:setStartUrl'
    },

    qsToEventMap2: {
        'expid'  : 'e.c:setExpId'
    },

    fetchCustomeSetting: function (component, event, helpler) {
        var action = component.get("c.getOktaAttributes");
        action.setCallback(this, function(resp){
            if(resp.getState() === 'SUCCESS'){
                var res = resp.getReturnValue();
                component.set('v.oktaAttributes',res);
                component.set('v.partnerPortalURL',"https://partner.rubrik.com/s/");
                if(res.Disable_User_Sync__c){
                    this.userLogin(component, event, helpler); 
                }else{
                    component.set("v.communityForgotPasswordUrl", res.Okta_Base_URL__c+res.Forgot_Password__c);
                }
            }else if (resp.getState() === "ERROR") {
                var errors = resp.getError();
                if (errors
                    && errors[0] 
                    && errors[0].message) {
                        console.log("Error message for fetchCustomeSetting: " +errors[0].message);
                }
            }
        
        });
        $A.enqueueAction(action);
    },

    userLogin: function (component, event, helper, res) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();    
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap2}).fire();
        component.set('v.isUsernamePasswordEnabled', helper.getIsUsernamePasswordEnabled(component, event, helper));
        component.set("v.isSelfRegistrationEnabled", helper.getIsSelfRegistrationEnabled(component, event, helper));
        console.log('communityForgotPasswordUrl:: ', component.get("v.communityForgotPasswordUrl"));
        component.set("v.communitySelfRegisterUrl", helper.getCommunitySelfRegisterUrl(component, event, helper));
        component.find("username").set("v.value",localStorage.usrname);
        localStorage.usrname = 'abc';
        localStorage.pass = '';
        localStorage.chkbx = '';
    },
    
    handleLogin: function (component, event, helpler) {
        let oktaAttributes = component.get("v.oktaAttributes");
        if(oktaAttributes.Disable_User_Sync__c){
            var param1 = component.find("username").get("v.value");
            var param2 = component.find("password").get("v.value");
            var key = component.get('v.randomCipherKey');
            var p1encrypted = CryptoJS.AES.encrypt(param1, CryptoJS.enc.Utf8.parse(key), { 
                iv: CryptoJS.enc.Utf8.parse(key),
                mode: CryptoJS.mode.CBC
            });
            console.log(p1encrypted.toString());
            var p2encrypted = CryptoJS.AES.encrypt(param2, CryptoJS.enc.Utf8.parse(key), { 
                iv: CryptoJS.enc.Utf8.parse(key),
                mode: CryptoJS.mode.CBC
            });
            var action = component.get("c.login");
            var startUrl = component.get("v.startUrl");
            
            startUrl = decodeURIComponent(startUrl);
            
            action.setParams({param1:p1encrypted.toString(), param2:p2encrypted.toString()+'ref;2#'+key, startUrl:startUrl});
            action.setCallback(this, function(a){
                var rtnValue = a.getReturnValue();
                if (rtnValue !== null) {
                    component.set("v.errorMessage",rtnValue);
                    component.set("v.showError",true);
                }
            });
            $A.enqueueAction(action);
        }else{
            window.open(oktaAttributes.PortalSAMLUrl__c+oktaAttributes.Customer_User_AppId__c+"/46", "_self");
        }
    },
    
    getIsUsernamePasswordEnabled : function (component, event, helpler) {
        var action = component.get("c.getIsUsernamePasswordEnabled");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.isUsernamePasswordEnabled',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getIsSelfRegistrationEnabled : function (component, event, helpler) {
        var action = component.get("c.getIsSelfRegistrationEnabled");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.isSelfRegistrationEnabled',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    
    getCommunityForgotPasswordUrl : function (component, event, helpler) {
        var action = component.get("c.getForgotPasswordUrl");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.communityForgotPasswordUrl',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },
    
    getCommunitySelfRegisterUrl : function (component, event, helpler) {
        var action = component.get("c.getSelfRegistrationUrl");
        action.setCallback(this, function(a){
        var rtnValue = a.getReturnValue();
            if (rtnValue !== null) {
                component.set('v.communitySelfRegisterUrl',rtnValue);
            }
        });
        $A.enqueueAction(action);
    },

    setBrandingCookie: function (component, event, helpler) {
        var expId = component.get("v.expid");
        if (expId) {
            var action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){ });
            $A.enqueueAction(action);
        }
    }
})