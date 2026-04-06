({
	doInit : function(cmp) {
        var getUrl = window.location;
        var baseUrl = getUrl .protocol + "//" + getUrl.host + "/" + getUrl.pathname.split('/')[1];
        var domainUrl = baseUrl.split('.lightning.')[0];
        var classicUrl = domainUrl+'.my.salesforce.com/'+cmp.get("v.recordId")
        cmp.set("v.classicUrl",classicUrl);
    }
})