({
    doinit : function(component, event, helper) {

        var action = component.get("c.fetchMultipleUsers");
        action.setCallback(component, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result[0]
                    && result[0].Contact.Account.GTC__c == 'Denied'){
                        component.set("v.isGtcAccount", true);
                }
            }else if(state === "ERROR"){
                console.log('There was a problem in doinit fetchMultipleUsers : '+JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);
        
        let csp_starturl = localStorage.getItem('csp_starturl');
        console.log('csp_starturl:: ',csp_starturl);

        if(csp_starturl
            && csp_starturl.includes('=/servlet/')){
                let url_redirect = $A.get("$Label.c.Community_Base_URL").replace('/s/','/')+csp_starturl.replace('=/','');
                window.open(url_redirect, "_self");
        }else{
            // CIAM-280: Fix for Support Portal links are truncated after One Passport authentication
            if(csp_starturl 
                && csp_starturl!=null 
                && csp_starturl!='undefined' 
                && csp_starturl!=''
                && csp_starturl != '=/s/'){
                localStorage.setItem('csp_starturl', '');
                let url_redirect = $A.get("$Label.c.Community_Base_URL")+csp_starturl.replace('=/s/','');
                window.open(url_redirect, "_self");
            }
            
            let csp_starturl_mutiple = localStorage.getItem('csp_starturl_mutiple');
            let is_mu_select = localStorage.getItem('is_mu_select');
            if(is_mu_select
                && csp_starturl_mutiple  
                && csp_starturl_mutiple!=null 
                && csp_starturl_mutiple!='undefined' 
                && csp_starturl_mutiple!=''
                && csp_starturl_mutiple != '=/s/'){
                    localStorage.setItem('is_mu_select', '');
                    let redirect_URL = $A.get("$Label.c.Community_Base_URL")+csp_starturl_mutiple.replace('=/s/','');
                    window.open(redirect_URL, "_self");
            }
            // CIAM-280: Fix for Support Portal links are truncated after One Passport authentication
        }
        
        var search = location.search;
        console.log(search);
        if(!!search){
            if(search.includes('file') && !search.includes('amazonaws')){
                var splitafter = search.split('=').pop();
                var enc = encodeURI(splitafter);//to encode
                console.log(enc);
                var dec = decodeURI(enc);
                console.log(dec);
                var str_esc=unescape(dec);
                console.log(str_esc);
                location ='https://support.rubrik.com/servlet/servlet.FileDownload'+str_esc;                
            }
        }

        // Check for Disable Okta User Sync flag
        var action = component.get("c.getOktaAttributesCustomSettings");
        action.setCallback(component, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();

                // CIAM-189: when impersonating support user from salesforce through Contact record page
                let sfUrl = document.referrer;

                let loginMode = localStorage.getItem('loginMode');

                // Display drop down for multiple Users
                if(!result.Disable_User_Sync__c
                    && !sfUrl.includes('my.salesforce.com') 
                    && !sfUrl.includes('lightning.force.com')
                    && loginMode != "sf_contact"){
                        helper.getMultipleUsers(component);
                }else{
                    // Impersonating contact (multiple users) from SF: Login to diorectly to CSP
                    localStorage.setItem("loginMode", "sf_contact");
                }
            }else if(state === "ERROR"){
                console.log('There was a problem in getOktaAttributesCustomSettings : '+JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);
    }
})