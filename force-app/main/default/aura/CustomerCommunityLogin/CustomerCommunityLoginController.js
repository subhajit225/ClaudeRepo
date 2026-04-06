({
    initialize: function(component, event, helper) {

        // CIAM-280: Fix for Support Portal links are truncated after One Passport authentication
        let csp_starturl = new URL(window.location.href).href.split('startURL')[1];
        if(decodeURIComponent(csp_starturl) != '=/s/'){
            console.log('page startURL:: ',decodeURIComponent(csp_starturl));
            localStorage.setItem('csp_starturl', decodeURIComponent(csp_starturl));
            localStorage.setItem('csp_starturl_mutiple', decodeURIComponent(csp_starturl));
        }
        // removing old links from cache if URL in login page
        else{
            localStorage.removeItem('csp_starturl');
            localStorage.removeItem('csp_starturl_mutiple');
        }

        helper.fetchCustomeSetting(component, event, helper);
    },
    
    jsLoaded: function(component, event, helper) {
        var key = CryptoJS.lib.WordArray.random(8);
        console.log(key.toString())
        component.set('v.randomCipherKey',key.toString());
    },
    
    handleLogin: function (component, event, helpler) {
        // Removeing Multiple Users key and values from Localstaorage: To get dropdown on next login button
        localStorage.removeItem('SupportMultipltUsers');
        localStorage.removeItem('loginMode');
        helpler.handleLogin(component, event, helpler);
    },
    
    setStartUrl: function (component, event, helpler) {
        var startUrl = event.getParam('startURL');
        if(startUrl) {
            component.set("v.startUrl", startUrl);
        }
    },
    
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },
    
    onKeyUp: function(component, event, helper){
        //checks for "enter" key
        if (event.keyCode  == 13) {
            helper.handleLogin(component, event, helper);
        }
    },
    
    navigateToForgotPassword: function(cmp, event, helper) {
        var forgotPwdUrl = cmp.get("v.communityForgotPasswordUrl");
        if ($A.util.isUndefinedOrNull(forgotPwdUrl)) {
            forgotPwdUrl = cmp.get("v.forgotPasswordUrl");
        }
        var startUrl = cmp.get("v.startUrl");
        if(startUrl){
            if(forgotPwdUrl.indexOf("?") === -1) {
                forgotPwdUrl = forgotPwdUrl + '?startURL=' + decodeURIComponent(startUrl);
            } else {
                forgotPwdUrl = forgotPwdUrl + '&startURL=' + decodeURIComponent(startUrl);
            }
        }
        var attributes = { url: forgotPwdUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    
    navigateToSelfRegister: function(cmp, event, helper) {
        var selfRegUrl = cmp.get("v.communitySelfRegisterUrl");
        if (selfRegUrl == null) {
            selfRegUrl = cmp.get("v.selfRegisterUrl");
        }
        var startUrl = cmp.get("v.startUrl");
        if(startUrl){
            if(selfRegUrl.indexOf("?") === -1) {
                selfRegUrl = selfRegUrl + '?startURL=' + decodeURIComponent(startUrl);
            } else {
                selfRegUrl = selfRegUrl + '&startURL=' + decodeURIComponent(startUrl);
            }
        }
        var attributes = { url: selfRegUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    closeModal: function(cmp, event, helper) {
        cmp.set("v.showError",false);
    }
})