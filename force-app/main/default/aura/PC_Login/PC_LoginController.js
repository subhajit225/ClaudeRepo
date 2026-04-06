({
    initialize: function(component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();    
        component.set('v.isUsernamePasswordEnabled', helper.getIsUsernamePasswordEnabled(component, event, helper));
        component.set("v.isSelfRegistrationEnabled", helper.getIsSelfRegistrationEnabled(component, event, helper));
        component.set("v.communityForgotPasswordUrl", helper.getCommunityForgotPasswordUrl(component, event, helper));
        component.set("v.communitySelfRegisterUrl", helper.getCommunitySelfRegisterUrl(component, event, helper));
        helper.getCodeofConduct(component, event, helper);
        helper.getDisableSync(component, event, helper);
    },
    
    handleLogin: function (component, event, helpler) {
        var urlparameter = '';
        if(window.location.href.indexOf('startURL') > -1){
            var temp = window.location.href.split('startURL=');
            var temp1 = temp[1].split('&');
            urlparameter = temp1[0];
            component.set("v.startUrl", urlparameter);
        }else{
            
        }
        helpler.handleLogin(component, event, helpler);
    },
    
    onKeyUp: function(component, event, helpler){
        if (event.keyCode === 13) {
            var urlparameter = '';
            if(window.location.href.indexOf('startURL') > -1){
                var temp = window.location.href.split('startURL=');
                var temp1 = temp[1].split('&');
                urlparameter = temp1[0];
                component.set("v.startUrl", urlparameter);
            }
            helpler.handleLogin(component, event, helpler);
        }
    },
    
    navigateToForgotPassword: function(cmp, event, helper) {
        var forgotPwdUrl = cmp.get("v.communityForgotPasswordUrl");
        if ($A.util.isUndefinedOrNull(forgotPwdUrl)) {
            forgotPwdUrl = cmp.get("v.forgotPasswordUrl");
        }
        var attributes = { url: forgotPwdUrl };
        $A.get("e.force:navigateToURL").setParams(attributes).fire();
    },
    handleGDPRAction : function(component, event, helper) {
        console.log('@@ handleGDPRAction - component.get("v.showTerms") '+component.get("v.showTerms"));
        if(component.get("v.showTerms").indexOf('Both') > -1){
            component.set("v.showTerms",'Conduct');
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
        }else if(component.get("v.showTerms").indexOf('success') > -1 || component.get("v.showTerms").indexOf('Terms') > -1){
            helper.handlesubmit(component, event, helper);
        }
    },
    handleConductClick : function(component, event, helper) {
        component.set("v.showTerms",'success');
        helper.handlesubmit(component, event, helper);
    },
    navigateToPartnerAccess : function (component, event, helper) {
        var url = window.location.href;
        var purl = '';  
        if(url.indexOf('login') > -1){
            var temp = url.split('login');
            purl = temp[0]+component.get("v.partnerAccessURL");
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": purl,
            "isredirect": false
        });
        urlEvent.fire();
    },
    getSelected : function(component,event,helper){
        var url = window.location.href;
        var purl = '';  
        // display modle and set seletedDocumentId attribute with selected record Id   
        component.set("v.hasModalOpen" , true);
        component.set("v.selectedDocumentId" , event.currentTarget.getAttribute("data-Id")); 
        if(url.indexOf('/s/login/') > -1){
            var temp = url.split('/s/login/');
            purl = temp[0]+'/servlet/servlet.FileDownload?file='+component.get("v.selectedDocumentId");
        }

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": purl,
            "isredirect": false
        });
        urlEvent.fire();
        
    }
})