({
    myAction : function(component, event, helper) {

    },

    handleLogout : function(component) {
        let communityBaseUrl = $A.get("$Label.c.Community_Base_URL").split('/s/');
        let encodedBaseUrl = encodeURI(communityBaseUrl);
        window.location.replace(communityBaseUrl[0]+"/secur/logout.jsp?retUrl="+encodedBaseUrl+"login");
    },
})