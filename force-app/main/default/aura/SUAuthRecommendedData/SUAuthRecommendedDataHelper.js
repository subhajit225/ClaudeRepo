({
    doRecommFunc : function(component, event, helper){
        var action = component.get("c.getCommunityCustomSettings");
        var permission = '';
        action.setParams({
            "authParams": {
                "permission": permission
            }
        });
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() == "SUCCESS") {
                var result= response.getReturnValue();
                if(result.isCustomSettingFilled){
                    component.set("v.customSettingsFilled", result.isCustomSettingFilled);
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
                    component.set("v.Bearer",result.token);
                    component.set("v.customSettingErrorMessage","");
                    if(result.UserType == "Guest" || result.UserType == undefined){
                        result.userEmail = '';
                    }
                    if (result.userEmail != null && result.userEmail != '') {
                        component.set("v.currentUserEmail", result.userEmail);
                    }
                    var searchQuery = '';
                    searchQuery = helper.getURLParameter('searchString');
                    if(searchQuery === null && searchQuery === 'undefined'){
                    	searchQuery = '';
                    }
                    var analyticsCmp = component.find("SuAnalytics");
                    if(component.get("v.child") == 'search'){
                        var sid = analyticsCmp.analytics('_gz_taid', '');
                        var cookie = analyticsCmp.analytics('_gz_sid', '');
                    }
                    var data = {
                        "searchString": searchQuery,
                        "uid": component.get("v.uid"),
                        "language": localStorage.getItem('language') || 'en',
                        "sid": sid + '$Enter$',
                        "cookie": cookie,
                        "useremail": component.get("v.currentUserEmail")
                    }
                    let scConfigObj;
                    if(component.get("v.scConfigObj")) {
                        scConfigObj = component.get("v.scConfigObj")
                    }
                    if(component.get("v.child") !== 'search') {
                        let searchStringForWidget = '';
                        const config = scConfigObj && scConfigObj.recommendations_widget_config;
                      
                        if (config && config.rec_widget_redirect_url) {
                            component.set("v.redirectionUrl", config.rec_widget_redirect_url)
                        }
                        if(config){
                            if(!config.rec_widget_regex || (window.location && !window.location.href.match(new RegExp(config.rec_widget_regex,'gm' )))){
                                searchStringForWidget = document && document.title || '';
                            }
                        }
                        data.searchString = searchStringForWidget;
                        data.recommendationType = 2;
                        data.sid= "";
                    } 

                    if (component.get("v.child") == 'search' || scConfigObj.rec_widget == 1) {
                        var xmlHttp = new XMLHttpRequest();
                        var url = component.get("v.endPoint") + "/ai/authSURecommendation";
                        xmlHttp.withCredentials = true;
                        xmlHttp.open("POST", url, true);
                        xmlHttp.setRequestHeader("Accept", "application/json");
                        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
                        xmlHttp.setRequestHeader('Content-Type', 'application/json');

                        xmlHttp.send(JSON.stringify(data));
                        xmlHttp.onreadystatechange = function () {
                            if (xmlHttp.readyState === 4) {
                                if (xmlHttp.status === 200) {
                                    var result = JSON.parse(xmlHttp.response);
                                    if (result.statusCode != 402) {
                                        component.set("v.recommendedList", result.result.hits);
                                    } else {
                                        if (result.statusCode == 402)
                                            $A.get('e.force:refreshView').fire()
                                    }
                                }
                                else {
                                    $A.log("Errors", response.getState());
                                }
                            }
                        }
                    }
                }else{
                    component.set("v.customSettingErrorMessage",'Please configure your SearchUnify and try again.');
                }
            }else {
            	console.log("Failed with state: " + response.getState());
            }
        });
        $A.enqueueAction(action);
    },
    getURLParameter : function(param) {
        var m = window;
        var s = m.document.URL;
        var result = decodeURIComponent((new RegExp('[?|&|#]' + param + '=' + '([^&;#]+?)(&|#|;|$)').exec(decodeURIComponent(s)) || [, ""])[1].replace(/\+/g, '%20'));
        return result;
    },
    runScriptMethodFunc: function(component,event){
        var data_Id    = event.target.getAttribute("data-Id") || "";
        var data_type  = event.target.getAttribute("data-Type") || "";
        var data_index = event.target.getAttribute("data-Index") || "";
        var data_rank = event.target.getAttribute("data-Rank") || "";
        var data_url = event.target.getAttribute("data-url") || "";
        var data_sub = event.target.getAttribute("data-Sub") || "";
        if(data_rank != ''){
            data_rank = (+data_rank) +1;
        }
        var childCmp = component.find("SuAnalytics");
        if(data_Id != '' && data_sub != ''){
            var auramethodResult = childCmp.analytics('conversion',{index:data_index,type:data_type,id:data_Id, rank:data_rank, convUrl:data_url, convSub:data_sub});
        }
	}
})